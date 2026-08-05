"""Replication confidence unit tests (Tier 3 validator)."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import pytest

from src import paths
from src.table3 import prepare_table3_sample, run_table3

HH = paths.FINAL / "HHsurvey.parquet"
VAL = paths.FINAL / "validation"
SAMPLES = paths.FINAL / "samples"

pytestmark = pytest.mark.skipif(not HH.exists(), reason="HHsurvey.parquet missing")


@pytest.fixture(scope="module")
def works_xxw3() -> dict:
    hh = pd.read_parquet(HH)
    sample = prepare_table3_sample(hh)
    res = run_table3(sample)
    row = res.loc[(res["outcome"] == "works") & (res["term"] == "xxw3")].iloc[0]
    return {
        "coef": float(row["coef"]),
        "se": float(row["se"]),
        "n": int(row["n"]),
        "mean_pre": float(row["mean_pre"]),
        "sample_n": len(sample),
        "hh_n": len(hh),
    }


def test_table3_any_work(works_xxw3: dict):
    """Tight check against unrounded Stata-equivalent estimate."""
    assert abs(works_xxw3["coef"] + 0.039351) < 1e-4
    assert works_xxw3["n"] == 11991
    assert abs(works_xxw3["mean_pre"] - 0.180) < 0.001


def test_esample_ne_full_panel(works_xxw3: dict):
    assert works_xxw3["hh_n"] != works_xxw3["sample_n"]
    assert works_xxw3["sample_n"] == 11991
    assert works_xxw3["hh_n"] > 100_000


def test_sample_exports_exist_after_verification():
    """Prefer committed verification run; skip if user has not exported yet."""
    p3 = SAMPLES / "sample_table3.parquet"
    p4 = SAMPLES / "sample_table4.parquet"
    if not p3.exists():
        pytest.skip("run scripts/run_verification.py to export e(sample) frames")
    assert len(pd.read_parquet(p3)) == 11991
    if p4.exists():
        assert len(pd.read_parquet(p4)) == 7650


def test_verification_artifacts_present():
    required = [
        "spec_equivalence_table3.csv",
        "merge_audit.csv",
        "esample_sizes.csv",
        "bandwidth_sensitivity_table3_works.csv",
        "table3_spec_coef_check.csv",
        "fe_weight_audit_table3.json",
        "variable_moments_table3_sample.csv",
    ]
    missing = [f for f in required if not (VAL / f).exists()]
    if missing:
        pytest.skip(
            "verification artifacts missing; run scripts/run_verification.py: "
            + ", ".join(missing)
        )
    bw = pd.read_csv(VAL / "bandwidth_sensitivity_table3_works.csv")
    row12 = bw.loc[bw["bandwidth"] == 12].iloc[0]
    assert abs(float(row12["xxw3"]) + 0.039351) < 1e-4


def test_spec_equivalence_all_match():
    path = VAL / "spec_equivalence_table3.csv"
    if not path.exists():
        pytest.skip("spec_equivalence_table3.csv missing")
    spec = pd.read_csv(path)
    assert spec["match"].astype(str).str.lower().isin(["true", "1"]).all()
