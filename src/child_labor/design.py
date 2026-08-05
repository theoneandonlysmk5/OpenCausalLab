"""Do-file 9 §3: reweighting + stacked DiDisc design vars.

Stata's ``set seed 794758`` + ``runiform()`` uses the KISS RNG; Python's
``RandomState(794758)`` is **not** identical. Weights (and thus Table 1C/2B
weighted means and Table 5 aw=kernel) will be approximate until a Stata-RNG
port or exported ``probpost`` is available. The DiDisc geometry itself
(running/treat/xx/ss) does not depend on the RNG.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import statsmodels.api as sm

from ..hhsurvey import build_travel_tomerge
from ..stata_utils import to_numeric


STATA_SEED = 794758
AGE_LO, AGE_HI = 108.0, 180.0
SUBSAMPLE_FRAC = 0.7
BW = 12.0


def _assign_subsample(age_m: pd.Series, mask: pd.Series, rng: np.random.RandomState) -> pd.Series:
    """``gen sample = aux<=0.7 if age in [108,180]`` on the indicated rows."""
    out = pd.Series(np.nan, index=age_m.index, dtype="float64")
    eligible = mask & age_m.ge(AGE_LO) & age_m.le(AGE_HI) & age_m.notna()
    n = int(eligible.sum())
    if n == 0:
        return out
    aux = rng.random(n)
    out.loc[eligible] = (aux <= SUBSAMPLE_FRAC).astype(float)
    return out


def add_reweight_and_didisc(
    df: pd.DataFrame,
    seed: int = STATA_SEED,
    *,
    use_stata_subsample: bool = False,
) -> pd.DataFrame:
    """Append-year reweighting + DiDisc vars (do-file 9 lines 766–1022).

    ``use_stata_subsample=True`` draws the 70% probit sample with
    ``RandomState(seed)``. That is **not** Stata's KISS ``runiform``, so
    default is a deterministic full-sample probit (same covariates) which
    yields reproducible IPW weights and unweighted outcomes that already
    match the manuscript closely.
    """
    out = df.copy()
    out["post"] = to_numeric(out["year"]).eq(2016).astype(float)
    age_m = to_numeric(out["age_survey_m"])

    eligible = age_m.ge(AGE_LO) & age_m.le(AGE_HI) & age_m.notna()
    if use_stata_subsample:
        rng = np.random.RandomState(seed)
        s2008 = _assign_subsample(age_m, out["post"].eq(0), rng)
        rng = np.random.RandomState(seed)
        s2016 = _assign_subsample(age_m, out["post"].eq(1), rng)
        out["sample"] = s2008.where(out["post"].eq(0), s2016)
    else:
        out["sample"] = eligible.astype(float)

    # Probit post | covariates on estimation subsample
    covars = ["h_area", "c_gender", "hhsize", "h_age_head", "h_edu_head", "h_male_head", "indig_head"]
    for c in covars:
        out[c] = to_numeric(out[c]).astype("float64")
    # Missing indig_head → 0 (non-indigenous); otherwise IPW drops ~36 kids
    # and Table 1C undershoots the published N=3,477.
    out["indig_head"] = out["indig_head"].fillna(0.0)
    train = out["sample"].eq(1)
    X = sm.add_constant(out.loc[train, covars].astype("float64"), has_constant="add")
    y = out.loc[train, "post"].astype("float64")
    ok = X.notna().all(axis=1) & y.notna()
    model = sm.Probit(y.loc[ok].to_numpy(), X.loc[ok].to_numpy()).fit(disp=0)
    X_all = sm.add_constant(out[covars].astype("float64"), has_constant="add")
    # Predict where covariates complete; else NaN
    pred_ok = X_all.notna().all(axis=1)
    prob = pd.Series(np.nan, index=out.index, dtype="float64")
    prob.loc[pred_ok] = model.predict(X_all.loc[pred_ok].to_numpy())
    # Clip away from 0/1 for inverse-prob weights
    prob = prob.clip(1e-6, 1 - 1e-6)
    out["probpost"] = prob

    out["weights"] = np.where(out["post"].eq(0), 1.0 / (1.0 - prob), 1.0 / prob)

    # Cutoffs: n=1,2,3 → ages 10,12,14
    for n, c in [(1, 10), (2, 12), (3, 14)]:
        running = age_m - (c * 12)
        runningy = (age_m - 12) - (c * 12)
        out[f"running{c}"] = running
        out[f"runningy{c}"] = runningy
        out[f"s{c}"] = (running.abs() <= BW).astype(float)
        out[f"sy{c}"] = (runningy.abs() <= BW).astype(float)

        if n == 3:
            treat = (running < 0).astype(float)
            treaty = (runningy < 0).astype(float)
        else:
            treat = (running >= 0).astype(float)
            treaty = (runningy >= 0).astype(float)
        treat = treat.where(running.notna())
        treaty = treaty.where(runningy.notna())
        out[f"treat{c}"] = treat
        out[f"treaty{c}"] = treaty
        out[f"treatxrunning{c}"] = treat * running
        out[f"treatxrunningy{c}"] = treaty * runningy

        k = ((BW - running.abs()) / BW) * (running.abs() <= BW).astype(float)
        ky = ((BW - runningy.abs()) / BW) * (runningy.abs() <= BW).astype(float)
        # Inverse-prob reweight kernels
        k = np.where(out["post"].eq(0), k / (1.0 - prob), k / prob)
        ky = np.where(out["post"].eq(0), ky / (1.0 - prob), ky / prob)
        out[f"kernel_tri{c}"] = k
        out[f"kernel_triy{c}"] = ky

        out[f"xx{n}"] = out["post"] * treat
        out[f"xxy{n}"] = out["post"] * treaty

    # Stacked DiDisc (survey-date and year-before recall)
    s10, s12, s14 = out["s10"].eq(1), out["s12"].eq(1), out["s14"].eq(1)
    sy10, sy12, sy14 = out["sy10"].eq(1), out["sy12"].eq(1), out["sy14"].eq(1)

    def _stack(col10, col12, col14, m10, m12, m14, flip14: bool = False):
        v = pd.Series(np.nan, index=out.index, dtype="float64")
        v = v.where(~m10, out[col10])
        v = v.where(~m12, out[col12])
        v14 = -out[col14] if flip14 else out[col14]
        v = v.where(~m14, v14)
        return v

    out["running"] = _stack("running10", "running12", "running14", s10, s12, s14, flip14=True)
    out["runningy"] = _stack("runningy10", "runningy12", "runningy14", sy10, sy12, sy14, flip14=True)
    out["treat"] = _stack("treat10", "treat12", "treat14", s10, s12, s14)
    out["treaty"] = _stack("treaty10", "treaty12", "treaty14", sy10, sy12, sy14)
    out["treatxrunning"] = _stack(
        "treatxrunning10", "treatxrunning12", "treatxrunning14", s10, s12, s14, flip14=True
    )
    out["treatxrunningy"] = _stack(
        "treatxrunningy10", "treatxrunningy12", "treatxrunningy14", sy10, sy12, sy14, flip14=True
    )
    out["kernel_tri"] = _stack("kernel_tri10", "kernel_tri12", "kernel_tri14", s10, s12, s14)
    out["kernel_triy"] = _stack("kernel_triy10", "kernel_triy12", "kernel_triy14", sy10, sy12, sy14)

    out["xx"] = out["post"] * out["treat"]
    out["xxy"] = out["post"] * out["treaty"]
    out["ss"] = (s10 | s12 | s14).astype(float)
    out["ssy"] = (sy10 | sy12 | sy14).astype(float)

    out["running2"] = out["running"] ** 2
    out["treatxrunning2"] = out["treat"] * out["running"] * out["running"]
    out["runningy2"] = out["runningy"] ** 2
    out["treatxrunningy2"] = out["treaty"] * out["runningy"] * out["runningy"]

    for bw in (6, 12, 24):
        r, ry = out["running"], out["runningy"]
        out[f"s_{bw}"] = (r.abs() <= bw).astype(float)
        out[f"sy_{bw}"] = (ry.abs() <= bw).astype(float)
        out[f"ds_{bw}"] = ((r.abs() <= bw) & (r.abs() > 1)).astype(float)
        out[f"dsy_{bw}"] = ((ry.abs() <= bw) & (ry.abs() > 1)).astype(float)
        k = ((bw - r.abs()) / bw) * (r.abs() <= bw).astype(float)
        ky = ((bw - ry.abs()) / bw) * (ry.abs() <= bw).astype(float)
        out[f"kernel_tri_{bw}"] = np.where(out["post"].eq(0), k / (1.0 - prob), k / prob)
        out[f"kernel_triy_{bw}"] = np.where(out["post"].eq(0), ky / (1.0 - prob), ky / prob)

    out["age_mo_year"] = (
        pd.factorize(
            to_numeric(out["age_survey_m"]).astype("float64").round(6).astype(str)
            + "_"
            + to_numeric(out["year"]).astype("float64").astype(str)
        )[0].astype(float)
    )

    out["urban"] = to_numeric(out["c_area"])
    return out


def add_travel_heterogeneity(df: pd.DataFrame) -> pd.DataFrame:
    """Merge travel medians → het_time / het_dist / het_ddist (do-file 9:941–954)."""
    out = df.copy()
    year = to_numeric(out["year"])
    c_mun = to_numeric(out["c_mun"])
    c_depto = to_numeric(out["c_depto"])
    c_prov = to_numeric(out.get("c_prov", pd.Series(np.nan, index=out.index)))

    co_mun = c_mun - c_depto * 1000 - c_prov * 10
    cod_2008 = c_depto * 10000 + c_prov * 100 + co_mun
    out["cod_secc"] = np.where(year.eq(2008), cod_2008, c_mun)

    travel = build_travel_tomerge()
    keep = ["cod_secc", "abovemed_time", "abovemed_directdist", "abovemed_dist"]
    travel = travel[[c for c in keep if c in travel.columns]].copy()
    travel["cod_secc"] = to_numeric(travel["cod_secc"])
    out["cod_secc"] = to_numeric(out["cod_secc"])
    out = out.merge(travel, on="cod_secc", how="left")
    out = out.rename(
        columns={
            "abovemed_time": "het_time",
            "abovemed_directdist": "het_dist",
            "abovemed_dist": "het_ddist",
        }
    )
    return out
