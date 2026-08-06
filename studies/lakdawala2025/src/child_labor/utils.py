"""Small shared helpers for the Child Labor Survey pipeline."""

from __future__ import annotations

import pandas as pd

from ..stata_utils import to_numeric


def mdy(month: pd.Series, day: pd.Series, year: pd.Series) -> pd.Series:
    """Stata ``mdy(month, day, year)`` → days since Stata epoch (1960-01-01)."""
    epoch = pd.Timestamp("1960-01-01")
    y = to_numeric(year).astype("float64")
    m = to_numeric(month).astype("float64")
    d = to_numeric(day).astype("float64")
    dt = pd.to_datetime({"year": y, "month": m, "day": d}, errors="coerce")
    return (dt - epoch).dt.days.astype("float64")


def merge_drop_using_only(
    left: pd.DataFrame, right: pd.DataFrame, on: list[str] | str, how: str = "left"
) -> pd.DataFrame:
    """``merge ...; drop if _merge==2`` — keep master + matched rows, not using-only."""
    merged = left.merge(right, on=on, how=how, indicator="_merge")
    merged = merged.loc[merged["_merge"] != "right_only"].copy()
    return merged.drop(columns="_merge")


def make_person_id(folio: pd.Series, number: pd.Series) -> pd.Series:
    """Stata ``id`` construction: folio + zero-padded 2-digit person number."""
    folio_n = to_numeric(folio)
    number_n = to_numeric(number)
    number_str = number_n.astype("Int64").astype("string").str.zfill(2)
    folio_str = folio_n.astype("Int64").astype("string")
    id_str = folio_str + number_str
    return to_numeric(id_str)
