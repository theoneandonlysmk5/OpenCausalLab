"""Shared helpers for Persona harmonization (2012–2019)."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from opencausallab.stata_semantics.stata_utils import inlist, inrange, recode_map, replace_where, stata_str, to_numeric


def read_dta(path: Path | str) -> pd.DataFrame:
    """Load a Stata .dta with encoding fallbacks used by this package."""
    import pyreadstat

    path = Path(path)
    try:
        df, _meta = pyreadstat.read_dta(str(path))
        return df
    except Exception:
        pass
    for encoding in ("latin1", "cp1252"):
        try:
            df, _meta = pyreadstat.read_dta(str(path), encoding=encoding)
            return df
        except Exception:
            continue
    # Last resort for files pandas can open (not format 110)
    return pd.read_stata(str(path), convert_categoricals=False)


def read_persona(year: int, raw_path: Path | None = None) -> pd.DataFrame:
    """Load raw Persona .dta for a survey year."""
    raw_path = raw_path or paths.raw_household_persona(year)
    return read_dta(raw_path)


def make_id(df: pd.DataFrame, folio_col: str = "folio", nro_col: str = "nro") -> pd.Series:
    """Concatenate folio and nro as Stata ``egen id=concat(folio nro)``."""
    folio = stata_str(_resolve_col(df, folio_col))
    nro = stata_str(df[nro_col])
    return folio + nro


def _resolve_col(df: pd.DataFrame, name: str) -> pd.Series:
    """Resolve column name, including BOM-prefixed folio in 2017."""
    if name in df.columns:
        return df[name]
    if name == "folio":
        for col in df.columns:
            if col.endswith("folio") or col == "ïfolio":
                return df[col]
    raise KeyError(f"Column {name!r} not found in dataframe")


def make_incomes(
    df: pd.DataFrame,
    *,
    yper: str = "yper",
    ylab: str = "ylab",
    yhog: str = "yhog",
    yhogpc: str = "yhogpc",
) -> pd.DataFrame:
    """Destring income vars and build ytotal/ytrabajo/yhogar/yhogarpc."""
    yper_n = to_numeric(df[yper])
    ylab_n = to_numeric(df[ylab])
    return pd.DataFrame(
        {
            "ytotal": yper_n.where(yper_n != 0),
            "ytrabajo": ylab_n.where(ylab_n != 0),
            "yhogar": to_numeric(df[yhog]),
            "yhogarpc": to_numeric(df[yhogpc]),
        },
        index=df.index,
    )


def make_work(df: pd.DataFrame) -> pd.Series:
    """Working status from s06a_* and pet (2016–2019 waves)."""
    s06a_01 = to_numeric(df["s06a_01"])
    s06a_02 = to_numeric(df["s06a_02"])
    s06a_03 = to_numeric(df["s06a_03"])
    s06a_05 = to_numeric(df["s06a_05"])
    s06a_10 = to_numeric(df["s06a_10"])
    pet = to_numeric(df["pet"])

    work = pd.Series(np.nan, index=df.index, dtype="float64")
    work = replace_where(work, 1.0, s06a_01.eq(1))
    work = replace_where(work, 1.0, inrange(s06a_02, 1, 7))
    work = replace_where(work, 1.0, inrange(s06a_03, 1, 9))
    work = replace_where(work, 0.0, pet.eq(1) & (s06a_05.eq(1) | s06a_10.eq(1)))
    return work


def make_work_lastweek(df: pd.DataFrame) -> pd.Series:
    s06a_01 = to_numeric(df["s06a_01"])
    out = s06a_01.copy()
    return replace_where(out, 0.0, out.eq(2))


def make_ocu_cat(df: pd.DataFrame, source_col: str, *, subtract_if_gt7: bool = False) -> pd.Series:
    ocu_cat = to_numeric(df[source_col])
    if subtract_if_gt7:
        ocu_cat = replace_where(ocu_cat, ocu_cat - 1, ocu_cat.gt(7))
    return ocu_cat


def make_ocu_cat2(ocu_cat: pd.Series) -> pd.Series:
    ocu_cat2 = pd.Series(np.nan, index=ocu_cat.index, dtype="float64")
    ocu_cat2 = replace_where(ocu_cat2, 1.0, inlist(ocu_cat, [1, 2, 6, 8]))
    ocu_cat2 = replace_where(ocu_cat2, 2.0, inlist(ocu_cat, [3, 5]))
    ocu_cat2 = replace_where(ocu_cat2, 3.0, ocu_cat.eq(4))
    ocu_cat2 = replace_where(ocu_cat2, 4.0, ocu_cat.eq(7))
    return ocu_cat2


def make_hours_worked_day_2016_2017(df: pd.DataFrame) -> pd.Series:
    """Hours/day with s06b_23a1 adjustment (2016–2017 Stata logic)."""
    aa = to_numeric(df["s06b_23aa"])
    ab = to_numeric(df["s06b_23ab"])
    a1 = to_numeric(df["s06b_23a1"])
    a2 = to_numeric(df["s06b_23a2"])
    base = aa + ab / 60.0
    out = pd.Series(np.nan, index=df.index, dtype="float64")
    out = replace_where(out, base, a1.eq(3))
    out = replace_where(out, base - a2 / 7.0, a1.eq(2))
    out = replace_where(out, base + a2 / 7.0, a1.eq(1))
    return out


def make_hours_worked_day_2018(df: pd.DataFrame) -> pd.Series:
    """Hours/day with swapped s06b_23a1==1/2 signs (2018 Stata quirk)."""
    aa = to_numeric(df["s06b_23aa"])
    ab = to_numeric(df["s06b_23ab"])
    a1 = to_numeric(df["s06b_23a1"])
    a2 = to_numeric(df["s06b_23a2"])
    base = aa + ab / 60.0
    out = pd.Series(np.nan, index=df.index, dtype="float64")
    out = replace_where(out, base, a1.eq(3))
    out = replace_where(out, base + a2 / 7.0, a1.eq(2))
    out = replace_where(out, base - a2 / 7.0, a1.eq(1))
    return out


def make_hours_worked_day_2019(df: pd.DataFrame) -> pd.Series:
    aa = to_numeric(df["s06b_23aa"])
    ab = to_numeric(df["s06b_23ab"])
    return aa + ab / 60.0


def make_job_location(
    df: pd.DataFrame,
    age: pd.Series,
    *,
    category4_values: list[float],
) -> pd.Series:
    s06b_20 = to_numeric(df["s06b_20"])
    job_location = pd.Series(np.nan, index=df.index, dtype="float64")
    job_location = replace_where(job_location, 1.0, s06b_20.eq(1))
    job_location = replace_where(job_location, 2.0, s06b_20.eq(2))
    job_location = replace_where(job_location, 3.0, inlist(s06b_20, [3, 4, 5, 6, 7, 8]))
    job_location = replace_where(job_location, 4.0, inlist(s06b_20, category4_values))
    job_location = replace_where(job_location, 5.0, age.ge(7) & job_location.isna())
    return job_location


def make_enrollment(df: pd.DataFrame, source_col: str) -> pd.Series:
    src = to_numeric(df[source_col])
    enrollment = pd.Series(np.nan, index=df.index, dtype="float64")
    enrollment = replace_where(enrollment, 1.0, src.eq(1))
    enrollment = replace_where(enrollment, 0.0, src.eq(2))
    return enrollment


def make_level_enrolled(
    df: pd.DataFrame,
    *,
    grade_col: str,
    level_a: str = "s05a_06a",
    level_b: str = "s05a_06b",
) -> pd.Series:
    s05a_06a = to_numeric(df[level_a])
    s05a_grade = to_numeric(df[grade_col])
    level_enrolled = pd.Series(np.nan, index=df.index, dtype="float64")
    level_enrolled = replace_where(
        level_enrolled, 1.0, s05a_06a.eq(41) & s05a_grade.eq(1)
    )
    for i in range(2, 7):
        level_enrolled = replace_where(
            level_enrolled, float(i), s05a_06a.eq(41) & s05a_grade.eq(i)
        )
    for i in range(1, 7):
        level_enrolled = replace_where(
            level_enrolled, float(6 + i), s05a_06a.eq(42) & s05a_grade.eq(i)
        )
    return level_enrolled


def make_enrolled_public(df: pd.DataFrame) -> pd.Series:
    s05a_09 = to_numeric(df["s05a_09"])
    return (s05a_09.eq(1)).astype(float).where(s05a_09.notna())


def make_estudia(df: pd.DataFrame) -> pd.Series:
    estudia = pd.Series(0.0, index=df.index)
    estudia = replace_where(estudia, 1.0, to_numeric(df["s05b_10"]).eq(1))
    s05b_11 = to_numeric(df["s05b_11"])
    s05b_11a = to_numeric(df["s05b_11a"]) if "s05b_11a" in df.columns else pd.Series(np.nan, index=df.index)
    estudia = replace_where(estudia, 1.0, s05b_11.eq(1) | s05b_11a.eq(1))
    return estudia


def binary_01(series: pd.Series, yes: float = 1.0, no: float = 2.0) -> pd.Series:
    x = to_numeric(series)
    out = pd.Series(np.nan, index=series.index, dtype="float64")
    out = replace_where(out, 1.0, x.eq(yes))
    out = replace_where(out, 0.0, x.eq(no))
    return out


def make_nocturna(df: pd.DataFrame) -> pd.Series:
    return inlist(to_numeric(df["s05a_06a"]), [12, 61, 62, 63, 64]).astype(float)


def rel_jefe_le4(s02a_05: pd.Series) -> pd.Series:
    """2012/2017/2018 rel_jefe mapping (threshold <=4)."""
    s = to_numeric(s02a_05)
    rel = pd.Series(np.nan, index=s.index, dtype="float64")
    rel = replace_where(rel, s, s.le(4))
    rel = replace_where(rel, 5.0, s.eq(8))
    rel = replace_where(rel, 6.0, s.eq(5))
    rel = replace_where(rel, 7.0, inlist(s, [6, 7]))
    rel = replace_where(rel, 8.0, s.gt(8))
    return rel


def rel_jefe_le3(s02a_05: pd.Series) -> pd.Series:
    """2016/2019 rel_jefe mapping (threshold <=3)."""
    s = to_numeric(s02a_05)
    rel = pd.Series(np.nan, index=s.index, dtype="float64")
    rel = replace_where(rel, s, s.le(3))
    rel = replace_where(rel, 3.0, s.eq(4))
    rel = replace_where(rel, 4.0, s.eq(5))
    rel = replace_where(rel, 5.0, s.eq(9))
    rel = replace_where(rel, 6.0, s.eq(6))
    rel = replace_where(rel, 7.0, inlist(s, [7, 8]))
    rel = replace_where(rel, 8.0, s.gt(8))
    return rel


def map_sector_from_caeb(caeb: pd.Series) -> pd.Series:
    caeb = to_numeric(caeb)
    sector = pd.Series(np.nan, index=caeb.index, dtype="float64")
    sector = replace_where(sector, 1.0, inlist(caeb, [0]))
    sector = replace_where(sector, 2.0, inlist(caeb, [1]))
    sector = replace_where(sector, 3.0, inlist(caeb, [2]))
    sector = replace_where(sector, 4.0, inlist(caeb, [3, 4]))
    sector = replace_where(sector, 5.0, inlist(caeb, [5]))
    sector = replace_where(sector, 6.0, inlist(caeb, [6]))
    sector = replace_where(sector, 7.0, inlist(caeb, [7, 9]))
    sector = replace_where(sector, 8.0, inlist(caeb, [10, 11]))
    sector = replace_where(sector, 9.0, inlist(caeb, [12, 13, 15, 16, 17, 18, 19]))
    sector = replace_where(sector, 10.0, inlist(caeb, [8]))
    sector = replace_where(sector, 11.0, inlist(caeb, [14, 20]))
    return sector


def make_type_est(df: pd.DataFrame) -> pd.Series:
    s06b_18 = to_numeric(df["s06b_18"])
    type_est = pd.Series(np.nan, index=df.index, dtype="float64")
    type_est = replace_where(type_est, 1.0, inlist(s06b_18, [3, 4]))
    type_est = replace_where(type_est, 2.0, inlist(s06b_18, [1, 2]))
    type_est = replace_where(type_est, 3.0, inlist(s06b_18, [5, 6]))
    return type_est


def make_places_taxes2(df: pd.DataFrame, source_col: str = "s06b_19") -> pd.Series:
    src = to_numeric(df[source_col])
    places_taxes2 = pd.Series(np.nan, index=df.index, dtype="float64")
    places_taxes2 = replace_where(places_taxes2, 1.0, inlist(src, [1, 2]))
    places_taxes2 = replace_where(places_taxes2, 2.0, inlist(src, [3]))
    places_taxes2 = replace_where(places_taxes2, 3.0, inlist(src, [4]))
    return places_taxes2


def make_contract(df: pd.DataFrame) -> pd.Series:
    s06b_17 = to_numeric(df["s06b_17"])
    contract = pd.Series(np.nan, index=df.index, dtype="float64")
    contract = replace_where(contract, s06b_17, inlist(s06b_17, [1, 2]))
    contract = replace_where(contract, 2.0, s06b_17.eq(3))
    contract = replace_where(contract, 3.0, s06b_17.eq(4))
    contract = replace_where(contract, 4.0, s06b_17.eq(5))
    return contract


def make_poverty(df: pd.DataFrame, *, destring_p: bool = False) -> pd.DataFrame:
    p0 = to_numeric(df["p0"])
    z = to_numeric(df["z"])
    pext0 = to_numeric(df["pext0"])
    zext = to_numeric(df["zext"])
    if destring_p:
        # Stata ``destring p*, replace`` — re-coerce in case of string storage
        p0 = to_numeric(df["p0"])
        z = to_numeric(df["z"])
        pext0 = to_numeric(df["pext0"])
        zext = to_numeric(df["zext"])
    return pd.DataFrame(
        {
            "poor": p0.eq(1).astype(float),
            "pov_line": z,
            "poor_xtr": pext0.eq(1).astype(float),
            "pov_xtr_line": zext,
        },
        index=df.index,
    )


def make_health_insurance(df: pd.DataFrame) -> pd.Series:
    return recode_map(df["s06c_29b"], {2: 0})


def make_sex_binary(df: pd.DataFrame) -> pd.Series:
    """2018/2019: gen sex=1 if s02a_02==1; replace sex=2 if s02a_02==2."""
    s02a_02 = to_numeric(df["s02a_02"])
    sex = pd.Series(np.nan, index=df.index, dtype="float64")
    sex = replace_where(sex, 1.0, s02a_02.eq(1))
    sex = replace_where(sex, 2.0, s02a_02.eq(2))
    return sex


def copy_standard_fields(df: pd.DataFrame, out: pd.DataFrame, *, esc_col: str) -> None:
    """Copy rename-only demographic / survey weight fields."""
    out["depto"] = to_numeric(df["depto"])
    out["area"] = to_numeric(df["area"])
    out["factor"] = to_numeric(df["factor"])
    # Keep UPM as string — later waves use alphanumeric PSU codes.
    out["upm"] = stata_str(df["upm"]) if "upm" in df.columns else pd.Series(pd.NA, index=df.index, dtype="string")


def select_keep(out: pd.DataFrame, keep: list[str]) -> pd.DataFrame:
    missing = [c for c in keep if c not in out.columns]
    if missing:
        raise RuntimeError(f"Missing expected output columns: {missing}")
    return out.loc[:, keep].copy()


def persona_output_path(year: int) -> Path:
    return paths.INTERMEDIATE / "persona" / f"EH{year}_Persona_relabel.parquet"


def write_persona_parquet(df: pd.DataFrame, year: int, out_path: Path | None = None) -> Path:
    out_path = out_path or persona_output_path(year)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    return out_path
