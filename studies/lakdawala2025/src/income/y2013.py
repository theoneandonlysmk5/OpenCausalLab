"""2013 Income harmonization — EH_Income_2013.do."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from ..persona.common import read_persona
from opencausallab.stata_semantics.stata_utils import replace_where, to_numeric
from .common import (
    build_labor_totals,
    build_remittances_block,
    finalize_income,
    make_person_id,
    monthly_rev,
    monthly_wage,
    rowtotal,
    zero_if_missing,
)


def harmonize_income_2013(raw_path: Path | None = None) -> pd.DataFrame:
    df = read_persona(2013, raw_path)
    out = make_person_id(df, nro_col="nro2a")
    out["t"] = 2013
    out["depto"] = to_numeric(df["id01"])
    out["area"] = to_numeric(df["area"])

    for occ, inc, per in [("main", "s6_25a", "s6_25b"), ("sec", "s6_43a", "s6_43b")]:
        out[f"wage_monthly_{occ}"] = monthly_wage(df[inc], df[per])
    out["wage_total"] = rowtotal(out, ["wage_monthly_main", "wage_monthly_sec"])

    out["bonus_monthly_main"] = to_numeric(df["s6_26a"]) / 12
    out["aguinaldo_monthly_main"] = to_numeric(df["s6_26b"]) / 12
    out["aguinaldo_yearly_main"] = to_numeric(df["s6_26b"])
    out["comision_monthly_main"] = monthly_wage(df["s6_27a1"], df["s6_27a2"])
    out["overtime_monthly_main"] = monthly_wage(df["s6_27b1"], df["s6_27b2"])
    out["extra_wages_main"] = rowtotal(
        out,
        ["bonus_monthly_main", "aguinaldo_monthly_main", "comision_monthly_main", "overtime_monthly_main"],
    )
    out["extra_wages_sec"] = zero_if_missing(to_numeric(df["s6_42a1"]) / 12)
    out["extra_wages"] = to_numeric(out["extra_wages_main"]) + to_numeric(out["extra_wages_sec"])

    kinds = ["food", "trans", "clothing", "lodging", "others"]
    letters = ["a", "b", "c", "d", "e"]
    inkind_cols = []
    for kind, letter in zip(kinds, letters):
        col = f"inkind_{kind}_monthly_main"
        out[col] = zero_if_missing(monthly_rev(df[f"s6_30{letter}3"], df[f"s6_30{letter}2"]))
        inkind_cols.append(col)
    out["inkind_payments_main"] = rowtotal(out, inkind_cols)
    out["inkind_payments_sec"] = rowtotal(df, ["s6_42b1", "s6_42c1"]) / 12
    out["inkind_payments"] = to_numeric(out["inkind_payments_main"]) + to_numeric(out["inkind_payments_sec"])

    out["y_wl_bonus_main"] = rowtotal(out, ["extra_wages_main", "inkind_payments_main"])
    out["y_wl_bonus_sec"] = rowtotal(out, ["extra_wages_sec", "inkind_payments_sec"])
    out["y_wl_bonus"] = to_numeric(out["y_wl_bonus_main"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings_main"] = to_numeric(out["wage_monthly_main"]) + to_numeric(out["y_wl_bonus_main"])
    out["y_earnings_sec"] = to_numeric(out["wage_monthly_sec"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings"] = to_numeric(out["wage_total"]) + to_numeric(out["y_wl_bonus"])

    for occ, base in [("main", "_31"), ("sec", "_43")]:
        out[f"rev_nw_labor_{occ}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s6{base}a"], df[f"s6{base}b"])
        )
    out["rev_nw_labor"] = rowtotal(out, ["rev_nw_labor_main_monthly", "rev_nw_labor_sec_monthly"])

    cost_names = ["inputs", "wage", "rent", "utilities", "taxes_others"]
    cost_letters = ["a", "b", "c", "d", "e"]
    for occ, base in [("main", "_32"), ("sec", "_44")]:
        cost_cols = []
        for name, letter in zip(cost_names, cost_letters):
            col = f"{name}_cost_monthly_{occ}"
            out[col] = zero_if_missing(
                monthly_rev(df[f"s6{base}{letter}1"], df[f"s6{base}{letter}2"])
            )
            cost_cols.append(col)
        out[f"rent_cost_monthly_{occ}"] = (
            to_numeric(out[f"rent_cost_monthly_{occ}"])
            + to_numeric(out[f"utilities_cost_monthly_{occ}"])
        )
        op_cols = [
            f"inputs_cost_monthly_{occ}",
            f"wage_cost_monthly_{occ}",
            f"rent_cost_monthly_{occ}",
            f"taxes_others_cost_monthly_{occ}",
        ]
        out[f"operational_cost_{occ}"] = rowtotal(out, op_cols)
    out["operational_cost"] = rowtotal(out, ["operational_cost_main", "operational_cost_sec"])

    out = build_labor_totals(out)

    for tag, base in [("main", "_33"), ("sec", "_45")]:
        sr = to_numeric(df[f"s6{base}a"])
        sr_m = monthly_rev(sr, df[f"s6{base}b"])
        out[f"y_nw_labor{tag}_sr_m"] = replace_where(sr_m, 0.0, sr.isna())
    out["y_nw_labor_sr"] = rowtotal(out, ["y_nw_labormain_sr_m", "y_nw_laborsec_sr_m"])

    out["retirement"] = to_numeric(df["s7_01a"])
    out["transfer_veterans"] = to_numeric(df["s7_01b"])
    out["transfer_disability"] = to_numeric(df["s7_01c"])
    out["transfer_widows"] = to_numeric(df["s7_01d"])
    out["y_social_security"] = rowtotal(
        out, ["retirement", "transfer_veterans", "transfer_disability", "transfer_widows"]
    )
    out["y_elderly_transfer"] = zero_if_missing(df["s7_01eb"])
    out["y_government"] = rowtotal(out, ["y_social_security", "y_elderly_transfer"])

    for name, letter in [("family_asistance", "a"), ("people_incountry", "b")]:
        out[f"{name}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s7_05{letter}1"], df[f"s7_05{letter}2"])
        )
    out["y_local_transfers"] = rowtotal(out, ["family_asistance_monthly", "people_incountry_monthly"])

    rem = build_remittances_block(
        df,
        receive_col="s7_06",
        amount_col="s7_09a",
        period_col="s7_07",
        currency_col="s7_09b",
    )
    out = pd.concat([out, rem], axis=1)

    for name, letter in [("revenues_interest", "a"), ("revenues_renting", "b"), ("revenues_other", "c")]:
        out[name] = zero_if_missing(df[f"s7_02{letter}"])
    out["y_int_assets_regular"] = rowtotal(out, ["revenues_interest", "revenues_renting", "revenues_other"])

    nr_map = {
        "revenues_rental_agric": "s7_03a",
        "revenues_dividends": "s7_03b",
        "revenues_rental_equip": "s7_03c",
        "revenues_indemnization": "s7_04a",
        "revenues_insurance": "s7_04b",
        "revenues_other_nr": "s7_04c",
    }
    for var, col in nr_map.items():
        out[var] = zero_if_missing(to_numeric(df[col]) / 12)
    out["y_non_regular"] = rowtotal(out, list(nr_map.keys()))

    return finalize_income(out)
