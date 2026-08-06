#!/usr/bin/env python3
"""Report which Dataverse raw files are present under data/raw/."""

from __future__ import annotations

import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
RAW = CASE_ROOT / "data" / "raw"

# Minimal layout expectations for Lakdawala household Persona/Income years.
REQUIRED = []
for year in range(2012, 2020):
    REQUIRED.append(("required", f"household/{year}", "Persona .dta"))
for year in range(2012, 2018):
    REQUIRED.append(("required", f"household/{year}", "Income-related .dta (as in Dataverse)"))


def has_any_dta(directory: Path) -> bool:
    if not directory.is_dir():
        return False
    return any(directory.rglob("*.dta"))


def main() -> int:
    print(f"Checking raw layout under {RAW}")
    missing = 0
    for kind, rel, note in REQUIRED:
        path = RAW / rel
        ok = has_any_dta(path)
        mark = "✓" if ok else "✗"
        print(f"  {mark} {rel}  ({note})")
        if not ok:
            missing += 1
    cl = RAW / "child_labor"
    print(f"  {'✓' if has_any_dta(cl) else '○'} child_labor/  (optional for Table 5 CL)")
    if missing:
        print(f"\n{missing} required year folders lack .dta files.")
        print("Place Dataverse extracts under studies/lakdawala2025/data/raw/ …")
        return 1
    print("\nRaw layout looks complete enough to start persona/income ETL.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
