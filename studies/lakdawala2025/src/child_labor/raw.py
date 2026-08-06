"""Raw-file loaders and column renames for the Child Labor Survey.

Mirrors the ``rename`` blocks in do-files 1, 2, 5, 6, keeping only the
columns needed downstream for Table 1C / 2B / Table 5 (cols 1-4).
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from .. import paths
from ..persona.common import read_dta
from opencausallab.stata_semantics.stata_utils import to_numeric
from .utils import make_person_id

CHILD_LABOR_RAW = paths.RAW / "child_labor"


_EDU_LEVEL_RECODE_2016 = {
    11: 1,
    12: 2,
    13: 3,
    21: 4,
    22: 5,
    23: 6,
    31: 7,
    32: 8,
    41: 9,
    42: 10,
    51: 11,
    52: 12,
    61: 13,
    62: 14,
    63: 15,
    64: 16,
    65: 17,
    71: 18,
    72: 19,
    73: 20,
    74: 21,
    75: 22,
    76: 23,
    77: 24,
    78: 25,
    79: 26,
    80: 27,
}


def _recode_edu_level_2016(series: pd.Series) -> pd.Series:
    """Do-file 5/6: map raw ENNA level codes (11,21,…) → 1–27."""
    return to_numeric(series).replace(_EDU_LEVEL_RECODE_2016)


def _recode_gender_area(df: pd.DataFrame) -> pd.DataFrame:
    """Stata ``recode gender (2=0)`` / ``recode area (2=0)`` → male=1, urban=1."""
    out = df.copy()
    if "gender" in out.columns:
        g = to_numeric(out["gender"])
        out["gender"] = g.where(~g.eq(2), 0.0)
    if "area" in out.columns:
        a = to_numeric(out["area"])
        out["area"] = a.where(~a.eq(2), 0.0)
    return out

# ---------------------------------------------------------------------------
# 2008 — ETI 2008 (files 1 & 2)
# ---------------------------------------------------------------------------

_CHILD_2008_RENAME = {
    "s1_02": "gender",
    "s1_03": "age",
    "s1_04": "indbelonging",
    "s1_081": "edu_lastgradeapproved_a",
    "s1_082": "edu_lastgradeapproved_b",
    "s1_09": "edu_attendance",
    "s1_07": "edu_reasnoteverenrolled",
    "s1_11": "edu_shift",
    "s1_12": "edu_missedschool",
    "s1_13": "edu_missedschool_days",
    "s2_23": "wrk_workedlastweek",
    "s2_24": "wrk_dedicateonehour",
    "s2_251": "wrk_impediment_a",
    "s2_252": "wrk_impediment_b",
    "s2_29": "wrk_joblocation",
    "s2_30": "wrk_jobposition",
    "s2_31": "wrk_typepayment",
    "s2_331": "wrk_mainylab_a",
    "s2_332": "wrk_mainylab_b",
    "s2_361": "wrk_mainytotal_a",
    "s2_362": "wrk_mainytotal_b",
    "s2_371": "wrk_mainyafobligations_a",
    "s2_372": "wrk_mainyafobligations_b",
    "s2_42a": "wrk_hrs_aa",
    "s2_42b": "wrk_hrs_ab",
    "s2_42c": "wrk_hrs_ba",
    "s2_42d": "wrk_hrs_bb",
    "s2_42e": "wrk_hrs_ca",
    "s2_42f": "wrk_hrs_cb",
    "s2_42g": "wrk_hrs_da",
    "s2_42h": "wrk_hrs_db",
    "s2_42i": "wrk_hrs_ea",
    "s2_42j": "wrk_hrs_eb",
    "s2_42k": "wrk_hrs_fa",
    "s2_42l": "wrk_hrs_fb",
    "s2_42m": "wrk_hrs_ga",
    "s2_42n": "wrk_hrs_gb",
    "s2_43": "wrk_employer",
    "s2_53": "wrk_shift",
    "s2_581": "rgh_syndic",
    "s2_60": "wrk_familymemberjobsearch",
    "s2_681": "wrk_jobinjury_a",
    "s2_682": "wrk_jobinjury_b",
    "s2_683": "wrk_jobinjury_c",
    "s2_71": "wrk_heavylift",
    "s2_72": "wrk_heavyequipment",
    "s2_741": "wrk_risks_a",
    "s2_742": "wrk_risks_b",
    "s2_743": "wrk_risks_c",
    "s2_751": "wrk_violence_a",
    "s2_752": "wrk_violence_b",
    "s2_753": "wrk_violence_c",
    "s3_761": "hse_groceries",
    "s3_762": "hse_repair",
    "s3_763": "hse_cook",
    "s3_764": "hse_dishes",
    "s3_765": "hse_laundry",
    "s3_766": "hse_babysitting",
    "s3_767": "hse_woodwater",
    "s3_768": "hse_other",
    "s3_769": "hse_none",
    "s3_78a": "hse_hrs_aa",
    "s3_78b": "hse_hrs_ab",
    "s3_78c": "hse_hrs_ba",
    "s3_78d": "hse_hrs_bb",
    "s3_78e": "hse_hrs_ca",
    "s3_78f": "hse_hrs_cb",
    "s3_78g": "hse_hrs_da",
    "s3_78h": "hse_hrs_db",
    "s3_78i": "hse_hrs_ea",
    "s3_78j": "hse_hrs_eb",
    "s3_78k": "hse_hrs_fa",
    "s3_78l": "hse_hrs_fb",
    "s3_78m": "hse_hrs_ga",
    "s3_78n": "hse_hrs_gb",
    "cpaeb": "ecoactivity",
    "ceob": "occ_cat",
    "urb_rur": "area",
    "miembros": "members",
    "teco": "wrk_status",
    "condnh": "catchild",
}

_HOUSEHOLD_2008_RENAME = {
    "id_person": "number",
    "s1_02": "gender",
    "s1_03": "age",
    "s1_04a": "bdate_dd",
    "s1_04b": "bdate_mm",
    "s1_04c": "bdate_yy",
    "s1_05": "maritalstatus",
    "s1_07": "rel_head",
    "s1_08b": "rel_father",
    "s1_08d": "rel_mother",
    "s1_09": "language_childhood",
    "s1_12": "ind_belonging",
    "s2_22a": "edu_lastgradeapproved_a",
    "s2_22b": "edu_lastgradeapproved_b",
    "s3_33": "wrk_workedlastweek",
    "s3_35b": "wrk_impediment_b",
    "s3_39": "wrk_joblocation",
    "s3_40": "wrk_jobposition",
    "cpaeb_1": "ecoactivity",
    "urbarur": "area",
}


def load_child_2008(path: Path | None = None) -> pd.DataFrame:
    """Do-file 1: rename ETI_2008.dta child-survey columns, build ``id``."""
    path = path or CHILD_LABOR_RAW / "ETI_2008" / "ETI_2008.dta"
    df = read_dta(path)
    keep_raw = ["folio", "id_person", "upm", "factor"] + list(_CHILD_2008_RENAME.keys())
    out = df[[c for c in keep_raw if c in df.columns]].rename(columns=_CHILD_2008_RENAME)
    out = out.rename(columns={"id_person": "number"})
    out["id"] = make_person_id(out["folio"], out["number"])
    return _recode_gender_area(out)


def load_household_2008(path: Path | None = None) -> pd.DataFrame:
    """Do-file 2: rename ETI_2008_household.dta columns, build ``id``."""
    path = path or CHILD_LABOR_RAW / "ETI_2008" / "ETI_2008_household.dta"
    df = read_dta(path)
    keep_raw = ["folio"] + list(_HOUSEHOLD_2008_RENAME.keys())
    out = df[[c for c in keep_raw if c in df.columns]].rename(columns=_HOUSEHOLD_2008_RENAME)
    out["id"] = make_person_id(out["folio"], out["number"])
    return _recode_gender_area(out)


def load_municipality_2008(path: Path | None = None) -> pd.DataFrame:
    """Do-file 3 (lines 431–455): upm → (depto, prov, secc, mun)."""
    path = path or CHILD_LABOR_RAW / "ETI_2008" / "upm_2001-2013.dta"
    df = read_dta(path)
    out = df[["dept327", "prov327", "secc327", "upm"]].copy()

    out["upm"] = to_numeric(out["upm"])
    out["depto"] = to_numeric(out["dept327"])
    out["prov"] = to_numeric(out["prov327"])
    out["secc"] = to_numeric(out["secc327"])
    out["mun"] = out["depto"] * 1000 + out["prov"] * 10 + out["secc"]
    return out[["upm", "depto", "prov", "secc", "mun"]].drop_duplicates()


# ---------------------------------------------------------------------------
# 2016 — ENNA 2016 (files 5 & 6)
# ---------------------------------------------------------------------------

_CHILD_2016_RENAME = {
    "nro": "number",
    "ns001a_02": "gender",
    "ns001a_03": "age",
    "ns001a_04aa": "bdate_dd",
    "ns001a_04ab": "bdate_mm",
    "ns001a_04ac": "bdate_yy",
    "ns01a_02a": "edu_lastgradeapproved_a",
    "ns01a_02b": "edu_lastgradeapproved_b",
    "ns01a_04": "edu_reasnotenrol",
    "ns01a_05c": "edu_shift",
    "ns01a_06": "edu_attendance",
    "ns02a_01": "wrk_workedlastweek",
    "ns02a_02": "wrk_dedicateonehour",
    "ns02a_03": "wrk_impediment_a",
    "ns02a_03a": "wrk_impediment_b",
    "ns02b_14": "wrk_jobposition",
    "ns02b_15": "wrk_joblocation",
    "ns02b_16aa": "wrk_hrs_aa",
    "ns02b_16ab": "wrk_hrs_ab",
    "ns02b_16ba": "wrk_hrs_ba",
    "ns02b_16bb": "wrk_hrs_bb",
    "ns02b_16ca": "wrk_hrs_ca",
    "ns02b_16cb": "wrk_hrs_cb",
    "ns02b_16da": "wrk_hrs_da",
    "ns02b_16db": "wrk_hrs_db",
    "ns02b_16ea": "wrk_hrs_ea",
    "ns02b_16eb": "wrk_hrs_eb",
    "ns02b_16fa": "wrk_hrs_fa",
    "ns02b_16fb": "wrk_hrs_fb",
    "ns02b_16ga": "wrk_hrs_ga",
    "ns02b_16gb": "wrk_hrs_gb",
    "ns02b_18": "wrk_shift",
    "ns02b_19_2a": "wrk_stopworkharm",
    "ns02b_20": "wrk_agreejob",
    "ns02c_26": "wrk_typepayment",
    "ns02c_27a": "wrk_mainylab_a",
    "ns02c_27b": "wrk_mainylab_b",
    "ns02c_32": "wrk_permission",
    "ns02d_33a": "wrk_risks_a",
    "ns02d_33b": "wrk_risks_b",
    "ns02d_33c": "wrk_risks_c",
    "ns02d_34": "wrk_heavylift",
    "ns02d_35": "wrk_dangerequipment_a",
    "ns02d_36a": "wrk_jobinjury_a",
    "ns02d_36b": "wrk_jobinjury_b",
    "ns02d_36c": "wrk_jobinjury_c",
    "ns02d_38a": "wrk_violence_a",
    "ns02d_38b": "wrk_violence_b",
    "ns02d_38c": "wrk_violence_c",
    "ns03a_01a": "hse_groceries",
    "ns03a_01b": "hse_repair",
    "ns03a_01c": "hse_cook",
    "ns03a_01d": "hse_dishes",
    "ns03a_01e": "hse_laundry",
    "ns03a_01f": "hse_babysitting",
    "ns03a_01g": "hse_woodwater",
    "ns03a_01h": "hse_other",
    "ns03a_02aa": "hse_hrs_groceries_h",
    "ns03a_02ab": "hse_hrs_groceries_m",
    "ns03a_02ba": "hse_hrs_repair_h",
    "ns03a_02bb": "hse_hrs_repair_m",
    "ns03a_02ca": "hse_hrs_cook_h",
    "ns03a_02cb": "hse_hrs_cook_m",
    "ns03a_02da": "hse_hrs_dishes_h",
    "ns03a_02db": "hse_hrs_dishes_m",
    "ns03a_02ea": "hse_hrs_laundry_h",
    "ns03a_02eb": "hse_hrs_laundry_m",
    "ns03a_02fa": "hse_hrs_babysitting_h",
    "ns03a_02fb": "hse_hrs_babysitting_m",
    "ns03a_02ga": "hse_hrs_woodwater_h",
    "ns03a_02gb": "hse_hrs_woodwater_m",
    "ns04a_01": "rgh_syndic",
    "condac": "work_status",
    "ncaeb_op": "ecoactivity",
    "ncob_op": "occ_cat",
}

_HOUSEHOLD_2016_RENAME = {
    "nro": "number",
    "s02a_02": "gender",
    "s02a_03": "age",
    "s02a_04a": "bdate_dd",
    "s02a_04b": "bdate_mm",
    "s02a_04c": "bdate_yy",
    "s02a_05": "rel_head",
    "s02a_06b": "rel_father",
    "s02a_06c": "rel_mother",
    "s02a_08": "language_childhood",
    "s02a_10": "maritalstatus",
    "s03a_2": "ind_belonging_a",
    "s03a_2npioc": "ind_belonging_b",
    "s05a_02a": "edu_lastgradeapproved_a",
    "s05a_02b": "edu_lastgradeapproved_b",
    "s06a_01": "wrk_workedlastweek",
    "s06a_03": "wrk_impediment_b",
    "s06b_16": "wrk_jobposition",
    "s06b_20": "wrk_joblocation",
    "cob_op": "occ_cat",
    "caeb_op": "ecoactivity",
}


def load_child_2016(path: Path | None = None) -> pd.DataFrame:
    """Do-file 5: rename ENNA_2016.dta child-survey columns, build ``id``."""
    path = path or CHILD_LABOR_RAW / "ENNA_2016" / "ENNA_2016.dta"
    df = read_dta(path)
    keep_raw = ["folio", "depto", "area", "upm", "factor"] + list(_CHILD_2016_RENAME.keys())
    out = df[[c for c in keep_raw if c in df.columns]].rename(columns=_CHILD_2016_RENAME)
    out["id"] = make_person_id(out["folio"], out["number"])
    if "edu_lastgradeapproved_a" in out.columns:
        out["edu_lastgradeapproved_a"] = _recode_edu_level_2016(out["edu_lastgradeapproved_a"])
    return _recode_gender_area(out)


def load_household_2016(path: Path | None = None) -> pd.DataFrame:
    """Do-file 6: rename ENNA_2016_household.dta columns, build ``id``."""
    path = path or CHILD_LABOR_RAW / "ENNA_2016" / "ENNA_2016_household.dta"
    df = read_dta(path)
    keep_raw = ["folio", "upm", "area", "depto", "factor", "yhog"] + list(
        _HOUSEHOLD_2016_RENAME.keys()
    )
    out = df[[c for c in keep_raw if c in df.columns]].rename(columns=_HOUSEHOLD_2016_RENAME)
    out["id"] = make_person_id(out["folio"], out["number"])
    if "edu_lastgradeapproved_a" in out.columns:
        out["edu_lastgradeapproved_a"] = _recode_edu_level_2016(out["edu_lastgradeapproved_a"])
    return _recode_gender_area(out)


def load_municipality_2016(path: Path | None = None) -> pd.DataFrame:
    """Do-file 7 (lines 564–577): upm → mun via upm_2016.dta.

    ``num_upm`` / child ``upm`` are string PSU ids (e.g. ``111-00415128304-A``);
    only ``NOMBRE_MUNICIPIO`` is destring'd to a numeric muni code.
    """
    path = path or CHILD_LABOR_RAW / "ENNA_2016" / "upm_2016.dta"
    df = read_dta(path)

    out = df[["num_upm", "NOMBRE_MUNICIPIO"]].rename(columns={"num_upm": "upm"})
    out["upm"] = out["upm"].astype("string").str.strip()
    out["mun"] = to_numeric(out["NOMBRE_MUNICIPIO"])
    return out[["upm", "mun"]].drop_duplicates("upm")
