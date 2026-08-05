#!/usr/bin/env python3
"""Cross-fitted DiDisc score + honest causal forest (local CATE only)."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.causal_ml import run_causal_ml, write_causal_ml_outputs  # noqa: E402
from src.table3 import load_hhsurvey  # noqa: E402


def main() -> None:
    hh = load_hhsurvey()
    result = run_causal_ml(hh)
    paths_out = write_causal_ml_outputs(result)

    print("CATE summary (weighted):")
    print(result["summary"].to_string(index=False))
    print("\nFeature importance:")
    print(result["feature_importance"].to_string(index=False))
    if not result["validation"].empty:
        print("\nHoldout / WLS validation:")
        print(result["validation"].to_string(index=False))
    print(f"\nForest sample N={len(result['used']):,}  features={result['features']}")
    print("Wrote:")
    for p in paths_out.values():
        print(f"  {p}")


if __name__ == "__main__":
    main()
