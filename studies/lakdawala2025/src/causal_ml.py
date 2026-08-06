"""
Local CATE exploration on top of the age-14 DiDisc design.

Pipeline (see studies/lakdawala2025/docs/Leah_replication_causal_ML_audit.md):
  1. Restrict to Table 3 local sample (triangular kernel > 0).
  2. Cross-fit residualize Y and T=xxw3 on nuisance design controls.
  3. Fit an honest causal forest on predetermined moderators only.
  4. Report local CATE summaries / subgroup means — never individual ITEs.

Treatment T is the DiDisc exposure ``xxw3 = post × 1{age<14}`` (week-before
recall), not a generic observational treatment.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from econml.grf import CausalForest
from sklearn.model_selection import KFold

from . import paths
from core.stata_semantics.stata_utils import to_numeric
from .table3 import CONTROLS, prepare_table3_sample

# Predetermined / design moderators for the forest (variable plan USE).
FOREST_FEATURES = [
    "male",
    "urban",
    "indig_head",
    "head_schooling",
    "head_age",
    "head_male",
    "het_time",
    "het_dist",
    "mtepsoffices",
]

# Nuisance controls for residualization: Table 3 RHS without xxw3.
NUISANCE = [c for c in CONTROLS if c != "xxw3"]


def build_analysis_frame(hh: pd.DataFrame) -> pd.DataFrame:
    """Table 3 local sample plus forest moderators."""
    sample = prepare_table3_sample(hh)
    # prepare resets index; rebuild from hh with same filter to keep extras.
    year = to_numeric(hh["year"])
    base = hh.loc[(year >= 2012) & (year <= 2019)].copy()
    for c in set(CONTROLS + FOREST_FEATURES + ["works", "kernel_triw14", "pre", "xxw3"]):
        if c in base.columns:
            base[c] = to_numeric(base[c])
    base["depto"] = to_numeric(base["depto"])
    base["year"] = to_numeric(base["year"]).astype(int)
    w = base["kernel_triw14"].fillna(0.0)
    base = base.loc[w > 0].copy()
    base["depto_year"] = (
        base["depto"].astype(int).astype(str) + "_" + base["year"].astype(int).astype(str)
    )
    need = (
        ["works", "xxw3", "kernel_triw14", "age_mo_year", "depto_year", "pre"]
        + CONTROLS
        + [c for c in FOREST_FEATURES if c in base.columns]
    )
    # Distance moderators missing for 2017–2019 — keep rows, forest will dropna.
    core = ["works", "xxw3", "kernel_triw14", "age_mo_year", "depto_year", "pre"] + CONTROLS
    base = base.dropna(subset=core).reset_index(drop=True)
    assert len(base) == len(sample) or abs(len(base) - len(sample)) <= 2
    return base


def _design_matrix(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    parts = []
    use = [c for c in cols if c in df.columns]
    X = df[use].astype(float)
    # departamento × year FE
    fe = pd.get_dummies(df["depto_year"], prefix="dy", drop_first=True, dtype=float)
    return pd.concat([X, fe], axis=1)


def crossfit_didisc_score(
    df: pd.DataFrame,
    *,
    outcome: str = "works",
    treatment: str = "xxw3",
    n_splits: int = 5,
    random_state: int = 42,
) -> pd.DataFrame:
    """
    Cross-fitted residualization of Y and T on nuisance controls + FE.

    Returns a copy with columns ``y_resid``, ``t_resid``, ``fold``.
    """
    out = df.copy().reset_index(drop=True)
    Z = _design_matrix(out, NUISANCE)
    y = out[outcome].to_numpy(dtype=float)
    t = out[treatment].to_numpy(dtype=float)
    w = out["kernel_triw14"].to_numpy(dtype=float)

    y_hat = np.zeros(len(out))
    t_hat = np.zeros(len(out))
    folds = np.zeros(len(out), dtype=int)

    kf = KFold(n_splits=n_splits, shuffle=True, random_state=random_state)
    for fold_id, (tr, te) in enumerate(kf.split(out)):
        folds[te] = fold_id
        Z_tr, Z_te = Z.iloc[tr], Z.iloc[te]
        # Weighted least squares via sqrt-weights (same as WLS).
        sw = np.sqrt(w[tr])
        Zw = Z_tr.to_numpy() * sw[:, None]
        # Add intercept
        Zw = np.column_stack([np.ones(len(tr)), Zw])
        Zte = np.column_stack([np.ones(len(te)), Z_te.to_numpy()])
        for target, store in ((y, y_hat), (t, t_hat)):
            yw = target[tr] * sw
            beta, *_ = np.linalg.lstsq(Zw, yw, rcond=None)
            store[te] = Zte @ beta

    out["y_resid"] = y - y_hat
    out["t_resid"] = t - t_hat
    out["fold"] = folds
    return out


def fit_honest_causal_forest(
    scored: pd.DataFrame,
    *,
    features: list[str] | None = None,
    random_state: int = 42,
    n_estimators: int = 500,
) -> tuple[CausalForest, pd.DataFrame, np.ndarray]:
    """
    Honest GRF of residualized Y on residualized T, X = predetermined moderators.

    Drops rows with missing forest features (e.g. distance after 2016).
    """
    features = features or [f for f in FOREST_FEATURES if f in scored.columns]
    use = scored.dropna(subset=features + ["y_resid", "t_resid", "kernel_triw14"]).copy()
    X = use[features].to_numpy(dtype=float)
    T = use["t_resid"].to_numpy(dtype=float).reshape(-1, 1)
    Y = use["y_resid"].to_numpy(dtype=float)
    w = use["kernel_triw14"].to_numpy(dtype=float)

    forest = CausalForest(
        n_estimators=n_estimators,
        honest=True,
        inference=True,
        min_samples_leaf=40,
        max_depth=6,
        random_state=random_state,
        n_jobs=-1,
    )
    forest.fit(X, T, Y, sample_weight=w)
    tau = forest.predict(X).reshape(-1)
    use = use.copy()
    use["cate"] = tau
    return forest, use, np.array(features, dtype=object)


def cate_summary(use: pd.DataFrame, features: list[str]) -> pd.DataFrame:
    """Aggregate local CATEs — never row-level ITEs for reporting."""
    rows = [
        {
            "stat": "mean_cate",
            "value": float(np.average(use["cate"], weights=use["kernel_triw14"])),
            "n": len(use),
        },
        {
            "stat": "std_cate",
            "value": float(use["cate"].std()),
            "n": len(use),
        },
        {
            "stat": "p10_cate",
            "value": float(use["cate"].quantile(0.10)),
            "n": len(use),
        },
        {
            "stat": "p90_cate",
            "value": float(use["cate"].quantile(0.90)),
            "n": len(use),
        },
    ]
    for f in features:
        if use[f].nunique(dropna=True) <= 4:
            for val, g in use.groupby(f):
                rows.append(
                    {
                        "stat": f"mean_cate|{f}={val}",
                        "value": float(
                            np.average(g["cate"], weights=g["kernel_triw14"])
                        ),
                        "n": len(g),
                    }
                )
    return pd.DataFrame(rows)


def holdout_validate_subgroups(
    use: pd.DataFrame,
    *,
    feature: str = "het_time",
    holdout_fold: int = 0,
) -> pd.DataFrame:
    """
    Compare forest subgroup CATE means to a simple holdout WLS interaction
    on residualized outcome (transparency check).
    """
    import statsmodels.formula.api as smf

    hold = use.loc[use["fold"] == holdout_fold].copy()
    train = use.loc[use["fold"] != holdout_fold].copy()
    if hold.empty or feature not in use.columns:
        return pd.DataFrame()

    # Forest means on holdout
    rows = []
    for val, g in hold.groupby(feature):
        rows.append(
            {
                "source": "forest_holdout",
                "subgroup": f"{feature}={val}",
                "estimate": float(np.average(g["cate"], weights=g["kernel_triw14"])),
                "n": len(g),
            }
        )

    # Linear interaction on train residuals, evaluate contrast
    hold[feature] = to_numeric(hold[feature])
    train[feature] = to_numeric(train[feature])
    # On full scored sample for a clean contrast SE: y_resid ~ t_resid * h
    df = use.dropna(subset=[feature, "y_resid", "t_resid"]).copy()
    df["t_x_h"] = df["t_resid"] * df[feature]
    m = smf.wls(
        "y_resid ~ t_resid + t_x_h + C(depto_year)",
        data=df,
        weights=df["kernel_triw14"],
    ).fit(cov_type="cluster", cov_kwds={"groups": df["age_mo_year"]})
    # effect h=0: t_resid; h=1: t_resid + t_x_h
    b0 = float(m.params["t_resid"])
    b1 = float(m.params["t_resid"] + m.params["t_x_h"])
    rows.append(
        {
            "source": "wls_interaction",
            "subgroup": f"{feature}=0",
            "estimate": b0,
            "n": int((df[feature] == 0).sum()),
        }
    )
    rows.append(
        {
            "source": "wls_interaction",
            "subgroup": f"{feature}=1",
            "estimate": b1,
            "n": int((df[feature] == 1).sum()),
        }
    )
    return pd.DataFrame(rows)


def run_causal_ml(hh: pd.DataFrame, *, random_state: int = 42) -> dict:
    frame = build_analysis_frame(hh)
    scored = crossfit_didisc_score(frame, random_state=random_state)
    forest, used, feats = fit_honest_causal_forest(scored, random_state=random_state)
    summary = cate_summary(used, list(feats))
    # Prefer distance holdout when available
    feat = "het_time" if used["het_time"].notna().mean() > 0.5 else "male"
    validation = holdout_validate_subgroups(used, feature=feat)
    fi = pd.DataFrame(
        {"feature": list(feats), "importance": forest.feature_importances_}
    ).sort_values("importance", ascending=False)
    return {
        "scored": scored,
        "used": used,
        "summary": summary,
        "validation": validation,
        "feature_importance": fi,
        "forest": forest,
        "features": list(feats),
    }


def write_causal_ml_outputs(result: dict, out_dir: Path | None = None) -> dict[str, Path]:
    out_dir = out_dir or (paths.FINAL / "tables")
    out_dir.mkdir(parents=True, exist_ok=True)
    paths_out = {}
    for key, name in (
        ("summary", "cate_summary.csv"),
        ("validation", "cate_holdout_validation.csv"),
        ("feature_importance", "cate_feature_importance.csv"),
    ):
        p = out_dir / name
        result[key].to_csv(p, index=False)
        paths_out[key] = p
    # Store CATE aggregates only (no individual ITE file by design)
    note = out_dir / "CATE_README.txt"
    note.write_text(
        "OpenCausalLab causal-ML outputs report local CATE summaries and "
        "subgroup means only. Individual treatment effects are not identified "
        "and are not written to disk.\n",
        encoding="utf-8",
    )
    paths_out["readme"] = note
    return paths_out
