"""Household-level aggregates (do-file 9, §§1.2/2.2): head/mother/father vars,
adult counts, and children-by-age-group counts.

Column-naming quirk preserved from Stata: the ``rename number-wrkhome_head``
loop in the original code stops just before ``indig_head``/``lang_spa_head``
are generated, so those two escape the ``h_`` prefix while every other
head/mother/father variable receives it (e.g. ``h_age_head`` but plain
``indig_head``). This is intentional and matches the required-columns list.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from core.stata_semantics.stata_utils import inrange, replace_where, to_numeric


def _head_indicator(rel_head: pd.Series) -> pd.Series:
    return to_numeric(rel_head).eq(1).astype(float)


def _parent_ref(rel_col: pd.Series) -> pd.Series:
    """``replace f_hh=. if f_hh==997`` — 997 marks "no such relative"."""
    x = to_numeric(rel_col)
    return x.where(x != 997)


def household_head_vars(hh: pd.DataFrame, indig_col: str = "ind_belonging") -> pd.DataFrame:
    """Do-file 9 (lines 75–159, and 2016 equivalent 433–516).

    Returns one row per ``folio`` with ``h_*`` head/mother/father columns
    plus unprefixed ``indig_head`` / ``lang_spa_head``.

    ``indig_col``: ``"ind_belonging"`` for 2008 (indig_h flags Quechua==1
    only — a faithfully-preserved quirk of the original code) or
    ``"ind_belonging_a"`` for 2016 (flags "I do belong"==1).
    """
    df = hh.copy()
    df["folio"] = to_numeric(df["folio"])
    df["number"] = to_numeric(df["number"])

    h_hh = _head_indicator(df["rel_head"])
    f_hh = _parent_ref(df["rel_father"])
    m_hh = _parent_ref(df["rel_mother"])

    df["father_hh"] = f_hh.groupby(df["folio"], dropna=False).transform("max")
    df["mother_hh"] = m_hh.groupby(df["folio"], dropna=False).transform("max")

    age = to_numeric(df["age"])
    schooling = to_numeric(df["schooling"])
    ecoactivity = to_numeric(df["ecoactivity"])
    gender = to_numeric(df["gender"])
    maritalstatus = to_numeric(df["maritalstatus"])
    language_childhood = to_numeric(df["language_childhood"])
    ind_belonging = to_numeric(df[indig_col])

    d_worked_hh = to_numeric(df["wrk_workedlastweek"])
    impediment_b = to_numeric(df["wrk_impediment_b"])
    d_worked_hh = replace_where(d_worked_hh, 1.0, impediment_b.lt(10))

    is_mother = df["number"].eq(df["mother_hh"])
    is_father = df["number"].eq(df["father_hh"])
    is_head = h_hh.eq(1)

    def _fill_max(series: pd.Series, mask: pd.Series) -> pd.Series:
        masked = series.where(mask)
        return masked.groupby(df["folio"], dropna=False).transform("max")

    out = pd.DataFrame({"folio": df["folio"], "number": df["number"]})
    out["h_age_mother"] = _fill_max(age, is_mother)
    out["h_edu_mother"] = _fill_max(schooling, is_mother)
    out["h_work_mother"] = _fill_max(d_worked_hh, is_mother)

    out["h_age_father"] = _fill_max(age, is_father)
    out["h_edu_father"] = _fill_max(schooling, is_father)
    out["h_work_father"] = _fill_max(d_worked_hh, is_father)

    out["h_age_head"] = _fill_max(age, is_head)
    married_h = pd.Series(np.nan, index=df.index, dtype="float64")
    married_h = replace_where(married_h, 1.0, maritalstatus.isin([2, 3]) & is_head)
    married_h = replace_where(married_h, 0.0, maritalstatus.isin([1, 4, 5, 6]) & is_head)
    out["h_married_head"] = _fill_max(married_h, pd.Series(True, index=df.index))
    out["h_edu_head"] = _fill_max(schooling, is_head)
    out["h_work_head"] = _fill_max(d_worked_hh, is_head)
    out["h_industry_head"] = _fill_max(ecoactivity, is_head)
    out["h_male_head"] = _fill_max(gender, is_head)

    # indig_h / lang_spa_h keep Stata's exact (asymmetric) restriction:
    # indig_h is head-only; lang_spa_h is unrestricted (all HH members).
    # Treat missing ind_belonging as non-indigenous (0). Pandas' nullable
    # eq() leaves <NA> for missing codes, which would drop those HH from the
    # IPW probit; filling 0 restores the published Table 1C N=3,477
    # (complete cases missing only h_edu_head).
    indig_h = pd.Series(np.nan, index=df.index, dtype="float64")
    indig_flag = ind_belonging.eq(1).fillna(False).astype(float)
    indig_h = replace_where(indig_h, indig_flag, is_head)
    out["indig_head"] = _fill_max(indig_h, pd.Series(True, index=df.index))
    lang_spa_h = language_childhood.eq(1).astype(float)
    out["lang_spa_head"] = _fill_max(lang_spa_h, pd.Series(True, index=df.index))

    per_folio = out.drop(columns="number").groupby("folio", dropna=False).first().reset_index()
    return per_folio


def household_composition(hh: pd.DataFrame) -> pd.DataFrame:
    """Do-file 9 (lines 163–236 / 519–592): hhsize, adult_women, adult_men."""
    df = hh.copy()
    df["folio"] = to_numeric(df["folio"])
    gender = to_numeric(df["gender"])
    age = to_numeric(df["age"])

    hhsize = df.groupby("folio", dropna=False)["number"].transform("count")
    n_female = (gender.eq(0)).groupby(df["folio"]).transform("sum")
    n_male = (gender.eq(1)).groupby(df["folio"]).transform("sum")

    child_mask = age.lt(18)
    girls = (gender.eq(0) & child_mask).groupby(df["folio"]).transform("sum")
    boys = (gender.eq(1) & child_mask).groupby(df["folio"]).transform("sum")

    out = pd.DataFrame(
        {
            "folio": df["folio"],
            "hhsize": hhsize,
            "n_female": n_female,
            "n_male": n_male,
            "girls": girls,
            "boys": boys,
        }
    )
    out = out.groupby("folio", as_index=False).first()
    out["adult_women"] = out["n_female"] - out["girls"]
    out["adult_men"] = out["n_male"] - out["boys"]
    return out[["folio", "hhsize", "adult_women", "adult_men"]]


def household_age_categories(hh: pd.DataFrame) -> pd.DataFrame:
    """Do-file 9 (lines 226–235 / 586–592): hh_agecat1-4 counts by folio."""
    df = hh.copy()
    df["folio"] = to_numeric(df["folio"])
    age = to_numeric(df["age"])
    cat1 = age.lt(7).astype(float)
    cat2 = (age.ge(7) & age.lt(10)).astype(float)
    cat3 = (age.ge(10) & age.lt(14)).astype(float)
    cat4 = (age.ge(14) & age.lt(18)).astype(float)
    out = pd.DataFrame(
        {
            "folio": df["folio"],
            "hh_agecat1": cat1,
            "hh_agecat2": cat2,
            "hh_agecat3": cat3,
            "hh_agecat4": cat4,
        }
    )
    return out.groupby("folio", as_index=False)[
        ["hh_agecat1", "hh_agecat2", "hh_agecat3", "hh_agecat4"]
    ].sum()


def remove_own_age_bucket(df: pd.DataFrame, age_col: str = "c_age") -> pd.DataFrame:
    """Do-file 9 (lines 254–262 / 616–623): remove the child from its own bin."""
    out = df.copy()
    age = to_numeric(out[age_col])
    out["hh_agecat1"] = out["hh_agecat1"] - age.lt(7).astype(float)
    out["hh_agecat2"] = out["hh_agecat2"] - (age.ge(7) & age.lt(10)).astype(float)
    out["hh_agecat3"] = out["hh_agecat3"] - (age.ge(10) & age.lt(14)).astype(float)
    out["hh_agecat4"] = out["hh_agecat4"] - (age.ge(14) & age.lt(18)).astype(float)
    for c in ["hh_agecat1", "hh_agecat2", "hh_agecat3", "hh_agecat4"]:
        out[c] = out[c].clip(lower=0)
    return out
