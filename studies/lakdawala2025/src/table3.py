"""
Table 3 — age-14 difference-in-discontinuity (DiDisc) on work outcomes.

Faithful Python translation of:
  studies/lakdawala2025/vendor/stata_dofiles/main_tables/Table_3_DDisc_Work.do

Stata specification (per outcome y):
  reg y xxw3 xxrw3 treatw14 runningw14 treatxrunningw14
      post post_rev urban head_schooling head_male head_age indig_head male
      hh_agecat1-4 adult_women adult_men eligible_gr i.depto#i.year
      [aw=kernel_triw14], vce(cluster age_mo_year)

Published manuscript targets (JDE R1 Table 3) are stored in PUBLISHED_TABLE3
for regression checks without a Stata license.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

import pandas as pd
import statsmodels.formula.api as smf

from . import paths
from core.stata_semantics.stata_utils import to_numeric

YVARS = [
    "works",
    "hours_week_a",
    "self_employed_a",
    "wrk_forother_a",
    "forbidden_a",
    "not_forbidden_a",
    "lf_participation",
]

YLABELS = {
    "works": "Any Work",
    "hours_week_a": "Hours Worked",
    "self_employed_a": "Work for Self",
    "wrk_forother_a": "Work for Others",
    "forbidden_a": "Prohibited Work",
    "not_forbidden_a": "Allowed Work",
    "lf_participation": "Labor Force Participation",
}

# Linear DiDisc / RD terms + controls (departamento×year FE added separately).
CONTROLS = [
    "xxw3",
    "xxrw3",
    "treatw14",
    "runningw14",
    "treatxrunningw14",
    "post",
    "post_rev",
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
]

# Manuscript Table 3 (rounded as printed).
PUBLISHED_TABLE3: dict[str, dict[str, float]] = {
    "works": {
        "xxw3": -0.039,
        "xxw3_se": 0.017,
        "xxrw3": -0.000,
        "xxrw3_se": 0.019,
        "n": 11991,
        "mean_pre": 0.180,
    },
    "hours_week_a": {
        "xxw3": -0.969,
        "xxw3_se": 0.526,
        "xxrw3": 0.508,
        "xxrw3_se": 0.562,
        "n": 11991,
        "mean_pre": 4.397,
    },
    "self_employed_a": {
        "xxw3": -0.002,
        "xxw3_se": 0.004,
        "xxrw3": -0.000,
        "xxrw3_se": 0.005,
        "n": 11991,
        "mean_pre": 0.00490,
    },
    "wrk_forother_a": {
        "xxw3": -0.037,
        "xxw3_se": 0.017,
        "xxrw3": -0.000,
        "xxrw3_se": 0.019,
        "n": 11991,
        "mean_pre": 0.175,
    },
    "forbidden_a": {
        "xxw3": 0.004,
        "xxw3_se": 0.006,
        "xxrw3": 0.018,
        "xxrw3_se": 0.012,
        "n": 11991,
        "mean_pre": 0.0114,
    },
    "not_forbidden_a": {
        "xxw3": -0.043,
        "xxw3_se": 0.015,
        "xxrw3": -0.019,
        "xxrw3_se": 0.018,
        "n": 11991,
        "mean_pre": 0.169,
    },
    "lf_participation": {
        "xxw3": -0.040,
        "xxw3_se": 0.017,
        "xxrw3": 0.002,
        "xxrw3_se": 0.019,
        "n": 11991,
        "mean_pre": 0.185,
    },
}

_RHS = (
    "xxw3 + xxrw3 + treatw14 + runningw14 + treatxrunningw14 + "
    "post + post_rev + urban + head_schooling + head_male + head_age + "
    "indig_head + male + hh_agecat1 + hh_agecat2 + hh_agecat3 + hh_agecat4 + "
    "adult_women + adult_men + eligible_gr + C(depto_year)"
)


def _stars(p: float) -> str:
    if p < 0.01:
        return "***"
    if p < 0.05:
        return "**"
    if p < 0.10:
        return "*"
    return ""


def load_hhsurvey(path: Path | None = None) -> pd.DataFrame:
    path = path or (paths.FINAL / "HHsurvey.parquet")
    return pd.read_parquet(path)


def prepare_table3_sample(
    hh: pd.DataFrame,
    *,
    years: tuple[int, int] = (2012, 2019),
) -> pd.DataFrame:
    """
    Analytic-weight sample for Table 3.

    Mirrors Stata ``keep if year>=2012 & year<=2019`` plus non-missing
    regressors and ``kernel_triw14 > 0`` (zero weights do not enter ``reg``).
    """
    df = hh.copy()
    year = to_numeric(df["year"])
    df = df.loc[(year >= years[0]) & (year <= years[1])].copy()

    needed = (
        list(YVARS)
        + CONTROLS
        + ["depto", "year", "kernel_triw14", "age_mo_year", "pre"]
    )
    missing_cols = [c for c in needed if c not in df.columns]
    if missing_cols:
        raise KeyError(f"HHsurvey missing Table 3 columns: {missing_cols}")

    for c in YVARS + CONTROLS + ["kernel_triw14", "pre"]:
        df[c] = to_numeric(df[c])
    df["depto"] = to_numeric(df["depto"])
    df["year"] = to_numeric(df["year"]).astype(int)
    df["age_mo_year"] = df["age_mo_year"]

    w = df["kernel_triw14"].fillna(0.0)
    df = df.loc[w > 0].copy()
    df["depto_year"] = (
        df["depto"].astype(int).astype(str) + "_" + df["year"].astype(int).astype(str)
    )

    complete = CONTROLS + ["kernel_triw14", "age_mo_year", "depto_year", "pre"] + list(
        YVARS
    )
    df = df.dropna(subset=complete).reset_index(drop=True)
    return df


def estimate_outcome(df: pd.DataFrame, y: str):
    """WLS DiDisc with departamento×year FE and age_mo_year clusters."""
    if y not in df.columns:
        raise KeyError(y)
    formula = f"{y} ~ {_RHS}"
    model = smf.wls(formula, data=df, weights=df["kernel_triw14"])
    return model.fit(
        cov_type="cluster",
        cov_kwds={"groups": df["age_mo_year"]},
    )


def run_table3(df: pd.DataFrame, yvars: Iterable[str] = YVARS) -> pd.DataFrame:
    """Estimate all Table 3 columns; return a tidy results frame."""
    rows: list[dict] = []
    for y in yvars:
        res = estimate_outcome(df, y)
        mean_pre = float(df.loc[df["pre"] == 1, y].mean())
        for term in ("xxw3", "xxrw3"):
            rows.append(
                {
                    "outcome": y,
                    "label": YLABELS.get(y, y),
                    "term": term,
                    "coef": float(res.params[term]),
                    "se": float(res.bse[term]),
                    "pvalue": float(res.pvalues[term]),
                    "stars": _stars(float(res.pvalues[term])),
                    "n": int(res.nobs),
                    "mean_pre": mean_pre,
                    "n_clusters": int(df["age_mo_year"].nunique()),
                }
            )
    return pd.DataFrame(rows)


def compare_to_published(results: pd.DataFrame) -> pd.DataFrame:
    """Side-by-side Python vs manuscript Table 3 for xxw3 / xxrw3."""
    rows: list[dict] = []
    for y, pub in PUBLISHED_TABLE3.items():
        sub = results.loc[results["outcome"] == y]
        if sub.empty:
            continue
        for term, pub_key, se_key in (
            ("xxw3", "xxw3", "xxw3_se"),
            ("xxrw3", "xxrw3", "xxrw3_se"),
        ):
            r = sub.loc[sub["term"] == term].iloc[0]
            rows.append(
                {
                    "outcome": y,
                    "term": term,
                    "coef_py": r["coef"],
                    "coef_paper": pub[pub_key],
                    "delta_coef": r["coef"] - pub[pub_key],
                    "se_py": r["se"],
                    "se_paper": pub[se_key],
                    "delta_se": r["se"] - pub[se_key],
                    "n_py": r["n"],
                    "n_paper": pub["n"],
                    "mean_pre_py": r["mean_pre"],
                    "mean_pre_paper": pub["mean_pre"],
                }
            )
    return pd.DataFrame(rows)


def format_wide(results: pd.DataFrame) -> pd.DataFrame:
    """One column per outcome (paper layout)."""
    out: dict[str, list] = {
        "stat": [
            "Post Law × 1{Age<14}",
            "SE",
            "Post Reversal × 1{Age<14}",
            "SE",
            "Obs.",
            "Mean (pre)",
        ]
    }
    for y in YVARS:
        sub = results.loc[results["outcome"] == y]
        if sub.empty:
            continue
        b = sub.loc[sub["term"] == "xxw3"].iloc[0]
        r = sub.loc[sub["term"] == "xxrw3"].iloc[0]
        out[YLABELS[y]] = [
            f"{b['coef']:.3f}{b['stars']}",
            f"({b['se']:.3f})",
            f"{r['coef']:.3f}{r['stars']}",
            f"({r['se']:.3f})",
            f"{int(b['n'])}",
            f"{b['mean_pre']:.3f}",
        ]
    return pd.DataFrame(out)


def export_local_sample(
    hh: pd.DataFrame,
    path: Path | None = None,
    *,
    extra_cols: Iterable[str] | None = None,
) -> Path:
    """
    Export age-14 local bandwidth sample for causal-ML stages.

    Same row filter as ``prepare_table3_sample``, plus optional moderators.
    """
    path = path or (paths.FINAL / "table3_local_sample.parquet")

    default_extra = [
        "id_year",
        "folio",
        "nro",
        "age",
        "age_dob_m",
        "sww14",
        "running14",
        "treat14",
        "f_weight",
        "indig",
        "lang_spa_h",
        "income_q",
        "cod_secc",
        "cod_prov",
        "distance_mteps",
        "mtepsoffices",
        "works717",
        "eligible",
    ]
    wanted = list(
        dict.fromkeys(
            list(YVARS)
            + CONTROLS
            + [
                "depto",
                "year",
                "kernel_triw14",
                "age_mo_year",
                "pre",
            ]
            + list(default_extra)
            + list(extra_cols or [])
        )
    )

    year = to_numeric(hh["year"])
    base = hh.loc[(year >= 2012) & (year <= 2019)].copy()
    for c in YVARS + CONTROLS + ["kernel_triw14", "pre"]:
        base[c] = to_numeric(base[c])
    base["depto"] = to_numeric(base["depto"])
    base["year"] = to_numeric(base["year"]).astype(int)
    w = base["kernel_triw14"].fillna(0.0)
    base = base.loc[w > 0].copy()
    base["depto_year"] = (
        base["depto"].astype(int).astype(str) + "_" + base["year"].astype(int).astype(str)
    )
    complete = CONTROLS + ["kernel_triw14", "age_mo_year", "depto_year", "pre"] + list(
        YVARS
    )
    base = base.dropna(subset=complete).reset_index(drop=True)
    keep = [c for c in wanted + ["depto_year"] if c in base.columns]
    out = base[keep].copy()

    path.parent.mkdir(parents=True, exist_ok=True)
    out.to_parquet(path, index=False)
    return path


def write_results(
    results: pd.DataFrame,
    comparison: pd.DataFrame,
    *,
    out_dir: Path | None = None,
) -> tuple[Path, Path, Path]:
    out_dir = out_dir or (paths.FINAL / "tables")
    out_dir.mkdir(parents=True, exist_ok=True)
    long_path = out_dir / "table3_didisc_work.csv"
    wide_path = out_dir / "table3_didisc_work_wide.csv"
    cmp_path = out_dir / "table3_vs_published.csv"
    results.to_csv(long_path, index=False)
    format_wide(results).to_csv(wide_path, index=False)
    comparison.to_csv(cmp_path, index=False)
    return long_path, wide_path, cmp_path
