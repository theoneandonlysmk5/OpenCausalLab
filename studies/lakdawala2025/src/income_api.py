"""
Income harmonization API — thin re-exports for scripts and downstream modules.
"""

from __future__ import annotations

from .income import (
    INCOME_YEARS,
    clean_income,
    compile_income,
    harmonize_income,
    harmonize_income_2012,
    harmonize_income_2013,
    harmonize_income_2014,
    harmonize_income_2015,
    harmonize_income_2016,
    harmonize_income_2017,
    write_cleaned_income,
    write_compiled_income,
    write_income_year,
)

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
    "write_cleaned_income",
    "write_compiled_income",
    "write_income_year",
]
