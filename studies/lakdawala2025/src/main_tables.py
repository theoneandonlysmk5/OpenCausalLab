"""
Main Tables 1–2 (descriptives) and 4–6 (DiDisc) from HHsurvey.

CL-survey panels (Table 1C, 2B, Table 5 cols 1–4) require
``RW_child_labor_survey.parquet`` when available.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from scipy import stats

from . import paths
from core.causal.didisc_reg import (
    DEMO,
    PERIOD,
    RD_W14,
    depto_year,
    didisc_formula,
    nlcom_sum,
    prepare_kernel_sample,
    stars,
    wls_cluster,
)
from core.stata_semantics.stata_utils import to_numeric
from .table3 import load_hhsurvey, prepare_table3_sample, run_table3

# ---------------------------------------------------------------------------
# Published manuscript targets
# ---------------------------------------------------------------------------

PUBLISHED_TABLE1_A = {
    # col1 all 10-15 means (paper rounding)
    "head_schooling": 8.603,
    "head_male": 0.787,
    "head_age": 44.401,
    "indig_head": 0.357,
    "hhsize": 5.593,
    "male": 0.501,
    "works": 0.152,
    "hours_week_a": 3.325,
    "self_employed_a": 0.003,
    "wrk_forother_a": 0.150,
    "wrk_foremployer_a": 0.017,
    "wrk_family_a": 0.133,
    "forbidden_a": 0.006,
    "not_forbidden_a": 0.146,
    "wrk30hrs_a": 0.030,
    "attendance_a": 0.970,
    "n": 7410,
    "n_work": 1130,
    "n_10_11": 2698,
    "n_12_13": 3108,
    "n_14_15": 1604,
}

PUBLISHED_TABLE2_A = {
    "firm_size_ext": 4,
    "firm_size_fam": 4,
    "wage_ext": 6.291,
    "wage_fam": 18.557,
    "taxes_ext": 0.098,
    "taxes_fam": 0.026,
    "fixed_ext": 0.64,
    "fixed_fam": 0.899,
    "mobile_ext": 0.36,
    "mobile_fam": 0.071,
    "home_ext": 0.0,
    "home_fam": 0.03,
    "agri_ext": 0.144,
    "agri_fam": 0.772,
    "sales_ext": 0.232,
    "sales_fam": 0.101,
    "other_ext": 0.624,
    "other_fam": 0.127,
    "n_ext": 113,
    "n_fam": 1094,
}

PUBLISHED_TABLE4 = {
    ("het_time", "all"): {
        "far": 0.002,
        "far_se": 0.061,
        "near": -0.030,
        "near_se": 0.021,
        "n": 7650,
        "mean": 0.180,
        "diff_p": 0.644,
    },
    ("het_time", "no_mteps"): {
        "far": 0.002,
        "far_se": 0.058,
        "near": -0.074,
        "near_se": 0.043,
        "n": 2984,
        "mean": 0.317,
        "diff_p": 0.338,
    },
    ("het_dist", "all"): {
        "far": 0.009,
        "far_se": 0.060,
        "near": -0.037,
        "near_se": 0.021,
        "n": 7650,
        "mean": 0.180,
        "diff_p": 0.496,
    },
    ("het_dist", "no_mteps"): {
        "far": 0.007,
        "far_se": 0.056,
        "near": -0.103,
        "near_se": 0.044,
        "n": 2984,
        "mean": 0.317,
        "diff_p": 0.175,
    },
}

PUBLISHED_TABLE5_WAGE = {
    "xxw3": 0.103,
    "xxw3_se": 0.180,
    "xxrw3": -0.012,
    "xxrw3_se": 0.180,
    "n": 712,
    # Stata estadd Mean is sum number_workers_w if e(sample)&pre — NOT log wage.
    # Do not alter the wage regression to match this mislabeled footer statistic.
    "mean": 6.656,
}

PUBLISHED_TABLE6 = {
    "location_out_fixed_a": {
        "xxw3": -0.051,
        "xxw3_se": 0.014,
        "xxrw3": -0.009,
        "xxrw3_se": 0.016,
        "n": 11991,
        "mean_pre": 0.149,
        "works_only": False,
    },
    "location_out_mobile_a": {
        "xxw3": 0.009,
        "xxw3_se": 0.008,
        "xxrw3": 0.005,
        "xxrw3_se": 0.013,
        "n": 11991,
        "mean_pre": 0.0248,
        "works_only": False,
    },
    "location_home_a": {
        "xxw3": 0.003,
        "xxw3_se": 0.004,
        "xxrw3": 0.003,
        "xxrw3_se": 0.003,
        "n": 11991,
        "mean_pre": 0.00588,
        "works_only": False,
    },
    "location_out_fixed_a_w": {
        "xxw3": -0.098,
        "xxw3_se": 0.035,
        "xxrw3": -0.043,
        "xxrw3_se": 0.050,
        "n": 2323,
        "mean_pre": 0.829,
        "works_only": True,
        "outcome": "location_out_fixed_a",
    },
    "location_out_mobile_a_w": {
        "xxw3": 0.078,
        "xxw3_se": 0.034,
        "xxrw3": 0.022,
        "xxrw3_se": 0.054,
        "n": 2323,
        "mean_pre": 0.138,
        "works_only": True,
        "outcome": "location_out_mobile_a",
    },
    "location_home_a_w": {
        "xxw3": 0.021,
        "xxw3_se": 0.018,
        "xxrw3": 0.021,
        "xxrw3_se": 0.018,
        "n": 2323,
        "mean_pre": 0.0327,
        "works_only": True,
        "outcome": "location_home_a",
    },
    "number_workers_a_w": {
        "xxw3": -0.726,
        "xxw3_se": 0.473,
        "xxrw3": -0.359,
        "xxrw3_se": 0.383,
        "n": 2250,
        "mean_pre": 4.796,
        "works_only": True,
        "outcome": "number_workers_a",
    },
}


def _mean(s: pd.Series) -> float:
    s = to_numeric(s)
    return float(s.mean()) if s.notna().any() else float("nan")


def _median(s: pd.Series) -> float:
    s = to_numeric(s)
    return float(s.median()) if s.notna().any() else float("nan")


# ---------------------------------------------------------------------------
# Table 1
# ---------------------------------------------------------------------------

def table1_panel_a(hh: pd.DataFrame) -> pd.DataFrame:
    adm = to_numeric(hh["age_dob_m"])
    year = to_numeric(hh["year"])
    mask = year.isin([2012, 2013]) & adm.ge(120) & adm.le(180)
    df = hh.loc[mask].copy()
    df["age10to11"] = (adm >= 120) & (adm < 144)
    df["age12to13"] = (adm >= 144) & (adm < 168)
    df["age14to15"] = (adm >= 168) & (adm < 192)

    rows = []
    chars = [
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "hhsize",
        "male",
    ]
    for c in chars:
        rows.append(
            {
                "variable": c,
                "all": _mean(df[c]),
                "working": _mean(df.loc[to_numeric(df["works"]) == 1, c]),
                "age10_11": _mean(df.loc[df["age10to11"], c]),
                "age12_13": _mean(df.loc[df["age12to13"], c]),
                "age14_15": _mean(df.loc[df["age14to15"], c]),
            }
        )

    # works: all children only for col working
    rows.append(
        {
            "variable": "works",
            "all": _mean(df["works"]),
            "working": np.nan,
            "age10_11": _mean(df.loc[df["age10to11"], "works"]),
            "age12_13": _mean(df.loc[df["age12to13"], "works"]),
            "age14_15": _mean(df.loc[df["age14to15"], "works"]),
        }
    )

    yvars = [
        "hours_week",
        "self_employed",
        "wrk_forother",
        "wrk_foremployer",
        "wrk_family",
        "forbidden",
        "not_forbidden",
        "wrk30hrs",
        "attendance",
    ]
    for y in yvars:
        ya = f"{y}_a"
        if ya not in df.columns or y not in df.columns:
            continue
        rows.append(
            {
                "variable": ya,
                "all": _mean(df[ya]),
                "working": _mean(df[y]),  # Stata: sum y among (implicit works sample for non-_a)
                "age10_11": _mean(df.loc[df["age10to11"], ya]),
                "age12_13": _mean(df.loc[df["age12to13"], ya]),
                "age14_15": _mean(df.loc[df["age14to15"], ya]),
            }
        )

    out = pd.DataFrame(rows)
    out.attrs["n_all"] = int(len(df))
    out.attrs["n_work"] = int((to_numeric(df["works"]) == 1).sum())
    out.attrs["n_10_11"] = int(df["age10to11"].sum())
    out.attrs["n_12_13"] = int(df["age12to13"].sum())
    out.attrs["n_14_15"] = int(df["age14to15"].sum())
    return out


def table1_panel_b(hh: pd.DataFrame) -> pd.DataFrame:
    adm = to_numeric(hh["age_dob_m"])
    year = to_numeric(hh["year"])
    mask = year.isin([2012, 2013]) & adm.ge(120) & adm.le(180)
    df = hh.loc[mask].copy()
    adm = to_numeric(df["age_dob_m"])
    df["age10to11"] = (adm >= 120) & (adm < 144)
    df["age12to13"] = (adm >= 144) & (adm < 168)
    df["age14to15"] = (adm >= 168) & (adm < 192)
    works = to_numeric(df["works"]) == 1

    rows = []
    # median firm size
    y = "number_workers_w"
    rows.append(
        {
            "variable": y,
            "stat": "median",
            "working": _median(df.loc[works, y]),
            "age10_11": _median(df.loc[df["age10to11"], y]),
            "age12_13": _median(df.loc[df["age12to13"], y]),
            "age14_15": _median(df.loc[df["age14to15"], y]),
            "n_working": int(to_numeric(df.loc[works, y]).notna().sum()),
        }
    )
    for y in [
        "wage_hour_w",
        "firm_taxes",
        "location_out_fixed_a",
        "location_out_mobile_a",
        "location_home_a",
    ]:
        if y not in df.columns:
            continue
        rows.append(
            {
                "variable": y,
                "stat": "mean",
                "working": _mean(df.loc[works, y]),
                "age10_11": _mean(df.loc[df["age10to11"], y]),
                "age12_13": _mean(df.loc[df["age12to13"], y]),
                "age14_15": _mean(df.loc[df["age14to15"], y]),
                "n_working": int(works.sum()),
            }
        )
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Table 2 Panel A
# ---------------------------------------------------------------------------

def table2_panel_a(hh: pd.DataFrame) -> pd.DataFrame:
    adm = to_numeric(hh["age_dob_m"])
    year = to_numeric(hh["year"])
    df = hh.loc[year.isin([2012, 2013]) & adm.ge(108) & adm.le(180)].copy()
    fam = to_numeric(df["wrk_family"]) == 1
    ext = to_numeric(df["wrk_foremployer"]) == 1

    def row(name, fam_v, ext_v, pval, n_fam=None, n_ext=None):
        return {
            "variable": name,
            "external": ext_v,
            "family": fam_v,
            "pval": pval,
            "n_external": n_ext,
            "n_family": n_fam,
        }

    rows = []
    # firm size median + median test approx via Mann-Whitney on ranks / scipy
    y = to_numeric(df["number_workers_w"])
    rows.append(
        row(
            "number_workers_w_median",
            _median(y[fam]),
            _median(y[ext]),
            float(stats.median_test(y[ext].dropna(), y[fam].dropna())[1])
            if y[ext].notna().any() and y[fam].notna().any()
            else np.nan,
            int(y[fam].notna().sum()),
            int(y[ext].notna().sum()),
        )
    )

    def ttest_row(name, col):
        s = to_numeric(df[col])
        a, b = s[ext].dropna(), s[fam].dropna()
        if len(a) < 2 or len(b) < 2:
            p = np.nan
        else:
            # Stata ``ttest`` defaults to equal-variance (Student); Welch needs ``unequal``.
            p = float(stats.ttest_ind(a, b, equal_var=True).pvalue)
        return row(name, _mean(s[fam]), _mean(s[ext]), p, int(b.shape[0]), int(a.shape[0]))

    for col, name in [
        ("wage_hour_w", "wage_hour_w"),
        ("firm_taxes", "firm_taxes"),
        ("location_out_fixed_a", "location_out_fixed_a"),
        ("location_out_mobile_a", "location_out_mobile_a"),
        ("location_home_a", "location_home_a"),
        ("agriculture_a", "agriculture_a"),
        ("sales_a", "sales_a"),
        ("other_occ", "other_occ"),
    ]:
        if col in df.columns:
            rows.append(ttest_row(name, col))
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Table 4
# ---------------------------------------------------------------------------

def _table4_one(
    hh: pd.DataFrame,
    *,
    moderator: str,
    include_eligible: bool,
    no_mteps: bool,
) -> dict[str, Any]:
    """
    Match Table_4_DDisc_HeterogeneityDistanceToInspectors.do.

    ``treatw14x{h} = treatw14 * h`` (from Preparing), not running interaction.
    near = xxw3 (h=0); far = xxw3 + xxwh3.
    """
    years = (2012, 2016)
    df = hh.copy()
    y = to_numeric(df["year"])
    df = df.loc[(y >= years[0]) & (y <= years[1])].copy()
    if no_mteps:
        df = df.loc[to_numeric(df["mtepsoffices"]) == 0].copy()

    df[moderator] = to_numeric(df[moderator])
    for c in [
        "works",
        "xxw3",
        "kernel_triw14",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "post",
        "pre",
        "urban",
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "male",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "eligible_gr",
    ]:
        if c in df.columns:
            df[c] = to_numeric(df[c])

    xxwh = f"xxw{moderator}3"
    if xxwh not in df.columns:
        df[xxwh] = df["xxw3"] * df[moderator]
    else:
        df[xxwh] = to_numeric(df[xxwh])

    tw = f"treatw14x{moderator}"
    if tw not in df.columns:
        df[tw] = df["treatw14"] * df[moderator]
    else:
        df[tw] = to_numeric(df[tw])

    px = f"postx{moderator}"
    if px not in df.columns:
        df[px] = df["post"] * df[moderator]
    else:
        df[px] = to_numeric(df[px])

    df["kernel_triw14"] = to_numeric(df["kernel_triw14"])
    df = df.loc[df["kernel_triw14"].fillna(0) > 0].copy()
    df["depto"] = to_numeric(df["depto"])
    df["year"] = to_numeric(df["year"]).astype(int)
    df["depto_year"] = depto_year(df)

    ctrl = [
        "post",
        "urban",
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "male",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
    ]
    if include_eligible:
        ctrl.append("eligible_gr")

    terms = [
        xxwh,
        "xxw3",
        moderator,
        px,
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        tw,
    ] + ctrl + ["C(depto_year)"]
    need = ["works", "kernel_triw14", "age_mo_year", "depto_year", "pre"] + [
        t for t in terms if t != "C(depto_year)"
    ]
    df = df.dropna(subset=need).reset_index(drop=True)
    formula = "works ~ " + " + ".join(terms)
    res = wls_cluster(formula, df, weight="kernel_triw14")
    near, near_se, _ = nlcom_sum(res, "xxw3")
    far, far_se, _ = nlcom_sum(res, "xxw3", xxwh)
    return {
        "moderator": moderator,
        "sample": "no_mteps" if no_mteps else "all",
        "near": near,
        "near_se": near_se,
        "far": far,
        "far_se": far_se,
        "diff_p": float(res.pvalues[xxwh]),
        "n": int(res.nobs),
        "mean_pre": float(df.loc[df["pre"] == 1, "works"].mean()),
        "stars_near": stars(float(res.pvalues["xxw3"]))
        if False
        else stars(2 * stats.t.sf(abs(near / near_se), res.df_resid)),
        "stars_far": stars(2 * stats.t.sf(abs(far / far_se), res.df_resid)),
    }


def run_table4(hh: pd.DataFrame) -> pd.DataFrame:
    rows = []
    # Panel A: het_time, NO eligible_gr
    rows.append(_table4_one(hh, moderator="het_time", include_eligible=False, no_mteps=False))
    rows.append(_table4_one(hh, moderator="het_time", include_eligible=False, no_mteps=True))
    # Panel B: het_dist, WITH eligible_gr
    rows.append(_table4_one(hh, moderator="het_dist", include_eligible=True, no_mteps=False))
    rows.append(_table4_one(hh, moderator="het_dist", include_eligible=True, no_mteps=True))
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Table 5 col 5 (HH wage) — CL cols separate
# ---------------------------------------------------------------------------

def run_table5_wage(hh: pd.DataFrame) -> dict[str, Any]:
    """
    ``reg log_wage_hour_w xx xxrw3 treatw14... [aw=kernel_triw14_18] if sww14_18==1``
    Note: Stata reports Mean of number_workers_w (not the wage outcome).
    """
    df = hh.copy()
    y = to_numeric(df["year"])
    df = df.loc[(y >= 2012) & (y <= 2019)].copy()
    for c in [
        "log_wage_hour_w",
        "xxw3",
        "xxrw3",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "post",
        "post_rev",
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "male",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "eligible_gr",
        "kernel_triw14_18",
        "sww14_18",
        "pre",
        "number_workers_w",
    ]:
        if c in df.columns:
            df[c] = to_numeric(df[c])
    df = df.loc[df["sww14_18"] == 1].copy()
    df = df.loc[df["kernel_triw14_18"].fillna(0) > 0].copy()
    # no urban in Table 5 wage controls
    df["depto"] = to_numeric(df["depto"])
    df["year"] = to_numeric(df["year"]).astype(int)
    df["depto_year"] = depto_year(df)
    terms = [
        "xxw3",
        "xxrw3",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "post",
        "post_rev",
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "male",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "eligible_gr",
        "C(depto_year)",
    ]
    need = ["log_wage_hour_w", "kernel_triw14_18", "age_mo_year", "depto_year", "pre"] + [
        t for t in terms if t != "C(depto_year)"
    ]
    df = df.dropna(subset=need).reset_index(drop=True)
    formula = "log_wage_hour_w ~ " + " + ".join(terms)
    res = wls_cluster(formula, df, weight="kernel_triw14_18")
    return {
        "xxw3": float(res.params["xxw3"]),
        "xxw3_se": float(res.bse["xxw3"]),
        "xxrw3": float(res.params["xxrw3"]),
        "xxrw3_se": float(res.bse["xxrw3"]),
        "n": int(res.nobs),
        "mean_number_workers_pre": float(
            df.loc[df["pre"] == 1, "number_workers_w"].mean()
        ),
        "stars_xxw3": stars(float(res.pvalues["xxw3"])),
    }


# ---------------------------------------------------------------------------
# Table 6
# ---------------------------------------------------------------------------

def run_table6(hh: pd.DataFrame) -> pd.DataFrame:
    rows = []
    # Panel A
    sample = prepare_table3_sample(hh)
    for y in ["location_out_fixed_a", "location_out_mobile_a", "location_home_a"]:
        formula = didisc_formula(y)
        need = [
            y,
            "xxw3",
            "xxrw3",
            *RD_W14,
            *PERIOD,
            *[c for c in DEMO],
            "kernel_triw14",
            "age_mo_year",
            "depto_year",
            "pre",
        ]
        df = sample.dropna(subset=[c for c in need if c in sample.columns]).copy()
        if "depto_year" not in df.columns:
            df["depto_year"] = depto_year(df)
        res = wls_cluster(formula, df, weight="kernel_triw14")
        rows.append(
            {
                "panel": "A_all",
                "outcome": y,
                "xxw3": float(res.params["xxw3"]),
                "xxw3_se": float(res.bse["xxw3"]),
                "xxrw3": float(res.params["xxrw3"]),
                "xxrw3_se": float(res.bse["xxrw3"]),
                "n": int(res.nobs),
                "mean_pre": float(df.loc[df["pre"] == 1, y].mean()),
                "stars_xxw3": stars(float(res.pvalues["xxw3"])),
            }
        )
    # Panel B works==1
    for y in [
        "location_out_fixed_a",
        "location_out_mobile_a",
        "location_home_a",
        "number_workers_a",
    ]:
        df = sample.loc[to_numeric(sample["works"]) == 1].copy()
        if "depto_year" not in df.columns:
            df["depto_year"] = depto_year(df)
        need = [
            y,
            "xxw3",
            "xxrw3",
            *RD_W14,
            *PERIOD,
            *DEMO,
            "kernel_triw14",
            "age_mo_year",
            "depto_year",
            "pre",
        ]
        df = df.dropna(subset=[c for c in need if c in df.columns]).reset_index(drop=True)
        formula = didisc_formula(y)
        res = wls_cluster(formula, df, weight="kernel_triw14")
        rows.append(
            {
                "panel": "B_working",
                "outcome": y,
                "xxw3": float(res.params["xxw3"]),
                "xxw3_se": float(res.bse["xxw3"]),
                "xxrw3": float(res.params["xxrw3"]),
                "xxrw3_se": float(res.bse["xxrw3"]),
                "n": int(res.nobs),
                "mean_pre": float(df.loc[df["pre"] == 1, y].mean()),
                "stars_xxw3": stars(float(res.pvalues["xxw3"])),
            }
        )
    return pd.DataFrame(rows)


def compare_numeric(paper: float, python: float, tol: float) -> str:
    if paper is None or python is None or not np.isfinite(python):
        return "missing"
    d = abs(float(python) - float(paper))
    if d <= tol * 0.15 and d <= 5e-4:
        return "match"
    if d <= tol:
        return "near"
    return "open"


def build_main_tables_ledger(hh: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Run all HHsurvey-based main tables and compare to manuscript."""
    ledger = []
    artifacts: dict[str, Any] = {}

    # Table 1
    t1a = table1_panel_a(hh)
    t1b = table1_panel_b(hh)
    artifacts["table1_a"] = t1a
    artifacts["table1_b"] = t1b
    for key, paper in [
        ("n", t1a.attrs["n_all"]),
        ("n_work", t1a.attrs["n_work"]),
        ("n_10_11", t1a.attrs["n_10_11"]),
        ("n_12_13", t1a.attrs["n_12_13"]),
        ("n_14_15", t1a.attrs["n_14_15"]),
    ]:
        ledger.append(
            {
                "table": "1",
                "result": f"Table1 {key}",
                "paper": PUBLISHED_TABLE1_A[key],
                "python": paper,
                "abs_diff": abs(paper - PUBLISHED_TABLE1_A[key]),
                "status": compare_numeric(PUBLISHED_TABLE1_A[key], paper, 2),
            }
        )
    for var in ["works", "male", "head_schooling", "hours_week_a", "not_forbidden_a"]:
        row = t1a.loc[t1a["variable"] == var]
        if row.empty:
            continue
        py = float(row.iloc[0]["all"])
        paper = PUBLISHED_TABLE1_A[var]
        ledger.append(
            {
                "table": "1",
                "result": f"Table1 {var} all",
                "paper": paper,
                "python": py,
                "abs_diff": abs(py - paper),
                "status": compare_numeric(paper, py, 0.005),
            }
        )

    # Table 2
    t2 = table2_panel_a(hh)
    artifacts["table2_a"] = t2
    mapping = [
        ("number_workers_w_median", "firm_size_ext", "firm_size_fam", "external", "family", 0.01),
        ("wage_hour_w", "wage_ext", "wage_fam", "external", "family", 0.05),
        ("firm_taxes", "taxes_ext", "taxes_fam", "external", "family", 0.01),
        ("location_out_fixed_a", "fixed_ext", "fixed_fam", "external", "family", 0.02),
        ("agriculture_a", "agri_ext", "agri_fam", "external", "family", 0.02),
    ]
    for var, pe, pf, ce, cf, tol in mapping:
        row = t2.loc[t2["variable"] == var]
        if row.empty:
            continue
        r = row.iloc[0]
        for paper_key, col in [(pe, ce), (pf, cf)]:
            py = float(r[col])
            paper = PUBLISHED_TABLE2_A[paper_key]
            ledger.append(
                {
                    "table": "2",
                    "result": f"Table2 {paper_key}",
                    "paper": paper,
                    "python": py,
                    "abs_diff": abs(py - paper),
                    "status": compare_numeric(paper, py, tol),
                }
            )
    # N
    r0 = t2.iloc[0]
    for paper_key, col in [("n_ext", "n_external"), ("n_fam", "n_family")]:
        py = float(r0[col])
        paper = PUBLISHED_TABLE2_A[paper_key]
        ledger.append(
            {
                "table": "2",
                "result": f"Table2 {paper_key}",
                "paper": paper,
                "python": py,
                "abs_diff": abs(py - paper),
                "status": compare_numeric(paper, py, 5),
            }
        )

    # Table 3
    sample = prepare_table3_sample(hh)
    t3 = run_table3(sample)
    artifacts["table3"] = t3
    from .table3 import PUBLISHED_TABLE3, compare_to_published

    cmp3 = compare_to_published(t3)
    for _, row in cmp3.iterrows():
        tol = 0.12 if row["outcome"] == "hours_week_a" else 0.005
        ledger.append(
            {
                "table": "3",
                "result": f"Table3 {row['outcome']} {row['term']}",
                "paper": row["coef_paper"],
                "python": row["coef_py"],
                "abs_diff": abs(row["delta_coef"]),
                "status": compare_numeric(row["coef_paper"], row["coef_py"], tol),
            }
        )
    ledger.append(
        {
            "table": "3",
            "result": "Table3 N",
            "paper": 11991,
            "python": int(t3["n"].iloc[0]),
            "abs_diff": abs(int(t3["n"].iloc[0]) - 11991),
            "status": compare_numeric(11991, int(t3["n"].iloc[0]), 0),
        }
    )

    # Table 4
    t4 = run_table4(hh)
    artifacts["table4"] = t4
    for _, r in t4.iterrows():
        key = (r["moderator"], r["sample"])
        pub = PUBLISHED_TABLE4[key]
        for side in ("near", "far"):
            ledger.append(
                {
                    "table": "4",
                    "result": f"Table4 {r['moderator']} {r['sample']} {side}",
                    "paper": pub[side],
                    "python": r[side],
                    "abs_diff": abs(r[side] - pub[side]),
                    "status": compare_numeric(pub[side], r[side], 0.015),
                }
            )
        ledger.append(
            {
                "table": "4",
                "result": f"Table4 {r['moderator']} {r['sample']} N",
                "paper": pub["n"],
                "python": r["n"],
                "abs_diff": abs(r["n"] - pub["n"]),
                "status": compare_numeric(pub["n"], r["n"], 5),
            }
        )

    # Table 5 wage
    t5 = run_table5_wage(hh)
    artifacts["table5_wage"] = t5
    for k, tol in [("xxw3", 0.05), ("xxrw3", 0.05), ("n", 5)]:
        paper = PUBLISHED_TABLE5_WAGE[k]
        py = t5[k]
        ledger.append(
            {
                "table": "5",
                "result": f"Table5 wage {k}",
                "paper": paper,
                "python": py,
                "abs_diff": abs(py - paper),
                "status": compare_numeric(paper, py, tol),
            }
        )

    # Table 1C / 2B / Table 5 cols 1–4 (Child Labor Survey)
    cl_path = paths.FINAL / "RW_child_labor_survey.parquet"
    if cl_path.exists():
        from .child_labor.tables import (
            compare_cl_to_published,
            load_cl,
            run_table5_cl,
            table1_panel_c,
            table2_panel_b,
        )

        cl = load_cl(cl_path)
        t1c = table1_panel_c(cl, use_weights=True)
        t2b = table2_panel_b(cl, use_weights=True)
        t5cl = run_table5_cl(cl)
        artifacts["table1_c"] = t1c
        artifacts["table2_b"] = t2b
        artifacts["table5_cl"] = t5cl
        cl_ledger = compare_cl_to_published(t1c, t2b, t5cl)
        ledger.extend(cl_ledger.to_dict("records"))

    # Table 6
    t6 = run_table6(hh)
    artifacts["table6"] = t6
    key_map = {
        ("A_all", "location_out_fixed_a"): "location_out_fixed_a",
        ("A_all", "location_out_mobile_a"): "location_out_mobile_a",
        ("A_all", "location_home_a"): "location_home_a",
        ("B_working", "location_out_fixed_a"): "location_out_fixed_a_w",
        ("B_working", "location_out_mobile_a"): "location_out_mobile_a_w",
        ("B_working", "location_home_a"): "location_home_a_w",
        ("B_working", "number_workers_a"): "number_workers_a_w",
    }
    for _, r in t6.iterrows():
        pk = key_map[(r["panel"], r["outcome"])]
        pub = PUBLISHED_TABLE6[pk]
        for term in ("xxw3", "xxrw3"):
            ledger.append(
                {
                    "table": "6",
                    "result": f"Table6 {pk} {term}",
                    "paper": pub[term],
                    "python": r[term],
                    "abs_diff": abs(r[term] - pub[term]),
                    "status": compare_numeric(pub[term], r[term], 0.02 if "number" not in pk else 0.15),
                }
            )
        ledger.append(
            {
                "table": "6",
                "result": f"Table6 {pk} N",
                "paper": pub["n"],
                "python": r["n"],
                "abs_diff": abs(r["n"] - pub["n"]),
                "status": compare_numeric(pub["n"], r["n"], 5),
            }
        )

    return pd.DataFrame(ledger), artifacts


def write_main_table_outputs(artifacts: dict, ledger: pd.DataFrame, out_dir: Path | None = None):
    out_dir = out_dir or (paths.FINAL / "tables")
    out_dir.mkdir(parents=True, exist_ok=True)
    ledger.to_csv(out_dir / "main_tables_ledger.csv", index=False)
    for name, obj in artifacts.items():
        path = out_dir / f"{name}.csv"
        if isinstance(obj, pd.DataFrame):
            obj.to_csv(path, index=False)
        elif isinstance(obj, dict):
            pd.DataFrame([obj]).to_csv(path, index=False)
    return out_dir
