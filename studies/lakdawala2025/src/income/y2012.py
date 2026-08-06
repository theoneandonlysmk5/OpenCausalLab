"""2012 Income harmonization — EH_Income_2012.do."""

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


def harmonize_income_2012(raw_path: Path | None = None) -> pd.DataFrame:
    df = read_persona(2012, raw_path)
    out = make_person_id(df, nro_col="nro1a")
    out["t"] = 2012
    out["depto"] = to_numeric(df["departamento"])
    out["area"] = to_numeric(df["area"])

    # Wages
    for occ, inc, per in [
        ("main", "s5_31a", "s5_31b"),
        ("sec", "s5_48a", "s5_48b"),
    ]:
        out[f"wage_monthly_{occ}"] = monthly_wage(df[inc], df[per])
    out["wage_total"] = rowtotal(out, ["wage_monthly_main", "wage_monthly_sec"])

    out["bonus_monthly_main"] = to_numeric(df["s5_32a"]) / 12
    out["aguinaldo_monthly_main"] = to_numeric(df["s5_32b"]) / 12
    out["aguinaldo_yearly_main"] = to_numeric(df["s5_32b"])
    out["comision_monthly_main"] = monthly_wage(df["s5_33a1"], df["s5_33a2"])
    out["overtime_monthly_main"] = monthly_wage(df["s5_33b1"], df["s5_33b2"])
    out["extra_wages_main"] = rowtotal(
        out,
        ["bonus_monthly_main", "aguinaldo_monthly_main", "comision_monthly_main", "overtime_monthly_main"],
    )
    out["extra_wages_sec"] = zero_if_missing(to_numeric(df["s5_49a2"]) / 12)
    out["extra_wages"] = to_numeric(out["extra_wages_main"]) + to_numeric(out["extra_wages_sec"])

    # In-kind main (period 1 → *20)
    kinds = ["food", "trans", "clothing", "lodging", "others"]
    letters = ["a", "b", "c", "d", "e"]
    inkind_cols = []
    for kind, letter in zip(kinds, letters):
        col = f"inkind_{kind}_monthly_main"
        out[col] = zero_if_missing(
            monthly_wage(df[f"s5_36{letter}3"], df[f"s5_36{letter}2"])
        )
        inkind_cols.append(col)
    out["inkind_payments_main"] = rowtotal(out, inkind_cols)
    out["inkind_payments_sec"] = (
        rowtotal(df, ["s5_49c2", "s5_49b2"]) / 12
    )
    out["inkind_payments"] = to_numeric(out["inkind_payments_main"]) + to_numeric(out["inkind_payments_sec"])

    out["y_wl_bonus_main"] = rowtotal(out, ["extra_wages_main", "inkind_payments_main"])
    out["y_wl_bonus_sec"] = rowtotal(out, ["extra_wages_sec", "inkind_payments_sec"])
    out["y_wl_bonus"] = to_numeric(out["y_wl_bonus_main"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings_main"] = to_numeric(out["wage_monthly_main"]) + to_numeric(out["y_wl_bonus_main"])
    out["y_earnings_sec"] = to_numeric(out["wage_monthly_sec"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings"] = to_numeric(out["wage_total"]) + to_numeric(out["y_wl_bonus"])

    # Self-employment revenue
    for occ, base in [("main", "_37"), ("sec", "_50")]:
        out[f"rev_nw_labor_{occ}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s5{base}a"], df[f"s5{base}b"])
        )
    out["rev_nw_labor"] = rowtotal(out, ["rev_nw_labor_main_monthly", "rev_nw_labor_sec_monthly"])

    # Costs: inputs, wage, rent, taxes_others
    cost_names = ["inputs", "wage", "rent", "taxes_others"]
    cost_letters = ["a", "b", "c", "d"]
    for occ, base in [("main", "_38"), ("sec", "_51")]:
        cost_cols = []
        for name, letter in zip(cost_names, cost_letters):
            col = f"{name}_cost_monthly_{occ}"
            out[col] = zero_if_missing(
                monthly_rev(df[f"s5{base}{letter}1"], df[f"s5{base}{letter}2"])
            )
            cost_cols.append(col)
        out[f"operational_cost_{occ}"] = rowtotal(out, cost_cols)
    out["operational_cost"] = rowtotal(out, ["operational_cost_main", "operational_cost_sec"])

    out = build_labor_totals(out)

    # Self-reported NW labor
    for tag, base in [("main", "_39"), ("sec", "_52")]:
        sr = to_numeric(df[f"s5{base}a"])
        sr_m = monthly_rev(sr, df[f"s5{base}b"])
        out[f"y_nw_labor{tag}_sr_m"] = replace_where(sr_m, 0.0, sr.isna())
    out["y_nw_labor_sr"] = rowtotal(out, ["y_nw_labormain_sr_m", "y_nw_laborsec_sr_m"])

    # Public non-labor
    out["retirement"] = to_numeric(df["s6_01a"])
    out["transfer_veterans"] = to_numeric(df["s6_01b"])
    out["transfer_disability"] = to_numeric(df["s6_01c"])
    out["transfer_widows"] = to_numeric(df["s6_01d"])
    out["y_social_security"] = rowtotal(
        out, ["retirement", "transfer_veterans", "transfer_disability", "transfer_widows"]
    )
    out["y_elderly_transfer"] = zero_if_missing(df["s6_01eb"])
    out["y_government"] = rowtotal(out, ["y_social_security", "y_elderly_transfer"])

    # Local transfers
    for name, letter in [("family_asistance", "a"), ("people_incountry", "b")]:
        out[f"{name}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s6_05{letter}1"], df[f"s6_05{letter}2"])
        )
    out["y_local_transfers"] = rowtotal(out, ["family_asistance_monthly", "people_incountry_monthly"])

    rem = build_remittances_block(
        df,
        receive_col="s6_06",
        amount_col="s6_09a",
        period_col="s6_07",
        currency_col="s6_09b",
        encode=True,
    )
    out = pd.concat([out, rem], axis=1)

    # Regular asset revenues
    for name, letter in [("revenues_interest", "a"), ("revenues_renting", "b"), ("revenues_other", "c")]:
        out[name] = zero_if_missing(df[f"s6_02{letter}"])
    out["y_int_assets_regular"] = rowtotal(out, ["revenues_interest", "revenues_renting", "revenues_other"])

    # Non-regular (annual / 12)
    nr_map = {
        "revenues_rental_agric": "s6_03a",
        "revenues_dividends": "s6_03b",
        "revenues_rental_equip": "s6_03c",
        "revenues_indemnization": "s6_04a",
        "revenues_insurance": "s6_04b",
        "revenues_other_nr": "s6_04c",
    }
    for var, col in nr_map.items():
        out[var] = zero_if_missing(to_numeric(df[col]) / 12)
    out["y_non_regular"] = rowtotal(
        out,
        list(nr_map.keys()),
    )

    return finalize_income(out)
