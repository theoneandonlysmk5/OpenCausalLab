#!/usr/bin/env python3
"""Compute SHA-256 for key analysis outputs → data/final/validation/output_hashes.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

from opencausallab.utils.provenance import git_hash, sha256_file  # noqa: E402

TARGETS = [
    CASE_ROOT / "data" / "final" / "HHsurvey.parquet",
    CASE_ROOT / "data" / "final" / "HHsurvey_ad.parquet",
    CASE_ROOT / "data" / "final" / "RW_child_labor_survey.parquet",
    CASE_ROOT / "data" / "final" / "samples" / "sample_table3.parquet",
    CASE_ROOT / "data" / "final" / "samples" / "sample_table4.parquet",
]


def main() -> None:
    out = CASE_ROOT / "data" / "final" / "validation" / "output_hashes.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "git_hash": git_hash(ROOT),
        "files": {},
    }
    for path in TARGETS:
        rel = str(path.relative_to(ROOT))
        if not path.exists():
            payload["files"][rel] = {"missing": True}
            print(f"MISSING  {rel}")
            continue
        digest = sha256_file(path)
        payload["files"][rel] = {
            "sha256": digest,
            "bytes": path.stat().st_size,
        }
        print(f"{digest}  {rel}")
    out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"\nWrote {out}")


if __name__ == "__main__":
    main()
