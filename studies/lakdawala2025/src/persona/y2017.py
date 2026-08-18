"""2017 Persona harmonization — EH_Persona_2017.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from opencausallab.stata_semantics.stata_utils import replace_where, to_numeric
from .common import (
    _resolve_col,
    binary_01,
    copy_standard_fields,
    make_contract,
    make_enrolled_public,
    make_estudia,
    make_health_insurance,
    make_hours_worked_day_2016_2017,
    make_id,
    make_incomes,
    make_job_location,
    make_level_enrolled,
    make_nocturna,
    make_ocu_cat,
    make_ocu_cat2,
    make_places_taxes2,
    make_poverty,
    make_type_est,
    make_work,
    make_work_lastweek,
    map_sector_from_caeb,
    read_persona,
    rel_jefe_le4,
    select_keep,
)
from opencausallab.stata_semantics.stata_utils import stata_str

PERSONA_2017_KEEP = [
    "id",  # unique person id: folio + within-household member number
    "folio",  # household id
    "depto",  # department (1–9: Chuquisaca … Pando)
    "area",  # urban / rural
    "sex",  # 1 = male, 2 = female (EH coding)
    "age",  # age in completed years (survey report, not month running var)
    "civil_status",  # marital / civil status
    "estudia",  # 1 if currently studying (0 if not / not asked)
    "lee_escribe",  # 1 if can read and write, 0 if not
    "esc",  # years of schooling (INE constructed `e`)
    "enrollment",  # 1 if currently enrolled in school, 0 if not
    "level_enrolled",  # grade 1–12 if in primary or secondary
    "enrolled_public",  # 1 if public or convenio school
    "work",  # 1 if employed (incl. unpaid/family/temporarily off), 0 if unemployed
    "work_lastweek",  # 1 if worked last week, 0 if no
    "ocu_cat",  # 8-way occupation: laborer, employee, own-account, employer, …, domestic
    "sector",  # 11-way industry of main job (CAEB collapsed; 1=ag, 2=mining, 5=construction)
    "hours_worked_day",  # usual hours per day (hours + minutes/60)
    "days_worked_week",  # usual days worked per week
    "ytotal",  # total personal income (yper); 0 stored as missing
    "ytrabajo",  # labor / work earnings (ylab), monthly Bs; 0 stored as missing
    "yhogar",  # household income
    "yhogarpc",  # household income per capita
    "factor",  # survey expansion weight
    "t",  # survey year (2017)
    "upm",  # primary sampling unit (municipality merge key)
    "rel_jefe",  # relation to household head (1 = head)
    "idioma",  # childhood language: 1 Quechua, 2 Aymara, 3 Spanish, 4 Guaraní, 5 other native, 6 foreign, 7 none
    "idioma_nativo",  # 1 if speaks a native language, 0 otherwise
    "birth_day",  # day of birth
    "birth_month",  # month of birth
    "birth_year",  # year of birth
    "pueblo",  # indigenous people: 1 Quechua, 2 Aymara, 3 other, 0 none
    "ocu_cat2",  # 4-way occupation: wage/coop/domestic, own-account, paid employer, unpaid family
    "job_location",  # 1 home, 2 fixed outside home, 3 roaming, 4 other, 5 does not work
    "number_workers",  # number of workers at the establishment
    "places_taxes2",  # coarser tax: 1 yes, 2 no/in process, 3 don't know
    "contract",  # 1 signed term contract, 2 verbal for a job, 3 plant staff, 4 no contract
    "type_est",  # establishment type: 1 private, 2 public, 3 NGO
    "poor",  # 1 if below the poverty line (p0==1); missing p0 → 0
    "poor_xtr",  # 1 if below the extreme poverty line (pext0==1)
    "pov_line",  # poverty line in bolivianos (z)
    "pov_xtr_line",  # extreme poverty line in bolivianos (zext)
    "suma_multiplica",  # 1 if able to add and multiply (basic math)
    "recibe_desayuno",  # 1 if receives school breakfast
    "recibe_bono_juancito",  # 1 if receives Bono Juancito Pinto (CCT receipt, not eligibility)
    "nocturna",  # 1 if enrolled in night / adult education
    "health_insurance",  # 1 if has health insurance, 0 if not (raw 2 recoded to 0)
]


def harmonize_persona_2017(raw_path: Path | None = None) -> pd.DataFrame:
    """Faithful Python translation of EH_Persona_2017.do."""
    df = read_persona(2017, raw_path)

    out = pd.DataFrame(index=df.index)
    out["folio"] = stata_str(_resolve_col(df, "folio"))
    out["id"] = make_id(df)
    out = pd.concat([out, make_incomes(df)], axis=1)

    out["sex"] = to_numeric(df["s02a_02"])
    out["age"] = to_numeric(df["s02a_03"])
    out["civil_status"] = to_numeric(df["s02a_10"])
    out["esc"] = to_numeric(df["aoesc"])

    out["work"] = make_work(df)
    out["work_lastweek"] = make_work_lastweek(df)

    ocu_cat = make_ocu_cat(df, "s06b_16")
    out["ocu_cat"] = ocu_cat
    out["ocu_cat2"] = make_ocu_cat2(ocu_cat)

    out["hours_worked_day"] = make_hours_worked_day_2016_2017(df)
    out["days_worked_week"] = to_numeric(df["s06b_22"])
    out["job_location"] = make_job_location(
        df, out["age"], category4_values=[0, 9]
    )

    out["enrollment"] = binary_01(df["s05a_05"])
    out["level_enrolled"] = make_level_enrolled(
        df, grade_col="s05a_06b"
    )
    out["enrolled_public"] = make_enrolled_public(df)

    copy_standard_fields(df, out)
    out["t"] = 2017

    out["estudia"] = make_estudia(df)
    out["lee_escribe"] = binary_01(df["s05a_01"])
    out["suma_multiplica"] = binary_01(df["s05a_01a"])
    out["recibe_desayuno"] = binary_01(df["s05a_07a"])
    out["recibe_bono_juancito"] = binary_01(df["s05a_08"])
    out["nocturna"] = make_nocturna(df)

    out["rel_jefe"] = rel_jefe_le4(df["s02a_05"])

    # Stata sets idioma=. then overwrites (commented block uses numeric codes)
    s02a_08 = df["s02a_08"].astype("string").fillna("").str.strip()
    idioma = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma = replace_where(idioma, 3.0, s02a_08.eq("6"))
    idioma = replace_where(idioma, 0.0, s02a_08.ne("") & s02a_08.ne(" ") & idioma.ne(3))
    out["idioma"] = idioma
    out["idioma_nativo"] = pd.Series(np.nan, index=df.index, dtype="float64")

    out["birth_day"] = to_numeric(df["s02a_04a"])
    out["birth_month"] = to_numeric(df["s02a_04b"])
    out["birth_year"] = to_numeric(df["s02a_04c"])

    s03a_04 = to_numeric(df["s03a_04"])
    pueblo = pd.Series(np.nan, index=df.index, dtype="float64")
    pueblo = replace_where(pueblo, 1.0, s03a_04.eq(1))
    pueblo = replace_where(pueblo, 0.0, s03a_04.eq(2))
    out["pueblo"] = pueblo

    out["sector"] = map_sector_from_caeb(df["caeb_op"])
    out["number_workers"] = to_numeric(df["s06b_21"])
    out["type_est"] = make_type_est(df)
    out["places_taxes2"] = make_places_taxes2(df)
    out["contract"] = make_contract(df)

    poverty = make_poverty(df)
    out = pd.concat([out, poverty], axis=1)

    out["health_insurance"] = make_health_insurance(df)

    return select_keep(out, PERSONA_2017_KEEP)
