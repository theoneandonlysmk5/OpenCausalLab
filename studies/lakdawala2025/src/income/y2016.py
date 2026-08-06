"""2016 Income harmonization — EH_Income_2016.do."""

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


def harmonize_income_2016(raw_path: Path | None = None) -> pd.DataFrame:
    df = read_persona(2016, raw_path)
    out = make_person_id(df)
    out["t"] = 2016
    out["depto"] = to_numeric(df["depto"])
    out["area"] = to_numeric(df["area"])

    # 2016: sec wage s06g_48a (not 43a); revenue g_50; costs g_51 with other1+other2
    for occ, inc, per in [("main", "s06c_25a", "s06c_25b"), ("sec", "s06g_48a", "s06g_48b")]:
        out[f"wage_monthly_{occ}"] = monthly_wage(df[inc], df[per])
    out["wage_total"] = rowtotal(out, ["wage_monthly_main", "wage_monthly_sec"])

    out["bonus_monthly_main"] = to_numeric(df["s06c_26a"]) / 12
    out["aguinaldo_monthly_main"] = to_numeric(df["s06c_26b"]) / 12
    out["aguinaldo_yearly_main"] = to_numeric(df["s06c_26b"])
    out["comision_monthly_main"] = monthly_wage(df["s06c_27aa"], df["s06c_27ab"])
    out["overtime_monthly_main"] = monthly_wage(df["s06c_27ba"], df["s06c_27bb"])
    out["extra_wages_main"] = rowtotal(
        out,
        ["bonus_monthly_main", "aguinaldo_monthly_main", "comision_monthly_main", "overtime_monthly_main"],
    )
    out["extra_wages_sec"] = zero_if_missing(to_numeric(df["s06g_49a1"]) / 12)
    out["extra_wages"] = to_numeric(out["extra_wages_main"]) + to_numeric(out["extra_wages_sec"])

    kinds = ["food", "trans", "clothing", "lodging", "others"]
    letters = ["a", "b", "c", "d", "e"]
    inkind_cols = []
    for kind, letter in zip(kinds, letters):
        col = f"inkind_{kind}_monthly_main"
        out[col] = zero_if_missing(
            monthly_wage(df[f"s06c_30{letter}2"], df[f"s06c_30{letter}1"])
        )
        inkind_cols.append(col)
    out["inkind_payments_main"] = rowtotal(out, inkind_cols)
    out["inkind_payments_sec"] = rowtotal(df, ["s06g_49b1", "s06g_49c1"]) / 12
    out["inkind_payments"] = to_numeric(out["inkind_payments_main"]) + to_numeric(out["inkind_payments_sec"])

    out["y_wl_bonus_main"] = rowtotal(out, ["extra_wages_main", "inkind_payments_main"])
    out["y_wl_bonus_sec"] = rowtotal(out, ["extra_wages_sec", "inkind_payments_sec"])
    out["y_wl_bonus"] = to_numeric(out["y_wl_bonus_main"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings_main"] = to_numeric(out["wage_monthly_main"]) + to_numeric(out["y_wl_bonus_main"])
    out["y_earnings_sec"] = to_numeric(out["wage_monthly_sec"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings"] = to_numeric(out["wage_total"]) + to_numeric(out["y_wl_bonus"])

    for occ, base in [("main", "d_31"), ("sec", "g_50")]:
        out[f"rev_nw_labor_{occ}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s06{base}a"], df[f"s06{base}b"])
        )
    out["rev_nw_labor"] = rowtotal(out, ["rev_nw_labor_main_monthly", "rev_nw_labor_sec_monthly"])

    cost_names = ["inputs", "wage", "rent", "interest", "taxes", "other1", "other2"]
    cost_letters = ["a", "b", "c", "d", "e", "f", "g"]
    for occ, base in [("main", "d_32"), ("sec", "g_51")]:
        for name, letter in zip(cost_names, cost_letters):
            col = f"{name}_cost_monthly_{occ}"
            out[col] = zero_if_missing(
                monthly_rev(df[f"s06{base}{letter}a"], df[f"s06{base}{letter}b"])
            )
        out[f"other_cost_monthly_{occ}"] = rowtotal(
            out, [f"other1_cost_monthly_{occ}", f"other2_cost_monthly_{occ}"]
        )
        op_cols = [
            f"inputs_cost_monthly_{occ}",
            f"wage_cost_monthly_{occ}",
            f"rent_cost_monthly_{occ}",
            f"taxes_cost_monthly_{occ}",
            f"other_cost_monthly_{occ}",
        ]
        out[f"operational_cost_{occ}"] = rowtotal(out, op_cols)
    out["operational_cost"] = rowtotal(out, ["operational_cost_main", "operational_cost_sec"])

    out = build_labor_totals(out)

    for tag, base in [("main", "d_33"), ("sec", "g_52")]:
        sr = to_numeric(df[f"s06{base}a"])
        sr_m = monthly_rev(sr, df[f"s06{base}b"])
        out[f"y_nw_labor{tag}_sr_m"] = replace_where(sr_m, 0.0, sr.isna())
    out["y_nw_labor_sr"] = rowtotal(out, ["y_nw_labormain_sr_m", "y_nw_laborsec_sr_m"])

    out["retirement"] = to_numeric(df["s07a_01a"])
    out["transfer_veterans"] = to_numeric(df["s07a_01b"])
    out["transfer_disability"] = to_numeric(df["s07a_01c"])
    out["transfer_widows"] = to_numeric(df["s07a_01d"])
    out["y_social_security"] = rowtotal(
        out, ["retirement", "transfer_veterans", "transfer_disability", "transfer_widows"]
    )
    out["y_elderly_transfer"] = zero_if_missing(df["s07a_01e0"])
    out["y_government"] = rowtotal(out, ["y_social_security", "y_elderly_transfer"])

    for name, letter in [("family_asistance", "a"), ("people_incountry", "b")]:
        out[f"{name}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s07b_05{letter}a"], df[f"s07b_05{letter}b"])
        )
    out["y_local_transfers"] = rowtotal(out, ["family_asistance_monthly", "people_incountry_monthly"])

    rem = build_remittances_block(
        df,
        receive_col="s07c_06",
        amount_col="s07c_08a",
        period_col="s07c_07",
        currency_col="s07c_08b",
        encode=False,
    )
    out = pd.concat([out, rem], axis=1)

    for name, letter in [("revenues_interest", "a"), ("revenues_renting", "b"), ("revenues_other", "c")]:
        out[name] = zero_if_missing(df[f"s07a_02{letter}"])
    out["y_int_assets_regular"] = rowtotal(out, ["revenues_interest", "revenues_renting", "revenues_other"])

    nr_map = {
        "revenues_rental_agric": "s07a_03a",
        "revenues_dividends": "s07a_03b",
        "revenues_rental_equip": "s07a_03c",
        "revenues_indemnization": "s07a_04a",
        "revenues_insurance": "s07a_04b",
        "revenues_other_nr": "s07a_04c",
    }
    for var, col in nr_map.items():
        out[var] = zero_if_missing(to_numeric(df[col]) / 12)
    out["y_non_regular"] = rowtotal(out, list(nr_map.keys()))

    return finalize_income(out)
