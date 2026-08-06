"""Income harmonization package (2012–2017)."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from .common import (
    INCOME_YEARS,
    income_cleaned_path,
    income_compiled_path,
    income_keep,
    income_relabel_path,
    write_income_parquet,
)
from .compile_clean import (
    clean_income,
    compile_income,
    write_cleaned_income,
    write_compiled_income,
)
from .y2012 import harmonize_income_2012
from .y2013 import harmonize_income_2013
from .y2014 import harmonize_income_2014
from .y2015 import harmonize_income_2015
from .y2016 import harmonize_income_2016
from .y2017 import harmonize_income_2017

__all__ = [
    "INCOME_YEARS",
    "clean_income",
    "compile_income",
    "harmonize_income",
    "harmonize_income_2012",
    "harmonize_income_2013",
    "harmonize_income_2014",
    "harmonize_income_2015",
    "harmonize_income_2016",
    "harmonize_income_2017",
    "income_keep",
    "write_cleaned_income",
    "write_compiled_income",
    "write_income_year",
]

_HARMONIZERS = {
    2012: harmonize_income_2012,
    2013: harmonize_income_2013,
    2014: harmonize_income_2014,
    2015: harmonize_income_2015,
    2016: harmonize_income_2016,
    2017: harmonize_income_2017,
}


def harmonize_income(year: int, raw_path: Path | None = None) -> pd.DataFrame:
    try:
        fn = _HARMONIZERS[year]
    except KeyError as exc:
        raise ValueError(f"No income harmonizer for year {year}") from exc
    return fn(raw_path)


def write_income_year(year: int, raw_path: Path | None = None) -> Path:
    df = harmonize_income(year, raw_path)
    return write_income_parquet(df, year)
