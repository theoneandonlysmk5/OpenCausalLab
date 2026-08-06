"""
Intermediate stage validation: persona → income → HHsurvey → Table 3 sample.

Compares row counts and key merge integrity before trusting coefficients.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from .. import paths
from core.stata_semantics.stata_utils import to_numeric
from ..table3 import prepare_table3_sample


def stage_ladder(hh: pd.DataFrame | None = None) -> pd.DataFrame:
    """Return a stage-by-stage N table (and golden expectations where known)."""
    rows: list[dict] = []

    def add(stage: str, n: int | None, expected: int | None, note: str = "") -> None:
        rows.append(
            {
                "stage": stage,
                "n": n,
                "expected": expected,
                "match": (n == expected) if (n is not None and expected is not None) else None,
                "note": note,
            }
        )

    persona = paths.INTERMEDIATE / "persona" / "EH_cleaned_persona.parquet"
    income = paths.INTERMEDIATE / "income" / "EH_cleaned_income.parquet"
    hh_path = paths.FINAL / "HHsurvey.parquet"

    if persona.exists():
        add("EH_cleaned_persona", len(pd.read_parquet(persona, columns=["year"])), 295482)
    else:
        add("EH_cleaned_persona", None, 295482, "missing")

    if income.exists():
        add("EH_cleaned_income", len(pd.read_parquet(income, columns=["year"])), 218360)
    else:
        add("EH_cleaned_income", None, 218360, "missing")

    if hh is None and hh_path.exists():
        hh = pd.read_parquet(hh_path)
    if hh is not None:
        add("HHsurvey age<21", len(hh), 125368)
        sample = prepare_table3_sample(hh)
        add("Table3 e(sample)", len(sample), 11991, "kernel>0 + complete cases")
        y = to_numeric(hh["year"])
        add("HHsurvey years 2012-2019", int(((y >= 2012) & (y <= 2019)).sum()), None)
    else:
        add("HHsurvey age<21", None, 125368, "missing")
        add("Table3 e(sample)", None, 11991, "missing")

    return pd.DataFrame(rows)


def write_stage_ladder(hh: pd.DataFrame | None = None, out: Path | None = None) -> Path:
    out = out or (paths.FINAL / "validation" / "intermediate_stage_ladder.csv")
    out.parent.mkdir(parents=True, exist_ok=True)
    stage_ladder(hh).to_csv(out, index=False)
    return out
