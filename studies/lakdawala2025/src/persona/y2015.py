"""2015 Persona harmonization — EH_Persona_2015.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from core.stata_semantics.stata_utils import inlist, inrange, replace_where, stata_str, to_numeric
from .common import (
    binary_01,
    make_incomes,
    make_ocu_cat2,
    map_sector_from_caeb,
    read_persona,
    select_keep,
)

PERSONA_2015_KEEP = [
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
    "poor",
    "poor_xtr",
    "pov_line",
    "pov_xtr_line",
    "recibe_desayuno",
    "recibe_bono_juancito",
    "health_insurance",
    "nocturna",
    "job_main_ocupation",
    "job_specifics_tasks",
]


def harmonize_persona_2015(raw_path: Path | None = None) -> pd.DataFrame:
    df = read_persona(2015, raw_path)

    folio = stata_str(df["folio"])
    nro = stata_str(df["nro"])
    out = pd.DataFrame({"folio": folio, "id": folio + nro})
    out = pd.concat([out, make_incomes(df)], axis=1)

    out["sex"] = to_numeric(df["s2a_02"])
    out["age"] = to_numeric(df["s2a_03"])
    out["civil_status"] = to_numeric(df["s2a_10"])
    out["esc"] = to_numeric(df["e"])
    out["area"] = to_numeric(df["area"])
    out["factor"] = to_numeric(df["factor"])
    out["upm"] = stata_str(df["upm"])
    out["depto"] = to_numeric(df["departamento"])
    out["t"] = 2015

    s6a_01 = to_numeric(df["s6a_01"])
    s6a_02 = to_numeric(df["s6a_02"])
    s6a_03 = to_numeric(df["s6a_03"])
    s6a_05 = to_numeric(df["s6a_05"])
    s6a_10a = to_numeric(df["s6a_10a"])
    pet = to_numeric(df["pet"])
    work = pd.Series(np.nan, index=df.index, dtype="float64")
    work = replace_where(work, 1.0, s6a_01.eq(1))
    work = replace_where(work, 1.0, inrange(s6a_02, 1, 6))
    work = replace_where(work, 1.0, inrange(s6a_03, 1, 7))
    work = replace_where(work, 0.0, pet.eq(1) & (s6a_05.eq(1) | s6a_10a.eq(1)))
    out["work"] = work
    work_lastweek = s6a_01.copy()
    out["work_lastweek"] = replace_where(work_lastweek, 0.0, work_lastweek.eq(2))

    ocu_cat = to_numeric(df["s6b_16"])
    out["ocu_cat"] = ocu_cat
    out["ocu_cat2"] = make_ocu_cat2(ocu_cat)

    out["hours_worked_day"] = to_numeric(df["s6b_23a"]) + to_numeric(df["s6b_23b"]) / 60.0
    out["days_worked_week"] = to_numeric(df["s6b_22"])

    s6b_20a = to_numeric(df["s6b_20a"])
    job_location = pd.Series(np.nan, index=df.index, dtype="float64")
    job_location = replace_where(job_location, 1.0, s6b_20a.eq(1))
    job_location = replace_where(job_location, 2.0, s6b_20a.eq(2))
    job_location = replace_where(job_location, 3.0, inlist(s6b_20a, [3, 4, 5, 6, 7, 8]))
    job_location = replace_where(job_location, 4.0, inlist(s6b_20a, [9]))
    job_location = replace_where(
        job_location, 5.0, out["age"].ge(7) & job_location.isna()
    )
    out["job_location"] = job_location

    s5a_4 = to_numeric(df["s5a_4"])
    enrollment = pd.Series(np.nan, index=df.index, dtype="float64")
    enrollment = replace_where(enrollment, 1.0, s5a_4.eq(1))
    enrollment = replace_where(enrollment, 0.0, s5a_4.eq(2))
    out["enrollment"] = enrollment

    s5a_5a = to_numeric(df["s5a_5a"])
    s5a_5b = to_numeric(df["s5a_5b"])
    level_enrolled = pd.Series(np.nan, index=df.index, dtype="float64")
    level_enrolled = replace_where(level_enrolled, 1.0, s5a_5a.eq(41) & s5a_5b.eq(1))
    for i in range(2, 7):
        level_enrolled = replace_where(
            level_enrolled, float(i), s5a_5a.eq(41) & s5a_5b.eq(i)
        )
    for i in range(1, 7):
        level_enrolled = replace_where(
            level_enrolled, float(6 + i), s5a_5a.eq(42) & s5a_5b.eq(i)
        )
    out["level_enrolled"] = level_enrolled

    s5a_9 = to_numeric(df["s5a_9"])
    out["enrolled_public"] = s5a_9.eq(1).astype(float).where(s5a_9.notna())

    estudia = pd.Series(0.0, index=df.index)
    estudia = replace_where(estudia, 1.0, to_numeric(df["s5b_10"]).eq(1))
    estudia = replace_where(
        estudia,
        1.0,
        to_numeric(df["s5b_11"]).eq(1) | to_numeric(df["s5b_11a"]).eq(1),
    )
    out["estudia"] = estudia
    out["lee_escribe"] = binary_01(df["s5a_1"])

    s5a_7 = to_numeric(df["s5a_7"])
    desayuno = pd.Series(np.nan, index=df.index, dtype="float64")
    desayuno = replace_where(desayuno, 1.0, inlist(s5a_7, [1, 2]))
    desayuno = replace_where(desayuno, 0.0, s5a_7.eq(3))
    out["recibe_desayuno"] = desayuno
    out["recibe_bono_juancito"] = binary_01(df["s5a_8"])
    out["nocturna"] = inlist(s5a_5a, [12, 61, 62, 63, 64]).astype(float)

    s2a_05 = to_numeric(df["s2a_05"])
    rel = pd.Series(np.nan, index=df.index, dtype="float64")
    rel = replace_where(rel, s2a_05, s2a_05.le(4))
    rel = replace_where(rel, 5.0, s2a_05.eq(8))
    rel = replace_where(rel, 6.0, s2a_05.eq(5))
    rel = replace_where(rel, 7.0, inlist(s2a_05, [6, 7]))
    rel = replace_where(rel, 8.0, s2a_05.gt(8))
    out["rel_jefe"] = rel

    # idioma / idioma_nativo (simplified 2015 Stata block)
    idioma = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma_nativo = pd.Series(np.nan, index=df.index, dtype="float64")
    s2a_08cod = df["s2a_08cod"].astype("string").fillna("").str.strip()
    idioma = replace_where(idioma, 3.0, s2a_08cod.eq("006"))
    idioma = replace_where(
        idioma,
        0.0,
        idioma.ne(3)
        & s2a_08cod.ne("")
        & s2a_08cod.ne(" ")
        & s2a_08cod.ne("A")
        & ~s2a_08cod.isin(["996", "997", "998"]),
    )
    out["idioma"] = idioma
    out["idioma_nativo"] = idioma_nativo

    out["birth_day"] = to_numeric(df["s2a_04a"])
    out["birth_month"] = to_numeric(df["s2a_04b"])
    out["birth_year"] = to_numeric(df["s2a_04c"])

    s3a_2a = to_numeric(df["s3a_2a"])
    pueblo = pd.Series(np.nan, index=df.index, dtype="float64")
    pueblo = replace_where(pueblo, 1.0, s3a_2a.eq(1))
    pueblo = replace_where(pueblo, 0.0, s3a_2a.eq(2))
    out["pueblo"] = pueblo

    out["sector"] = map_sector_from_caeb(df["caeb_op"])
    out["number_workers"] = to_numeric(df["s6b_21"])

    s6b_18 = to_numeric(df["s6b_18"])
    type_est = pd.Series(np.nan, index=df.index, dtype="float64")
    type_est = replace_where(type_est, 1.0, inlist(s6b_18, [3, 4]))
    type_est = replace_where(type_est, 2.0, inlist(s6b_18, [1, 2]))
    type_est = replace_where(type_est, 3.0, inlist(s6b_18, [5, 6]))
    out["type_est"] = type_est

    s6b_19 = to_numeric(df["s6b_19"])
    places_taxes2 = pd.Series(np.nan, index=df.index, dtype="float64")
    places_taxes2 = replace_where(places_taxes2, 1.0, inlist(s6b_19, [1, 2]))
    places_taxes2 = replace_where(places_taxes2, 2.0, inlist(s6b_19, [3]))
    places_taxes2 = replace_where(places_taxes2, 3.0, inlist(s6b_19, [4]))
    out["places_taxes2"] = places_taxes2

    s6b_17 = to_numeric(df["s6b_17"])
    contract = pd.Series(np.nan, index=df.index, dtype="float64")
    contract = replace_where(contract, s6b_17, inlist(s6b_17, [1, 2]))
    contract = replace_where(contract, 2.0, s6b_17.eq(3))
    contract = replace_where(contract, 3.0, s6b_17.eq(4))
    contract = replace_where(contract, 4.0, s6b_17.eq(5))
    out["contract"] = contract

    out["poor"] = to_numeric(df["p0"]).eq(1).astype(float)
    out["pov_line"] = to_numeric(df["z"])
    out["poor_xtr"] = to_numeric(df["pext0"]).eq(1).astype(float)
    out["pov_xtr_line"] = to_numeric(df["zext"])

    out["job_main_ocupation"] = df["s6b_11a"]
    out["job_specifics_tasks"] = df["s6b_11b"]
    out["health_insurance"] = to_numeric(df["s6c_29b"]).replace({2: 0})

    return select_keep(out, PERSONA_2015_KEEP)
