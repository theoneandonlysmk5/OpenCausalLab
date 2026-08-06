"""Tests for Stata-compatible rounding (age-in-months)."""

import numpy as np
import pandas as pd

from opencausallab.stata_semantics.stata_utils import stata_round


def test_stata_round_half_away_from_zero():
    x = np.array([2.5, 3.5, -2.5, 0.5, 1.5, 252.5])
    got = stata_round(x)
    assert got.tolist() == [3.0, 4.0, -3.0, 1.0, 2.0, 253.0]


def test_stata_round_differs_from_numpy_bankers():
    # np.round uses bankers; Stata does not
    assert float(np.round(2.5)) == 2.0
    assert float(stata_round(np.array([2.5]))[0]) == 3.0


def test_stata_round_series_preserves_index():
    s = pd.Series([2.5, 3.0], index=["a", "b"])
    out = stata_round(s)
    assert list(out.index) == ["a", "b"]
    assert out.tolist() == [3.0, 3.0]
