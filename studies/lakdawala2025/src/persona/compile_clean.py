"""
Persona compile + clean.

Stata sources:
  2. Compiling/2.1.EH_Persona_compiling.do
  2. Compiling/2.2.EH_Persona_cleaned.do
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from opencausallab.stata_semantics.stata_utils import inlist, inrange, replace_where, stata_str, to_numeric, winsor_high
from .common import persona_output_path, read_dta, write_persona_parquet


def _load_year_relabel(year: int) -> pd.DataFrame:
    path = persona_output_path(year)
    if not path.exists():
        raise FileNotFoundError(
            f"Missing {path}. Run scripts/run_persona_all_years.py first."
        )
    return pd.read_parquet(path)


def _merge_upm_mm(left: pd.DataFrame, upm_path: Path) -> pd.DataFrame:
    """Approximate Stata ``merge m:m upm ...`` then ``drop if _merge==2``."""
    right = read_dta(upm_path)
    right = right.copy()
    right["upm"] = stata_str(right["upm"])
    # UPM crosswalks are unique on upm → behaves like m:1
    overlap = [c for c in right.columns if c in left.columns and c != "upm"]
    right = right.drop(columns=overlap, errors="ignore")
    merged = left.merge(
        right, on="upm", how="left", suffixes=("", "_upm"), validate="m:1"
    )
    return merged


def compile_persona(
    years: range | list[int] | None = None,
) -> pd.DataFrame:
    """Translate 2.1.EH_Persona_compiling.do → EH_compiled_persona."""
    years = list(years) if years is not None else list(range(2012, 2020))
    frames = [_load_year_relabel(y) for y in years]
    # Stata: use 2012; append 2013; tostring upm; append 2014-2019
    out = frames[0].copy()
    if 2013 in years:
        idx = years.index(2013)
        out = pd.concat([out, frames[idx]], axis=0, ignore_index=True, sort=False)
        out["upm"] = stata_str(out["upm"])
        rest = [frames[i] for i, y in enumerate(years) if y not in (2012, 2013)]
    else:
        out["upm"] = stata_str(out["upm"])
        rest = frames[1:]
    for fr in rest:
        fr = fr.copy()
        fr["upm"] = stata_str(fr["upm"])
        out = pd.concat([out, fr], axis=0, ignore_index=True, sort=False)

    out["upm"] = stata_str(out["upm"])
    raw = paths.RAW / "household"
    out = _merge_upm_mm(out, raw / "upm_2001-2013_relabeled.dta")
    out = _merge_upm_mm(out, raw / "upm_2015-2017_relabeled.dta")
    out = _merge_upm_mm(out, raw / "upm_2016_relabeled.dta")

    out["folio"] = stata_str(out["folio"])
    out["id"] = stata_str(out["id"])
    return out


def _stata_str_ne_empty(s: pd.Series) -> pd.Series:
    """Stata ``varname != ""`` (missing strings are empty)."""
    as_str = s.astype("string")
    return as_str.notna() & as_str.ne("")


def _concat_code(*parts: pd.Series, where: pd.Series | None = None) -> pd.Series:
    """Stata ``egen ... = concat(varlist)`` with no separator.

    If ``where`` is given, results are missing where the condition is false,
    matching ``egen ... = concat(...) if cond``.
    """
    as_str = [stata_str(p).fillna("") for p in parts]
    out = as_str[0]
    for p in as_str[1:]:
        out = out + p
    if where is not None:
        out = out.where(where.fillna(False))
    return out


def clean_persona(compiled: pd.DataFrame | None = None) -> pd.DataFrame:
    """Translate 2.2.EH_Persona_cleaned.do → EH_cleaned_persona."""
    df = compiled.copy() if compiled is not None else compile_persona()
    df["id"] = stata_str(df["id"])
    df["folio"] = stata_str(df["folio"])

    t = to_numeric(df["t"])
    depto = to_numeric(df["depto"])
    aux = pd.Series(0, index=df.index)

    provincia = to_numeric(df["provincia"]) if "provincia" in df.columns else pd.Series(np.nan, index=df.index)
    seccion = to_numeric(df["seccion"]) if "seccion" in df.columns else pd.Series(np.nan, index=df.index)
    provincia15 = df["provincia15"].astype("string") if "provincia15" in df.columns else pd.Series(pd.NA, index=df.index, dtype="string")
    seccion15 = df["seccion15"].astype("string") if "seccion15" in df.columns else pd.Series(pd.NA, index=df.index, dtype="string")
    provincia16 = df["provincia16"] if "provincia16" in df.columns else pd.Series(pd.NA, index=df.index)
    seccion16 = df["seccion16"] if "seccion16" in df.columns else pd.Series(pd.NA, index=df.index)
    prov = df["prov"].astype("string") if "prov" in df.columns else pd.Series(pd.NA, index=df.index, dtype="string")
    mun = df["mun"].astype("string") if "mun" in df.columns else pd.Series(pd.NA, index=df.index, dtype="string")

    mask_1213_lt10 = provincia.lt(10) & inrange(t, 2012, 2013)
    mask_1213_ge10 = provincia.ge(10) & inrange(t, 2012, 2013)
    mask_2015 = t.eq(2015)
    mask_2016 = t.eq(2016)
    mask_2014 = t.eq(2014)

    # egen if is stricter than replace if for 2015: blank provincia15/seccion15
    # leave aux3 missing, then replace copies that missing onto all t==2015 rows.
    aux1 = _concat_code(depto, aux, provincia, where=mask_1213_lt10)
    aux2 = _concat_code(depto, provincia, where=mask_1213_ge10)
    aux3 = _concat_code(
        depto, provincia15, where=mask_2015 & _stata_str_ne_empty(provincia15)
    )
    aux5 = _concat_code(depto, provincia16, where=mask_2016)

    cod_prov = pd.Series(" ", index=df.index, dtype="string")
    cod_prov = replace_where(cod_prov, aux1, mask_1213_lt10)
    cod_prov = replace_where(cod_prov, aux2, mask_1213_ge10)
    cod_prov = replace_where(cod_prov, aux3, mask_2015)
    cod_prov = replace_where(cod_prov, aux5, mask_2016)
    cod_prov = replace_where(cod_prov, prov, mask_2014)

    mask_secc_lt10 = seccion.lt(10) & inrange(t, 2012, 2013)
    mask_secc_ge10 = seccion.ge(10) & inrange(t, 2012, 2013)
    sec_aux1 = _concat_code(cod_prov, aux, seccion, where=mask_secc_lt10)
    sec_aux2 = _concat_code(cod_prov, seccion, where=mask_secc_ge10)
    sec_aux3 = _concat_code(
        cod_prov, seccion15, where=mask_2015 & _stata_str_ne_empty(seccion15)
    )
    sec_aux5 = _concat_code(cod_prov, seccion16, where=mask_2016)

    cod_secc = pd.Series(" ", index=df.index, dtype="string")
    cod_secc = replace_where(cod_secc, sec_aux1, mask_secc_lt10)
    cod_secc = replace_where(cod_secc, sec_aux2, mask_secc_ge10)
    cod_secc = replace_where(cod_secc, sec_aux3, mask_2015)
    cod_secc = replace_where(cod_secc, sec_aux5, mask_2016)
    cod_secc = replace_where(cod_secc, mun, mask_2014)

    df["cod_prov"] = to_numeric(cod_prov)
    df["cod_secc"] = to_numeric(cod_secc)
    df["depto"] = to_numeric(df["depto"])

    drop_cols = [
        "provincia15",
        "seccion15",
        "mun",
        "prov",
        "provincia",
        "seccion",
        "prov_name",
        "secc_name",
        "I02_DEPTO",
        "provincia16",
        "seccion16",
    ]
    df = df.drop(columns=[c for c in drop_cols if c in df.columns], errors="ignore")

    # Work variables
    age = to_numeric(df["age"])
    work = to_numeric(df["work"])
    work2 = work.copy()
    work2 = replace_where(work2, 0.0, age.ge(7) & work.isna())
    df["work2"] = work2

    participa = pd.Series(np.nan, index=df.index, dtype="float64")
    participa = replace_where(participa, 1.0, work.eq(1))
    participa = replace_where(participa, 0.0, age.ge(7) & work.isna())
    # later: replace participa=1 if work==0
    participa = replace_where(participa, 1.0, work.eq(0))
    df["participa"] = participa

    ytrabajo = to_numeric(df["ytrabajo"])
    ytotal = to_numeric(df["ytotal"])
    ytrabajo2 = ytrabajo.fillna(0)
    ytotal2 = ytotal.fillna(0)
    df["ytrabajo2"] = ytrabajo2
    df["ytotal2"] = ytotal2

    ocu_cat2 = to_numeric(df["ocu_cat2"])
    wage_worker = pd.Series(np.nan, index=df.index, dtype="float64")
    wage_worker = replace_where(wage_worker, 1.0, inlist(ocu_cat2, [1, 3]))
    wage_worker = replace_where(
        wage_worker, 0.0, inlist(ocu_cat2, [2, 4]) | work2.eq(0)
    )
    df["wage_worker"] = wage_worker

    hours_day = to_numeric(df["hours_worked_day"])
    days_week = to_numeric(df["days_worked_week"])
    df = df.rename(columns={"hours_worked_day": "hours_day", "days_worked_week": "days_week"})
    hours_week = hours_day * days_week
    hours_week = replace_where(hours_week, 0.0, hours_day.isna() & age.ge(7))
    hours_week = replace_where(hours_week, 0.0, work2.eq(0))
    df["hours_day"] = hours_day
    df["days_week"] = days_week
    df["hours_week"] = hours_week

    df["wage_hour"] = ytrabajo / (hours_week * 4.33)

    unpaid = pd.Series(np.nan, index=df.index, dtype="float64")
    unpaid = replace_where(unpaid, 1.0, inlist(ocu_cat2, [4]))
    unpaid = replace_where(unpaid, 0.0, work2.eq(0) | inlist(ocu_cat2, [1, 2, 3]))
    df["unpaid_worker"] = unpaid

    self_emp = pd.Series(np.nan, index=df.index, dtype="float64")
    self_emp = replace_where(self_emp, 1.0, ocu_cat2.eq(2))
    self_emp = replace_where(self_emp, 0.0, work2.eq(0) | inlist(ocu_cat2, [1, 3, 4]))
    df["self_employed"] = self_emp

    # number_workers categories
    nw = to_numeric(df["number_workers"])
    nwc = pd.Series(np.nan, index=df.index, dtype="float64")
    nwc = replace_where(nwc, 1.0, nw.eq(1) & nwc.isna())
    nwc = replace_where(nwc, 2.0, inrange(nw, 2, 4) & nwc.isna())
    nwc = replace_where(nwc, 3.0, inrange(nw, 5, 9) & nwc.isna())
    nwc = replace_where(nwc, 4.0, inrange(nw, 10, 14) & nwc.isna())
    nwc = replace_where(nwc, 5.0, inrange(nw, 15, 19) & nwc.isna())
    nwc = replace_where(nwc, 6.0, inrange(nw, 20, 49) & nwc.isna())
    nwc = replace_where(nwc, 7.0, inrange(nw, 50, 99) & nwc.isna())
    nwc = replace_where(nwc, 8.0, inrange(nw, 100, 500000) & nw.notna() & nwc.isna())
    nwc = replace_where(nwc, 9.0, nw.eq(888888) & nwc.isna())
    df["number_workers_cat"] = nwc
    df["number_workers"] = nw.where(nw != 888888)

    # place_taxes from places_taxes / places_taxes2
    if "places_taxes" in df.columns:
        place_taxes = to_numeric(df["places_taxes"])
    else:
        place_taxes = pd.Series(np.nan, index=df.index, dtype="float64")
    if "places_taxes2" in df.columns:
        place_taxes = to_numeric(df["places_taxes2"])
    df["place_taxes"] = place_taxes
    df = df.drop(columns=[c for c in df.columns if c.startswith("places_taxes")], errors="ignore")

    ocu_cat = to_numeric(df["ocu_cat"])
    ocu_cat = replace_where(ocu_cat, 9.0, work2.eq(0) & age.ge(7))
    ocu_cat2 = replace_where(ocu_cat2, 5.0, work2.eq(0) & age.ge(7))
    df["ocu_cat"] = ocu_cat
    df["ocu_cat2"] = ocu_cat2

    # Household characteristics
    folio = df["folio"]
    rel = to_numeric(df["rel_jefe"])
    sex = to_numeric(df["sex"])
    esc = to_numeric(df["esc"])
    idioma = to_numeric(df["idioma"])

    g = df.groupby([folio, t], sort=False)

    aux_cpropia = ((ocu_cat.eq(2) & rel.eq(1)).astype(float)).where(ocu_cat.eq(2) & rel.eq(1), other=np.nan)
    # Stata: gen aux=1 if cond; egen total — missing treated as 0 in total? 
    # egen total of 1/missing: missing ignored, so count of heads who are self-employed category...
    # Actually gen aux_cpropia=1 if ocu_cat==2 & rel_jefe==1 → else missing
    # egen total → sum of nonmissing → count of such people
    aux_cpropia = np.where(ocu_cat.eq(2) & rel.eq(1), 1.0, np.nan)
    aux_cpropia2 = pd.Series(aux_cpropia, index=df.index).groupby([folio, t]).transform("sum")
    # sum of all-NaN group is 0 in pandas with min_count? default sum of empty is 0
    head_selfemp = (aux_cpropia2 > 0).astype(float)
    df["head_selfemp"] = head_selfemp

    aux_w = ytotal2.where(age.ge(18))
    df["adult_earnings"] = aux_w.groupby([folio, t]).transform("sum")

    aux_esc = esc.where(rel.eq(1))
    df["head_schooling"] = aux_esc.groupby([folio, t]).transform("sum")

    df["n_household"] = pd.Series(1, index=df.index).groupby([folio, t]).transform("sum")
    df["n_female"] = sex.eq(2).astype(float).groupby([folio, t]).transform("sum")
    df["n_male"] = sex.eq(1).astype(float).groupby([folio, t]).transform("sum")

    age_bins = [
        (0, 5, "n_0_5"),
        (6, 13, "n_6_13"),
        (14, 17, "n_14_17"),
        (18, 25, "n_18_25"),
        (26, 35, "n_26_35"),
        (36, 45, "n_36_45"),
        (46, 55, "n_46_55"),
        (56, 65, "n_56_65"),
    ]
    for lo, hi, name in age_bins:
        df[name] = inrange(age, lo, hi).astype(float).groupby([folio, t]).transform("sum")
    df["n_65_more"] = age.gt(65).astype(float).groupby([folio, t]).transform("sum")

    aux = np.where(rel.eq(1) & work.eq(1), 1.0, np.nan)
    df["head_works"] = pd.Series(aux, index=df.index).groupby([folio, t]).transform("sum")

    aux = np.where(ocu_cat2.eq(2), 1.0, np.nan)
    any_business = pd.Series(aux, index=df.index).groupby([folio, t]).transform("sum")
    any_business = any_business.fillna(0)
    any_business = (any_business > 0).astype(float)
    df["any_business"] = any_business

    aux = pd.Series(np.nan, index=df.index, dtype="float64")
    aux = replace_where(aux, 1.0, sex.eq(1) & rel.eq(1))
    aux = replace_where(aux, 0.0, sex.eq(2) & rel.eq(1))
    df["head_male"] = aux.groupby([folio, t]).transform("sum")

    aux = age.where(rel.eq(1))
    df["head_age"] = aux.groupby([folio, t]).transform("sum")

    aux = np.where(rel.eq(1) & idioma.eq(3), 1.0, np.nan)
    df["head_spanish"] = pd.Series(aux, index=df.index).groupby([folio, t]).transform("sum")

    # Personal characteristics
    age_cat = pd.Series(np.nan, index=df.index, dtype="float64")
    age_cat = replace_where(age_cat, 1.0, inrange(age, 0, 5))
    age_cat = replace_where(age_cat, 2.0, inrange(age, 6, 13))
    age_cat = replace_where(age_cat, 3.0, inrange(age, 14, 17))
    age_cat = replace_where(age_cat, 4.0, inrange(age, 18, 25))
    age_cat = replace_where(age_cat, 5.0, inrange(age, 26, 35))
    age_cat = replace_where(age_cat, 6.0, inrange(age, 36, 45))
    age_cat = replace_where(age_cat, 7.0, inrange(age, 46, 55))
    age_cat = replace_where(age_cat, 8.0, inrange(age, 56, 65))
    age_cat = replace_where(age_cat, 9.0, age.gt(65))
    df["age_cat"] = age_cat

    df = df.rename(columns={"idioma": "language_childhood"})
    language_childhood = to_numeric(df["language_childhood"])
    pueblo = to_numeric(df["pueblo"]) if "pueblo" in df.columns else pd.Series(np.nan, index=df.index)
    indigenous = pd.Series(np.nan, index=df.index, dtype="float64")
    indigenous = replace_where(indigenous, 1.0, inlist(pueblo, [1, 2, 3]))
    indigenous = replace_where(indigenous, 0.0, pueblo.eq(0))
    df["indigenous"] = indigenous
    # replace pueblo=. if inlist(t,2017,2015,2014); drop pueblo
    df = df.drop(columns=["pueblo"], errors="ignore")

    spanish = pd.Series(np.nan, index=df.index, dtype="float64")
    spanish = replace_where(spanish, 1.0, language_childhood.eq(3))
    spanish = replace_where(spanish, 0.0, inlist(language_childhood, [0, 1, 2, 4, 5, 6, 7]))
    df["spanish"] = spanish
    df["language_childhood"] = language_childhood.where(language_childhood != 0)

    male = pd.Series(np.nan, index=df.index, dtype="float64")
    male = replace_where(male, 1.0, sex.eq(1))
    male = replace_where(male, 0.0, sex.eq(2))
    df["male"] = male
    df = df.drop(columns=["sex"], errors="ignore")

    area = to_numeric(df["area"]) if "area" in df.columns else pd.Series(np.nan, index=df.index)
    urban = pd.Series(np.nan, index=df.index, dtype="float64")
    urban = replace_where(urban, 1.0, area.eq(1))
    urban = replace_where(urban, 0.0, area.eq(2))
    df["urban"] = urban
    df = df.drop(columns=["area"], errors="ignore")

    by = to_numeric(df["birth_year"])
    bm = to_numeric(df["birth_month"])
    bd = to_numeric(df["birth_day"])
    by = by.where(by <= 2100)
    bm = bm.where(bm <= 12)
    # Faithful Stata typo: replace birth_day=. if birth_month>31
    bd = bd.where(~(bm > 31))
    df["birth_year"] = by
    df["birth_month"] = bm
    df["birth_day"] = bd

    if "recibe_bono_juancito" in df.columns:
        bono = to_numeric(df["recibe_bono_juancito"])
        bono = replace_where(bono, 0.0, bono.isna() & inrange(t, 2007, 2018))
        df["recibe_bono_juancito"] = bono
    if "recibe_desayuno" in df.columns:
        des = to_numeric(df["recibe_desayuno"])
        des = replace_where(des, 0.0, des.isna() & (inrange(t, 2008, 2018) | t.eq(2004)))
        df["recibe_desayuno"] = des
    if "enrollment" in df.columns:
        df["enrollment"] = to_numeric(df["enrollment"]).fillna(0)
    if "lee_escribe" in df.columns:
        df["lee_escribe"] = to_numeric(df["lee_escribe"]).fillna(0)
    if "suma_multiplica" in df.columns:
        sm = to_numeric(df["suma_multiplica"])
        sm = replace_where(sm, 0.0, sm.isna() & inrange(t, 2016, 2018))
        df["suma_multiplica"] = sm

    rename_map = {
        "esc": "schooling",
        "factor": "f_weight",
        "ytrabajo": "ylabor",
        "ytrabajo2": "ylabor2",
        "yhogar": "yhousehold",
        "yhogarpc": "ypc",
        "work": "employed",
        "work2": "works",
        "participa": "lf_participation",
        "estudia": "attendance",
        "lee_escribe": "reads",
        "rel_jefe": "rel_head",
        "idioma_nativo": "native_language",
        "enrollment": "enrolled",
        "suma_multiplica": "basic_math",
        "nocturna": "night_education",
        "recibe_desayuno": "receives_breakfast",
        "recibe_bono_juancito": "receives_cct_juancito",
        "place_taxes": "firm_taxes",
    }
    df = df.rename(columns={k: v for k, v in rename_map.items() if k in df.columns})

    # Winsor high p=0.01
    for x in [
        "hours_day",
        "days_week",
        "hours_week",
        "ytotal",
        "ylabor",
        "yhousehold",
        "ypc",
        "wage_hour",
    ]:
        if x in df.columns:
            df[f"{x}_w"] = winsor_high(df[x], p=0.01)

    df["year"] = t
    df["year2"] = t
    df["id_year"] = stata_str(df["year"]) + stata_str(df["id"])
    df["folio_year"] = stata_str(df["year"]) + stata_str(df["folio"])

    # income rename *_c
    for old, new in [
        ("ytotal", "ytotal_c"),
        ("ylabor", "ylabor_c"),
        ("yhousehold", "yhousehold_c"),
        ("ypc", "ypc_c"),
        ("ytotal2", "ytotal2_c"),
        ("ylabor2", "ylabor2_c"),
    ]:
        if old in df.columns:
            df = df.rename(columns={old: new})

    # collection dates
    for src, dst in [
        ("encuesta_dia", "collection_day"),
        ("encuesta_mes", "collection_month"),
        ("encuesta_ano", "collection_year"),
    ]:
        if src in df.columns:
            df = df.rename(columns={src: dst})
        elif dst not in df.columns:
            df[dst] = np.nan

    cm = to_numeric(df["collection_month"]) if "collection_month" in df.columns else pd.Series(np.nan, index=df.index)
    cy = to_numeric(df["collection_year"]) if "collection_year" in df.columns else pd.Series(np.nan, index=df.index)
    cm = replace_where(cm, 12.0, inlist(cm, [1, 2]))
    df["collection_month"] = cm
    df["collection_year"] = cy

    aux_min = cm.groupby(cy).transform("min")
    aux_max = cm.groupby(cy).transform("max")
    start = aux_min.where(aux_min.notna())
    end = aux_max.where(aux_max.notna())
    year = to_numeric(df["year"])
    start = replace_where(start, 12.0, year.eq(2078))  # faithful Stata typo
    start = replace_where(start, 11.0, year.eq(2015))
    start = replace_where(start, 10.0, inlist(year, [2012, 2017, 2019]))
    end = replace_where(end, 11.0, inlist(year, [2012, 2015]))
    end = replace_where(end, 12.0, inlist(year, [2017, 2018, 2019]))
    df["collection_month_start"] = start
    df["collection_month_end"] = end

    # Drop any leftover date_collection* if present
    df = df.drop(columns=[c for c in df.columns if c.startswith("date_collection")], errors="ignore")

    return df


def write_compiled_persona(out_path: Path | None = None) -> Path:
    out_path = out_path or (paths.INTERMEDIATE / "persona" / "EH_compiled_persona.parquet")
    df = compile_persona()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    return out_path


def write_cleaned_persona(out_path: Path | None = None) -> Path:
    out_path = out_path or (paths.INTERMEDIATE / "persona" / "EH_cleaned_persona.parquet")
    compiled_path = paths.INTERMEDIATE / "persona" / "EH_compiled_persona.parquet"
    if compiled_path.exists():
        compiled = pd.read_parquet(compiled_path)
    else:
        compiled = compile_persona()
        compiled_path.parent.mkdir(parents=True, exist_ok=True)
        compiled.to_parquet(compiled_path, index=False)
    df = clean_persona(compiled)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(out_path, index=False)
    return out_path
