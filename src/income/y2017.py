"""2017 Income harmonization — EH_Income_2017.do."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from ..persona.common import read_persona
from ..stata_utils import replace_where, to_numeric
from .common import (
    REMITTANCE_RATES_2017,
    build_labor_totals,
    build_remittances_block,
    destring_cols,
    finalize_income,
    make_person_id,
    monthly_rev,
    monthly_wage,
    rowtotal,
    zero_if_missing,
)

DESTRING_WAGES = [
    "s06c_25a", "s06c_25b", "s06g_47a", "s06g_47b", "s06c_26a", "s06c_26b",
    "s06c_27aa", "s06c_27ab", "s06c_27ba", "s06c_27bb", "s06g_48a1",
    "s06c_30a1", "s06c_30a2", "s06c_30b1", "s06c_30b2", "s06c_30c1", "s06c_30c2",
    "s06c_30d1", "s06c_30d2", "s06c_30e1", "s06c_30e2", "s06g_48b1", "s06g_48c1",
    "s06d_33a", "s06d_33b",
]

DESTRING_INCOMES = [
    "s06d_31a", "s06d_31b", "s06d_32aa", "s06d_32ab", "s06d_32ba", "s06d_32bb",
    "s06d_32ca", "s06d_32cb", "s06d_32da", "s06d_32db", "s06d_32ea", "s06d_32eb",
    "s06d_32fa", "s06d_32fb", "s06f_45a", "s06f_45b", "s06g_50aa", "s06g_50ab",
    "s06g_50ba", "s06g_50bb", "s06g_50ca", "s06g_50cb", "s06g_50da", "s06g_50db",
    "s06g_50ea", "s06g_50eb", "s06g_50fa", "s06g_50fb", "s06g_50ga", "s06g_50gb",
    "s06g_49a", "s06g_49b",
]

DESTRING_NOLABOR = [
    "s07a_01a", "s07a_01b", "s07a_01c", "s07a_01d", "s07a_01e", "s07a_01e0",
    "s07b_05aa", "s07b_05ab", "s07b_05ba", "s07b_05bb",
]


def harmonize_income_2017(raw_path: Path | None = None) -> pd.DataFrame:
    df = read_persona(2017, raw_path)
    df = destring_cols(df, DESTRING_WAGES)

    out = make_person_id(df)
    out["t"] = 2017
    out["depto"] = to_numeric(df["depto"])
    out["area"] = to_numeric(df["area"])

    # 2017: sec wage s06g_47a; extra s06g_48a1; revenue g_49
    for occ, inc, per in [("main", "s06c_25a", "s06c_25b"), ("sec", "s06g_47a", "s06g_47b")]:
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
    out["extra_wages_sec"] = zero_if_missing(to_numeric(df["s06g_48a1"]) / 12)
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
    out["inkind_payments_sec"] = rowtotal(df, ["s06g_48b1", "s06g_48c1"]) / 12
    out["inkind_payments"] = to_numeric(out["inkind_payments_main"]) + to_numeric(out["inkind_payments_sec"])

    out["y_wl_bonus_main"] = rowtotal(out, ["extra_wages_main", "inkind_payments_main"])
    out["y_wl_bonus_sec"] = rowtotal(out, ["extra_wages_sec", "inkind_payments_sec"])
    out["y_wl_bonus"] = to_numeric(out["y_wl_bonus_main"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings_main"] = to_numeric(out["wage_monthly_main"]) + to_numeric(out["y_wl_bonus_main"])
    out["y_earnings_sec"] = to_numeric(out["wage_monthly_sec"]) + to_numeric(out["y_wl_bonus_sec"])
    out["y_earnings"] = to_numeric(out["wage_total"]) + to_numeric(out["y_wl_bonus"])

    df = destring_cols(df, DESTRING_INCOMES)

    for occ, base in [("main", "d_31"), ("sec", "g_49")]:
        out[f"rev_nw_labor_{occ}_monthly"] = zero_if_missing(
            monthly_rev(df[f"s06{base}a"], df[f"s06{base}b"])
        )
    out["rev_nw_labor"] = rowtotal(out, ["rev_nw_labor_main_monthly", "rev_nw_labor_sec_monthly"])

    cost_names = ["inputs", "wage", "rent", "interest", "taxes", "other"]
    cost_letters = ["a", "b", "c", "d", "e", "f"]
    for occ, base in [("main", "d_32"), ("sec", "g_50")]:
        for name, letter in zip(cost_names, cost_letters):
            col = f"{name}_cost_monthly_{occ}"
            out[col] = zero_if_missing(
                monthly_rev(df[f"s06{base}{letter}a"], df[f"s06{base}{letter}b"])
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

    for tag, base in [("main", "d_33"), ("sec", "g_51")]:
        sr = to_numeric(df[f"s06{base}a"])
        sr_m = monthly_rev(sr, df[f"s06{base}b"])
        out[f"y_nw_labor{tag}_sr_m"] = replace_where(sr_m, 0.0, sr.isna())
    out["y_nw_labor_sr"] = rowtotal(out, ["y_nw_labormain_sr_m", "y_nw_laborsec_sr_m"])

    df = destring_cols(df, DESTRING_NOLABOR)
    # Stata also destrings s07c_0*, s07a_02*, s07a_03*, s07a_04* — coerce if present
    extra = [c for c in df.columns if c.startswith(("s07c_0", "s07a_02", "s07a_03", "s07a_04"))]
    df = destring_cols(df, extra)

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
        rates=REMITTANCE_RATES_2017,
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
