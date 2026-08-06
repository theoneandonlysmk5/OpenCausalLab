"""2017 Persona harmonization — EH_Persona_2017.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from core.stata_semantics.stata_utils import replace_where, to_numeric
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
from core.stata_semantics.stata_utils import stata_str

PERSONA_2017_KEEP = [
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
    "suma_multiplica",
    "recibe_desayuno",
    "recibe_bono_juancito",
    "nocturna",
    "health_insurance",
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
        df, grade_col="s05a_06b", level_a="s05a_06a", level_b="s05a_06b"
    )
    out["enrolled_public"] = make_enrolled_public(df)

    copy_standard_fields(df, out, esc_col="aoesc")
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

    poverty = make_poverty(df, destring_p=True)
    out = pd.concat([out, poverty], axis=1)

    out["health_insurance"] = make_health_insurance(df)

    return select_keep(out, PERSONA_2017_KEEP)
