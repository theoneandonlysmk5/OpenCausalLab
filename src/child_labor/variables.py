"""Calculated variables (do-files 3 and 7): risks, injury, d_worked, schooling, age.

Only the subset needed for Table 1C / 2B / Table 5 (cols 1-4) is implemented;
peripheral labeled categoricals (violence detail, job-search reasons, etc.)
are intentionally left out of scope (see module docstring in build.py).
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from ..stata_utils import inrange, replace_where, stata_round, to_numeric
from .utils import mdy


def schooling_2008(a: pd.Series, b: pd.Series) -> pd.Series:
    """Do-file 3, lines 96–103 (also do-file 3 §2, household schooling)."""
    a = to_numeric(a)
    b = to_numeric(b).replace(99, np.nan)
    out = pd.Series(np.nan, index=a.index, dtype="float64")
    out = replace_where(out, 0.0, a.eq(1))
    out = replace_where(out, b, a.eq(2) & b.notna())
    out = replace_where(out, 8 + b, a.eq(3) & b.notna())
    out = replace_where(out, 12 + b, a.eq(4) & b.notna())
    out = replace_where(out, 12 + b, a.eq(5) & b.notna())
    out = replace_where(out, 0.0, inrange(a, 6, 9))
    return out


def schooling_2016(a: pd.Series, b: pd.Series) -> pd.Series:
    """Do-file 7, lines 105–127 (also do-file 7 §2, household schooling).

    Sequential ``replace`` semantics: later steps can depend on the
    schooling value set by earlier steps (e.g. capping at 15/17/19/24).
    """
    a = to_numeric(a)
    b = to_numeric(b)
    s = pd.Series(np.nan, index=a.index, dtype="float64")
    bnn = b.notna()

    s = replace_where(s, 0.0, inrange(a, 1, 3))
    s = replace_where(s, 0.0, inrange(a, 11, 17))
    s = replace_where(s, b, a.eq(4) & bnn)
    s = replace_where(s, 5 + b, a.eq(5) & bnn)
    s = replace_where(s, 8 + b, a.eq(6) & bnn)
    s = replace_where(s, b, a.eq(7) & bnn)
    s = replace_where(s, 8 + b, a.eq(8) & bnn)
    s = replace_where(s, b, a.eq(9) & bnn)
    s = replace_where(s, 6 + b, a.eq(10) & bnn)
    s = replace_where(s, 12 + b, a.eq(18) & bnn)
    s = replace_where(s, 12 + b, inrange(a, 23, 25) & bnn)
    s = replace_where(s, 15.0, s.gt(15) & inrange(a, 23, 25) & bnn)
    s = replace_where(s, 15.0, s.gt(15) & a.eq(18) & bnn)
    s = replace_where(s, 12 + b, a.eq(19) & bnn)
    s = replace_where(s, 12 + b, a.eq(20) & bnn)
    s = replace_where(s, 17.0, s.gt(15) & a.eq(19) & bnn)
    s = replace_where(s, 17.0, s.gt(15) & a.eq(20) & bnn)
    s = replace_where(s, 17 + b, a.eq(21) & bnn)
    s = replace_where(s, 19.0, s.gt(19) & a.eq(21) & bnn)
    s = replace_where(s, 19 + b, a.eq(22) & bnn)
    s = replace_where(s, 24.0, s.gt(24) & a.eq(22) & bnn)
    s = replace_where(s, 12.0, s.ge(26) & a.le(27))
    return s


def child_vars_2008(df: pd.DataFrame) -> pd.DataFrame:
    """Do-file 3 §1 (lines 26–351): child-level derived variables."""
    out = df.copy()
    wl = to_numeric(out["wrk_workedlastweek"])
    dh = to_numeric(out["wrk_dedicateonehour"])
    ia = to_numeric(out["wrk_impediment_a"])
    d_worked = (wl.eq(1) | (dh.ge(1) & dh.lt(10)) | ia.eq(1)).astype(float)
    out["d_worked"] = d_worked

    jobpos = to_numeric(out["wrk_jobposition"])
    out["jobposition"] = jobpos.where(d_worked.eq(1))  # base=worked children only

    heavylift = to_numeric(out["wrk_heavylift"])
    heavyequip = to_numeric(out["wrk_heavyequipment"])
    out["heavylift_a"] = heavylift.eq(1).astype(float)
    out["heavyequip_a"] = heavyequip.eq(1).astype(float)

    risks_a_raw = to_numeric(out["wrk_risks_a"])
    risks_a_h = risks_a_raw.copy()
    risks_a_h = replace_where(risks_a_h, np.nan, risks_a_raw.eq(10))
    risks_a_h = replace_where(risks_a_h, 10.0, risks_a_raw.eq(11))
    risks_a_h = replace_where(risks_a_h, np.nan, risks_a_raw.eq(12))
    risks_a_h = replace_where(risks_a_h, 11.0, risks_a_raw.eq(13))
    risks_a_h = replace_where(risks_a_h, np.nan, risks_a_raw.eq(6))
    out["risks"] = (inrange(risks_a_h, 1, 11)).astype(float).where(d_worked.eq(1) & risks_a_h.notna())
    out["risks_a"] = inrange(risks_a_h, 1, 11).astype(float)
    for i in range(1, 12):
        out[f"r_{i}_a"] = risks_a_h.eq(i).astype(float)

    inj_a_raw = to_numeric(out["wrk_jobinjury_a"])
    inj_a_h = inj_a_raw.copy()
    inj_a_h = replace_where(inj_a_h, np.nan, inj_a_raw.eq(9))
    inj_a_h = replace_where(inj_a_h, 9.0, inj_a_raw.eq(10))
    inj_a_h = replace_where(inj_a_h, 10.0, inj_a_raw.eq(11))
    out["injury"] = inrange(inj_a_h, 1, 10).astype(float).where(d_worked.eq(1) & inj_a_h.notna())
    out["injury_a"] = inrange(inj_a_h, 1, 10).astype(float)
    for i in range(1, 11):
        out[f"i_{i}_a"] = inj_a_h.eq(i).astype(float)

    night_shift_a = to_numeric(out["wrk_shift"]).isin([2, 3]).astype(float)
    out["night_shift_a"] = night_shift_a

    weekworkhrs = sum(
        to_numeric(out[c]).fillna(0)
        for c in ["wrk_hrs_aa", "wrk_hrs_ba", "wrk_hrs_ca", "wrk_hrs_da", "wrk_hrs_ea", "wrk_hrs_fa", "wrk_hrs_ga"]
    )
    out["weekworkhrs_a"] = weekworkhrs

    wemp = to_numeric(out["wrk_employer"])
    out["workforemployer"] = wemp.eq(4).astype(float)
    out["workforfamily"] = wemp.isin([1, 2]).astype(float)

    out["schooling"] = schooling_2008(out["edu_lastgradeapproved_a"], out["edu_lastgradeapproved_b"])
    return out


def child_vars_2016(df: pd.DataFrame) -> pd.DataFrame:
    """Do-file 7 §1 (lines 26–530): child-level derived variables."""
    out = df.copy()
    wl = to_numeric(out["wrk_workedlastweek"])
    dh = to_numeric(out["wrk_dedicateonehour"])
    ia = to_numeric(out["wrk_impediment_a"])
    d_worked = (wl.eq(1) | (dh.ge(1) & dh.lt(9)) | ia.eq(1)).astype(float)
    out["d_worked"] = d_worked

    jobpos_raw = to_numeric(out["wrk_jobposition"])
    out["wrk_family"] = jobpos_raw.eq(1).astype(float).where(d_worked.eq(1))
    out["jobposition"] = jobpos_raw.where(d_worked.eq(1))

    heavylift = to_numeric(out["wrk_heavylift"])
    heavyequip = to_numeric(out["wrk_dangerequipment_a"])
    out["heavylift_a"] = heavylift.eq(1).astype(float)
    out["heavyequip_a"] = heavyequip.eq(1).astype(float)

    risks_a_raw = to_numeric(out["wrk_risks_a"]).replace(99, np.nan)
    out["risks"] = inrange(risks_a_raw, 1, 11).astype(float).where(d_worked.eq(1) & risks_a_raw.notna())
    out["risks_a"] = inrange(risks_a_raw, 1, 11).astype(float)
    for i in range(1, 12):
        out[f"r_{i}_a"] = risks_a_raw.eq(i).astype(float)

    inj_a_raw = to_numeric(out["wrk_jobinjury_a"])
    out["injury"] = inrange(inj_a_raw, 1, 10).astype(float).where(d_worked.eq(1) & inj_a_raw.notna())
    out["injury_a"] = inrange(inj_a_raw, 1, 10).astype(float)
    for i in range(1, 11):
        out[f"i_{i}_a"] = inj_a_raw.eq(i).astype(float)

    night_shift_a = to_numeric(out["wrk_shift"]).isin([2, 3]).astype(float)
    out["night_shift_a"] = night_shift_a

    weekworkhrs = sum(
        to_numeric(out[c]).fillna(0)
        for c in ["wrk_hrs_aa", "wrk_hrs_ba", "wrk_hrs_ca", "wrk_hrs_da", "wrk_hrs_ea", "wrk_hrs_fa", "wrk_hrs_ga"]
    )
    out["weekworkhrs_a"] = weekworkhrs

    out["schooling"] = schooling_2016(out["edu_lastgradeapproved_a"], out["edu_lastgradeapproved_b"])
    # Harmonize employer-type labels with 2008 (Table 2B uses workforfamily/workforemployer).
    out["workforfamily"] = out["wrk_family"]
    out["workforemployer"] = (
        to_numeric(out["wrk_jobposition"]).isin([2, 3, 4, 5]).astype(float).where(d_worked.eq(1))
    )
    return out


def add_age_survey_2008(df: pd.DataFrame) -> pd.DataFrame:
    """Do-file 3 (lines 490–497): age at survey date (fixed 2008-11-01)."""
    out = df.copy()
    doc = mdy(pd.Series(11, index=out.index), pd.Series(1, index=out.index), pd.Series(2008, index=out.index))
    dob = mdy(out["bdate_mm"], out["bdate_dd"], out["bdate_yy"])
    age_survey = doc - dob
    out["age_survey"] = age_survey
    out["age_survey_m"] = stata_round(age_survey / 30.0)
    return out


def add_age_survey_2016(df: pd.DataFrame, hhsurvey: pd.DataFrame) -> pd.DataFrame:
    """Do-file 7 (lines 508–530): age at per-household collection date.

    ``doc`` is looked up from ``HHsurvey`` (2016 rows) by ``folio``.
    """
    out = df.copy()
    hh = hhsurvey.loc[to_numeric(hhsurvey["year"]).eq(2016)].copy()
    hh["folio"] = to_numeric(hh["folio"])
    hh["doc"] = mdy(hh["collection_month"], hh["collection_day"], pd.Series(2016, index=hh.index))
    doc_by_folio = hh.groupby("folio", dropna=False)["doc"].first()

    out["folio"] = to_numeric(out["folio"])
    doc = out["folio"].map(doc_by_folio)
    dob = mdy(out["bdate_mm"], out["bdate_dd"], out["bdate_yy"])
    age_survey = doc - dob
    out["age_survey"] = age_survey
    out["age_survey_m"] = stata_round(age_survey / 30.0)
    return out
