"""Table 3 DiDisc replication checks against published manuscript numbers."""

from __future__ import annotations

import pandas as pd
import pytest

from src import paths
from src.table3 import (
    PUBLISHED_TABLE3,
    compare_to_published,
    prepare_table3_sample,
    run_table3,
)

HH_PATH = paths.FINAL / "HHsurvey.parquet"

pytestmark = pytest.mark.skipif(
    not HH_PATH.exists(),
    reason="HHsurvey.parquet not built yet",
)


@pytest.fixture(scope="module")
def results() -> pd.DataFrame:
    hh = pd.read_parquet(HH_PATH)
    sample = prepare_table3_sample(hh)
    return run_table3(sample)


def test_sample_size_near_paper(results: pd.DataFrame):
    n = int(results["n"].iloc[0])
    assert abs(n - 11991) <= 2


def test_pre_mean_works(results: pd.DataFrame):
    mean = float(results.loc[results["outcome"] == "works", "mean_pre"].iloc[0])
    assert mean == pytest.approx(0.180, abs=0.002)


def test_xxw3_near_published(results: pd.DataFrame):
    """Printed manuscript precision (and unrounded works anchor)."""
    cmp = compare_to_published(results)
    for _, row in cmp.loc[cmp["term"] == "xxw3"].iterrows():
        # Printed cells round to three decimals; raw gap must stay tiny.
        tol = 0.001 if row["outcome"] != "hours_week_a" else 0.002
        assert abs(row["delta_coef"]) <= tol, row.to_dict()
        assert abs(row["delta_se"]) <= 0.002, row.to_dict()


def test_table3_any_work_unrounded(results: pd.DataFrame):
    coef = float(
        results.loc[
            (results["outcome"] == "works") & (results["term"] == "xxw3"), "coef"
        ].iloc[0]
    )
    assert abs(coef + 0.039351) < 1e-4


def test_sign_and_significance_works(results: pd.DataFrame):
    row = results.loc[
        (results["outcome"] == "works") & (results["term"] == "xxw3")
    ].iloc[0]
    assert row["coef"] < 0
    assert row["pvalue"] < 0.10
    # Reversal term near zero (paper ≈ 0).
    rev = results.loc[
        (results["outcome"] == "works") & (results["term"] == "xxrw3")
    ].iloc[0]
    assert abs(rev["coef"]) < 0.03


def test_published_keys_cover_yvars():
    assert set(PUBLISHED_TABLE3) >= {
        "works",
        "hours_week_a",
        "not_forbidden_a",
        "lf_participation",
    }
