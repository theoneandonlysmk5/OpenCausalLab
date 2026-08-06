"""
Household Survey — Persona harmonization.

Phase 2 Module A: translate year-level Persona scripts and expose a unified API.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .persona.compile_clean import (
    clean_persona,
    compile_persona,
    write_cleaned_persona,
    write_compiled_persona,
)
from .persona.common import persona_output_path, write_persona_parquet
from .persona.y2012 import harmonize_persona_2012
from .persona.y2013 import harmonize_persona_2013
from .persona.y2014 import harmonize_persona_2014
from .persona.y2015 import harmonize_persona_2015
from .persona.y2016 import harmonize_persona_2016
from .persona.y2017 import harmonize_persona_2017
from .persona.y2018 import harmonize_persona_2018
from .persona.y2019 import harmonize_persona_2019
from core.stata_semantics.stata_utils import to_numeric

__all__ = [
    "clean_persona",
    "compile_persona",
    "harmonize_persona",
    "harmonize_persona_2012",
    "harmonize_persona_2013",
    "harmonize_persona_2014",
    "harmonize_persona_2015",
    "harmonize_persona_2016",
    "harmonize_persona_2017",
    "harmonize_persona_2018",
    "harmonize_persona_2019",
    "summarize_persona",
    "write_cleaned_persona",
    "write_compiled_persona",
    "write_persona_year",
    "write_persona_2012",
]

_HARMONIZERS = {
    2012: harmonize_persona_2012,
    2013: harmonize_persona_2013,
    2014: harmonize_persona_2014,
    2015: harmonize_persona_2015,
    2016: harmonize_persona_2016,
    2017: harmonize_persona_2017,
    2018: harmonize_persona_2018,
    2019: harmonize_persona_2019,
}


def harmonize_persona(year: int, raw_path: Path | None = None) -> pd.DataFrame:
    """Dispatch to year-specific Persona harmonizer (2012–2019)."""
    try:
        fn = _HARMONIZERS[year]
    except KeyError as exc:
        supported = sorted(_HARMONIZERS)
        raise ValueError(
            f"Persona harmonization for {year} is not implemented. Supported: {supported}"
        ) from exc
    return fn(raw_path)


def write_persona_year(year: int, out_path: Path | None = None) -> Path:
    out_path = out_path or persona_output_path(year)
    df = harmonize_persona(year)
    return write_persona_parquet(df, year, out_path)


def write_persona_2012(out_path: Path | None = None) -> Path:
    return write_persona_year(2012, out_path)


def summarize_persona(df: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for col in df.columns:
        s = df[col]
        num = to_numeric(s)
        mean_val = num.mean()
        rows.append(
            {
                "variable": col,
                "dtype": str(s.dtype),
                "n": len(s),
                "n_missing": int(s.isna().sum()),
                "missing_rate": float(s.isna().mean()),
                "n_unique": int(s.nunique(dropna=True)),
                "mean": float(mean_val) if pd.notna(mean_val) else np.nan,
            }
        )
    return pd.DataFrame(rows)
