"""Unit tests for Persona 2012 logic (no full survey file required)."""

from __future__ import annotations

import numpy as np
import pandas as pd

from core.stata_semantics.stata_utils import inlist, inrange, replace_where, stata_str, to_numeric


def test_stata_str_integers():
    s = pd.Series([1, 2, 10, np.nan])
    out = stata_str(s)
    assert out.tolist()[:3] == ["1", "2", "10"]
    assert pd.isna(out.iloc[3])


def test_inrange_inlist():
    s = pd.Series([1, 3, 7, None])
    assert inrange(s, 1, 6).tolist() == [True, True, False, False]
    assert inlist(s, [1, 7]).tolist() == [True, False, True, False]


def test_work_definition_order():
    """Mirror EH_Persona_2012 work construction on a tiny frame."""
    df = pd.DataFrame(
        {
            "s5_01": [1, 2, 2, 2],
            "s5_02": [7, 3, 7, 7],
            "s5_03": [8, 8, 5, 8],
            "s5_05": [2, 2, 2, 1],
            "s5_15": [6, 6, 6, 2],
            "pet": [1, 1, 1, 1],
        }
    )
    work = pd.Series(np.nan, index=df.index, dtype="float64")
    work = replace_where(work, 1.0, to_numeric(df["s5_01"]).eq(1))
    work = replace_where(work, 1.0, inrange(df["s5_02"], 1, 6))
    work = replace_where(work, 1.0, inrange(df["s5_03"], 1, 6))
    work = replace_where(
        work,
        0.0,
        to_numeric(df["pet"]).eq(1)
        & (to_numeric(df["s5_05"]).eq(1) | to_numeric(df["s5_15"]).eq(1)),
    )
    assert work.tolist() == [1.0, 1.0, 1.0, 0.0]


def test_persona_all_years_if_raw_present():
    from pathlib import Path

    from src.household import harmonize_persona

    expected = {
        2012: 31935,
        2013: 35693,
        2014: 36618,
        2015: 37364,
        2016: 38549,
        2017: 38201,
        2018: 37517,
        2019: 39605,
    }
    for year, n in expected.items():
        raw_dir = Path("data/raw/household") / str(year)
        if not raw_dir.exists():
            continue
        df = harmonize_persona(year)
        assert len(df) == n
        assert df["id"].is_unique
        assert "work" in df.columns and "age" in df.columns

