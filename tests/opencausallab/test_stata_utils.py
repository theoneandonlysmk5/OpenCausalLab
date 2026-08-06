"""Unit tests for reusable opencausallab/ (no microdata)."""

from __future__ import annotations

import hashlib
from pathlib import Path

import numpy as np
import pandas as pd

from opencausallab.stata_semantics.stata_utils import stata_round, to_numeric, winsor_high
from opencausallab.utils.seeds import OPENCAUSAL_SEED
from opencausallab.validation.audit import SampleFlow, classify_count, classify_mean, weighted_mean


def test_stata_round_half_away_from_zero():
    x = np.array([2.5, -2.5, 252.5])
    assert stata_round(x).tolist() == [3.0, -3.0, 253.0]


def test_to_numeric_bool_object():
    s = pd.Series([True, False, None], dtype=object)
    out = to_numeric(s)
    assert out.tolist()[:2] == [1.0, 0.0]
    assert pd.isna(out.iloc[2])


def test_winsor_high():
    s = pd.Series([1.0, 2.0, 3.0, 100.0])
    out = winsor_high(s, p=0.25)
    assert out.max() <= s.quantile(0.75) + 1e-9


def test_weighted_mean():
    x = pd.Series([1.0, 3.0])
    w = pd.Series([1.0, 1.0])
    assert abs(weighted_mean(x, w) - 2.0) < 1e-12


def test_sample_flow_and_classifiers():
    df = pd.DataFrame({"folio": [1, 2, 3]})
    flow = SampleFlow(hh_col="folio")
    flow.log(df, "start")
    assert flow.rows[0]["n"] == 3
    assert classify_count(100, 100) == "match"
    assert classify_mean(0.15, 0.1501) == "match"


def test_opencausal_seed_stable():
    assert isinstance(OPENCAUSAL_SEED, int)


def test_sha256_file(tmp_path: Path):
    p = tmp_path / "x.txt"
    p.write_text("hello\n", encoding="utf-8")
    digest = hashlib.sha256(p.read_bytes()).hexdigest()
    assert len(digest) == 64
    # provenance helper if present
    try:
        from opencausallab.utils.provenance import sha256_file
    except ImportError:
        return
    assert sha256_file(p) == digest
