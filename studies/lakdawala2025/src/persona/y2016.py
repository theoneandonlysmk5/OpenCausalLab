"""2016 Persona harmonization — EH_Persona_2016.do."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from .. import paths
from opencausallab.stata_semantics.stata_utils import inlist, inrange, replace_where, stata_str, to_numeric
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
    rel_jefe_le3,
    select_keep,
)

PERSONA_2016_KEEP = [
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
    "encuesta_dia",
    "encuesta_mes",
    "encuesta_ano",
    "main_reason_work",
    "hired_recruiters",
    "work_conditions",
    "poor",
    "poor_xtr",
    "pov_line",
    "pov_xtr_line",
    "suma_multiplica",
    "recibe_desayuno",
    "recibe_bono_juancito",
    "nocturna",
    "health_insurance",
    "job_main_ocupation",
    "job_specifics_tasks",
]


def _load_merged_2016(
    persona_path: Path | None = None,
    vivienda_path: Path | None = None,
) -> pd.DataFrame:
    """Merge vivienda (encuesta dates) 1:m onto persona by folio."""
    persona_path = persona_path or paths.raw_household_persona(2016)
    vivienda_path = vivienda_path or paths.raw_household_vivienda(2016)

    import pyreadstat
    viv, _ = pyreadstat.read_dta(str(vivienda_path))
    viv = viv[["folio", "s01a_00a", "s01a_00b", "s01a_00c"]].copy()
    viv = viv.rename(
        columns={
            "s01a_00a": "encuesta_dia",
            "s01a_00b": "encuesta_mes",
            "s01a_00c": "encuesta_ano",
        }
    )

    df, _ = pyreadstat.read_dta(str(persona_path))
    return df.merge(viv, on="folio", how="left", validate="m:1")


def harmonize_persona_2016(
    raw_path: Path | None = None,
    vivienda_path: Path | None = None,
) -> pd.DataFrame:
    """Faithful Python translation of EH_Persona_2016.do."""
    df = _load_merged_2016(raw_path, vivienda_path)

    out = pd.DataFrame(index=df.index)
    out["folio"] = stata_str(_resolve_col(df, "folio"))
    out["id"] = make_id(df)
    out = pd.concat([out, make_incomes(df)], axis=1)

    out["sex"] = to_numeric(df["s02a_02"])
    out["age"] = to_numeric(df["s02a_03"])
    out["civil_status"] = to_numeric(df["s02a_10"])
    out["esc"] = to_numeric(df["e"])

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

    copy_standard_fields(df, out, esc_col="e")
    out["t"] = 2016

    out["estudia"] = make_estudia(df)
    out["lee_escribe"] = binary_01(df["s05a_01"])
    out["suma_multiplica"] = binary_01(df["s05a_01a"])
    out["recibe_desayuno"] = binary_01(df["s05a_07a"])
    out["recibe_bono_juancito"] = binary_01(df["s05a_08"])
    out["nocturna"] = make_nocturna(df)

    out["rel_jefe"] = rel_jefe_le3(df["s02a_05"])

    s2a_08 = to_numeric(df["s02a_08"])
    idioma = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma = replace_where(idioma, 1.0, s2a_08.eq(27))
    idioma = replace_where(idioma, 2.0, s2a_08.eq(2))
    idioma = replace_where(idioma, 3.0, s2a_08.eq(6))
    idioma = replace_where(idioma, 4.0, s2a_08.eq(12))
    idioma = replace_where(
        idioma, 6.0, inlist(s2a_08, [41, 42, 44, 45, 46, 54, 55, 58, 60])
    )
    idioma = replace_where(idioma, 7.0, s2a_08.eq(998))
    idioma = replace_where(idioma, 5.0, s2a_08.notna() & idioma.isna())
    out["idioma"] = idioma

    cods2_07a = to_numeric(df["s02a_07_1cod"])
    cods2_07b = to_numeric(df["s02a_07_2cod"])
    cods2_07c = to_numeric(df["s02a_07_3cod"])
    idioma_nativo = pd.Series(np.nan, index=df.index, dtype="float64")
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(idioma, [1, 2, 4, 5]))
    native_codes = [2, 7, 10, 12, 14, 20, 24, 26, 27, 29, 32, 36]
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(cods2_07a, native_codes))
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(cods2_07b, native_codes))
    idioma_nativo = replace_where(idioma_nativo, 1.0, inlist(cods2_07c, native_codes))
    idioma_nativo = replace_where(idioma_nativo, 0.0, idioma_nativo.isna())
    out["idioma_nativo"] = idioma_nativo

    out["birth_day"] = to_numeric(df["s02a_04a"])
    out["birth_month"] = to_numeric(df["s02a_04b"])
    out["birth_year"] = to_numeric(df["s02a_04c"])

    s3a_02b = to_numeric(df["s03a_2npioc"])
    s03a_2 = to_numeric(df["s03a_2"])
    pueblo = pd.Series(np.nan, index=df.index, dtype="float64")
    pueblo = replace_where(pueblo, 1.0, s3a_02b.eq(28))
    pueblo = replace_where(pueblo, 2.0, s3a_02b.eq(3))
    pueblo = replace_where(pueblo, 3.0, s03a_2.eq(1) & pueblo.isna())
    pueblo = replace_where(pueblo, 0.0, s03a_2.ne(1))
    out["pueblo"] = pueblo

    out["sector"] = map_sector_from_caeb(df["caeb_op"])
    out["number_workers"] = to_numeric(df["s06b_21"])
    out["type_est"] = make_type_est(df)
    out["places_taxes2"] = make_places_taxes2(df)
    out["contract"] = make_contract(df)

    poverty = make_poverty(df)
    out = pd.concat([out, poverty], axis=1)

    out["main_reason_work"] = to_numeric(df["s08a_03aa"])
    out["work_conditions"] = to_numeric(df["s08a_04"])
    out["hired_recruiters"] = to_numeric(df["s08a_06"])

    out["job_main_ocupation"] = df["s06b_11a"]
    out["job_specifics_tasks"] = df["s06b_11b"]
    out["health_insurance"] = make_health_insurance(df)

    out["encuesta_dia"] = to_numeric(df["encuesta_dia"])
    out["encuesta_mes"] = to_numeric(df["encuesta_mes"])
    out["encuesta_ano"] = to_numeric(df["encuesta_ano"])

    return select_keep(out, PERSONA_2016_KEEP)
