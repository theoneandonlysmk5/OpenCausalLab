#!/usr/bin/env python3
"""Build RW_child_labor_survey.parquet and print quick N / mean checks."""

from __future__ import annotations

import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

from src.child_labor.build import build_rw_child_labor_survey  # noqa: E402
from opencausallab.stata_semantics.stata_utils import to_numeric  # noqa: E402


def main() -> None:
    print("Building RW_child_labor_survey…")
    df = build_rw_child_labor_survey()
    print(f"Wrote {df.shape[0]:,} × {df.shape[1]} rows")
    age = to_numeric(df["age_survey_m"])
    year = to_numeric(df["year"])
    for y in (2008, 2016):
        sub = df.loc[year.eq(y)]
        print(
            f"  year={y}: N={len(sub):,}  "
            f"age_m nonmiss={to_numeric(sub['age_survey_m']).notna().sum():,}  "
            f"age 10–15={((age.loc[year.eq(y)] >= 120) & (age.loc[year.eq(y)] <= 180)).sum():,}"
        )
    # Table 1C-style unweighted / weighted risk means (2008, ages 10–15)
    m = year.eq(2008) & age.ge(120) & age.le(180)
    w = to_numeric(df.loc[m, "weights"])
    for yname in ("risks_a", "risks", "injury_a", "injury"):
        y = to_numeric(df.loc[m, yname])
        ok = y.notna() & w.notna()
        if ok.any():
            mean_w = (y[ok] * w[ok]).sum() / w[ok].sum()
            print(f"  2008 ages10-15 {yname}: N={ok.sum()}  wmean={mean_w:.3f}")


if __name__ == "__main__":
    main()
