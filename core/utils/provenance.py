"""Provenance sidecars and SHA-256 helpers for analysis outputs."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd


def git_hash(cwd: Path | None = None) -> str | None:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "HEAD"],
            cwd=cwd or Path.cwd(),
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return out.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def sha256_file(path: Path, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            block = f.read(chunk)
            if not block:
                break
            h.update(block)
    return h.hexdigest()


def write_provenance(
    path: Path,
    *,
    created_by: str,
    extra: dict[str, Any] | None = None,
) -> Path:
    meta: dict[str, Any] = {
        "path": str(path),
        "created_by": created_by,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "git_hash": git_hash(path.parent),
        "python": sys.version.split()[0],
        "sha256": sha256_file(path) if path.exists() else None,
    }
    if extra:
        meta.update(extra)
    side = path.with_suffix(path.suffix + ".provenance.json")
    side.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    return side


def write_parquet(
    df: pd.DataFrame,
    path: Path,
    *,
    created_by: str,
    extra: dict[str, Any] | None = None,
) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(path, index=False)
    write_provenance(path, created_by=created_by, extra=extra)
    return path
