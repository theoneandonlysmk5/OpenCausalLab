"""
Pre-specified subgroup / interaction DiDisc benchmarks.

Faithful translations of:
  - appendix_tables/Table_A3_DDisc_HeterogeneityByGender.do
  - main_tables/Table_4_DDisc_HeterogeneityDistanceToInspectors.do

Plus predetermined-moderator splits (urban, indig_head) on the gender template.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from scipy import stats

from . import paths
from opencausallab.stata_semantics.stata_utils import to_numeric
from .table3 import CONTROLS

OUTCOME = "works"

PUBLISHED_GENDER = {
    "girls": -0.050,
    "boys": -0.029,
    "n": 11991,
    "diff_p": 0.424,
}
PUBLISHED_DISTANCE_TIME = {
    "far": 0.002,
    "near": -0.030,
    "n": 7650,
}


def _stars(p: float) -> str:
    if p < 0.01:
        return "***"
    if p < 0.05:
        return "**"
    if p < 0.10:
        return "*"
    return ""


def _depto_year(df: pd.DataFrame) -> pd.Series:
    return (
        to_numeric(df["depto"]).astype(int).astype(str)
        + "_"
        + to_numeric(df["year"]).astype(int).astype(str)
    )


def _wls_cluster(formula: str, df: pd.DataFrame, weight: str = "kernel_triw14"):
    model = smf.wls(formula, data=df, weights=df[weight])
    return model.fit(
        cov_type="cluster",
        cov_kwds={"groups": df["age_mo_year"]},
    )


def _nlcom_linear(
    res, coef_a: str, coef_b: str | None = None
) -> tuple[float, float, float]:
    """Estimate a (+ b) with delta-method SE from clustered covariance."""
    params = res.params
    cov = res.cov_params()
    if coef_b is None:
        est = float(params[coef_a])
        se = float(np.sqrt(cov.loc[coef_a, coef_a]))
    else:
        est = float(params[coef_a] + params[coef_b])
        var = (
            cov.loc[coef_a, coef_a]
            + cov.loc[coef_b, coef_b]
            + 2.0 * cov.loc[coef_a, coef_b]
        )
        se = float(np.sqrt(max(var, 0.0)))
    df_r = getattr(res, "df_resid", np.inf)
    t = est / se if se > 0 else np.nan
    p = float(2 * stats.t.sf(abs(t), df_r)) if np.isfinite(t) else np.nan
    return est, se, p


def estimate_binary_heterogeneity(
    df: pd.DataFrame,
    *,
    moderator: str,
    label0: str,
    label1: str,
    outcome: str = OUTCOME,
    include_reversal: bool = True,
    years: tuple[int, int] | None = None,
    drop_eligible: bool = False,
) -> dict:
    """
    Interaction DiDisc: ``xxw3`` + ``xxw3×h`` (+ reversal analogues).

    Effect at h=0 is ``xxw3``; at h=1 is ``xxw3 + xxw3_x_h``.
    Matches Stata ``treatw14x{h} := treatxrunningw14 * h``.
    """
    work = df.copy()
    if years is not None:
        y = to_numeric(work["year"])
        work = work.loc[(y >= years[0]) & (y <= years[1])].copy()

    work[moderator] = to_numeric(work[moderator])
    work[outcome] = to_numeric(work[outcome])
    for c in CONTROLS:
        if c in work.columns:
            work[c] = to_numeric(work[c])
    work["kernel_triw14"] = to_numeric(work["kernel_triw14"])
    work = work.loc[work["kernel_triw14"].fillna(0) > 0].copy()
    work["depto"] = to_numeric(work["depto"])
    work["year"] = to_numeric(work["year"]).astype(int)
    work["depto_year"] = _depto_year(work)

    work["xxw3_x_h"] = work["xxw3"] * work[moderator]
    work["post_x_h"] = work["post"] * work[moderator]
    # Stata name treatw14xh but constructed as treatxrunningw14 * h
    work["treatw14_x_h"] = work["treatxrunningw14"] * work[moderator]
    if include_reversal:
        work["xxrw3_x_h"] = work["xxrw3"] * work[moderator]
        work["post_rev_x_h"] = work["post_rev"] * work[moderator]

    # Table 3 controls, keep moderator once as main effect.
    ctrl = []
    for c in CONTROLS:
        if c in {"xxw3", "xxrw3"}:
            continue
        if not include_reversal and c == "post_rev":
            continue
        if drop_eligible and c == "eligible_gr":
            continue
        if c == moderator:
            continue
        ctrl.append(c)
    ctrl.append(moderator)

    parts = [
        "xxw3",
        "xxw3_x_h",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "treatw14_x_h",
        "post_x_h",
    ]
    if include_reversal:
        parts += ["xxrw3", "xxrw3_x_h", "post_rev_x_h"]
    parts += ctrl + ["C(depto_year)"]

    need = [outcome, "kernel_triw14", "age_mo_year", "depto_year", "pre", moderator] + [
        t for t in parts if t != "C(depto_year)"
    ]
    work = work.dropna(subset=[c for c in need if c in work.columns]).reset_index(
        drop=True
    )

    formula = f"{outcome} ~ " + " + ".join(parts)
    res = _wls_cluster(formula, work)
    mean_pre = float(work.loc[work["pre"] == 1, outcome].mean())

    e0, se0, p0 = _nlcom_linear(res, "xxw3")
    e1, se1, p1 = _nlcom_linear(res, "xxw3", "xxw3_x_h")
    out: dict = {
        "moderator": moderator,
        "outcome": outcome,
        "sample": "all",
        "n": int(res.nobs),
        "mean_pre": mean_pre,
        # Coding-correct: h=0 / h=1
        f"effect_{label0}": e0,
        f"se_{label0}": se0,
        f"p_{label0}": p0,
        f"stars_{label0}": _stars(p0),
        f"effect_{label1}": e1,
        f"se_{label1}": se1,
        f"p_{label1}": p1,
        f"stars_{label1}": _stars(p1),
        "diff_h1_minus_h0": float(res.params["xxw3_x_h"]),
        "diff_se": float(res.bse["xxw3_x_h"]),
        "diff_p": float(res.pvalues["xxw3_x_h"]),
        "years": f"{int(work['year'].min())}-{int(work['year'].max())}",
        "label0": label0,
        "label1": label1,
    }
    # Stata Table A3 labels `nlcom (girls: xxw3+xxwh3) (boys: xxw3)` with
    # xxwh3=xxw3*male — i.e. swaps names relative to male=0/1 coding.
    if moderator == "male":
        out["stata_label_girls"] = e1
        out["stata_label_boys"] = e0
        out["stata_se_girls"] = se1
        out["stata_se_boys"] = se0

    if include_reversal and "xxrw3" in res.params.index:
        r0, rse0, rp0 = _nlcom_linear(res, "xxrw3")
        r1, rse1, rp1 = _nlcom_linear(res, "xxrw3", "xxrw3_x_h")
        out.update(
            {
                f"rev_{label0}": r0,
                f"rev_se_{label0}": rse0,
                f"rev_p_{label0}": rp0,
                f"rev_{label1}": r1,
                f"rev_se_{label1}": rse1,
                f"rev_p_{label1}": rp1,
                "rev_diff_p": float(res.pvalues.get("xxrw3_x_h", np.nan)),
            }
        )
    return out


def run_prespecified_subgroups(hh: pd.DataFrame) -> pd.DataFrame:
    """Gender (A3), urban, indig_head, MTEPS distance (Table 4)."""
    rows: list[dict] = []

    rows.append(
        estimate_binary_heterogeneity(
            hh,
            moderator="male",
            label0="girls",
            label1="boys",
            include_reversal=True,
            years=(2012, 2019),
        )
    )
    rows.append(
        estimate_binary_heterogeneity(
            hh,
            moderator="urban",
            label0="rural",
            label1="urban",
            include_reversal=True,
            years=(2012, 2019),
        )
    )
    rows.append(
        estimate_binary_heterogeneity(
            hh,
            moderator="indig_head",
            label0="nonindig_head",
            label1="indig_head",
            include_reversal=True,
            years=(2012, 2019),
        )
    )

    for mod in ("het_time", "het_dist"):
        r_all = estimate_binary_heterogeneity(
            hh,
            moderator=mod,
            label0="near",
            label1="far",
            include_reversal=False,
            years=(2012, 2016),
            drop_eligible=True,
        )
        rows.append(r_all)

        no_mteps = hh.loc[to_numeric(hh["mtepsoffices"]) == 0].copy()
        r_nm = estimate_binary_heterogeneity(
            no_mteps,
            moderator=mod,
            label0="near",
            label1="far",
            include_reversal=False,
            years=(2012, 2016),
            drop_eligible=True,
        )
        r_nm["sample"] = "no_mteps_offices"
        rows.append(r_nm)

    return pd.DataFrame(rows)


def write_subgroup_results(
    results: pd.DataFrame, out_dir: Path | None = None
) -> tuple[Path, Path]:
    out_dir = out_dir or (paths.FINAL / "tables")
    out_dir.mkdir(parents=True, exist_ok=True)
    long_path = out_dir / "subgroup_didisc.csv"
    results.to_csv(long_path, index=False)

    display_rows = []
    for _, r in results.iterrows():
        for lab in (r["label0"], r["label1"]):
            display_rows.append(
                {
                    "moderator": r["moderator"],
                    "sample": r.get("sample", "all"),
                    "years": r["years"],
                    "subgroup": lab,
                    "effect": r[f"effect_{lab}"],
                    "se": r[f"se_{lab}"],
                    "stars": r[f"stars_{lab}"],
                    "n": r["n"],
                    "mean_pre": r["mean_pre"],
                    "diff_p": r.get("diff_p"),
                }
            )
    disp = pd.DataFrame(display_rows)
    disp_path = out_dir / "subgroup_didisc_display.csv"
    disp.to_csv(disp_path, index=False)
    return long_path, disp_path
