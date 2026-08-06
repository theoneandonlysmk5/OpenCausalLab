#!/usr/bin/env python3
"""Build HHsurvey analysis files (Stata 3. Preparing for analysis.do)."""

from __future__ import annotations

import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

import pandas as pd  # noqa: E402

from src.hhsurvey import build_hhsurvey, write_hhsurvey  # noqa: E402
from opencausallab.stata_semantics.stata_utils import to_numeric  # noqa: E402


def main() -> None:
    child_path, adult_path = write_hhsurvey()
    df = pd.read_parquet(child_path)
    full = build_hhsurvey()

    age = to_numeric(full["age"])
    print(f"Full pipeline rows={len(full):,} cols={full.shape[1]}")
    print(f"HHsurvey → {child_path}")
    print(f"  rows={len(df):,} cols={df.shape[1]}")
    print(f"  age<21 check: {(to_numeric(df['age']) < 21).all()}")

    s14 = to_numeric(df.get("s14", df.get("sww14")))
    if "sww14" in df.columns:
        print(f"  fraction sww14==1 (bandwidth age-14): {(to_numeric(df['sww14']) == 1).mean():.4f}")
    if "s14" in df.columns:
        print(f"  fraction s14==1: {(to_numeric(df['s14']) == 1).mean():.4f}")

    if "sww14" in df.columns and "works" in df.columns:
        mask = to_numeric(df["sww14"]) == 1
        print(f"  mean works among sww14==1: {to_numeric(df.loc[mask, 'works']).mean():.4f}")

    for col in ("treatw14", "xxw3", "kernel_triw14", "cod_secc", "income_q"):
        if col in df.columns:
            print(f"  nonmissing {col}: {to_numeric(df[col]).notna().mean():.4f}")

    print("  rows by year:")
    print(df.groupby("year").size().to_string())
    print(f"HHsurvey_ad → {adult_path}")
    print(f"  rows={pd.read_parquet(adult_path).shape[0]:,}")


if __name__ == "__main__":
    main()
