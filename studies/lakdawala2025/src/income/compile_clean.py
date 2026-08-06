"""
Income compile + clean.

Stata sources:
  2. Compiling/2.3.EH_Income_compiling.do
  2. Compiling/2.4.EH_Income_cleaned.do
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from opencausallab.stata_semantics.stata_utils import inrange, replace_where, stata_str, to_numeric, winsor_high
from .common import (
    IDENT_KEEP,
    INCOMES_KEEP,
    NOLABOR_KEEP,
    WAGES_KEEP,
    income_cleaned_path,
    income_compiled_path,
    income_relabel_path,
)


def _load_year_relabel(year: int) -> pd.DataFrame:
    path = income_relabel_path(year)
    if not path.exists():
        raise FileNotFoundError(
            f"Missing {path}. Run scripts/run_income_all_years.py first."
        )
    return pd.read_parquet(path)


def compile_income(years: list[int] | None = None) -> pd.DataFrame:
    """Translate 2.3.EH_Income_compiling.do → EH_compiled_income."""
    years = years or list(range(2012, 2018))
    frames = []
    for year in years:
        df = _load_year_relabel(year)
        df = df.copy()
        df["folio"] = stata_str(df["folio"])
        frames.append(df)
    out = pd.concat(frames, axis=0, ignore_index=True, sort=False)
    out = out.rename(columns={"t": "year"})

    ident = ["id", "folio", "depto", "area", "year"]
    wages = WAGES_KEEP
    incomes = INCOMES_KEEP
    nolabor = NOLABOR_KEEP
    order = ident + wages + incomes + nolabor
    present = [c for c in order if c in out.columns]
    return out.loc[:, present].copy()


def _winsor_p99(series: pd.Series) -> pd.Series:
    """Stata: gen x_w=x; replace x_w=r(p99) if x>r(p99) & x!=."""
    x = to_numeric(series)
    w = x.copy()
    if x.notna().sum() == 0:
        return w
    cap = x.quantile(0.99)
    return replace_where(w, cap, x.gt(cap) & x.notna())


def clean_income(compiled: pd.DataFrame | None = None) -> pd.DataFrame:
    """Translate 2.4.EH_Income_cleaned.do → EH_cleaned_income."""
    df = compiled.copy() if compiled is not None else compile_income()
    df["id"] = stata_str(df["id"])
    df["folio"] = stata_str(df["folio"])
    year = to_numeric(df["year"])

    df["id_year"] = stata_str(df["year"]) + stata_str(df["id"])
    df["folio_year"] = stata_str(df["year"]) + stata_str(df["folio"])

    wages_w = [
        "wage_monthly_main",
        "wage_monthly_sec",
        "extra_wages_main",
        "extra_wages_sec",
        "inkind_payments_main",
        "inkind_payments_sec",
        "y_wl_bonus_main",
        "y_wl_bonus_sec",
    ]
    incomes_w = [
        "rev_nw_labor_main_monthly",
        "rev_nw_labor_sec_monthly",
        "operational_cost_main",
        "operational_cost_sec",
        "y_nw_labormain_sr_m",
        "y_nw_laborsec_sr_m",
    ]
    nolabor_w = [
        "retirement",
        "transfer_veterans",
        "transfer_disability",
        "transfer_widows",
        "y_elderly_transfer",
        "family_asistance_monthly",
        "people_incountry_monthly",
        "y_foreign_remittances",
        "remittances_currency",
        "revenues_interest",
        "revenues_renting",
        "revenues_other",
        "revenues_rental_agric",
        "revenues_dividends",
        "revenues_rental_equip",
        "revenues_indemnization",
        "revenues_insurance",
        "revenues_other_nr",
    ]
    for x in wages_w + incomes_w + nolabor_w:
        if x in df.columns:
            df[f"{x}_w"] = _winsor_p99(df[x])

    # Rebuild wage aggregates (_w)
    df["wage_total_w"] = _rowtotal(df, ["wage_monthly_main_w", "wage_monthly_sec_w"])
    df["extra_wages_w"] = to_numeric(df["extra_wages_main_w"]) + to_numeric(df["extra_wages_sec_w"])
    df["inkind_payments_w"] = to_numeric(df["inkind_payments_main_w"]) + to_numeric(df["inkind_payments_sec_w"])
    df["y_wl_bonus_w"] = to_numeric(df["y_wl_bonus_main_w"]) + to_numeric(df["y_wl_bonus_sec_w"])
    df["y_earnings_main_w"] = to_numeric(df["wage_monthly_main_w"]) + to_numeric(df["y_wl_bonus_main_w"])
    df["y_earnings_sec_w"] = to_numeric(df["wage_monthly_sec_w"]) + to_numeric(df["y_wl_bonus_sec_w"])
    df["y_earnings_w"] = to_numeric(df["wage_total_w"]) + to_numeric(df["y_wl_bonus_w"])

    df["rev_nw_labor_w"] = _rowtotal(df, ["rev_nw_labor_main_monthly_w", "rev_nw_labor_sec_monthly_w"])
    df["operational_cost_w"] = _rowtotal(df, ["operational_cost_main_w", "operational_cost_sec_w"])
    df["y_nw_labor_sr_w"] = _rowtotal(df, ["y_nw_labormain_sr_m_w", "y_nw_laborsec_sr_m_w"])
    df["y_nw_labor_main_w"] = to_numeric(df["rev_nw_labor_main_monthly_w"]) - to_numeric(df["operational_cost_main_w"])
    df["y_nw_labor_sec_w"] = to_numeric(df["rev_nw_labor_sec_monthly_w"]) - to_numeric(df["operational_cost_sec_w"])
    df["y_nw_labor_w"] = to_numeric(df["rev_nw_labor_w"]) - to_numeric(df["operational_cost_w"])
    df["y_labor_w"] = _rowtotal(df, ["y_earnings_w", "y_nw_labor_w"])
    df["y_labor_main_w"] = _rowtotal(df, ["y_earnings_main_w", "y_nw_labor_w"])
    df["y_labor_sec_w"] = _rowtotal(df, ["y_earnings_sec_w", "y_nw_labor_sec_w"])

    df["y_social_security_w"] = _rowtotal(
        df, ["retirement_w", "transfer_veterans_w", "transfer_disability_w", "transfer_widows_w"]
    )
    df["y_government_w"] = _rowtotal(df, ["y_social_security_w", "y_elderly_transfer_w"])
    df["y_local_transfers_w"] = _rowtotal(df, ["family_asistance_monthly_w", "people_incountry_monthly_w"])
    df["y_private_transfers_w"] = _rowtotal(df, ["y_foreign_remittances_w", "y_local_transfers_w"])
    df["y_int_assets_regular_w"] = _rowtotal(
        df, ["revenues_interest_w", "revenues_renting_w", "revenues_other_w"]
    )
    df["y_non_regular_w"] = _rowtotal(
        df,
        [
            "revenues_rental_agric_w",
            "revenues_dividends_w",
            "revenues_rental_equip_w",
            "revenues_indemnization_w",
            "revenues_insurance_w",
            "revenues_other_nr_w",
        ],
    )
    df["y_int_assets_total_w"] = _rowtotal(df, ["y_int_assets_regular_w", "y_non_regular_w"])
    df["y_nonlabor_w"] = _rowtotal(df, ["y_int_assets_total_w", "y_private_transfers_w", "y_government_w"])
    df["y_person_w"] = _rowtotal(df, ["y_labor_w", "y_nonlabor_w"])

    # Household totals
    g = df.groupby(["folio", "year"], sort=False)
    nper = g["id"].transform("count")
    for suffix in ["", "_w"]:
        src = f"y_person{suffix}"
        df[f"y_household{suffix}"] = g[src].transform("sum")
        df[f"y_percapita{suffix}"] = df[f"y_household{suffix}"] / nper

    df["id"] = stata_str(df["id"])
    df["folio"] = stata_str(df["folio"])

    # Rename blocks (raw + _w)
    rename_pairs = [
        ("wage_monthly_main", "y_wl_gross_main"),
        ("wage_monthly_sec", "y_wl_gross_sec"),
        ("wage_total", "y_wl_gross"),
        ("extra_wages_main", "y_wl_cash_extra_main"),
        ("extra_wages", "y_wl_cash_extra"),
        ("extra_wages_sec", "y_wl_cash_extra_sec"),
        ("inkind_payments_main", "y_wl_inkind_extra_main"),
        ("inkind_payments_sec", "y_wl_inkind_extra_sec"),
        ("inkind_payments", "y_wl_inkind_extra"),
        ("y_earnings_main", "y_wl_earnings_main"),
        ("y_earnings_sec", "y_wl_earnings_sec"),
        ("y_earnings", "y_wl_earnings"),
        ("rev_nw_labor", "y_nwl_rev"),
        ("rev_nw_labor_main_monthly", "y_nwl_rev_main"),
        ("rev_nw_labor_sec_monthly", "y_nwl_rev_sec"),
        ("operational_cost_main", "cost_nwl_main"),
        ("operational_cost_sec", "cost_nwl_sec"),
        ("operational_cost", "cost_nwl"),
        ("y_nw_labor_main", "y_nwl_income_main"),
        ("y_nw_labor", "y_nwl_income"),
        ("y_nw_labor_sec", "y_nwl_income_sec"),
        ("y_nw_labor_sr", "y_nwl_income_sr"),
        ("y_nw_labormain_sr_m", "y_nwl_income_sr_main"),
        ("y_nw_laborsec_sr_m", "y_nwl_income_sr_sec"),
        ("y_labor", "y_labor"),
        ("y_labor_main", "y_labor_main"),
        ("y_labor_sec", "y_labor_sec"),
        ("retirement", "y_nl_ret"),
        ("transfer_veterans", "y_nl_vet"),
        ("transfer_disability", "y_nl_dis"),
        ("transfer_widows", "y_nl_widow"),
        ("y_social_security", "y_nl_ss"),
        ("y_elderly_transfer", "y_nl_elderly_transfer"),
        ("y_government", "y_nl_gov"),
        ("y_local_transfers", "y_nl_domestic"),
        ("family_asistance_monthly", "y_nl_famassist_transfers"),
        ("people_incountry_monthly", "y_nl_hhdom_transfers"),
        ("y_foreign_remittances", "y_nl_remittances"),
        ("y_private_transfers", "y_nl_hhtrans"),
        ("y_int_assets_regular", "y_rents_reg"),
        ("revenues_interest", "y_rents_reg_int"),
        ("revenues_renting", "y_rents_reg_rent"),
        ("revenues_other", "y_rents_reg_oth"),
        ("y_non_regular", "y_rents_o"),
        ("revenues_rental_agric", "y_rents_o_agrrent"),
        ("revenues_dividends", "y_rents_o_div"),
        ("revenues_rental_equip", "y_rents_o_equip"),
        ("revenues_indemnization", "y_rent_o_indem"),
        ("revenues_insurance", "y_rent_o_insurance"),
        ("revenues_other_nr", "y_rent_o_oth"),
        ("y_int_assets_total", "y_rents"),
        ("y_person", "y_personal"),
    ]
    for suffix in ["", "_w"]:
        for old, new in rename_pairs:
            src = f"{old}{suffix}"
            dst = f"{new}{suffix}"
            if src in df.columns:
                df = df.rename(columns={src: dst})

    if "aguinaldo_yearly_main" in df.columns:
        df = df.rename(columns={"aguinaldo_yearly_main": "y_wl_aguinaldo_main_year"})

    # Fill missings with 0 (Stata section 3)
    zero_rules = [
        ("y_wl_gross_main", None),
        ("y_wl_gross_sec", None),
        ("y_wl_cash_extra_sec", inrange(year, 2015, 2017)),
        ("y_wl_aguinaldo_main_year", year != 2004),
        ("y_wl_earnings_main", None),
        ("y_wl_earnings_sec", None),
        ("y_nwl_rev_sec", inrange(year, 2005, 2017)),
        ("cost_nwl_sec", inrange(year, 2012, 2017)),
        ("y_nwl_income_main", None),
        ("y_nwl_income_sec", inrange(year, 2012, 2017)),
        ("y_nwl_income_sr_main", None),
        ("y_nwl_income_sr_sec", inrange(year, 2005, 2017)),
        ("y_labor_sec", inrange(year, 2012, 2017)),
        ("y_nl_ret", None),
        ("y_nl_vet", None),
        ("y_nl_dis", None),
        ("y_nl_widow", None),
        ("y_nl_ss", None),
        ("y_rent_o_insurance", inrange(year, 2004, 2017)),
    ]
    for col, cond in zero_rules:
        if col not in df.columns:
            continue
        x = to_numeric(df[col])
        if cond is None:
            mask = x.isna()
        else:
            mask = x.isna() & cond
        df[col] = replace_where(x, 0.0, mask)

    return df


def _rowtotal(df: pd.DataFrame, cols: list[str]) -> pd.Series:
    present = [c for c in cols if c in df.columns]
    if not present:
        return pd.Series(0.0, index=df.index)
    return df[present].apply(to_numeric).fillna(0).sum(axis=1)


def write_compiled_income(out_path: Path | None = None) -> Path:
    out_path = out_path or income_compiled_path()
    df = compile_income()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    return out_path


def write_cleaned_income(out_path: Path | None = None) -> Path:
    out_path = out_path or income_cleaned_path()
    compiled_path = income_compiled_path()
    if compiled_path.exists():
        compiled = pd.read_parquet(compiled_path)
    else:
        compiled = compile_income()
        compiled_path.parent.mkdir(parents=True, exist_ok=True)
        compiled.to_parquet(compiled_path, index=False)
    df = clean_income(compiled)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    return out_path
