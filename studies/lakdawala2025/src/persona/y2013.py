"""2013 Persona harmonization — EH_Persona_2013.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import pyreadstat

from .. import paths
from core.stata_semantics.stata_utils import inlist, inrange, replace_where, stata_str, to_numeric
from .common import (
    binary_01,
    make_incomes,
    make_ocu_cat2,
    map_sector_from_caeb,
    select_keep,
)

PERSONA_2013_KEEP = [
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
]

_NATIVE_LANG_CODES = [
    "002",
    "004",
    "007",
    "039",
    "012",
    "018",
    "020",
    "024",
    "027",
    "029",
    "034",
]


def _load_merged_2013(
    persona_path: Path | None = None,
    vivienda_path: Path | None = None,
) -> pd.DataFrame:
    vivienda_path = vivienda_path or paths.raw_household_vivienda(2013)
    persona_path = persona_path or paths.raw_household_persona(2013)
    viv, _ = pyreadstat.read_dta(str(vivienda_path))
    viv = viv[["folio", "c_mes", "c_dia"]].copy()
    viv["encuesta_ano"] = 2013
    viv = viv.rename(columns={"c_mes": "encuesta_mes", "c_dia": "encuesta_dia"})
    persona, _ = pyreadstat.read_dta(str(persona_path))
    # Stata merge 1:m on folio; keep person rows (matched + persona-only if any)
    folio_viv = stata_str(viv["folio"])
    folio_per = stata_str(persona["folio"])
    viv = viv.assign(folio=folio_viv)
    persona = persona.assign(folio=folio_per)
    return persona.merge(viv, on="folio", how="left")


def harmonize_persona_2013(raw_path: Path | None = None) -> pd.DataFrame:
    df = _load_merged_2013(persona_path=raw_path)

    folio = stata_str(df["folio"])
    nro = stata_str(df["nro2a"])
    out = pd.DataFrame({"folio": folio, "id": folio + nro})
    out = pd.concat([out, make_incomes(df)], axis=1)

    out["sex"] = to_numeric(df["s2_02"])
    out["age"] = to_numeric(df["s2_03"])
    out["civil_status"] = to_numeric(df["s2_10"])
    esc = to_numeric(df["e"])
    out["esc"] = esc.where(esc != 99)
    out["area"] = to_numeric(df["area"])
    out["factor"] = to_numeric(df["factor"])
    out["depto"] = to_numeric(df["id01"])
    out["t"] = 2013
    out["upm"] = to_numeric(df["upm"])
    out["encuesta_ano"] = to_numeric(df["encuesta_ano"])
    out["encuesta_mes"] = to_numeric(df["encuesta_mes"])
    out["encuesta_dia"] = to_numeric(df["encuesta_dia"])

    # Work
    s6_01 = to_numeric(df["s6_01"])
    s6_02 = to_numeric(df["s6_02"])
    s6_03 = to_numeric(df["s6_03"])
    s6_05 = to_numeric(df["s6_05"])
    s6_10 = to_numeric(df["s6_10"])
    pet = to_numeric(df["pet"])
    work = pd.Series(np.nan, index=df.index, dtype="float64")
    work = replace_where(work, 1.0, s6_01.eq(1))
    work = replace_where(work, 1.0, inrange(s6_02, 1, 6))
    work = replace_where(work, 1.0, inrange(s6_03, 1, 5))
    work = replace_where(work, 0.0, pet.eq(1) & (s6_05.eq(1) | s6_10.eq(1)))
    out["work"] = work
    work_lastweek = s6_01.copy()
    out["work_lastweek"] = replace_where(work_lastweek, 0.0, work_lastweek.eq(2))

    ocu_cat = to_numeric(df["s6_16"])
    out["ocu_cat"] = ocu_cat
    out["ocu_cat2"] = make_ocu_cat2(ocu_cat)

    out["hours_worked_day"] = to_numeric(df["s6_23h"]) + to_numeric(df["s6_23m"]) / 60.0
    out["days_worked_week"] = to_numeric(df["s6_22"])

    s6_19 = to_numeric(df["s6_19"])
    job_location = pd.Series(np.nan, index=df.index, dtype="float64")
    job_location = replace_where(job_location, 1.0, s6_19.eq(1))
    job_location = replace_where(job_location, 2.0, s6_19.eq(2))
    job_location = replace_where(job_location, 3.0, inlist(s6_19, [3, 4, 5, 6, 7]))
    job_location = replace_where(job_location, 4.0, inlist(s6_19, [8]))
    job_location = replace_where(
        job_location, 5.0, out["age"].ge(7) & job_location.isna()
    )
    out["job_location"] = job_location

    s5_04 = to_numeric(df["s5_04"])
    enrollment = pd.Series(np.nan, index=df.index, dtype="float64")
    enrollment = replace_where(enrollment, 1.0, s5_04.eq(1))
    enrollment = replace_where(enrollment, 0.0, s5_04.eq(2))
    out["enrollment"] = enrollment

    s5_05a = to_numeric(df["s5_05a"])
    s5_05b = to_numeric(df["s5_05b"])
    level_enrolled = pd.Series(np.nan, index=df.index, dtype="float64")
    level_enrolled = replace_where(level_enrolled, 1.0, s5_05a.eq(19) & s5_05b.eq(1))
    for i in range(2, 7):
        level_enrolled = replace_where(
            level_enrolled, float(i), s5_05a.eq(19) & s5_05b.eq(i)
        )
    for i in range(1, 7):
        level_enrolled = replace_where(
            level_enrolled, float(6 + i), s5_05a.eq(20) & s5_05b.eq(i)
        )
    out["level_enrolled"] = level_enrolled

    s5_09 = to_numeric(df["s5_09"])
    out["enrolled_public"] = (s5_09.eq(1) | s5_09.eq(2)).astype(float).where(s5_09.notna())

    estudia = pd.Series(0.0, index=df.index)
    estudia = replace_where(estudia, 1.0, to_numeric(df["s5_10"]).eq(1))
    estudia = replace_where(estudia, 1.0, to_numeric(df["s5_11"]).eq(1))
    out["estudia"] = estudia
    out["lee_escribe"] = binary_01(df["s5_01"])

    s5_07 = to_numeric(df["s5_07"])
    desayuno = pd.Series(np.nan, index=df.index, dtype="float64")
    desayuno = replace_where(desayuno, 1.0, inlist(s5_07, [1, 2]))
    desayuno = replace_where(desayuno, 0.0, s5_07.eq(3))
    out["recibe_desayuno"] = desayuno
    out["recibe_bono_juancito"] = binary_01(df["s5_08"])
    out["nocturna"] = inlist(s5_05a, [12, 61, 62, 63, 64]).astype(float)

    # rel_jefe (2012-style <=4)
    s2_05 = to_numeric(df["s2_05"])
    rel = pd.Series(np.nan, index=df.index, dtype="float64")
    rel = replace_where(rel, s2_05, s2_05.le(4))
    rel = replace_where(rel, 5.0, s2_05.eq(8))
    rel = replace_where(rel, 6.0, s2_05.eq(5))
    rel = replace_where(rel, 7.0, inlist(s2_05, [6, 7]))
    rel = replace_where(rel, 8.0, s2_05.gt(8))
    out["rel_jefe"] = rel

    s2_08 = df["s2_08"].astype("string").fillna("").str.strip()
    idioma = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma = replace_where(idioma, 1.0, s2_08.eq("QUECHUA"))
    idioma = replace_where(idioma, 2.0, s2_08.eq("AYMARA"))
    idioma = replace_where(idioma, 3.0, s2_08.eq("CASTELLANO"))
    idioma = replace_where(idioma, 4.0, s2_08.eq("GUARAN"))
    idioma = replace_where(idioma, 6.0, s2_08.eq("IDIOMA EXTRANJERO"))
    idioma = replace_where(idioma, 7.0, s2_08.eq("99"))
    idioma = replace_where(idioma, 5.0, s2_08.ne("") & idioma.isna())
    out["idioma"] = idioma

    def _code_str(col: str) -> pd.Series:
        return df[col].astype("string").fillna("").str.strip().str.zfill(3)

    idioma_nativo = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(idioma, [1, 2, 4, 5]))
    for col in ["cods2_07a", "cods2_07b", "cods2_07c"]:
        codes = _code_str(col)
        idioma_nativo = replace_where(idioma_nativo, 1.0, codes.isin(_NATIVE_LANG_CODES))
    idioma_nativo = replace_where(idioma_nativo, 0.0, idioma_nativo.isna())
    out["idioma_nativo"] = idioma_nativo

    out["birth_day"] = to_numeric(df["s2_04a"])
    out["birth_month"] = to_numeric(df["s2_04b"])
    out["birth_year"] = to_numeric(df["s2_04c"])

    s3_02a = to_numeric(df["s3_02a"])
    s3_02b = df["s3_02b"].astype("string").fillna("").str.strip()
    pueblo = pd.Series(np.nan, index=df.index, dtype="float64")
    pueblo = replace_where(pueblo, 1.0, s3_02b.eq("QUECHUA"))
    pueblo = replace_where(pueblo, 2.0, s3_02b.eq("AYMARA"))
    pueblo = replace_where(pueblo, 3.0, s3_02a.eq(1) & pueblo.isna())
    pueblo = replace_where(pueblo, 0.0, s3_02a.ne(1))
    out["pueblo"] = pueblo

    out["sector"] = map_sector_from_caeb(df["caeb_op1"])
    out["number_workers"] = to_numeric(df["s6_20"])

    s6_17 = to_numeric(df["s6_17"])
    type_est = pd.Series(np.nan, index=df.index, dtype="float64")
    type_est = replace_where(type_est, 1.0, inlist(s6_17, [2, 3]))
    type_est = replace_where(type_est, 2.0, inlist(s6_17, [1]))
    type_est = replace_where(type_est, 3.0, s6_17.eq(4))
    out["type_est"] = type_est

    s6_18 = to_numeric(df["s6_18"])
    places_taxes2 = pd.Series(np.nan, index=df.index, dtype="float64")
    places_taxes2 = replace_where(places_taxes2, 1.0, inlist(s6_18, [1, 2]))
    places_taxes2 = replace_where(places_taxes2, 2.0, inlist(s6_18, [3]))
    places_taxes2 = replace_where(places_taxes2, 3.0, inlist(s6_18, [4]))
    out["places_taxes2"] = places_taxes2

    s6_21 = to_numeric(df["s6_21"])
    contract = pd.Series(np.nan, index=df.index, dtype="float64")
    contract = replace_where(contract, s6_21, inlist(s6_21, [1, 2, 3]))
    contract = replace_where(contract, 4.0, s6_21.eq(5))
    contract = replace_where(contract, 5.0, s6_21.eq(4))
    out["contract"] = contract

    out["poor"] = to_numeric(df["p0"]).eq(1).astype(float)
    out["pov_line"] = to_numeric(df["z"])
    out["poor_xtr"] = to_numeric(df["pext0"]).eq(1).astype(float)
    out["pov_xtr_line"] = to_numeric(df["zext"])

    out["job_main_ocupation"] = df["s6_11a"]
    out["job_specifics_tasks"] = df["s6_11b"]
    out["health_insurance"] = to_numeric(df["s6_29b"]).replace({2: 0})

    return select_keep(out, PERSONA_2013_KEEP)
