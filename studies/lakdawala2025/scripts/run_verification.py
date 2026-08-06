#!/usr/bin/env python3
"""Run Tier 1–3 replication confidence audits → data/final/validation/."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.validation.verification import run_all_verification  # noqa: E402


def main() -> None:
    artifacts = run_all_verification()
    print("Verification artifacts written:")
    for name, path in sorted(artifacts.items()):
        print(f"  {name}: {path}")


if __name__ == "__main__":
    main()
