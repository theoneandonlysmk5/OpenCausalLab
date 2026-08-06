#!/usr/bin/env python3
"""Compile and clean Persona panel (Stata 2.1 + 2.2)."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.persona.compile_clean import (  # noqa: E402
    write_cleaned_persona,
    write_compiled_persona,
)


def main() -> None:
    import pandas as pd

    compiled_path = write_compiled_persona()
    cleaned_path = write_cleaned_persona()
    compiled = pd.read_parquet(compiled_path)
    cleaned = pd.read_parquet(cleaned_path)

    print(f"Compiled → {compiled_path}")
    print(f"  rows={len(compiled):,} cols={compiled.shape[1]}")
    print(f"  years={sorted(compiled['t'].dropna().unique().tolist())}")
    print(f"  upm nonmiss={compiled['upm'].notna().mean():.3%}")

    print(f"Cleaned → {cleaned_path}")
    print(f"  rows={len(cleaned):,} cols={cleaned.shape[1]}")
    print(f"  works mean (age>=7)={cleaned.loc[cleaned['age']>=7,'works'].mean():.4f}")
    print(f"  male mean={cleaned['male'].mean():.4f}")
    print(f"  urban mean={cleaned['urban'].mean():.4f}")
    print(f"  cod_secc nonmiss={cleaned['cod_secc'].notna().mean():.3%}")
    print(f"  head_schooling mean={cleaned['head_schooling'].mean():.4f}")
    by_year = cleaned.groupby("year").size()
    print("  rows by year:")
    print(by_year.to_string())


if __name__ == "__main__":
    main()
