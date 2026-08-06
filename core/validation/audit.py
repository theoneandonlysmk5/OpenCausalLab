"""
Stage-by-stage pipeline validation utilities.

Follows the OpenCausalLab validation protocol:
  Raw → year-cleaned → merge → constructed vars → regression sample
  → descriptives → coefficients → SEs

Without Stata intermediates, we compare Python checkpoints to each other
and to manuscript golden values, and log every discrepancy.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

import numpy as np
import pandas as pd

from .. import paths
from ..stata_utils import to_numeric


def audit_frame(
    df: pd.DataFrame,
    name: str,
    key_cols: list[str] | None = None,
    *,
    as_dict: bool = False,
) -> dict[str, Any]:
    """Row/column/duplicate/missingness snapshot for one checkpoint."""
    info: dict[str, Any] = {
        "name": name,
        "rows": int(len(df)),
        "columns": int(df.shape[1]),
        "duplicate_rows": int(df.duplicated().sum()),
    }
    if key_cols:
        present = [c for c in key_cols if c in df.columns]
        missing_keys = [c for c in key_cols if c not in df.columns]
        info["key_cols"] = present
        info["missing_key_cols"] = missing_keys
        if present:
            info["duplicate_keys"] = int(df.duplicated(present, keep=False).sum())
            info["nunique_keys"] = int(df.drop_duplicates(present).shape[0])
        else:
            info["duplicate_keys"] = None
            info["nunique_keys"] = None
    miss = df.isna().sum().sort_values(ascending=False)
    info["top_missing"] = {str(k): int(v) for k, v in miss.head(20).items() if v > 0}
    if not as_dict:
        print(f"\n{name}")
        print("Rows:", info["rows"])
        print("Columns:", info["columns"])
        print("Duplicate rows:", info["duplicate_rows"])
        if key_cols:
            print("Duplicate keys:", info.get("duplicate_keys"))
        if info["top_missing"]:
            print("Missing values (top):")
            for k, v in list(info["top_missing"].items())[:10]:
                print(f"  {k}: {v}")
    return info


def variable_audit(df: pd.DataFrame, cols: Iterable[str]) -> pd.DataFrame:
    cols = [c for c in cols if c in df.columns]
    if not cols:
        return pd.DataFrame()
    num = df[cols].apply(to_numeric)
    desc = num.describe(
        percentiles=[0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99]
    ).T
    desc["n_missing"] = num.isna().sum()
    desc["n_nonmissing"] = num.notna().sum()
    return desc


def binary_audit(df: pd.DataFrame, cols: Iterable[str]) -> pd.DataFrame:
    rows = []
    for col in cols:
        if col not in df.columns:
            continue
        s = to_numeric(df[col])
        rows.append(
            {
                "variable": col,
                "n": int(s.notna().sum()),
                "n_missing": int(s.isna().sum()),
                "mean": float(s.mean()) if s.notna().any() else np.nan,
                "share_0": float((s == 0).mean()),
                "share_1": float((s == 1).mean()),
                "n_other": int(((s.notna()) & ~s.isin([0, 1])).sum()),
            }
        )
    return pd.DataFrame(rows)


def weighted_mean(x: pd.Series, w: pd.Series) -> float:
    x = to_numeric(x)
    w = to_numeric(w)
    valid = x.notna() & w.notna() & (w > 0)
    if valid.sum() == 0:
        return float("nan")
    return float(np.average(x[valid], weights=w[valid]))


class SampleFlow:
    """Accumulate N / household counts through filters."""

    def __init__(self, hh_col: str = "folio"):
        self.hh_col = hh_col
        self.rows: list[dict[str, Any]] = []

    def log(self, df: pd.DataFrame, step: str) -> pd.DataFrame:
        hh = (
            int(df[self.hh_col].nunique())
            if self.hh_col in df.columns
            else np.nan
        )
        self.rows.append({"step": step, "n": int(len(df)), "households": hh})
        return df

    def to_frame(self) -> pd.DataFrame:
        return pd.DataFrame(self.rows)


# Manuscript golden values (printed precision).
GOLDEN = {
    "table1_prelaw_ages_10_15_n": 7410,
    "table1_prelaw_any_work": 0.152,
    "table1_prelaw_hours": 3.325,
    "table1_prelaw_male": 0.501,
    "table1_prelaw_urban_implied": None,  # not printed as urban share in col1
    "table3_n": 11991,
    "table3_mean_works": 0.180,
    "table3_xxw3": -0.039,
    "table3_xxw3_se": 0.017,
    "table3_xxrw3": -0.000,
    "table3_xxrw3_se": 0.019,
    "table3_clusters_expected_approx": 192,
}


def append_ledger(
    ledger: list[dict],
    *,
    result: str,
    paper,
    python,
    status: str,
    likely_cause: str,
    unit: str = "",
) -> None:
    try:
        abs_diff = (
            abs(float(python) - float(paper))
            if paper is not None and python is not None
            else None
        )
    except (TypeError, ValueError):
        abs_diff = None
    ledger.append(
        {
            "result": result,
            "paper": paper,
            "python": python,
            "abs_diff": abs_diff,
            "status": status,
            "likely_cause": likely_cause,
            "unit": unit,
        }
    )


def classify_count(paper: int, python: int, exact_tol: int = 0, near_tol: int = 5) -> str:
    d = abs(python - paper)
    if d <= exact_tol:
        return "match"
    if d <= near_tol:
        return "near"
    return "open"


def classify_mean(paper: float, python: float, tol: float = 0.005) -> str:
    d = abs(python - paper)
    if d <= 5e-4:
        return "match"
    if d <= tol:
        return "near"
    return "open"
