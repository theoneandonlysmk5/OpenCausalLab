"""2012 Persona harmonization — EH_Persona_2012.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from ..stata_utils import inlist, inrange, recode_map, replace_where, stata_str, to_numeric
from .common import read_persona, select_keep

PERSONA_2012_KEEP = [
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
    "places_taxes",
    "places_taxes2",
    "contract",
    "type_est",
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


def harmonize_persona_2012(raw_path: Path | None = None) -> pd.DataFrame:
    """Faithful Python translation of EH_Persona_2012.do → EH2012_Persona_relabel."""
    df = read_persona(2012, raw_path)

    folio = stata_str(df["folio"])
    nro = stata_str(df["nro1a"])
    out = pd.DataFrame({"folio": folio, "id": folio + nro})

    yper = to_numeric(df["yper"])
    ylab = to_numeric(df["ylab"])
    out["ytotal"] = yper.where(yper != 0)
    out["ytrabajo"] = ylab.where(ylab != 0)
    out["yhogar"] = to_numeric(df["yhog"])
    out["yhogarpc"] = to_numeric(df["yhogpc"])

    out["sex"] = to_numeric(df["s1_03"])
    out["age"] = to_numeric(df["s1_04"])
    out["civil_status"] = to_numeric(df["s1_13"])
    out["esc"] = to_numeric(df["e"])
    out["area"] = to_numeric(df["area"])
    out["factor"] = to_numeric(df["factor"])
    out["depto"] = to_numeric(df["departamento"])
    out["t"] = 2012

    s5_01 = to_numeric(df["s5_01"])
    s5_02 = to_numeric(df["s5_02"])
    s5_03 = to_numeric(df["s5_03"])
    s5_05 = to_numeric(df["s5_05"])
    s5_15 = to_numeric(df["s5_15"])
    pet = to_numeric(df["pet"])

    work = pd.Series(np.nan, index=df.index, dtype="float64")
    work = replace_where(work, 1.0, s5_01.eq(1))
    work = replace_where(work, 1.0, inrange(s5_02, 1, 6))
    work = replace_where(work, 1.0, inrange(s5_03, 1, 6))
    work = replace_where(work, 0.0, pet.eq(1) & (s5_05.eq(1) | s5_15.eq(1)))
    out["work"] = work

    work_lastweek = s5_01.copy()
    work_lastweek = replace_where(work_lastweek, 0.0, work_lastweek.eq(2))
    out["work_lastweek"] = work_lastweek

    ocu_cat = to_numeric(df["s5_21"])
    out["ocu_cat"] = ocu_cat

    ocu_cat2 = pd.Series(np.nan, index=df.index, dtype="float64")
    ocu_cat2 = replace_where(ocu_cat2, 1.0, inlist(ocu_cat, [1, 2, 6, 8]))
    ocu_cat2 = replace_where(ocu_cat2, 2.0, inlist(ocu_cat, [3, 5]))
    ocu_cat2 = replace_where(ocu_cat2, 3.0, ocu_cat.eq(4))
    ocu_cat2 = replace_where(ocu_cat2, 4.0, ocu_cat.eq(7))
    out["ocu_cat2"] = ocu_cat2

    out["hours_worked_day"] = to_numeric(df["s5_29h"]) + to_numeric(df["s5_29m"]) / 60.0
    out["days_worked_week"] = to_numeric(df["s5_29"])

    s5_26 = to_numeric(df["s5_26"])
    job_location = pd.Series(np.nan, index=df.index, dtype="float64")
    job_location = replace_where(job_location, 1.0, s5_26.eq(1))
    job_location = replace_where(job_location, 2.0, s5_26.eq(2))
    job_location = replace_where(job_location, 3.0, inlist(s5_26, [3, 4, 5, 6, 7]))
    job_location = replace_where(job_location, 4.0, inlist(s5_26, [8]))
    job_location = replace_where(
        job_location, 5.0, out["age"].ge(7) & job_location.isna()
    )
    out["job_location"] = job_location

    s4_04 = to_numeric(df["s4_04"])
    enrollment = pd.Series(np.nan, index=df.index, dtype="float64")
    enrollment = replace_where(enrollment, 1.0, s4_04.eq(1))
    enrollment = replace_where(enrollment, 0.0, s4_04.eq(2))
    out["enrollment"] = enrollment

    s4_05a = to_numeric(df["s4_05a"])
    s4_05b = to_numeric(df["s4_05b"])
    level_enrolled = pd.Series(np.nan, index=df.index, dtype="float64")
    level_enrolled = replace_where(level_enrolled, 1.0, s4_05a.eq(19) & s4_05b.eq(1))
    for i in range(2, 7):
        level_enrolled = replace_where(
            level_enrolled, float(i), s4_05a.eq(19) & s4_05b.eq(i)
        )
    for i in range(1, 7):
        level_enrolled = replace_where(
            level_enrolled, float(6 + i), s4_05a.eq(20) & s4_05b.eq(i)
        )
    out["level_enrolled"] = level_enrolled

    s4_10 = to_numeric(df["s4_10"])
    enrolled_public = (s4_10.eq(1) | s4_10.eq(2)).astype(float)
    out["enrolled_public"] = enrolled_public.where(s4_10.notna())

    estudia = pd.Series(0.0, index=df.index)
    estudia = replace_where(estudia, 1.0, to_numeric(df["s4_12"]).eq(1))
    estudia = replace_where(estudia, 1.0, to_numeric(df["s4_13"]).eq(1))
    out["estudia"] = estudia

    lee = pd.Series(np.nan, index=df.index, dtype="float64")
    s4_01 = to_numeric(df["s4_01"])
    lee = replace_where(lee, 1.0, s4_01.eq(1))
    lee = replace_where(lee, 0.0, s4_01.eq(2))
    out["lee_escribe"] = lee

    s4_07 = to_numeric(df["s4_07"])
    desayuno = pd.Series(np.nan, index=df.index, dtype="float64")
    desayuno = replace_where(desayuno, 1.0, inlist(s4_07, [1, 2]))
    desayuno = replace_where(desayuno, 0.0, s4_07.eq(3))
    out["recibe_desayuno"] = desayuno

    s4_08 = to_numeric(df["s4_08"])
    bono = pd.Series(np.nan, index=df.index, dtype="float64")
    bono = replace_where(bono, 1.0, s4_08.eq(1))
    bono = replace_where(bono, 0.0, s4_08.eq(2))
    out["recibe_bono_juancito"] = bono

    out["nocturna"] = inlist(s4_05a, [12, 61, 62, 63, 64]).astype(float)

    upm2 = stata_str(df["upm"])
    upm = to_numeric(upm2.str.slice(0, 5))
    out["upm"] = upm

    s1_08 = to_numeric(df["s1_08"])
    rel = pd.Series(np.nan, index=df.index, dtype="float64")
    rel = replace_where(rel, s1_08, s1_08.le(4))
    rel = replace_where(rel, 5.0, s1_08.eq(8))
    rel = replace_where(rel, 6.0, s1_08.eq(5))
    rel = replace_where(rel, 7.0, inlist(s1_08, [6, 7]))
    rel = replace_where(rel, 8.0, s1_08.gt(8))
    out["rel_jefe"] = rel

    c1_11 = df["c1_11"].astype("string").fillna("").str.strip()
    idioma = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma = replace_where(idioma, 1.0, c1_11.eq("QUECHUA"))
    idioma = replace_where(idioma, 2.0, c1_11.eq("AYMARA"))
    idioma = replace_where(idioma, 3.0, c1_11.eq("CASTELLANO"))
    idioma = replace_where(idioma, 4.0, c1_11.eq("GUARAN"))
    idioma = replace_where(idioma, 6.0, c1_11.eq("IDIOMA EXTRANJERO"))
    idioma = replace_where(idioma, 7.0, c1_11.eq("99"))
    idioma = replace_where(idioma, 5.0, c1_11.ne("") & idioma.isna())
    out["idioma"] = idioma

    c1_10a = df["c1_10a"].astype("string").fillna("").str.strip()
    c1_10b = df["c1_10b"].astype("string").fillna("").str.strip()
    idioma_nativo = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(idioma, [1, 2, 4, 5]))
    idioma_nativo = replace_where(
        idioma_nativo,
        1.0,
        c1_10a.ne("") & c1_10a.ne("CASTELLANO") & c1_10a.ne("IDIOMA EXTRANJERO"),
    )
    idioma_nativo = replace_where(
        idioma_nativo,
        1.0,
        c1_10b.ne("") & c1_10b.ne("CASTELLANO") & c1_10b.ne("IDIOMA EXTRANJERO"),
    )
    idioma_nativo = replace_where(
        idioma_nativo,
        1.0,
        c1_10b.ne("") & c1_10b.ne("CASTELLANO") & c1_10b.ne("IDIOMA EXTRANJERO"),
    )
    idioma_nativo = replace_where(idioma_nativo, 0.0, idioma_nativo.isna())
    out["idioma_nativo"] = idioma_nativo

    out["birth_day"] = to_numeric(df["s1_05a"])
    out["birth_month"] = to_numeric(df["s1_05b"])
    out["birth_year"] = to_numeric(df["s1_05c"])

    s2_05a = to_numeric(df["s2_05a"])
    s2_05b = df["s2_05b"].astype("string").fillna("").str.strip()
    pueblo = pd.Series(np.nan, index=df.index, dtype="float64")
    pueblo = replace_where(pueblo, 1.0, s2_05b.eq("QUECHUA"))
    pueblo = replace_where(pueblo, 2.0, s2_05b.eq("AYMARA"))
    pueblo = replace_where(pueblo, 3.0, s2_05a.eq(1) & pueblo.isna())
    pueblo = replace_where(pueblo, 0.0, s2_05a.ne(1))
    out["pueblo"] = pueblo

    caeb = to_numeric(df["caeb_op1"])
    sector = pd.Series(np.nan, index=df.index, dtype="float64")
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
    out["sector"] = sector

    out["number_workers"] = to_numeric(df["s5_27"])

    s5_22 = to_numeric(df["s5_22"])
    type_est = pd.Series(np.nan, index=df.index, dtype="float64")
    type_est = replace_where(type_est, 1.0, s5_22.eq(2))
    type_est = replace_where(type_est, 2.0, s5_22.eq(1))
    type_est = replace_where(type_est, 3.0, s5_22.eq(3))
    out["type_est"] = type_est

    s5_25 = to_numeric(df["s5_25"])
    places_taxes = pd.Series(np.nan, index=df.index, dtype="float64")
    places_taxes = replace_where(places_taxes, 1.0, inlist(s5_25, [1, 2]))
    places_taxes = replace_where(places_taxes, 2.0, inlist(s5_25, [3]))
    places_taxes = replace_where(places_taxes, 3.0, inlist(s5_25, [4, 5]))
    places_taxes = replace_where(places_taxes, 4.0, inlist(s5_25, [6]))
    out["places_taxes"] = places_taxes

    places_taxes2 = pd.Series(np.nan, index=df.index, dtype="float64")
    places_taxes2 = replace_where(places_taxes2, 1.0, inlist(s5_25, [1, 2]))
    places_taxes2 = replace_where(places_taxes2, 2.0, inlist(s5_25, [3, 4, 5]))
    places_taxes2 = replace_where(places_taxes2, 3.0, inlist(s5_25, [6]))
    out["places_taxes2"] = places_taxes2

    out["contract"] = to_numeric(df["s5_28"])

    out["poor"] = to_numeric(df["p0"]).eq(1).astype(float)
    out["pov_line"] = to_numeric(df["z"])
    out["poor_xtr"] = to_numeric(df["pext0"]).eq(1).astype(float)
    out["pov_xtr_line"] = to_numeric(df["zext"])

    out["job_main_ocupation"] = df["s5_16a"]
    out["job_specifics_tasks"] = df["s5_16b"]

    health = recode_map(df["s5_35b"], {2: 0})
    out["health_insurance"] = health

    return select_keep(out, PERSONA_2012_KEEP)
