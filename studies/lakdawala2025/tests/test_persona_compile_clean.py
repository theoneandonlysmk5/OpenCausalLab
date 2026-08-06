"""Tests for Persona compile + clean."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import pytest

pytestmark = pytest.mark.microdata


def test_compile_clean_outputs_if_present():
    cleaned = Path("data/intermediate/persona/EH_cleaned_persona.parquet")
    compiled = Path("data/intermediate/persona/EH_compiled_persona.parquet")
    if not cleaned.exists() or not compiled.exists():
        return

    comp = pd.read_parquet(compiled)
    clean = pd.read_parquet(cleaned)

    assert len(comp) == 295482
    assert len(clean) == len(comp)
    assert set(range(2012, 2020)).issubset(set(clean["year"].dropna().astype(int)))
    assert clean["id"].notna().all()
    assert "works" in clean.columns and "employed" in clean.columns
    # works fills zeros for age>=7; should be denser than employed
    assert clean.loc[clean["age"] >= 7, "works"].notna().mean() > 0.99
    assert clean["male"].between(0, 1).mean() > 0.99
    assert clean["urban"].between(0, 1).mean() > 0.9
