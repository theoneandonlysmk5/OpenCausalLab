"""Child Labor Survey tables: Table 1C, 2B, Table 5 cols 1–4."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from scipy import stats

from .. import paths
from core.causal.didisc_reg import depto_year, stars, wls_cluster
from core.stata_semantics.stata_utils import to_numeric

# Manuscript (JDE r1) targets
PUBLISHED_TABLE1_C = {
    "risks_a_all": 0.294,
    "risks_working": 0.545,
    "risks_a_10_11": 0.246,
    "risks_a_12_13": 0.314,
    "risks_a_14_15": 0.346,
    "injury_a_all": 0.178,
    "injury_working": 0.324,
    "injury_a_10_11": 0.163,
    "injury_a_12_13": 0.184,
    "injury_a_14_15": 0.194,
    "n_all": 3477,
    "n_work": 1749,
    "n_10_11": 1343,
    "n_12_13": 1389,
    "n_14_15": 745,
}

PUBLISHED_TABLE2_B = {
    "risks_ext": 0.679,
    "risks_fam": 0.537,
    "injury_ext": 0.447,
    "injury_fam": 0.314,
    "n_ext": 186,
    "n_fam": 1741,
    "pval_risks": 0.0001,
    "pval_injury": 0.0006,
}

PUBLISHED_TABLE5_CL = {
    "risks_a_all": {"xx": -0.008, "xx_se": 0.017, "n": 8372, "mean": 0.281},
    "risks_a_work": {"xx": -0.038, "xx_se": 0.035, "n": 2914, "mean": 0.536},
    "injury_a_all": {"xx": -0.015, "xx_se": 0.014, "n": 8411, "mean": 0.188},
    "injury_a_work": {"xx": -0.015, "xx_se": 0.029, "n": 3208, "mean": 0.327},
}


def load_cl(path: Path | None = None) -> pd.DataFrame:
    path = path or (paths.FINAL / "RW_child_labor_survey.parquet")
    return pd.read_parquet(path)


def _wmean(y: pd.Series, w: pd.Series) -> float:
    y = to_numeric(y)
    w = to_numeric(w)
    ok = y.notna() & w.notna()
    if not ok.any():
        return float("nan")
    return float((y[ok] * w[ok]).sum() / w[ok].sum())


def _wn(y: pd.Series, w: pd.Series | None = None) -> int:
    y = to_numeric(y)
    if w is None:
        return int(y.notna().sum())
    w = to_numeric(w)
    return int((y.notna() & w.notna()).sum())


def table1_panel_c(cl: pd.DataFrame, *, use_weights: bool = True) -> pd.DataFrame:
    """Table 1 Panel C: 2008 CL survey, ages 10–15 (age_survey_m ∈ [120,180])."""
    df = cl.copy()
    age = to_numeric(df["age_survey_m"])
    year = to_numeric(df["year"])
    mask = year.eq(2008) & age.ge(120) & age.le(180)
    df = df.loc[mask].copy()
    age = to_numeric(df["age_survey_m"])
    df["age10to11"] = age.ge(120) & age.lt(144)
    df["age12to13"] = age.ge(144) & age.lt(168)
    df["age14to15"] = age.ge(168) & age.lt(192)
    w = to_numeric(df["weights"]) if use_weights else pd.Series(1.0, index=df.index)

    rows = []
    for y, ya in [("risks", "risks_a"), ("injury", "injury_a")]:
        rows.append(
            {
                "variable": ya,
                "all": _wmean(df[ya], w),
                "working": _wmean(df[y], w),
                "age10_11": _wmean(df.loc[df["age10to11"], ya], w.loc[df["age10to11"]]),
                "age12_13": _wmean(df.loc[df["age12to13"], ya], w.loc[df["age12to13"]]),
                "age14_15": _wmean(df.loc[df["age14to15"], ya], w.loc[df["age14to15"]]),
                "n_all": _wn(df[ya], w),
                "n_work": _wn(df[y], w),
                "n_10_11": _wn(df.loc[df["age10to11"], ya], w.loc[df["age10to11"]]),
                "n_12_13": _wn(df.loc[df["age12to13"], ya], w.loc[df["age12to13"]]),
                "n_14_15": _wn(df.loc[df["age14to15"], ya], w.loc[df["age14to15"]]),
            }
        )
    out = pd.DataFrame(rows)
    # Obs row uses injury Ns (Stata writes n_a2 / n_2 from injury loop)
    out.attrs["n_all"] = int(out.loc[out["variable"] == "injury_a", "n_all"].iloc[0])
    out.attrs["n_work"] = int(out.loc[out["variable"] == "injury_a", "n_work"].iloc[0])
    out.attrs["n_10_11"] = int(out.loc[out["variable"] == "injury_a", "n_10_11"].iloc[0])
    out.attrs["n_12_13"] = int(out.loc[out["variable"] == "injury_a", "n_12_13"].iloc[0])
    out.attrs["n_14_15"] = int(out.loc[out["variable"] == "injury_a", "n_14_15"].iloc[0])
    out.attrs["use_weights"] = use_weights
    return out


def table2_panel_b(cl: pd.DataFrame, *, use_weights: bool = True) -> dict[str, Any]:
    """Table 2 Panel B: 2008 CL, ages 9–15, risks/injury by employer type."""
    df = cl.copy()
    age = to_numeric(df["age_survey_m"])
    year = to_numeric(df["year"])
    mask = year.eq(2008) & age.ge(108) & age.le(180)
    df = df.loc[mask].copy()
    w = to_numeric(df["weights"]) if use_weights else pd.Series(1.0, index=df.index)
    fam = to_numeric(df["workforfamily"]).eq(1)
    emp = to_numeric(df["workforemployer"]).eq(1)

    out: dict[str, Any] = {"use_weights": use_weights}
    for y in ("risks", "injury"):
        out[f"{y}_fam"] = _wmean(df.loc[fam, y], w.loc[fam])
        out[f"{y}_ext"] = _wmean(df.loc[emp, y], w.loc[emp])
        out[f"n_{y}_fam"] = _wn(df.loc[fam, y], w.loc[fam])
        out[f"n_{y}_ext"] = _wn(df.loc[emp, y], w.loc[emp])

        # Weighted mean-diff p-value via WLS of y on employer type
        sub = df.loc[fam | emp, [y]].copy()
        sub["y"] = to_numeric(sub[y])
        sub["ext"] = emp.loc[fam | emp].astype(float)
        sub["w"] = w.loc[fam | emp]
        sub = sub.dropna()
        if len(sub) > 2 and sub["ext"].nunique() == 2:
            import statsmodels.formula.api as smf

            res = smf.wls("y ~ ext", data=sub, weights=sub["w"]).fit()
            out[f"pval_{y}"] = float(res.pvalues["ext"])
        else:
            out[f"pval_{y}"] = float("nan")

    out["n_fam"] = out["n_risks_fam"]
    out["n_ext"] = out["n_risks_ext"]
    return out


def _prepare_cl_reg(cl: pd.DataFrame, *, recall_y: bool) -> pd.DataFrame:
    df = cl.copy()
    flag = "ssy" if recall_y else "ss"
    df = df.loc[to_numeric(df[flag]).eq(1)].copy()
    num_cols = [
        "risks_a",
        "injury_a",
        "d_worked",
        "xx",
        "xxy",
        "post",
        "treat",
        "treaty",
        "running",
        "runningy",
        "treatxrunning",
        "treatxrunningy",
        "kernel_tri",
        "kernel_triy",
        "h_edu_head",
        "h_male_head",
        "h_age_head",
        "indig_head",
        "c_gender",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "c_area",
        "s10",
        "s12",
        "s14",
        "sy10",
        "sy12",
        "sy14",
        "age_mo_year",
        "c_depto",
        "year",
    ]
    for c in num_cols:
        if c in df.columns:
            df[c] = to_numeric(df[c])
    df["depto_year"] = depto_year(df, "c_depto", "year")
    return df


def _table5_one(
    df: pd.DataFrame,
    *,
    outcome: str,
    recall_y: bool,
    working_only: bool,
) -> dict[str, Any]:
    """One Table 5 CL column (risks or injury × all/working)."""
    work = to_numeric(df["d_worked"]).eq(1)
    sub = df.loc[work].copy() if working_only else df.copy()

    if recall_y:
        # injury: use year-before running vars; Stata renames xxy→xx for esttab
        drop_survey = ["xx", "treat", "running", "treatxrunning", "kernel_tri", "s10", "s12", "s14"]
        sub = sub.drop(columns=[c for c in drop_survey if c in sub.columns], errors="ignore")
        sub = sub.rename(
            columns={
                "xxy": "xx",
                "treaty": "treat",
                "runningy": "running",
                "treatxrunningy": "treatxrunning",
                "kernel_triy": "kernel_tri",
                "sy10": "s10",
                "sy12": "s12",
                "sy14": "s14",
            }
        )

    dem = [
        "post",
        "treat",
        "running",
        "treatxrunning",
        "h_edu_head",
        "h_male_head",
        "h_age_head",
        "indig_head",
        "c_gender",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "c_area",
        "s10",
        "s12",
        "s14",
    ]
    terms = ["xx"] + dem
    # Stata adds d_worked control for injury × working sample
    if recall_y and working_only:
        terms.append("d_worked")
    terms.append("C(depto_year)")

    need = [outcome, "kernel_tri", "age_mo_year", "depto_year"] + [
        t for t in terms if t != "C(depto_year)"
    ]
    # Stata Mean is NOT e(sample): ``sum y if year==2008 & ss==1 [& d_worked==1]``
    # (unweighted), before listwise deletion on controls / kernel.
    ss_flag = "ssy" if recall_y else "ss"
    mean_mask = to_numeric(df["year"]).eq(2008) & to_numeric(df[ss_flag]).eq(1)
    if working_only:
        mean_mask = mean_mask & to_numeric(df["d_worked"]).eq(1)
    mean_pre = float(to_numeric(df.loc[mean_mask, outcome]).mean())

    sub = sub.dropna(subset=[c for c in need if c in sub.columns]).copy()
    sub = sub.loc[to_numeric(sub["kernel_tri"]).fillna(0) > 0].reset_index(drop=True)
    formula = f"{outcome} ~ " + " + ".join(terms)
    res = wls_cluster(formula, sub, weight="kernel_tri")
    return {
        "outcome": outcome,
        "sample": "working" if working_only else "all",
        "recall": "year_before" if recall_y else "survey_date",
        "xx": float(res.params["xx"]),
        "xx_se": float(res.bse["xx"]),
        "n": int(res.nobs),
        "mean": mean_pre,
        "stars_xx": stars(float(res.pvalues["xx"])),
    }


def run_table5_cl(cl: pd.DataFrame) -> pd.DataFrame:
    """Table 5 columns 1–4 (CL survey stacked DiDisc)."""
    risks_df = _prepare_cl_reg(cl, recall_y=False)
    injury_df = _prepare_cl_reg(cl, recall_y=True)
    rows = [
        _table5_one(risks_df, outcome="risks_a", recall_y=False, working_only=False),
        _table5_one(risks_df, outcome="risks_a", recall_y=False, working_only=True),
        _table5_one(injury_df, outcome="injury_a", recall_y=True, working_only=False),
        _table5_one(injury_df, outcome="injury_a", recall_y=True, working_only=True),
    ]
    return pd.DataFrame(rows)


def compare_cl_to_published(
    t1c: pd.DataFrame,
    t2b: dict[str, Any],
    t5: pd.DataFrame,
) -> pd.DataFrame:
    """Ledger rows for CL panels vs manuscript."""
    from ..main_tables import compare_numeric

    rows: list[dict[str, Any]] = []

    # Table 1C
    r = t1c.loc[t1c["variable"] == "risks_a"].iloc[0]
    i = t1c.loc[t1c["variable"] == "injury_a"].iloc[0]
    mapping = [
        ("risks_a_all", float(r["all"]), 0.02),
        ("risks_working", float(r["working"]), 0.02),
        ("risks_a_10_11", float(r["age10_11"]), 0.02),
        ("risks_a_12_13", float(r["age12_13"]), 0.02),
        ("risks_a_14_15", float(r["age14_15"]), 0.02),
        ("injury_a_all", float(i["all"]), 0.02),
        ("injury_working", float(i["working"]), 0.02),
        ("injury_a_10_11", float(i["age10_11"]), 0.02),
        ("injury_a_12_13", float(i["age12_13"]), 0.02),
        ("injury_a_14_15", float(i["age14_15"]), 0.02),
        ("n_all", float(t1c.attrs["n_all"]), 50),
        ("n_work", float(t1c.attrs["n_work"]), 50),
        ("n_10_11", float(t1c.attrs["n_10_11"]), 50),
        ("n_12_13", float(t1c.attrs["n_12_13"]), 50),
        ("n_14_15", float(t1c.attrs["n_14_15"]), 50),
    ]
    for key, py, tol in mapping:
        paper = PUBLISHED_TABLE1_C[key]
        rows.append(
            {
                "table": "1C",
                "result": f"Table1C {key}",
                "paper": paper,
                "python": py,
                "abs_diff": abs(py - paper),
                "status": compare_numeric(paper, py, tol),
            }
        )

    # Table 2B
    for key, tol in [
        ("risks_ext", 0.05),
        ("risks_fam", 0.05),
        ("injury_ext", 0.05),
        ("injury_fam", 0.05),
        ("n_ext", 20),
        ("n_fam", 50),
    ]:
        paper = PUBLISHED_TABLE2_B[key]
        py = float(t2b[key])
        rows.append(
            {
                "table": "2B",
                "result": f"Table2B {key}",
                "paper": paper,
                "python": py,
                "abs_diff": abs(py - paper),
                "status": compare_numeric(paper, py, tol),
            }
        )

    # Table 5 CL
    key_map = {
        ("risks_a", "all"): "risks_a_all",
        ("risks_a", "working"): "risks_a_work",
        ("injury_a", "all"): "injury_a_all",
        ("injury_a", "working"): "injury_a_work",
    }
    for _, row in t5.iterrows():
        k = key_map[(row["outcome"], row["sample"])]
        paper = PUBLISHED_TABLE5_CL[k]
        for field, tol in [("xx", 0.03), ("xx_se", 0.02), ("n", 200), ("mean", 0.05)]:
            py = float(row[field])
            p = float(paper[field])
            rows.append(
                {
                    "table": "5CL",
                    "result": f"Table5 {k} {field}",
                    "paper": p,
                    "python": py,
                    "abs_diff": abs(py - p),
                    "status": compare_numeric(p, py, tol),
                }
            )
    return pd.DataFrame(rows)
