#!/usr/bin/env python3
"""Run Persona 2012 harmonization and print validation summary."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.household import summarize_persona, write_persona_2012  # noqa: E402
from src.paths import INTERMEDIATE  # noqa: E402


def main() -> None:
    out = write_persona_2012()
    import pandas as pd

    df = pd.read_parquet(out)
    summary = summarize_persona(df)
    summary_path = INTERMEDIATE / "persona" / "EH2012_Persona_relabel_summary.csv"
    summary.to_csv(summary_path, index=False)

    print(f"Wrote {out}")
    print(f"Rows={len(df):,} Cols={df.shape[1]}")
    print(f"Summary → {summary_path}")
    print("\nKey checks:")
    for col in ["work", "age", "sex", "enrollment", "ocu_cat", "sector", "upm", "id"]:
        s = df[col]
        print(
            f"  {col}: missing={s.isna().mean():.3%} unique={s.nunique(dropna=True)} "
            f"mean={pd.to_numeric(s, errors='coerce').mean():.4f}"
            if pd.api.types.is_numeric_dtype(pd.to_numeric(s, errors="coerce"))
            else f"  {col}: missing={s.isna().mean():.3%} unique={s.nunique(dropna=True)}"
        )
    print("\nwork value counts:")
    print(df["work"].value_counts(dropna=False).sort_index().to_string())
    print("\nage>=7 work rate:", float(df.loc[df["age"] >= 7, "work"].mean()))


if __name__ == "__main__":
    main()
