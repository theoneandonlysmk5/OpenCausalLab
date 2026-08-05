#!/usr/bin/env python3
"""Run Income harmonization for all years 2012–2017."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.income import INCOME_YEARS, write_income_year  # noqa: E402
from src.paths import INTERMEDIATE  # noqa: E402


def main() -> None:
    import pandas as pd

    rows = []
    for year in INCOME_YEARS:
        out = write_income_year(year)
        df = pd.read_parquet(out)
        rows.append(
            {
                "year": year,
                "rows": len(df),
                "cols": df.shape[1],
                "id_unique": bool(df["id"].is_unique),
                "path": str(out),
            }
        )
        print(f"{year}: rows={len(df):,} cols={df.shape[1]} id_unique={df['id'].is_unique}")

    overview = pd.DataFrame(rows)
    overview_path = INTERMEDIATE / "income" / "income_years_overview.csv"
    overview.to_csv(overview_path, index=False)
    print(f"\nOverview → {overview_path}")


if __name__ == "__main__":
    main()
