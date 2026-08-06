"""Tests for Income harmonization (2012–2017)."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import pytest

pytest.importorskip("pyreadstat")

from src.income import harmonize_income
from src.persona.common import read_persona

pytestmark = pytest.mark.microdata


def _persona_rows(year: int) -> int:
    return len(read_persona(year))


def test_income_row_counts_match_persona():
    for year in range(2012, 2018):
        df = harmonize_income(year)
        expected = _persona_rows(year)
        assert len(df) == expected, f"{year}: income {len(df)} != persona {expected}"


def test_income_id_unique_within_year():
    for year in range(2012, 2018):
        df = harmonize_income(year)
        assert df["id"].is_unique, f"{year}: duplicate ids"


def test_income_cleaned_outputs_if_present():
    cleaned = Path("data/intermediate/income/EH_cleaned_income.parquet")
    compiled = Path("data/intermediate/income/EH_compiled_income.parquet")
    if not cleaned.exists() or not compiled.exists():
        return

    comp = pd.read_parquet(compiled)
    clean = pd.read_parquet(cleaned)

    assert len(clean) == len(comp)
    assert "y_household" in clean.columns
    assert "y_household_w" in clean.columns
    assert clean.groupby("year")["id"].apply(lambda s: s.is_unique).all()
