"""Tests for main Tables 1–6 HHsurvey replications vs manuscript."""

from __future__ import annotations

import pandas as pd
import pytest

from src import paths
from src.main_tables import build_main_tables_ledger

HH = paths.FINAL / "HHsurvey.parquet"
pytestmark = [
    pytest.mark.microdata,
    pytest.mark.skipif(not HH.exists(), reason="HHsurvey missing"),
]


@pytest.fixture(scope="module")
def ledger():
    hh = pd.read_parquet(HH)
    led, _ = build_main_tables_ledger(hh)
    return led


def test_no_open_rows(ledger: pd.DataFrame):
    open_rows = ledger.loc[ledger["status"] == "open"]
    assert open_rows.empty, open_rows.to_dict("records")


def test_table1_3_6_counts_match(ledger: pd.DataFrame):
    for res in ["Table1 n", "Table3 N", "Table6 location_out_fixed_a N"]:
        row = ledger.loc[ledger["result"] == res].iloc[0]
        assert row["status"] == "match", row.to_dict()


def test_table3_main_coef_match(ledger: pd.DataFrame):
    row = ledger.loc[ledger["result"] == "Table3 works xxw3"].iloc[0]
    assert row["status"] == "match"
    assert abs(row["python"] - (-0.039)) < 0.001
