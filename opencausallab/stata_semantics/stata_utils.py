"""Small helpers that mirror common Stata idioms used in the replication package."""

from __future__ import annotations

import numpy as np
import pandas as pd


def to_numeric(series: pd.Series) -> pd.Series:
    """Coerce Stata-like object columns to float, preserving missingness."""
    if pd.api.types.is_bool_dtype(series):
        return series.astype("float64")
    if pd.api.types.is_numeric_dtype(series):
        return pd.to_numeric(series, errors="coerce")
    # Boolean stored as object (e.g. travel median flags) → 0/1 float.
    if series.dtype == object:
        sample = series.dropna().head(20)
        if len(sample) and all(isinstance(v, (bool, np.bool_)) for v in sample):
            out = pd.Series(np.nan, index=series.index, dtype="float64")
            out = out.mask(series == True, 1.0)
            out = out.mask(series == False, 0.0)
            return out
    cleaned = series.astype("string").str.strip().str.replace(",", ".", regex=False)
    cleaned = cleaned.replace(
        {
            "": pd.NA,
            ".": pd.NA,
            "nan": pd.NA,
            "None": pd.NA,
            "True": "1",
            "False": "0",
            "true": "1",
            "false": "0",
        }
    )
    return pd.to_numeric(cleaned, errors="coerce")


def stata_str(series: pd.Series) -> pd.Series:
    """Approximate Stata tostring without leading-zero padding."""
    out = series.copy()
    if pd.api.types.is_numeric_dtype(out):
        # Match Stata tostring of integers: no trailing .0
        num = pd.to_numeric(out, errors="coerce")
        as_int = num.dropna().mod(1).eq(0)
        result = pd.Series(pd.NA, index=out.index, dtype="string")
        int_idx = num.index[num.notna()][as_int.to_numpy()]
        float_idx = num.index[num.notna()][~as_int.to_numpy()]
        result.loc[int_idx] = num.loc[int_idx].astype("int64").astype("string")
        result.loc[float_idx] = num.loc[float_idx].astype("string")
        return result
    return out.astype("string").str.strip()


def inlist(series: pd.Series, values) -> pd.Series:
    return to_numeric(series).isin(list(values))


def inrange(series: pd.Series, low: float, high: float) -> pd.Series:
    x = to_numeric(series)
    return x.ge(low) & x.le(high)


def replace_where(base: pd.Series, value, condition: pd.Series) -> pd.Series:
    out = base.copy()
    out = out.where(~condition.fillna(False), value)
    return out


def recode_map(series: pd.Series, mapping: dict) -> pd.Series:
    x = to_numeric(series)
    return x.replace(mapping)


def stata_round(series_or_array, unit: float = 1.0) -> np.ndarray | pd.Series:
    """
    Stata ``round(x)`` / ``round(x, unit)``.

    Half-integers round **away from zero** (not banker's rounding as in ``np.round``).
    Critical for ``age_dob_m = round(age_dob/30)``.
    """
    is_series = isinstance(series_or_array, pd.Series)
    x = to_numeric(series_or_array) if is_series else np.asarray(series_or_array, dtype=float)
    vals = np.asarray(x, dtype=float)
    if unit != 1.0:
        vals = vals / unit
    out = np.empty_like(vals, dtype=float)
    mask = np.isfinite(vals)
    out[~mask] = np.nan
    v = vals[mask]
    pos = v >= 0
    rounded = np.empty_like(v)
    rounded[pos] = np.floor(v[pos] + 0.5)
    rounded[~pos] = np.ceil(v[~pos] - 0.5)
    if unit != 1.0:
        rounded = rounded * unit
    out[mask] = rounded
    if is_series:
        return pd.Series(out, index=series_or_array.index)
    return out


def winsor_high(series: pd.Series, p: float = 0.01) -> pd.Series:
    """Stata ``winsor ..., p(#) high``: cap at the (1-p) quantile."""
    x = to_numeric(series)
    if x.notna().sum() == 0:
        return x
    cap = x.quantile(1.0 - p)
    return x.clip(upper=cap)
