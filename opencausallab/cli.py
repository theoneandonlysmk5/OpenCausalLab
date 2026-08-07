"""Root-friendly CLI for OpenCausalLab case studies.

Examples::

    ocl study lakdawala2025 table3
    ocl study lakdawala2025 verify
    ocl study lakdawala2025 check-data

    python -m opencausallab study lakdawala2025 table3
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

STUDIES = {
    "lakdawala2025": {
        "root": REPO_ROOT / "studies" / "lakdawala2025",
        "commands": {
            "table3": "scripts/run_table3.py",
            "verify": "scripts/ci_gate.py",
            "check-data": "scripts/check_data_layout.py",
            "verification": "scripts/run_verification.py",
        },
    },
}


def _run_study(study_id: str, command: str) -> int:
    meta = STUDIES.get(study_id)
    if meta is None:
        known = ", ".join(sorted(STUDIES))
        print(f"Unknown study {study_id!r}. Known: {known}", file=sys.stderr)
        return 2
    script_rel = meta["commands"].get(command)
    if script_rel is None:
        known = ", ".join(sorted(meta["commands"]))
        print(
            f"Unknown command {command!r} for {study_id}. Known: {known}",
            file=sys.stderr,
        )
        return 2
    case_root: Path = meta["root"]
    script = case_root / script_rel
    if not script.is_file():
        print(f"Missing script: {script}", file=sys.stderr)
        return 2
    env = os.environ.copy()
    env["PYTHONPATH"] = os.pathsep.join(
        [str(REPO_ROOT), str(case_root), env.get("PYTHONPATH", "")]
    )
    rel_script = script.relative_to(REPO_ROOT)
    rel_cwd = case_root.relative_to(REPO_ROOT)
    print(f"+ {sys.executable} {rel_script}  (cwd={rel_cwd})")
    completed = subprocess.run([sys.executable, str(script)], cwd=case_root, env=env)
    return int(completed.returncode)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ocl",
        description="OpenCausalLab command-line interface",
    )
    sub = parser.add_subparsers(dest="group", required=True)

    study = sub.add_parser("study", help="Run a case-study command from the repo root")
    study.add_argument("study_id", help="e.g. lakdawala2025")
    study.add_argument(
        "command",
        help="table3 | verify | check-data | verification",
    )
    return parser


def main(argv: list[str] | None = None) -> None:
    """Console entry point (``ocl`` / ``python -m opencausallab``)."""
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.group == "study":
        raise SystemExit(_run_study(args.study_id, args.command))
    parser.error(f"Unhandled group {args.group}")


if __name__ == "__main__":
    main()
