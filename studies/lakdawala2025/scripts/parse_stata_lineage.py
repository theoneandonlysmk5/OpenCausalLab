#!/usr/bin/env python3
"""Parse vendor Stata .do files for use/save/merge/append/do edges."""

from __future__ import annotations

import csv
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DO_ROOT = ROOT / "vendor" / "stata_dofiles"
OUT = ROOT / "docs" / "lineage_edges_raw.csv"

USE = re.compile(r'^\s*(?:use|u)\s+(?:"([^"]+)"|\'([^\']+)\'|([^\s,]+))', re.I | re.M)
SAVE = re.compile(r'^\s*save(?:dta)?\s+(?:"([^"]+)"|\'([^\']+)\'|([^\s,]+))', re.I | re.M)
MERGE = re.compile(r'^\s*merge\b.*?using\s+(?:"([^"]+)"|\'([^\']+)\'|([^\s,]+))', re.I | re.M)
APPEND = re.compile(r'^\s*append\s+using\s+(?:"([^"]+)"|\'([^\']+)\'|([^\s,]+))', re.I | re.M)
JOINBY = re.compile(r'^\s*joinby\b.*?using\s+(?:"([^"]+)"|\'([^\']+)\'|([^\s,]+))', re.I | re.M)
DOCALL = re.compile(r'^\s*do\s+(?:"([^"]+)"|\'([^\']+)\'|([^\s]+))', re.I | re.M)
GLOBAL = re.compile(r'^\s*global\s+(\w+)\s+"([^"]*)"', re.I | re.M)


def pick(m: re.Match[str]) -> str:
    return next(g for g in m.groups() if g)


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    lines = []
    for line in text.splitlines():
        if re.match(r"^\s*\*", line):
            continue
        lines.append(re.sub(r"//.*$", "", line))
    return "\n".join(lines)


def main() -> None:
    rows: list[tuple[str, str, str]] = []
    for path in sorted(DO_ROOT.rglob("*.do")):
        body = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
        rel = str(path.relative_to(DO_ROOT))
        for kind, rx in [
            ("use", USE),
            ("save", SAVE),
            ("merge_using", MERGE),
            ("joinby_using", JOINBY),
            ("append_using", APPEND),
            ("do", DOCALL),
        ]:
            for m in rx.finditer(body):
                rows.append((rel, kind, pick(m)))
        for m in GLOBAL.finditer(body):
            rows.append((rel, "global", f"{m.group(1)}={m.group(2)}"))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["do_file", "edge_type", "path_or_value"])
        w.writerows(rows)

    by_file: dict[str, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for rel, kind, val in rows:
        by_file[rel][kind].append(val)

    print(f"Wrote {OUT} ({len(rows)} edges from {len(by_file)} do-files)")


if __name__ == "__main__":
    main()
