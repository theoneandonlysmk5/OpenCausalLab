"""Build ``RW_child_labor_survey.parquet`` from ETI 2008 + ENNA 2016.

Orchestrates do-files 1–3, 5–7, 9 into a single final frame used by
Table 1C / 2B / Table 5 (cols 1–4).
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from .. import paths
from .design import add_reweight_and_didisc, add_travel_heterogeneity
from .merge import build_rd_2008, build_rd_2016
from .raw import (
    load_child_2008,
    load_child_2016,
    load_household_2008,
    load_household_2016,
    load_municipality_2008,
    load_municipality_2016,
)
from .variables import (
    add_age_survey_2008,
    add_age_survey_2016,
    child_vars_2008,
    child_vars_2016,
    schooling_2008,
    schooling_2016,
)


def _prepare_2008() -> pd.DataFrame:
    child = load_child_2008()
    hh = load_household_2008()
    mun = load_municipality_2008()

    hh["schooling"] = schooling_2008(hh["edu_lastgradeapproved_a"], hh["edu_lastgradeapproved_b"])

    # Birth dates live on the HH roster; merge onto child by id (do-file 3).
    bdate = hh[["id", "bdate_dd", "bdate_mm", "bdate_yy"]].drop_duplicates("id")
    child = child.merge(bdate, on="id", how="left")
    child = child_vars_2008(child)
    child = add_age_survey_2008(child)
    return build_rd_2008(child, hh, mun)


def _prepare_2016(hhsurvey: pd.DataFrame | None = None) -> pd.DataFrame:
    child = load_child_2016()
    hh = load_household_2016()
    mun = load_municipality_2016()

    hh["schooling"] = schooling_2016(hh["edu_lastgradeapproved_a"], hh["edu_lastgradeapproved_b"])
    child = child_vars_2016(child)

    if hhsurvey is None:
        hhsurvey = pd.read_parquet(paths.FINAL / "HHsurvey.parquet")
    child = add_age_survey_2016(child, hhsurvey)
    return build_rd_2016(child, hh, mun)


def build_rw_child_labor_survey(
    hhsurvey: pd.DataFrame | None = None,
    out_path: Path | None = None,
) -> pd.DataFrame:
    """Full CL pipeline → ``data/final/RW_child_labor_survey.parquet``."""
    rd08 = _prepare_2008()
    rd16 = _prepare_2016(hhsurvey=hhsurvey)
    # Align columns so concat does not warn on all-NA dtype differences.
    cols = sorted(set(rd08.columns) | set(rd16.columns))
    rd08 = rd08.reindex(columns=cols)
    rd16 = rd16.reindex(columns=cols)
    stacked = pd.concat([rd08, rd16], ignore_index=True, sort=False)
    stacked = add_reweight_and_didisc(stacked)
    stacked = add_travel_heterogeneity(stacked)

    out_path = out_path or (paths.FINAL / "RW_child_labor_survey.parquet")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    stacked.to_parquet(out_path, index=False)
    return stacked
