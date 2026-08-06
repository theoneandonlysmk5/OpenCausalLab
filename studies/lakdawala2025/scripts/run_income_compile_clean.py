#!/usr/bin/env python3
"""Compile and clean Income datasets (2012–2017)."""

from __future__ import annotations

import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

from src.income import write_cleaned_income, write_compiled_income  # noqa: E402


def main() -> None:
    import pandas as pd

    compiled_path = write_compiled_income()
    cleaned_path = write_cleaned_income()

    comp = pd.read_parquet(compiled_path)
    clean = pd.read_parquet(cleaned_path)

    print(f"Compiled: {len(comp):,} rows → {compiled_path}")
    print(f"Cleaned:  {len(clean):,} rows → {cleaned_path}")
    print(f"Years: {sorted(comp['year'].dropna().astype(int).unique().tolist())}")
    print(f"y_household present: {'y_household' in clean.columns}")


if __name__ == "__main__":
    main()
