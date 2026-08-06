#!/usr/bin/env python3
"""CI replication gate.

Stages (as available):
  1. Unit tests that never need microdata
  2. If HHsurvey.parquet exists — rebuild Table 3, run verification, pytest
  3. Always — gate committed ledger / verification artifacts vs manuscript

Exit 0 only if every applicable stage PASSes.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.logutil import setup_logging  # noqa: E402

log = setup_logging("ci_gate")

HH = ROOT / "data" / "final" / "HHsurvey.parquet"
SUMMARY = Path(os.environ.get("GITHUB_STEP_SUMMARY", ROOT / "data" / "final" / "validation" / "ci_summary.md"))


def run(cmd: list[str], *, label: str) -> None:
    log.info("=== %s ===", label)
    log.info("+ %s", " ".join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True)


def append_summary(lines: list[str]) -> None:
    SUMMARY.parent.mkdir(parents=True, exist_ok=True)
    with SUMMARY.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def gate_committed_artifacts() -> None:
    import pandas as pd

    led = pd.read_csv(ROOT / "data" / "final" / "tables" / "main_tables_ledger.csv")
    t3 = led.loc[led["result"] == "Table3 works xxw3"].iloc[0]
    assert abs(float(t3["python"]) + 0.039351) < 1e-4, t3.to_dict()
    n = led.loc[led["result"] == "Table3 N"].iloc[0]
    assert abs(float(n["python"]) - 11991) < 0.5

    # Firm size remains Near/Open in narrative docs; ledger may use near.
    # Fail only on unexpected blank statuses.
    assert led["status"].notna().all()

    spec = pd.read_csv(ROOT / "data" / "final" / "validation" / "spec_equivalence_table3.csv")
    bad = spec.loc[~spec["match"].astype(str).str.lower().isin(["true", "1"])]
    assert bad.empty, bad.to_dict("records")

    bw = pd.read_csv(
        ROOT / "data" / "final" / "validation" / "bandwidth_sensitivity_table3_works.csv"
    )
    row12 = bw.loc[bw["bandwidth"] == 12].iloc[0]
    assert abs(float(row12["xxw3"]) + 0.039351) < 1e-4

    coef = pd.read_csv(ROOT / "data" / "final" / "validation" / "table3_spec_coef_check.csv")
    works = coef.loc[coef["outcome"] == "works"].iloc[0]
    assert abs(float(works["python_xxw3"]) + 0.039351) < 1e-4
    assert int(works["python_n"]) == 11991

    print("committed artifact gate PASS")
    log.info("committed artifact gate PASS")


def gate_live_table3() -> None:
    import pandas as pd

    from src.table3 import compare_to_published, prepare_table3_sample, run_table3

    hh = pd.read_parquet(HH)
    sample = prepare_table3_sample(hh)
    results = run_table3(sample)
    cmp = compare_to_published(results)
    xx = cmp.loc[cmp["term"] == "xxw3"]
    assert len(sample) == 11991
    for _, row in xx.iterrows():
        tol = 0.002 if row["outcome"] == "hours_week_a" else 0.001
        assert abs(row["delta_coef"]) <= tol, row.to_dict()
    works = results.loc[
        (results["outcome"] == "works") & (results["term"] == "xxw3")
    ].iloc[0]
    assert abs(float(works["coef"]) + 0.039351) < 1e-4
    log.info("live Table 3 gate PASS")


def main() -> int:
    stages: list[tuple[str, str]] = []
    SUMMARY.write_text("# Replication CI\n\n", encoding="utf-8")

    # 1. Always: pure unit tests
    run(
        [sys.executable, "-m", "pytest", "tests/test_stata_round.py", "-q", "--tb=short"],
        label="1. Unit tests (no microdata)",
    )
    stages.append(("Unit tests", "PASS"))

    has_hh = HH.exists()
    append_summary(
        [
            f"**HHsurvey.parquet:** `{'present' if has_hh else 'absent'}`",
            "",
            "| Stage | Result |",
            "|-------|--------|",
        ]
    )

    if has_hh:
        # 2. Rebuild Table 3
        run([sys.executable, "scripts/run_table3.py"], label="2. Rebuild Table 3")
        stages.append(("Rebuild Table 3", "PASS"))
        gate_live_table3()
        stages.append(("Live Table 3 gate", "PASS"))

        # 3. Verification suite
        run([sys.executable, "scripts/run_verification.py"], label="3. Verification")
        stages.append(("Verification", "PASS"))

        # 4. Pytest replication validators
        run(
            [
                sys.executable,
                "-m",
                "pytest",
                "tests/test_table3.py",
                "tests/test_verification.py",
                "-q",
                "--tb=short",
            ],
            label="4. Pytest (Table 3 + verification)",
        )
        stages.append(("Pytest Table 3 / verification", "PASS"))
    else:
        log.warning(
            "HHsurvey.parquet not found — skipping live rebuild/verification. "
            "Committed artifact gates still run. Set secret HHSURVEY_PARQUET_URL for full CI."
        )
        stages.append(("Rebuild Table 3", "SKIPPED (no microdata)"))
        stages.append(("Verification", "SKIPPED (no microdata)"))
        stages.append(("Pytest Table 3 / verification", "SKIPPED (no microdata)"))

    # 5. Always: committed outputs must still match manuscript anchors
    gate_committed_artifacts()
    stages.append(("Committed artifact gate", "PASS"))

    for name, result in stages:
        append_summary([f"| {name} | {result} |"])

    append_summary(["", "## Verdict", "", "**PASS**", ""])
    log.info("=" * 40)
    log.info("REPLICATION CI: PASS")
    for name, result in stages:
        log.info("  %s  %s", result, name)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        append_summary(["", "## Verdict", "", f"**FAIL**: `{exc}`", ""])
        log.exception("REPLICATION CI: FAIL")
        raise SystemExit(1) from exc