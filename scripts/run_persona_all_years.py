#!/usr/bin/env python3
"""Run Persona harmonization for all years 2012–2019."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.household import summarize_persona, write_persona_year  # noqa: E402
from src.paths import INTERMEDIATE  # noqa: E402


def main() -> None:
    import pandas as pd

    rows = []
    for year in range(2012, 2020):
        out = write_persona_year(year)
        df = pd.read_parquet(out)
        summary = summarize_persona(df)
        summary_path = INTERMEDIATE / "persona" / f"EH{year}_Persona_relabel_summary.csv"
        summary.to_csv(summary_path, index=False)
        rows.append(
            {
                "year": year,
                "rows": len(df),
                "cols": df.shape[1],
                "id_unique": bool(df["id"].is_unique),
                "work_mean_nonmiss": float(df["work"].mean()),
                "age_mean": float(df["age"].mean()),
                "path": str(out),
            }
        )
        print(
            f"{year}: rows={len(df):,} cols={df.shape[1]} "
            f"id_unique={df['id'].is_unique} work_nonmiss_mean={df['work'].mean():.4f}"
        )

    overview = pd.DataFrame(rows)
    overview_path = INTERMEDIATE / "persona" / "persona_years_overview.csv"
    overview.to_csv(overview_path, index=False)
    print(f"\nOverview → {overview_path}")


if __name__ == "__main__":
    main()
