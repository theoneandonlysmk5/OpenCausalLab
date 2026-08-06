"""Shared WLS DiDisc helper used by main tables."""

from __future__ import annotations

from typing import Iterable

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from scipy import stats

from .stata_utils import to_numeric


def stars(p: float) -> str:
    if p < 0.01:
        return "***"
    if p < 0.05:
        return "**"
    if p < 0.10:
        return "*"
    return ""


def depto_year(df: pd.DataFrame, depto: str = "depto", year: str = "year") -> pd.Series:
    return (
        to_numeric(df[depto]).astype(int).astype(str)
        + "_"
        + to_numeric(df[year]).astype(int).astype(str)
    )


def wls_cluster(
    formula: str,
    df: pd.DataFrame,
    *,
    weight: str,
    cluster: str = "age_mo_year",
):
    model = smf.wls(formula, data=df, weights=to_numeric(df[weight]))
    return model.fit(
        cov_type="cluster",
        cov_kwds={"groups": df[cluster]},
    )


def nlcom_sum(res, a: str, b: str | None = None) -> tuple[float, float, float]:
    """Estimate a or a+b with delta-method SE."""
    cov = res.cov_params()
    if b is None:
        est = float(res.params[a])
        se = float(np.sqrt(cov.loc[a, a]))
    else:
        est = float(res.params[a] + res.params[b])
        var = cov.loc[a, a] + cov.loc[b, b] + 2.0 * cov.loc[a, b]
        se = float(np.sqrt(max(var, 0.0)))
    df_r = getattr(res, "df_resid", np.inf)
    t = est / se if se > 0 else np.nan
    p = float(2 * stats.t.sf(abs(t), df_r)) if np.isfinite(t) else np.nan
    return est, se, p


def prepare_kernel_sample(
    hh: pd.DataFrame,
    *,
    years: tuple[int, int] = (2012, 2019),
    kernel: str = "kernel_triw14",
    extra: Iterable[str] = (),
    require: Iterable[str] = (),
) -> pd.DataFrame:
    """Keep years + kernel>0 + complete required columns."""
    df = hh.copy()
    y = to_numeric(df["year"])
    df = df.loc[(y >= years[0]) & (y <= years[1])].copy()
    df[kernel] = to_numeric(df[kernel])
    df = df.loc[df[kernel].fillna(0) > 0].copy()
    df["depto"] = to_numeric(df["depto"])
    df["year"] = to_numeric(df["year"]).astype(int)
    df["depto_year"] = depto_year(df)
    cols = list(dict.fromkeys(list(require) + list(extra) + [kernel, "age_mo_year", "depto_year", "pre"]))
    for c in cols:
        if c in df.columns and c not in {"depto_year", "age_mo_year"}:
            df[c] = to_numeric(df[c])
    need = [c for c in cols if c in df.columns]
    return df.dropna(subset=need).reset_index(drop=True)


# Standard Table-3-like RHS pieces
RD_W14 = ["treatw14", "runningw14", "treatxrunningw14"]
PERIOD = ["post", "post_rev"]
DEMO = [
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


def didisc_formula(
    y: str,
    *,
    include_reversal: bool = True,
    include_urban: bool = True,
    include_eligible: bool = True,
    extra_terms: Iterable[str] = (),
) -> str:
    terms = ["xxw3"]
    if include_reversal:
        terms.append("xxrw3")
    terms += list(RD_W14)
    terms += ["post"]
    if include_reversal:
        terms.append("post_rev")
    for c in DEMO:
        if c == "urban" and not include_urban:
            continue
        if c == "eligible_gr" and not include_eligible:
            continue
        terms.append(c)
    terms += list(extra_terms)
    terms.append("C(depto_year)")
    # unique preserve order
    seen = set()
    rhs = []
    for t in terms:
        if t not in seen:
            seen.add(t)
            rhs.append(t)
    return f"{y} ~ " + " + ".join(rhs)
