"""Shared helpers for Income harmonization (2012–2017)."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from ..persona.common import _resolve_col, select_keep
from core.stata_semantics.stata_utils import replace_where, stata_str, to_numeric

WAGES_KEEP = [
    "wage_total",
    "wage_monthly_main",
    "wage_monthly_sec",
    "extra_wages",
    "extra_wages_main",
    "extra_wages_sec",
    "aguinaldo_yearly_main",
    "inkind_payments",
    "inkind_payments_main",
    "inkind_payments_sec",
    "y_wl_bonus_main",
    "y_wl_bonus_sec",
    "y_wl_bonus",
    "y_earnings_main",
    "y_earnings_sec",
    "y_earnings",
]

INCOMES_KEEP = [
    "rev_nw_labor",
    "rev_nw_labor_main_monthly",
    "rev_nw_labor_sec_monthly",
    "operational_cost_main",
    "operational_cost_sec",
    "operational_cost",
    "y_nw_labor_main",
    "y_nw_labor_sec",
    "y_nw_labor",
    "y_nw_labor_sr",
    "y_nw_labormain_sr_m",
    "y_nw_laborsec_sr_m",
    "y_labor",
    "y_labor_main",
    "y_labor_sec",
]

NOLABOR_KEEP = [
    "retirement",
    "transfer_veterans",
    "transfer_disability",
    "transfer_widows",
    "y_social_security",
    "y_elderly_transfer",
    "y_government",
    "y_local_transfers",
    "family_asistance_monthly",
    "people_incountry_monthly",
    "y_private_transfers",
    "remittances_currency",
    "y_foreign_remittances",
    "y_int_assets_regular",
    "revenues_interest",
    "revenues_renting",
    "revenues_other",
    "y_non_regular",
    "revenues_rental_agric",
    "revenues_dividends",
    "revenues_rental_equip",
    "revenues_indemnization",
    "revenues_insurance",
    "revenues_other_nr",
    "y_int_assets_total",
    "y_nonlabor",
    "y_person",
]

IDENT_KEEP = ["id", "folio", "depto", "area", "t"]

INCOME_YEARS = list(range(2012, 2018))

REMITTANCE_RATES_DEFAULT = {
    1: 1.0,
    2: 7.60566,
    3: (6.96 + 6.86) / 2,
    4: 0.45597,
    5: 2.13514,
    6: 0.01034,
}

REMITTANCE_RATES_2017 = {
    1: 1.0,
    2: 7.22425,
    3: (6.96 + 6.86) / 2,
    4: 0.43199,
    5: 2.10740,
    6: 0.01023,
}


def income_keep() -> list[str]:
    return IDENT_KEEP + WAGES_KEEP + INCOMES_KEEP + NOLABOR_KEEP


def income_relabel_path(year: int) -> Path:
    return paths.INTERMEDIATE / "income" / f"EH{year}_Income_relabel.parquet"


def income_compiled_path() -> Path:
    return paths.INTERMEDIATE / "income" / "EH_compiled_income.parquet"


def income_cleaned_path() -> Path:
    return paths.INTERMEDIATE / "income" / "EH_cleaned_income.parquet"


def write_income_parquet(df: pd.DataFrame, year: int, out_path: Path | None = None) -> Path:
    out_path = out_path or income_relabel_path(year)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    return out_path


def rowtotal(df: pd.DataFrame, cols: list[str]) -> pd.Series:
    """Stata ``egen rowtotal`` — missing treated as 0."""
    present = [c for c in cols if c in df.columns]
    if not present:
        return pd.Series(0.0, index=df.index)
    return df[present].apply(to_numeric).fillna(0).sum(axis=1)


def monthly_from_period(
    amount: pd.Series,
    period: pd.Series,
    *,
    p1_mult: float = 20,
) -> pd.Series:
    amt = to_numeric(amount)
    per = to_numeric(period)
    out = pd.Series(np.nan, index=amt.index, dtype="float64")
    out = replace_where(out, amt * p1_mult, per.eq(1))
    out = replace_where(out, amt * 4, per.eq(2))
    out = replace_where(out, amt * 2, per.eq(3))
    out = replace_where(out, amt, per.eq(4))
    out = replace_where(out, amt / 2, per.eq(5))
    out = replace_where(out, amt / 3, per.eq(6))
    out = replace_where(out, amt / 6, per.eq(7))
    out = replace_where(out, amt / 12, per.eq(8))
    return out


def monthly_wage(amount: pd.Series, period: pd.Series) -> pd.Series:
    return monthly_from_period(amount, period, p1_mult=20)


def monthly_rev(amount: pd.Series, period: pd.Series) -> pd.Series:
    return monthly_from_period(amount, period, p1_mult=30)


def zero_if_missing(series: pd.Series) -> pd.Series:
    x = to_numeric(series)
    return replace_where(x, 0.0, x.isna())


def make_person_id(df: pd.DataFrame, *, nro_col: str = "nro") -> pd.DataFrame:
    folio = stata_str(_resolve_col(df, "folio"))
    nro = stata_str(df[nro_col])
    return pd.DataFrame({"folio": folio, "id": folio + nro}, index=df.index)


def encode_currency(series: pd.Series) -> pd.Series:
    x = to_numeric(series)
    if x.notna().any():
        return x
    s = series.astype("string").str.strip()
    codes, _ = pd.factorize(s, sort=True)
    out = pd.Series(np.nan, index=series.index, dtype="float64")
    mask = codes >= 0
    out.loc[mask] = codes[mask] + 1
    return out


def remittances_monthly(amount: pd.Series, period: pd.Series) -> pd.Series:
    amt = to_numeric(amount)
    per = to_numeric(period)
    out = pd.Series(np.nan, index=amt.index, dtype="float64")
    out = replace_where(out, amt * 4, per.eq(2))
    out = replace_where(out, amt * 2, per.eq(3))
    out = replace_where(out, amt, per.eq(4))
    out = replace_where(out, amt / 2, per.eq(5))
    out = replace_where(out, amt / 3, per.eq(6))
    out = replace_where(out, amt / 6, per.eq(7))
    out = replace_where(out, amt / 12, per.eq(8))
    return out


def remittances_tc(currency: pd.Series, rates: dict[int, float]) -> pd.Series:
    cur = to_numeric(currency)
    out = pd.Series(np.nan, index=currency.index, dtype="float64")
    for code, rate in rates.items():
        out = replace_where(out, float(rate), cur.eq(code))
    return out


def build_remittances_block(
    df: pd.DataFrame,
    *,
    receive_col: str,
    amount_col: str,
    period_col: str,
    currency_col: str,
    encode: bool = True,
    rates: dict[int, float] | None = None,
) -> pd.DataFrame:
    rates = rates or REMITTANCE_RATES_DEFAULT
    out = pd.DataFrame(index=df.index)
    amount = to_numeric(df[amount_col])
    period = to_numeric(df[period_col])
    currency_raw = df[currency_col]
    currency = encode_currency(currency_raw) if encode else to_numeric(currency_raw)
    monthly = remittances_monthly(amount, period)
    tc = remittances_tc(currency, rates)
    out["remittances_currency"] = currency
    out["y_foreign_remittances"] = zero_if_missing(monthly * tc)
    return out


def build_labor_totals(out: pd.DataFrame) -> pd.DataFrame:
    """Shared y_labor / y_nw_labor block after wages + self-employment."""
    out["y_nw_labor_main"] = (
        to_numeric(out["rev_nw_labor_main_monthly"]) - to_numeric(out["operational_cost_main"])
    )
    out["y_nw_labor_sec"] = (
        to_numeric(out["rev_nw_labor_sec_monthly"]) - to_numeric(out["operational_cost_sec"])
    )
    out["y_nw_labor"] = to_numeric(out["rev_nw_labor"]) - to_numeric(out["operational_cost"])
    out["y_labor"] = rowtotal(out, ["y_earnings", "y_nw_labor"])
    # Stata quirk: y_labor_main uses total y_nw_labor, not y_nw_labor_main
    out["y_labor_main"] = rowtotal(out, ["y_earnings_main", "y_nw_labor"])
    out["y_labor_sec"] = rowtotal(out, ["y_earnings_sec", "y_nw_labor_sec"])
    return out


def finalize_income(out: pd.DataFrame) -> pd.DataFrame:
    out["y_private_transfers"] = rowtotal(
        out, ["y_foreign_remittances", "y_local_transfers"]
    )
    out["y_int_assets_total"] = rowtotal(out, ["y_int_assets_regular", "y_non_regular"])
    out["y_nonlabor"] = rowtotal(
        out, ["y_int_assets_total", "y_private_transfers", "y_government"]
    )
    out["y_person"] = rowtotal(out, ["y_labor", "y_nonlabor"])
    return select_keep(out, income_keep())


def destring_cols(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    out = df.copy()
    for col in cols:
        if col in out.columns:
            out[col] = to_numeric(out[col])
    return out
