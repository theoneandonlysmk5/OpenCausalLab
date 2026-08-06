"""Table 3 sample flow + incremental regression ladder."""

from __future__ import annotations

from typing import Any

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf

from opencausallab.stata_semantics.stata_utils import to_numeric
from ..table3 import CONTROLS, YVARS, prepare_table3_sample, run_table3
from opencausallab.validation.audit import (
    GOLDEN,
    SampleFlow,
    append_ledger,
    binary_audit,
    classify_count,
    classify_mean,
    variable_audit,
    weighted_mean,
)


def table3_sample_flow(hh: pd.DataFrame) -> pd.DataFrame:
    """Reproduce estimation N before comparing coefficients."""
    flow = SampleFlow(hh_col="folio" if "folio" in hh.columns else "id_year")
    df = hh.copy()
    flow.log(df, "HHsurvey age<21")

    year = to_numeric(df["year"])
    df = df.loc[(year >= 2012) & (year <= 2019)].copy()
    flow.log(df, "years 2012-2019")

    df = df.loc[to_numeric(df["runningw14"]).notna()].copy()
    flow.log(df, "nonmissing runningw14 (age-in-months week-before)")

    sww = to_numeric(df.get("sww14", pd.Series(np.nan, index=df.index)))
    df_bw = df.loc[sww == 1].copy()
    flow.log(df_bw, "bandwidth |runningw14|<=12 (sww14==1)")

    w = to_numeric(df["kernel_triw14"]).fillna(0)
    df_k = df.loc[w > 0].copy()
    flow.log(df_k, "triangular kernel_triw14 > 0")

    for y in ("works",):
        df_y = df_k.loc[to_numeric(df_k[y]).notna()].copy()
        flow.log(df_y, f"nonmissing outcome {y}")

    need = CONTROLS + ["kernel_triw14", "age_mo_year", "depto", "year"]
    present = [c for c in need if c in df_k.columns]
    df_cc = df_k.dropna(subset=present + ["works"]).copy()
    flow.log(df_cc, "complete cases (Table 3 controls + works)")

    # Crosstabs on final sample
    return flow.to_frame()


def table3_sample_diagnostics(hh: pd.DataFrame) -> dict[str, Any]:
    sample = prepare_table3_sample(hh)
    year = sample["year"].astype(int)
    treat = to_numeric(sample["treatw14"])
    pre = to_numeric(sample["pre"])
    post = to_numeric(sample["post"])
    post_rev = to_numeric(sample["post_rev"])
    urban = to_numeric(sample["urban"])

    diag = {
        "n": len(sample),
        "n_by_year": sample.groupby(year).size().to_dict(),
        "n_below14": int((treat == 1).sum()),
        "n_above14": int((treat == 0).sum()),
        "n_pre": int((pre == 1).sum()),
        "n_post": int((post == 1).sum()),
        "n_post_rev": int((post_rev == 1).sum()),
        "n_urban": int((urban == 1).sum()),
        "n_rural": int((urban == 0).sum()),
        "n_clusters": int(sample["age_mo_year"].nunique()),
        "mean_works_unweighted": float(to_numeric(sample["works"]).mean()),
        "mean_works_pre": float(
            to_numeric(sample.loc[pre == 1, "works"]).mean()
        ),
        "mean_works_kernel_weighted": weighted_mean(
            sample["works"], sample["kernel_triw14"]
        ),
        "crosstab_treat_period": pd.crosstab(
            treat.rename("treatw14"),
            pd.Series(
                np.where(pre == 1, "pre", np.where(post == 1, "post", "post_rev")),
                index=sample.index,
                name="period",
            ),
        ).to_dict(),
    }
    return diag


def regression_ladder(hh: pd.DataFrame) -> pd.DataFrame:
    """
    Incremental specs for the age-14 DiDisc on works.

    Reveals which component moves the coefficient relative to the paper.
    """
    df = prepare_table3_sample(hh)
    df["depto_year"] = (
        df["depto"].astype(int).astype(str) + "_" + df["year"].astype(int).astype(str)
    )
    w = df["kernel_triw14"]
    groups = df["age_mo_year"]

    specs = {
        "M1_raw_didisc": "works ~ xxw3",
        "M2_plus_reversal": "works ~ xxw3 + xxrw3",
        "M3_plus_rd_splines": (
            "works ~ xxw3 + xxrw3 + treatw14 + runningw14 + treatxrunningw14"
        ),
        "M4_plus_period": (
            "works ~ xxw3 + xxrw3 + treatw14 + runningw14 + treatxrunningw14 "
            "+ post + post_rev"
        ),
        "M5_plus_demo": (
            "works ~ xxw3 + xxrw3 + treatw14 + runningw14 + treatxrunningw14 "
            "+ post + post_rev + urban + head_schooling + head_male + head_age "
            "+ indig_head + male + hh_agecat1 + hh_agecat2 + hh_agecat3 "
            "+ hh_agecat4 + adult_women + adult_men + eligible_gr"
        ),
        "M6_plus_fe": (
            "works ~ xxw3 + xxrw3 + treatw14 + runningw14 + treatxrunningw14 "
            "+ post + post_rev + urban + head_schooling + head_male + head_age "
            "+ indig_head + male + hh_agecat1 + hh_agecat2 + hh_agecat3 "
            "+ hh_agecat4 + adult_women + adult_men + eligible_gr + C(depto_year)"
        ),
    }

    rows = []
    for name, formula in specs.items():
        # unweighted OLS
        ols = smf.ols(formula, data=df).fit(
            cov_type="cluster", cov_kwds={"groups": groups}
        )
        # kernel WLS (Table 3)
        wls = smf.wls(formula, data=df, weights=w).fit(
            cov_type="cluster", cov_kwds={"groups": groups}
        )
        for label, res in (("ols_cluster", ols), ("wls_kernel_cluster", wls)):
            rows.append(
                {
                    "spec": name,
                    "estimator": label,
                    "xxw3": float(res.params["xxw3"]),
                    "xxw3_se": float(res.bse["xxw3"]),
                    "xxrw3": float(res.params.get("xxrw3", np.nan))
                    if "xxrw3" in res.params
                    else np.nan,
                    "xxrw3_se": float(res.bse["xxrw3"])
                    if "xxrw3" in res.bse
                    else np.nan,
                    "n": int(res.nobs),
                    "r2": float(res.rsquared),
                }
            )
    return pd.DataFrame(rows)


def table1_prelaw_audit(hh: pd.DataFrame) -> dict[str, Any]:
    """
    Table 1 Panel A: ``Table_1_Desc_Statistics.do``

    ``keep if year in 2012/2013``
    ``keep if age_dob_m>=120 & age_dob_m<=180``
    """
    df = hh.copy()
    adm = to_numeric(df["age_dob_m"])
    year = to_numeric(df["year"])
    mask = year.isin([2012, 2013]) & adm.ge(120) & adm.le(180)
    sub = df.loc[mask].copy()
    works = to_numeric(sub["works"])
    # Table 1 uses ``hours_week`` with base=workers for some cols; all-children
    # column uses the _a (zeros for non-workers) concept in practice via sum.
    # Prefer hours_week_a for the all-children mean (paper col 1 = 3.325).
    hours_col = "hours_week_a" if "hours_week_a" in sub.columns else "hours_week"
    return {
        "n": int(len(sub)),
        "mean_works": float(works.mean()),
        "mean_hours": float(to_numeric(sub[hours_col]).mean()),
        "mean_male": float(to_numeric(sub["male"]).mean()),
        "mean_head_schooling": float(to_numeric(sub["head_schooling"]).mean())
        if "head_schooling" in sub.columns
        else np.nan,
        "mean_indig_head": float(to_numeric(sub["indig_head"]).mean())
        if "indig_head" in sub.columns
        else np.nan,
        "n_10_11": int(((adm >= 120) & (adm < 144) & mask).sum()),
        "n_12_13": int(((adm >= 144) & (adm < 168) & mask).sum()),
        "n_14_15": int(((adm >= 168) & (adm < 192) & mask).sum()),
    }


def build_table3_ledger(hh: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Compare Python Table 3 artifacts to manuscript golden values."""
    from ..table3 import compare_to_published, run_table3

    sample = prepare_table3_sample(hh)
    results = run_table3(sample)
    comparison = compare_to_published(results)
    diag = table3_sample_diagnostics(hh)
    t1 = table1_prelaw_audit(hh)

    ledger: list[dict] = []
    append_ledger(
        ledger,
        result="Table1 pre-law ages10-15 N",
        paper=GOLDEN["table1_prelaw_ages_10_15_n"],
        python=t1["n"],
        status=classify_count(GOLDEN["table1_prelaw_ages_10_15_n"], t1["n"], near_tol=10),
        likely_cause="age_dob_m filter 120-180; 4-row residual vs Stata HHsurvey",
        unit="count",
    )
    append_ledger(
        ledger,
        result="Table1 pre-law any work mean",
        paper=GOLDEN["table1_prelaw_any_work"],
        python=t1["mean_works"],
        status=classify_mean(GOLDEN["table1_prelaw_any_work"], t1["mean_works"], 0.005),
        likely_cause="sample / works definition",
        unit="share",
    )
    append_ledger(
        ledger,
        result="Table1 subgroup N 10-11",
        paper=2698,
        python=t1["n_10_11"],
        status=classify_count(2698, t1["n_10_11"], near_tol=5),
        likely_cause="age_dob_m bins",
        unit="count",
    )
    append_ledger(
        ledger,
        result="Table1 subgroup N 12-13",
        paper=3108,
        python=t1["n_12_13"],
        status=classify_count(3108, t1["n_12_13"], near_tol=5),
        likely_cause="age_dob_m bins",
        unit="count",
    )
    append_ledger(
        ledger,
        result="Table1 subgroup N 14-15",
        paper=1604,
        python=t1["n_14_15"],
        status=classify_count(1604, t1["n_14_15"], near_tol=10),
        likely_cause="keep uses <=180 so 14-15 bin is truncated",
        unit="count",
    )
    append_ledger(
        ledger,
        result="Table3 estimation N",
        paper=GOLDEN["table3_n"],
        python=diag["n"],
        status=classify_count(GOLDEN["table3_n"], diag["n"], near_tol=5),
        likely_cause="kernel boundary / complete-case / one-row merge drift",
        unit="count",
    )
    append_ledger(
        ledger,
        result="Table3 pre mean works",
        paper=GOLDEN["table3_mean_works"],
        python=diag["mean_works_pre"],
        status=classify_mean(GOLDEN["table3_mean_works"], diag["mean_works_pre"], 0.002),
        likely_cause="sample composition",
        unit="share",
    )

    for _, row in comparison.iterrows():
        term = row["term"]
        out = row["outcome"]
        append_ledger(
            ledger,
            result=f"Table3 {out} {term} coef",
            paper=row["coef_paper"],
            python=row["coef_py"],
            status=classify_mean(row["coef_paper"], row["coef_py"], 0.01)
            if out != "hours_week_a"
            else classify_mean(row["coef_paper"], row["coef_py"], 0.12),
            likely_cause="microdata / WLS numerics / FE collinearity",
            unit="coef",
        )
        append_ledger(
            ledger,
            result=f"Table3 {out} {term} SE",
            paper=row["se_paper"],
            python=row["se_py"],
            status=classify_mean(row["se_paper"], row["se_py"], 0.02),
            likely_cause="cluster sandwich / dof / weight scaling",
            unit="se",
        )

    return pd.DataFrame(ledger), {
        "diagnostics": diag,
        "table1": t1,
        "results": results,
        "comparison": comparison,
        "var_audit": variable_audit(
            sample,
            [
                "works",
                "xxw3",
                "xxrw3",
                "treatw14",
                "runningw14",
                "kernel_triw14",
                "post",
                "pre",
                "urban",
                "male",
            ],
        ),
        "binary_audit": binary_audit(
            sample, ["works", "xxw3", "treatw14", "post", "pre", "urban", "male"]
        ),
    }
