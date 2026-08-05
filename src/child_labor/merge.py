"""Per-child RD frames (do-file 9, §§1/2): merge child + household + upm.

Column-prefix quirk preserved from Stata: the ``rename number-catchild``
(2008) / ``rename number-occ_danger2`` (2016) loop in do-file 9 only
prefixes columns that existed *before* the calculated variables were
appended, so raw survey fields become ``c_<name>`` while variables
computed afterwards (``risks``, ``injury``, ``d_worked``, ``wrk_family``,
...) stay unprefixed. We reproduce that split explicitly by name rather
than by replaying Stata's column order.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from ..stata_utils import to_numeric
from .household import (
    household_age_categories,
    household_composition,
    household_head_vars,
    remove_own_age_bucket,
)
from .utils import merge_drop_using_only


def build_rd_2008(
    child: pd.DataFrame,
    household: pd.DataFrame,
    municipality: pd.DataFrame,
) -> pd.DataFrame:
    """Do-file 9 §1 (lines 30–381): 2008 RD frame, one row per child."""
    c = child.copy()
    c["folio"] = to_numeric(c["folio"])
    c["upm"] = to_numeric(c["upm"])
    c = merge_drop_using_only(c, municipality[["upm", "depto", "prov", "mun"]], on="upm")

    out = pd.DataFrame(index=c.index)
    out["id"] = c["id"]
    out["folio"] = c["folio"]
    out["c_number"] = to_numeric(c["number"])
    out["c_gender"] = to_numeric(c["gender"])
    out["c_age"] = to_numeric(c["age"])
    out["c_area"] = to_numeric(c["area"])
    out["h_area"] = out["c_area"]
    out["c_depto"] = to_numeric(c["depto"])
    out["c_prov"] = to_numeric(c["prov"])
    out["c_mun"] = to_numeric(c["mun"])
    out["c_indbelonging"] = to_numeric(c["indbelonging"])
    out["c_ecoactivity"] = to_numeric(c["ecoactivity"])
    out["c_wrk_employer"] = to_numeric(c["wrk_employer"])
    out["c_wrk_familymemberjobsearch"] = to_numeric(c["wrk_familymemberjobsearch"])
    out["c_wrk_jobposition"] = to_numeric(c["wrk_jobposition"])

    for col in [
        "d_worked",
        "risks",
        "risks_a",
        "injury",
        "injury_a",
        "heavylift_a",
        "heavyequip_a",
        "night_shift_a",
        "weekworkhrs_a",
        "workforemployer",
        "workforfamily",
        "jobposition",
        "age_survey_m",
        "age_survey",
    ]:
        out[col] = to_numeric(c[col]) if col in c.columns else np.nan

    for i in range(1, 12):
        out[f"r_{i}_a"] = to_numeric(c.get(f"r_{i}_a"))
    for i in range(1, 11):
        out[f"i_{i}_a"] = to_numeric(c.get(f"i_{i}_a"))

    out["year"] = 2008.0

    # --- Household head/mother/father + composition + age categories -----
    hh = household.copy()
    hh["folio"] = to_numeric(hh["folio"])
    head_vars = household_head_vars(hh, indig_col="ind_belonging")
    comp = household_composition(hh)
    agecat = household_age_categories(hh)

    out = out.merge(head_vars, on="folio", how="left")
    out = out.merge(comp, on="folio", how="left")
    out = out.merge(agecat, on="folio", how="left")
    out = remove_own_age_bucket(out, age_col="c_age")

    return out


def build_rd_2016(
    child: pd.DataFrame,
    household: pd.DataFrame,
    municipality: pd.DataFrame,
) -> pd.DataFrame:
    """Do-file 9 §2 (lines 387–759): 2016 RD frame, one row per child."""
    c = child.copy()
    c["folio"] = to_numeric(c["folio"])
    # 2016 UPM ids are strings — do not coerce to numeric (would NaN → cartesian merge).
    c["upm"] = c["upm"].astype("string").str.strip()
    mun = municipality.copy()
    mun["upm"] = mun["upm"].astype("string").str.strip()
    c = merge_drop_using_only(c, mun[["upm", "mun"]], on="upm")

    out = pd.DataFrame(index=c.index)
    out["id"] = c["id"]
    out["folio"] = c["folio"]
    out["c_number"] = to_numeric(c["number"])
    out["c_gender"] = to_numeric(c["gender"])
    out["c_age"] = to_numeric(c["age"])
    out["c_area"] = to_numeric(c["area"])
    out["c_depto"] = to_numeric(c["depto"])
    out["c_prov"] = np.nan
    out["c_mun"] = to_numeric(c["mun"])
    out["c_ecoactivity"] = to_numeric(c["ecoactivity"])
    out["c_wrk_permission"] = to_numeric(c["wrk_permission"])
    out["c_wrk_jobposition"] = to_numeric(c["wrk_jobposition"])
    out["h_area"] = out["c_area"]

    for col in [
        "d_worked",
        "risks",
        "risks_a",
        "injury",
        "injury_a",
        "heavylift_a",
        "heavyequip_a",
        "night_shift_a",
        "weekworkhrs_a",
        "wrk_family",
        "workforfamily",
        "workforemployer",
        "jobposition",
        "age_survey_m",
        "age_survey",
    ]:
        out[col] = to_numeric(c[col]) if col in c.columns else np.nan

    for i in range(1, 12):
        out[f"r_{i}_a"] = to_numeric(c.get(f"r_{i}_a"))
    for i in range(1, 11):
        out[f"i_{i}_a"] = to_numeric(c.get(f"i_{i}_a"))

    out["year"] = 2016.0

    hh = household.copy()
    hh["folio"] = to_numeric(hh["folio"])
    head_vars = household_head_vars(hh, indig_col="ind_belonging_a")
    comp = household_composition(hh)
    agecat = household_age_categories(hh)

    out = out.merge(head_vars, on="folio", how="left")
    out = out.merge(comp, on="folio", how="left")
    out = out.merge(agecat, on="folio", how="left")
    out = remove_own_age_bucket(out, age_col="c_age")

    return out
