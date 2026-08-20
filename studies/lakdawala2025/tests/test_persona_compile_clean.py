"""Tests for Persona compile + clean."""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import pytest

from opencausallab.stata_semantics.stata_utils import replace_where, to_numeric
from src.persona.compile_clean import _concat_code, _stata_str_ne_empty


def test_concat_code_2015_blank_province_stays_missing():
    """egen concat if t==2015 & provincia15!="" then replace if t==2015."""
    depto = pd.Series([5, 5, 1, 2])
    provincia15 = pd.Series(["12", "", pd.NA, "03"], dtype="string")
    t = pd.Series([2015, 2015, 2015, 2014])
    where = t.eq(2015) & _stata_str_ne_empty(provincia15)
    aux3 = _concat_code(depto, provincia15, where=where)

    assert aux3.iloc[0] == "512"
    assert pd.isna(aux3.iloc[1])
    assert pd.isna(aux3.iloc[2])
    assert pd.isna(aux3.iloc[3])

    cod_prov = pd.Series(" ", index=depto.index, dtype="string")
    cod_prov = replace_where(cod_prov, aux3, t.eq(2015))
    assert cod_prov.iloc[0] == "512"
    assert pd.isna(cod_prov.iloc[1])
    assert pd.isna(cod_prov.iloc[2])
    assert cod_prov.iloc[3] == " "
    assert pd.isna(to_numeric(cod_prov).iloc[1])


def test_concat_code_2015_blank_section_stays_missing():
    """egen concat if t==2015 & seccion15!="" then replace if t==2015."""
    cod_prov = pd.Series(["512", "5", "1"], dtype="string")
    seccion15 = pd.Series(["01", "", pd.NA], dtype="string")
    t = pd.Series([2015, 2015, 2015])
    where = t.eq(2015) & _stata_str_ne_empty(seccion15)
    aux3 = _concat_code(cod_prov, seccion15, where=where)

    assert aux3.iloc[0] == "51201"
    assert pd.isna(aux3.iloc[1])
    assert pd.isna(aux3.iloc[2])

    cod_secc = pd.Series(" ", index=cod_prov.index, dtype="string")
    cod_secc = replace_where(cod_secc, aux3, t.eq(2015))
    assert cod_secc.iloc[0] == "51201"
    assert pd.isna(cod_secc.iloc[1])
    assert pd.isna(cod_secc.iloc[2])


def test_stata_str_ne_empty_treats_missing_as_empty():
    s = pd.Series(["12", "", " ", pd.NA], dtype="string")
    got = _stata_str_ne_empty(s)
    assert got.tolist() == [True, False, True, False]


@pytest.mark.microdata
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
