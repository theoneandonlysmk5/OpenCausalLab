#!/usr/bin/env python3
"""Replicate manuscript Table 3 (age-14 DiDisc work outcomes) in Python."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.table3 import (  # noqa: E402
    compare_to_published,
    export_local_sample,
    format_wide,
    load_hhsurvey,
    prepare_table3_sample,
    run_table3,
    write_results,
)


def main() -> None:
    hh = load_hhsurvey()
    sample = prepare_table3_sample(hh)
    print(f"Table 3 sample N={len(sample):,}  clusters={sample['age_mo_year'].nunique()}")

    results = run_table3(sample)
    comparison = compare_to_published(results)
    long_p, wide_p, cmp_p = write_results(results, comparison)
    local_p = export_local_sample(hh)

    print("\n" + format_wide(results).to_string(index=False))
    print("\nvs manuscript (xxw3):")
    xx = comparison.loc[comparison["term"] == "xxw3", ["outcome", "coef_py", "coef_paper", "delta_coef", "se_py", "se_paper"]]
    print(xx.to_string(index=False, float_format=lambda x: f"{x: .4f}"))
    print(f"\nWrote:\n  {long_p}\n  {wide_p}\n  {cmp_p}\n  {local_p}")


if __name__ == "__main__":
    main()
