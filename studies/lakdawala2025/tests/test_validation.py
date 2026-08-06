"""Golden / sample-flow validation tests."""

from __future__ import annotations

import math

import pandas as pd
import pytest

from src import paths
from core.validation.audit import GOLDEN
from src.validation.table3_audit import (
    build_table3_ledger,
    table3_sample_flow,
    table3_sample_diagnostics,
)

HH = paths.FINAL / "HHsurvey.parquet"
pytestmark = pytest.mark.skipif(not HH.exists(), reason="HHsurvey missing")


@pytest.fixture(scope="module")
def hh():
    return pd.read_parquet(HH)


def test_sample_flow_ends_near_paper_n(hh):
    flow = table3_sample_flow(hh)
    final_n = int(flow.iloc[-1]["n"])
    assert abs(final_n - GOLDEN["table3_n"]) <= 5


def test_table3_n_before_coefficients(hh):
    diag = table3_sample_diagnostics(hh)
    assert abs(diag["n"] - GOLDEN["table3_n"]) <= 5
    assert math.isclose(diag["mean_works_pre"], GOLDEN["table3_mean_works"], abs_tol=0.002)


def test_ledger_has_no_sign_flip_on_main_coef(hh):
    ledger, _ = build_table3_ledger(hh)
    row = ledger.loc[ledger["result"] == "Table3 works xxw3 coef"].iloc[0]
    assert float(row["python"]) < 0
    assert float(row["paper"]) < 0
    assert abs(float(row["python"]) - float(row["paper"])) < 0.01


def test_n_is_priority_status(hh):
    ledger, _ = build_table3_ledger(hh)
    n_row = ledger.loc[ledger["result"] == "Table3 estimation N"].iloc[0]
    assert n_row["status"] in {"match", "near"}
