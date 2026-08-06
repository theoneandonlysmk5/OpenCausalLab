"""Subgroup DiDisc and causal-ML smoke / manuscript checks."""

from __future__ import annotations

import pandas as pd
import pytest

from src import paths
from opencausallab.stata_semantics.stata_utils import to_numeric
from src.subgroup import PUBLISHED_GENDER, run_prespecified_subgroups

HH_PATH = paths.FINAL / "HHsurvey.parquet"

pytestmark = [
    pytest.mark.microdata,
    pytest.mark.skipif(not HH_PATH.exists(), reason="HHsurvey missing"),
]


def test_to_numeric_bool():
    s = pd.Series([True, False, None])
    out = to_numeric(s)
    assert out.tolist()[0] == 1.0
    assert out.tolist()[1] == 0.0
    assert pd.isna(out.tolist()[2])


@pytest.fixture(scope="module")
def hh() -> pd.DataFrame:
    return pd.read_parquet(HH_PATH)


def test_het_interactions_nonmissing(hh: pd.DataFrame):
    m = hh["het_time"].notna()
    assert m.mean() > 0.5
    assert hh.loc[m, "xxwhet_time3"].notna().mean() > 0.99


def test_gender_near_paper(hh: pd.DataFrame):
    res = run_prespecified_subgroups(hh)
    g = res.loc[res["moderator"] == "male"].iloc[0]
    # Compare using Stata's nlcom label mapping (swapped vs male=0/1).
    assert abs(g["stata_label_girls"] - PUBLISHED_GENDER["girls"]) < 0.02
    assert abs(g["stata_label_boys"] - PUBLISHED_GENDER["boys"]) < 0.02
    assert abs(g["n"] - PUBLISHED_GENDER["n"]) <= 2


def test_distance_signs(hh: pd.DataFrame):
    res = run_prespecified_subgroups(hh)
    d = res.loc[(res["moderator"] == "het_time") & (res["sample"] == "all")].iloc[0]
    # Near more negative than far (paper pattern)
    assert d["effect_near"] < d["effect_far"]
    assert abs(d["n"] - 7650) < 50


@pytest.mark.causal_ml
def test_causal_ml_runs(hh: pd.DataFrame):
    pytest.importorskip("econml")
    from src.causal_ml import (
        build_analysis_frame,
        cate_summary,
        crossfit_didisc_score,
        fit_honest_causal_forest,
    )

    frame = build_analysis_frame(hh)
    scored = crossfit_didisc_score(frame, n_splits=3, random_state=0)
    assert "y_resid" in scored and scored["y_resid"].notna().all()
    forest, used, feats = fit_honest_causal_forest(
        scored,
        features=["male", "urban", "indig_head", "head_schooling", "head_male"],
        n_estimators=52,
        random_state=0,
    )
    summary = cate_summary(used, list(feats))
    assert forest is not None
    assert "cate" in used.columns
    assert summary.loc[summary["stat"] == "mean_cate", "value"].iloc[0] < 0.05
    assert used["cate"].notna().all()
