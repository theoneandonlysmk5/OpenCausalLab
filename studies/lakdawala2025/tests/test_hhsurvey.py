"""Tests for HHsurvey build (Stata 3. Preparing for analysis.do)."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from src.hhsurvey import (
    build_ch_ages,
    build_ch_income,
    build_hhsurvey,
    build_travel_tomerge,
    write_hhsurvey,
)
from src.stata_utils import to_numeric


def _load_persona():
    return pd.read_parquet("data/intermediate/persona/EH_cleaned_persona.parquet")


def _load_income():
    return pd.read_parquet("data/intermediate/income/EH_cleaned_income.parquet")


def test_travel_tomerge_shape():
    travel = build_travel_tomerge()
    assert len(travel) == 339
    assert "cod_secc" in travel.columns
    assert "abovemed_time" in travel.columns
    assert travel["cod_secc"].notna().all()


def test_ch_income_one_row_per_hh():
    persona = _load_persona()
    income = _load_income()
    ch = build_ch_income(persona, income)
    assert ch.groupby(["folio", "year"]).size().max() == 1
    assert "income_q" in ch.columns
    assert "hhsize" in ch.columns


def test_ch_ages_sums():
    persona = _load_persona()
    ch = build_ch_ages(persona)
    assert len(ch) > 0
    for col in ("hh_agecat1", "hh_agecat2", "hh_agecat3", "hh_agecat4"):
        assert col in ch.columns
        assert ch[col].min() >= 0


def test_build_hhsurvey_row_count():
    df = build_hhsurvey()
    persona = _load_persona()
    assert len(df) == len(persona)


def test_hhsurvey_outputs_if_built():
    child = Path("data/final/HHsurvey.parquet")
    if not child.exists():
        write_hhsurvey()
    df = pd.read_parquet(child)
    age = to_numeric(df["age"])
    assert (age < 21).all()
    assert "treatw14" in df.columns
    assert "runningw14" in df.columns
    assert "income_q" in df.columns
    assert len(df) > 100_000


def test_id_year_unique_in_full():
    df = build_hhsurvey()
    assert df["id_year"].is_unique
