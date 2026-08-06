#!/usr/bin/env python3
"""Run pre-specified subgroup DiDisc benchmarks."""

from __future__ import annotations

import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

from src.subgroup import (  # noqa: E402
    PUBLISHED_DISTANCE_TIME,
    PUBLISHED_GENDER,
    run_prespecified_subgroups,
    write_subgroup_results,
)
from src.table3 import load_hhsurvey  # noqa: E402


def main() -> None:
    hh = load_hhsurvey()
    results = run_prespecified_subgroups(hh)
    long_p, disp_p = write_subgroup_results(results)

    print(disp_p.read_text() if False else "")
    print(results.filter(regex=r"^(moderator|sample|years|n|effect_|diff_p|mean_pre)").to_string(index=False))

    g = results.loc[results["moderator"] == "male"].iloc[0]
    print(
        f"\nGender (coding-correct girls=male0 / boys=male1): "
        f"{g['effect_girls']:.3f} / {g['effect_boys']:.3f}"
    )
    print(
        f"Gender vs paper via Stata nlcom labels: "
        f"girls {g['stata_label_girls']:.3f} (paper {PUBLISHED_GENDER['girls']}), "
        f"boys {g['stata_label_boys']:.3f} (paper {PUBLISHED_GENDER['boys']}), "
        f"diff_p {g['diff_p']:.3f} (paper {PUBLISHED_GENDER['diff_p']})"
    )
    d = results.loc[
        (results["moderator"] == "het_time") & (results["sample"] == "all")
    ].iloc[0]
    print(
        f"Distance(time) vs paper: near {d['effect_near']:.3f} (paper {PUBLISHED_DISTANCE_TIME['near']}), "
        f"far {d['effect_far']:.3f} (paper {PUBLISHED_DISTANCE_TIME['far']}), N={d['n']} (paper {PUBLISHED_DISTANCE_TIME['n']})"
    )
    print(f"\nWrote:\n  {long_p}\n  {disp_p}")


if __name__ == "__main__":
    main()
