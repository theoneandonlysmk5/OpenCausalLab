"""2014 Persona harmonization — EH_Persona_2014.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from opencausallab.stata_semantics.stata_utils import inlist, inrange, replace_where, stata_str, to_numeric
from .common import (
    binary_01,
    make_incomes,
    make_ocu_cat2,
    map_sector_from_caeb,
    select_keep,
)

PERSONA_2014_KEEP = [
    "id",
    "folio",
    "depto",
    "area",
    "sex",
    "age",
    "civil_status",
    "estudia",
    "lee_escribe",
    "esc",
    "enrollment",
    "level_enrolled",
    "enrolled_public",
    "work",
    "work_lastweek",
    "ocu_cat",
    "sector",
    "hours_worked_day",
    "days_worked_week",
    "ytotal",
    "ytrabajo",
    "yhogar",
    "yhogarpc",
    "factor",
    "t",
    "upm",
    "rel_jefe",
    "idioma",
    "idioma_nativo",
    "birth_day",
    "birth_month",
    "birth_year",
    "pueblo",
    "ocu_cat2",
    "mun",
    "prov",
    "job_location",
    "number_workers",
    "places_taxes2",
    "contract",
    "type_est",
    "encuesta_ano",
    "encuesta_mes",
    "encuesta_dia",
    "poor",
    "poor_xtr",
    "pov_line",
    "pov_xtr_line",
    "recibe_desayuno",
    "recibe_bono_juancito",
    "nocturna",
    "health_insurance",
    "job_main_ocupation",
    "job_specifics_tasks",
    "s5c_13",
    "s5c_14",
    "s5c_15",
    "s5c_16",
]

_ENCODE_NATIVE_CODES = [3, 5, 8, 10, 11, 14, 15, 16, 19, 20, 22, 23]


def _stata_encode(series: pd.Series) -> pd.Series:
    """Approximate Stata ``encode``: alphabetical codes starting at 1."""
    s = series.astype("string")
    levels = sorted({v for v in s.dropna().unique() if v != ""})
    mapping = {v: i + 1 for i, v in enumerate(levels)}
    return s.map(mapping).astype("float64")


def _load_merged_2014(
    persona_path: Path | None = None,
    vivienda_path: Path | None = None,
) -> pd.DataFrame:
    vivienda_path = vivienda_path or paths.raw_household_vivienda(2014)
    persona_path = persona_path or paths.raw_household_persona(2014)
    import pyreadstat
    viv, _ = pyreadstat.read_dta(str(vivienda_path))
    viv = viv[["folio", "ano", "mes", "dia"]].copy()
    viv = viv.rename(
        columns={"ano": "encuesta_ano", "mes": "encuesta_mes", "dia": "encuesta_dia"}
    )
    from .common import read_dta

    persona = read_dta(persona_path)
    viv = viv.assign(folio=stata_str(viv["folio"]))
    persona = persona.assign(folio=stata_str(persona["folio"]))
    return persona.merge(viv, on="folio", how="left")


def harmonize_persona_2014(raw_path: Path | None = None) -> pd.DataFrame:
    df = _load_merged_2014(persona_path=raw_path)

    folio = stata_str(df["folio"])
    nro = stata_str(df["nro"])
    out = pd.DataFrame({"folio": folio, "id": folio + nro})
    out = pd.concat([out, make_incomes(df)], axis=1)

    out["sex"] = to_numeric(df["s2a_02"])
    out["age"] = to_numeric(df["s2a_03"])
    out["esc"] = to_numeric(df["e"])
    civil = to_numeric(df["s2a_10"])
    out["civil_status"] = civil.where(civil != 9)
    out["depto"] = to_numeric(df["depto"])
    out["factor"] = to_numeric(df["factor"])
    out["upm"] = stata_str(df["upm"])
    out["t"] = 2014
    out["encuesta_ano"] = to_numeric(df["encuesta_ano"])
    out["encuesta_mes"] = to_numeric(df["encuesta_mes"])
    out["encuesta_dia"] = to_numeric(df["encuesta_dia"])
    out["mun"] = df["mun"] if "mun" in df.columns else np.nan
    # Stata: destring prov; tostring prov
    out["prov"] = stata_str(to_numeric(df["prov"]))

    urbrur = to_numeric(df["urbrur"])
    area = pd.Series(np.nan, index=df.index, dtype="float64")
    area = replace_where(area, 1.0, urbrur.eq(1))
    area = replace_where(area, 2.0, urbrur.eq(2))
    out["area"] = area

    s6a_01 = to_numeric(df["s6a_01"])
    s6a_02 = to_numeric(df["s6a_02"])
    s6a_03 = to_numeric(df["s6a_03"])
    s6a_05 = to_numeric(df["s6a_05"])
    s6a_10 = to_numeric(df["s6a_10"])
    pet = to_numeric(df["pet"])
    work = pd.Series(np.nan, index=df.index, dtype="float64")
    work = replace_where(work, 1.0, s6a_01.eq(1))
    work = replace_where(work, 1.0, inrange(s6a_02, 1, 6))
    work = replace_where(work, 1.0, inrange(s6a_03, 1, 6))
    work = replace_where(work, 0.0, pet.eq(1) & (s6a_05.eq(1) | s6a_10.eq(1)))
    out["work"] = work
    work_lastweek = s6a_01.copy()
    out["work_lastweek"] = replace_where(work_lastweek, 0.0, work_lastweek.eq(2))

    ocu_cat = to_numeric(df["s6b_16"])
    out["ocu_cat"] = ocu_cat
    out["ocu_cat2"] = make_ocu_cat2(ocu_cat)

    s6b_23m = to_numeric(df["s6b_23m"]).fillna(0)
    out["hours_worked_day"] = to_numeric(df["s6b_23h"]) + s6b_23m / 60.0
    out["days_worked_week"] = to_numeric(df["s6b_22"])

    s6b_19 = to_numeric(df["s6b_19"])
    job_location = pd.Series(np.nan, index=df.index, dtype="float64")
    job_location = replace_where(job_location, 1.0, s6b_19.eq(1))
    job_location = replace_where(job_location, 2.0, s6b_19.eq(2))
    job_location = replace_where(job_location, 3.0, inlist(s6b_19, [3, 4, 5, 6, 7, 8]))
    job_location = replace_where(job_location, 4.0, inlist(s6b_19, [0, 9]))
    job_location = replace_where(
        job_location, 5.0, out["age"].ge(7) & job_location.isna()
    )
    out["job_location"] = job_location

    s5a_04 = to_numeric(df["s5a_04"])
    enrollment = pd.Series(np.nan, index=df.index, dtype="float64")
    enrollment = replace_where(enrollment, 1.0, s5a_04.eq(1))
    enrollment = replace_where(enrollment, 0.0, s5a_04.eq(2))
    out["enrollment"] = enrollment

    s5a_05 = to_numeric(df["s5a_05"])
    s5a_05a = to_numeric(df["s5a_05a"])
    level_enrolled = pd.Series(np.nan, index=df.index, dtype="float64")
    level_enrolled = replace_where(level_enrolled, 1.0, s5a_05.eq(41) & s5a_05a.eq(1))
    for i in range(2, 7):
        level_enrolled = replace_where(
            level_enrolled, float(i), s5a_05.eq(41) & s5a_05a.eq(i)
        )
    for i in range(1, 7):
        level_enrolled = replace_where(
            level_enrolled, float(6 + i), s5a_05.eq(42) & s5a_05a.eq(i)
        )
    out["level_enrolled"] = level_enrolled

    s5a_09 = to_numeric(df["s5a_09"])
    out["enrolled_public"] = s5a_09.eq(1).astype(float).where(s5a_09.notna())

    estudia = pd.Series(0.0, index=df.index)
    estudia = replace_where(estudia, 1.0, to_numeric(df["s5b_10"]).eq(1))
    estudia = replace_where(estudia, 1.0, to_numeric(df["s5b_11"]).eq(1))
    out["estudia"] = estudia
    out["lee_escribe"] = binary_01(df["s5a_01"])

    s5a_07 = to_numeric(df["s5a_07"])
    desayuno = pd.Series(np.nan, index=df.index, dtype="float64")
    desayuno = replace_where(desayuno, 1.0, inlist(s5a_07, [1, 2]))
    desayuno = replace_where(desayuno, 0.0, s5a_07.eq(3))
    out["recibe_desayuno"] = desayuno
    out["recibe_bono_juancito"] = binary_01(df["s5a_08"])
    out["nocturna"] = inlist(s5a_05, [12, 61, 62, 63, 64]).astype(float)

    s2a_05 = to_numeric(df["s2a_05"])
    rel = pd.Series(np.nan, index=df.index, dtype="float64")
    rel = replace_where(rel, s2a_05, s2a_05.le(4))
    rel = replace_where(rel, 5.0, s2a_05.eq(8))
    rel = replace_where(rel, 6.0, s2a_05.eq(5))
    rel = replace_where(rel, 7.0, inlist(s2a_05, [6, 7]))
    rel = replace_where(rel, 8.0, s2a_05.gt(8))
    out["rel_jefe"] = rel

    s2a_08 = df["s2a_08"].astype("string").fillna("").str.strip()
    idioma = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma = replace_where(idioma, 1.0, s2a_08.eq("QUECHUA"))
    idioma = replace_where(idioma, 2.0, s2a_08.eq("AYMARA"))
    idioma = replace_where(idioma, 3.0, s2a_08.eq("CASTELLANO"))
    idioma = replace_where(idioma, 4.0, s2a_08.eq("GUARAN"))
    idioma = replace_where(idioma, 6.0, s2a_08.eq("IDIOMA EXTRANJERO"))
    idioma = replace_where(idioma, 7.0, s2a_08.eq("99"))
    idioma = replace_where(idioma, 5.0, s2a_08.ne("") & idioma.isna())
    out["idioma"] = idioma

    cod_a = _stata_encode(df["s2a_07a"])
    cod_b = _stata_encode(df["s2a_07b"])
    cod_c = _stata_encode(df["s2a_07c"])
    idioma_nativo = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(idioma, [1, 2, 4, 5]))
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(cod_a, _ENCODE_NATIVE_CODES))
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(cod_b, _ENCODE_NATIVE_CODES))
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(cod_c, _ENCODE_NATIVE_CODES))
    idioma_nativo = replace_where(idioma_nativo, 0.0, idioma_nativo.isna())
    out["idioma_nativo"] = idioma_nativo

    out["birth_day"] = to_numeric(df["s2a_04a"])
    out["birth_month"] = to_numeric(df["s2a_04b"])
    out["birth_year"] = to_numeric(df["s2a_04c"])

    s3a_02a = to_numeric(df["s3a_02a"])
    pueblo = pd.Series(np.nan, index=df.index, dtype="float64")
    pueblo = replace_where(pueblo, 1.0, s3a_02a.eq(1))
    pueblo = replace_where(pueblo, 0.0, s3a_02a.eq(2))
    out["pueblo"] = pueblo

    out["sector"] = map_sector_from_caeb(df["caeb_op"])
    out["number_workers"] = to_numeric(df["s6b_20"])

    s6b_17 = to_numeric(df["s6b_17"])
    type_est = pd.Series(np.nan, index=df.index, dtype="float64")
    type_est = replace_where(type_est, 1.0, inlist(s6b_17, [3, 4]))
    type_est = replace_where(type_est, 2.0, inlist(s6b_17, [1, 2]))
    type_est = replace_where(type_est, 3.0, inlist(s6b_17, [5, 6]))
    out["type_est"] = type_est

    s6b_18 = to_numeric(df["s6b_18"])
    places_taxes2 = pd.Series(np.nan, index=df.index, dtype="float64")
    places_taxes2 = replace_where(places_taxes2, 1.0, inlist(s6b_18, [1, 2]))
    places_taxes2 = replace_where(places_taxes2, 2.0, inlist(s6b_18, [3]))
    places_taxes2 = replace_where(places_taxes2, 3.0, inlist(s6b_18, [4]))
    out["places_taxes2"] = places_taxes2

    s6b_21 = to_numeric(df["s6b_21"])
    contract = pd.Series(np.nan, index=df.index, dtype="float64")
    contract = replace_where(contract, s6b_21, inlist(s6b_21, [1, 2, 3]))
    contract = replace_where(contract, 4.0, s6b_21.eq(5))
    contract = replace_where(contract, 5.0, s6b_21.eq(4))
    out["contract"] = contract

    out["poor"] = to_numeric(df["p0"]).eq(1).astype(float)
    out["pov_line"] = to_numeric(df["z"])
    out["poor_xtr"] = to_numeric(df["pext0"]).eq(1).astype(float)
    out["pov_xtr_line"] = to_numeric(df["zext"])

    out["job_main_ocupation"] = df["s6b_11ad"]
    out["job_specifics_tasks"] = df["s6b_11b"]
    out["health_insurance"] = to_numeric(df["s6c_29b"]).replace({2: 0})

    for col in ["s5c_13", "s5c_14", "s5c_15", "s5c_16"]:
        out[col] = df[col] if col in df.columns else np.nan

    return select_keep(out, PERSONA_2014_KEEP)
