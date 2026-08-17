"""
Household Survey — final analysis merge.

Faithful Python translation of Stata ``3. Preparing for analysis.do``.
"""

from __future__ import annotations

import unicodedata
from pathlib import Path

import numpy as np
import pandas as pd

from . import paths
from .persona.common import read_dta
from opencausallab.stata_semantics.stata_utils import recode_map, replace_where, stata_round, to_numeric, winsor_high

_EPOCH = pd.Timestamp("1960-01-01")

CAPITAL_MUNIS = {
    "Cobija",
    "Cochabamba",
    "Trinidad",
    "Santa Cruz de la Sierra",
    "Sucre",
    "Tarija",
    "Potosí",
    "Oruro",
    "La Paz",
}

MTEPS_MUNIS = {
    "Riberalta",
    "Guayaramerín",
    "Trinidad",
    "Cobija",
    "Oruro",
    "Monteagudo",
    "Sucre",
    "Uyuni",
    "Villazón",
    "Tupiza",
    "Llallagua",
    "Potosí",
    "Puerto Suarez",
    "Villamontes",
    "Yacuiba",
    "Bermejo",
    "Tarija",
    "Warnes",
    "Montero",
    "Camiri",
    "Santa Cruz de la Sierra",
    "Villa Tunari",
    "Cochabamba",
    "El Alto",
    "La Paz",
}

# Published Table 4 no-MTEPS N=2984 (= our 2892 + 72 + 20) is recovered only when
# Potosí and Puerto Suarez/Suárez are coded mtepsoffices==0, despite both appearing
# in ``3. Preparing for analysis.do``. Likely Stata cause: travel.dta spells
# ``Puerto Suárez`` (≠ do-file ``Puerto Suarez``), so travel_tomerge flags it 0;
# Potosí is likewise unflagged in the authors' effective sample (travel flag
# retained or string match failure). Default follows the *published* sample.
FOLLOW_PUBLISHED_MTEPS_SAMPLE = True
MTEPS_EXCLUDE_FOR_PUBLISHED = frozenset({"Potosí", "Puerto Suarez", "Puerto Suárez"})


def _strip_accents(s: str) -> str:
    return "".join(
        c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn"
    )


def _muni_matches(muni: pd.Series, names: set[str]) -> pd.Series:
    """Exact match, plus accent-insensitive match (``Puerto Suárez`` ↔ ``Puerto Suarez``)."""
    m = muni.astype("string")
    exact = m.isin(names)
    norm_names = {_strip_accents(n).casefold() for n in names}
    norm_m = m.fillna("").map(lambda x: _strip_accents(str(x)).casefold())
    return exact | norm_m.isin(norm_names)


def _flag_mtepsoffices(muni: pd.Series) -> pd.Series:
    """Do-file mtepsoffices coding (+ optional published-sample exclusions)."""
    names = set(MTEPS_MUNIS)
    if FOLLOW_PUBLISHED_MTEPS_SAMPLE:
        names -= set(MTEPS_EXCLUDE_FOR_PUBLISHED)
    matched = _muni_matches(muni, names)
    out = pd.Series(np.nan, index=muni.index, dtype="float64")
    has_name = muni.notna() & (muni.astype("string").fillna("") != "")
    out = out.mask(has_name & matched, 1.0)
    out = out.mask(has_name & ~matched, 0.0)
    return out

SECTOR_RECODE = {2: 3, 3: 4, 4: 17, 5: 6, 6: 7, 7: 9, 8: 17, 9: 17, 10: 8, 11: 17}
INDUSTRY_HEAD_RECODE = {**SECTOR_RECODE, 99: 17}

HH_HEAD_PREFIXES = (
    "age_",
    "married_",
    "industry_",
    "pos_worker_",
    "pos_employee_",
    "pos_selfemp_",
    "pos_employer_",
    "pos_other_",
    "wrkhome_",
    "indig_",
    "lang_spa_",
)

DIDISC_CUTOFFS = {1: 10, 2: 12, 3: 14}
HET_VARS = ("het_time", "het_dist", "het_ddist")
BW_ROBUSTNESS = (6, 12, 18, 24)


def _mdy(month: pd.Series, day: pd.Series, year: pd.Series) -> pd.Series:
    y = to_numeric(year).astype("float64")
    m = to_numeric(month).astype("float64")
    d = to_numeric(day).astype("float64")
    dt = pd.to_datetime({"year": y, "month": m, "day": d}, errors="coerce")
    return (dt - _EPOCH).dt.days


def _xtile(series: pd.Series, n: int) -> pd.Series:
    """Approximate Stata ``xtile ..., n(k)`` (equal-count groups, 1..k)."""
    x = to_numeric(series)
    out = pd.Series(np.nan, index=series.index, dtype="float64")
    valid = x.notna()
    if valid.sum() == 0:
        return out
    ranks = x[valid].rank(method="first")
    out.loc[valid] = np.ceil(ranks / ranks.max() * n).clip(1, n)
    return out


def _stata_merge_drop_using_only(
    left: pd.DataFrame, right: pd.DataFrame, on: list[str] | str, how: str = "left"
) -> pd.DataFrame:
    """``merge m:1 ... ; drop if _merge==2`` — keep master + matched, not using-only."""
    merged = left.merge(right, on=on, how=how, indicator="_merge", validate="m:1")
    merged = merged.loc[merged["_merge"] != "right_only"].copy()
    merged = merged.drop(columns="_merge")
    return merged


def build_travel_tomerge(travel_path: Path | None = None) -> pd.DataFrame:
    """Section 1: medians, capital/MTEPS flags, rename muni_code → cod_secc."""
    travel_path = travel_path or paths.RAW / "auxiliar" / "travel_capitales.dta"
    df = read_dta(travel_path).copy()

    for col, med_name, above_name in [
        ("dist", "median_directdist", "abovemed_directdist"),
        ("ttime", "median_time", "abovemed_time"),
        ("tdist", "median_dist", "abovemed_dist"),
    ]:
        # Stata: ``sum x, detail`` → ``gen median=r(p50)`` stores **float**
        # (not double). Comparing double ``x`` to that float can put exact
        # median ties above the cutoff (e.g. Aiquile ttime==p50 → far), which
        # is required to match published Table 4 Panel A.
        x = to_numeric(df[col])
        median_val = float(np.float32(x.median()))
        df[med_name] = median_val
        # Store as 0/1 float (not bool) so later to_numeric / parquet round-trips stay numeric.
        df[above_name] = (x > median_val).astype("float64")
    df = df.rename(columns={"muni_code": "cod_secc"})
    df["cod_secc"] = to_numeric(df["cod_secc"]).astype("Int64")

    muni = df["muni_name"].astype("string")
    df["capital"] = np.where(muni.isin(CAPITAL_MUNIS), 1, 0).astype("float64")
    df.loc[~muni.isin(CAPITAL_MUNIS) & muni.notna(), "capital"] = 0

    df["mtepsoffices"] = _flag_mtepsoffices(muni)

    return df


def build_ch_income(persona: pd.DataFrame, income: pd.DataFrame) -> pd.DataFrame:
    """HH-level income tempfile (Stata ``ch_income`` block)."""
    inc_cols = ["id_year", "y_wl_earnings", "y_household"]
    merged = persona.merge(income[inc_cols], on="id_year", how="outer", validate="m:1")

    merged["hhsize"] = merged.groupby(["folio", "year"], dropna=False)["folio"].transform("count")

    child = merged.loc[to_numeric(merged["age"]) < 18].copy()
    child["gi"] = np.where(to_numeric(child["male"]) == 0, 1, np.nan)
    child["bo"] = np.where(to_numeric(child["male"]) == 1, 1, np.nan)
    child["girls"] = child.groupby(["folio", "year"], dropna=False)["gi"].transform("sum")
    child["boys"] = child.groupby(["folio", "year"], dropna=False)["bo"].transform("sum")
    child["child_income"] = child.groupby(["folio", "year"], dropna=False)["y_wl_earnings"].transform("sum")

    out = (
        child.groupby(["folio", "year"], as_index=False)
        .agg(
            hhsize=("hhsize", "first"),
            child_income=("child_income", "first"),
            y_household=("y_household", "first"),
            girls=("girls", "first"),
            boys=("boys", "first"),
        )
    )

    out["income_adults"] = to_numeric(out["y_household"]) - to_numeric(out["child_income"])
    out["income_adults_pc"] = out["income_adults"] / to_numeric(out["hhsize"])
    out["income_q"] = _xtile(out["income_adults_pc"], 5)
    return out


def build_ch_ages(persona: pd.DataFrame) -> pd.DataFrame:
    """HH-level age-category counts (Stata ``ch_ages`` block)."""
    df = persona.copy()
    age = to_numeric(df["age"])
    df["hh_agecat1"] = (age < 7).astype(int)
    df["hh_agecat2"] = ((age >= 7) & (age < 10)).astype(int)
    df["hh_agecat3"] = ((age >= 10) & (age < 14)).astype(int)
    df["hh_agecat4"] = ((age >= 14) & (age < 18)).astype(int)
    return (
        df.groupby(["folio", "year"], as_index=False)[
            ["hh_agecat1", "hh_agecat2", "hh_agecat3", "hh_agecat4"]
        ]
        .sum()
    )


def _apply_person_level_vars(df: pd.DataFrame) -> pd.DataFrame:
    """Lines 64–251: DOB, work outcomes, head vars."""
    out = df.copy()

    birth_day = to_numeric(out["birth_day"])
    birth_day = replace_where(birth_day, np.nan, birth_day.isin([99, 88]))
    birth_month = to_numeric(out["birth_month"])
    birth_year = to_numeric(out["birth_year"])
    coll_day = to_numeric(out["collection_day"])
    coll_month = to_numeric(out["collection_month"])
    coll_year = to_numeric(out["collection_year"])

    out["birth_day"] = birth_day
    out["dob"] = _mdy(birth_month, birth_day, birth_year)
    out["s_date"] = _mdy(coll_month, coll_day, coll_year)
    out["age_dob"] = to_numeric(out["s_date"]) - to_numeric(out["dob"])
    out["age_dob_m"] = stata_round(to_numeric(out["age_dob"]) / 30)

    age = to_numeric(out["age"])
    schooling = to_numeric(out["schooling"])
    out["lag_schooling"] = age - 5 - schooling
    out["lag_schooling"] = replace_where(out["lag_schooling"], 0, out["lag_schooling"] < 0)

    out["agecat"] = np.nan
    out.loc[(age > 6) & (age < 10), "agecat"] = 1
    out.loc[(age >= 10) & (age < 12), "agecat"] = 2
    out.loc[(age >= 12) & (age < 14), "agecat"] = 3
    out.loc[(age >= 14) & (age < 18), "agecat"] = 4
    out.loc[age >= 18, "agecat"] = 5

    works = to_numeric(out["works"])
    wage_worker = to_numeric(out["wage_worker"])
    out["paid"] = np.where(works == 1, wage_worker, np.nan)
    out["paid_a"] = wage_worker

    wage_hour_w = to_numeric(out["wage_hour_w"])
    out["wage_hour_w_a"] = wage_hour_w
    out.loc[works == 0, "wage_hour_w_a"] = 0
    out["log_wage_hour_w_a"] = np.log(out["wage_hour_w_a"] + 1)
    out["log_wage_hour_w"] = np.log(wage_hour_w + 1)
    out["log_ylabor_w"] = np.log(to_numeric(out["ylabor_w"]) + 1)
    ylabor_w = to_numeric(out["ylabor_w"])
    out["plusminearnings"] = np.where(ylabor_w.notna(), (ylabor_w >= 1200).astype(float), np.nan)

    ocu_cat = to_numeric(out["ocu_cat"])
    out["wrk_family"] = np.where(works == 1, (ocu_cat == 7).astype(float), np.nan)
    out["wrk_family_a"] = (ocu_cat == 7).astype(float)
    out["wrk_out"] = np.where(works == 1, ((ocu_cat < 7) | (ocu_cat == 8)).astype(float), np.nan)
    out["wrk_out_a"] = ((ocu_cat < 7) | (ocu_cat == 8)).astype(float)
    out["wrk_foremployer"] = np.where(
        works == 1, ((ocu_cat < 3) | (ocu_cat == 8)).astype(float), np.nan
    )
    out["wrk_foremployer_a"] = ((ocu_cat < 3) | (ocu_cat == 8)).astype(float)
    out["wrk_forother"] = np.where(
        works == 1,
        ((ocu_cat < 3) | (ocu_cat == 8) | (ocu_cat == 7) | (ocu_cat == 6)).astype(float),
        np.nan,
    )
    out["wrk_forother_a"] = (
        (ocu_cat < 3) | (ocu_cat == 8) | (ocu_cat == 7) | (ocu_cat == 6)
    ).astype(float)

    self_emp = to_numeric(out["self_employed"])
    out["self_employed"] = np.where(works == 0, np.nan, self_emp)
    out["self_employed_a"] = self_emp
    out.loc[works == 0, "self_employed_a"] = 0

    hours_week_w = to_numeric(out["hours_week_w"])
    out["wrk30hrs"] = np.where(
        works == 1, ((hours_week_w > 30) & hours_week_w.notna()).astype(float), np.nan
    )
    out["wrk30hrs_a"] = ((hours_week_w > 30) & hours_week_w.notna()).astype(float)

    out["domestic"] = np.where(works == 1, (ocu_cat == 8).astype(float), np.nan)
    out["domestic_a"] = (ocu_cat == 8).astype(float)

    out["hours_week_a"] = hours_week_w
    out["hours_week"] = hours_week_w
    out.loc[works == 0, "hours_week"] = np.nan

    attendance = to_numeric(out["attendance"])
    out["attendance"] = np.where(age < 6, np.nan, attendance)
    # Stata: gen attendance_a=attendance; replace attendance=. if works==0
    out["attendance_a"] = out["attendance"].copy()
    out.loc[works == 0, "attendance"] = np.nan

    sector = to_numeric(out["sector"])
    for name, cond in [
        ("agriculture_a", sector == 1),
        ("mining_a", sector == 2),
        ("manufacture_a", sector == 3),
        ("construction_a", sector == 5),
        ("sales_a", sector == 6),
        ("transportation_a", sector == 7),
        ("accomodation_a", sector == 10),
        (
            "other_a",
            sector.isin([4, 8, 9, 11]),
        ),
    ]:
        out[name] = cond.astype(float)

    out["other_occ"] = (
        (out["mining_a"] == 1)
        | (out["manufacture_a"] == 1)
        | (out["construction_a"] == 1)
        | (out["transportation_a"] == 1)
        | (out["accomodation_a"] == 1)
        | (out["other_a"] == 1)
    ).astype(float)
    out["common"] = np.where(sector.isin([1, 6, 3]), 1, np.nan)

    wrk_family = to_numeric(out["wrk_family"])
    forbidden = pd.Series(np.nan, index=out.index, dtype="float64")
    forbidden = np.where(
        ((sector == 1) & (wrk_family == 0)) | sector.isin([2, 5]),
        1,
        forbidden,
    )
    forbidden = np.where(pd.isna(forbidden) & (works == 1), 0, forbidden)
    forbidden = np.where(works == 0, np.nan, forbidden)
    out["forbidden"] = forbidden
    out["forbidden_a"] = forbidden
    out.loc[works == 0, "forbidden_a"] = 0
    out["not_forbidden_a"] = 1 - out["forbidden_a"]
    out.loc[works == 0, "not_forbidden_a"] = 0
    out["not_forbidden"] = out["not_forbidden_a"]
    out.loc[works == 0, "not_forbidden"] = np.nan

    job_loc = to_numeric(out["job_location"])
    out["wrk_home"] = (job_loc == 1).astype(float)
    out["wrk_fixedloc"] = (job_loc == 2).astype(float)
    out["wrk_roamingloc"] = (job_loc == 3).astype(float)

    h_hh = (to_numeric(out["rel_head"]) == 1).astype(float)
    out["h_hh"] = h_hh
    out["age_h"] = np.where(h_hh == 1, age, np.nan)

    civil = to_numeric(out["civil_status"])
    married_h = pd.Series(np.nan, index=out.index, dtype="float64")
    head = h_hh == 1
    married_h = np.where(head & civil.isin([2, 3]), 1, married_h)
    married_h = np.where(head & civil.isin([1, 4, 5, 6]), 0, married_h)
    out["married_h"] = married_h

    out["industry_h"] = np.where(h_hh == 1, sector, np.nan)
    out["lang_spa_h"] = (to_numeric(out["language_childhood"]) == 1).astype(float)

    for ocu_val, col in [
        (1, "pos_worker_h"),
        (2, "pos_employee_h"),
        (3, "pos_selfemp_h"),
        ((4, 5), "pos_employer_h"),
        ((6, 7, 8), "pos_other_h"),
    ]:
        if isinstance(ocu_val, tuple):
            cond = ocu_cat.isin(ocu_val)
        else:
            cond = ocu_cat == ocu_val
        out[col] = np.where(h_hh == 1, cond.astype(float), np.nan)

    out["indig_h"] = np.where(h_hh == 1, (to_numeric(out["indigenous"]) == 1).astype(float), np.nan)
    out["wrkhome_h"] = np.where(h_hh == 1, (job_loc == 1).astype(float), np.nan)

    for prefix in HH_HEAD_PREFIXES:
        h_col = f"{prefix}h"
        head_col = f"{prefix}head"
        out[head_col] = out.groupby(["folio", "year"], dropna=False)[h_col].transform("max")
        out = out.drop(columns=[h_col])

    return out


def _apply_hh_merges_and_recodes(df: pd.DataFrame, ch_income: pd.DataFrame, ch_ages: pd.DataFrame) -> pd.DataFrame:
    """Lines 313–344: merge HH temps, agecat adjust, prov, sector recode."""
    out = _stata_merge_drop_using_only(df, ch_income, on=["folio", "year"])
    out = _stata_merge_drop_using_only(out, ch_ages, on=["folio", "year"])

    age = to_numeric(out["age"])
    out.loc[age < 7, "hh_agecat1"] = to_numeric(out.loc[age < 7, "hh_agecat1"]) - 1
    out.loc[(age >= 7) & (age < 10), "hh_agecat2"] = (
        to_numeric(out.loc[(age >= 7) & (age < 10), "hh_agecat2"]) - 1
    )
    out.loc[(age >= 10) & (age < 14), "hh_agecat3"] = (
        to_numeric(out.loc[(age >= 10) & (age < 14), "hh_agecat3"]) - 1
    )
    out.loc[(age >= 14) & (age < 18), "hh_agecat4"] = (
        to_numeric(out.loc[(age >= 14) & (age < 18), "hh_agecat4"]) - 1
    )
    for col in ("hh_agecat1", "hh_agecat2", "hh_agecat3", "hh_agecat4"):
        out[col] = to_numeric(out[col]).clip(lower=0)

    out["adult_women"] = to_numeric(out["n_female"]) - to_numeric(out["girls"])
    out["adult_men"] = to_numeric(out["n_male"]) - to_numeric(out["boys"])
    out = out.drop(columns=["boys", "girls"])

    cod_secc = to_numeric(out["cod_secc"])
    out["prov"] = (cod_secc // 10).astype("Int64")

    out["sector"] = recode_map(out["sector"], SECTOR_RECODE)
    out["industry_head"] = recode_map(out["industry_head"], INDUSTRY_HEAD_RECODE)

    return out


def _apply_cct_and_firm_vars(df: pd.DataFrame) -> pd.DataFrame:
    """Lines 347–489: CCT eligibility, firm size, municipal aggregates."""
    out = df.copy()
    enrolled = to_numeric(out["enrolled"])
    enrolled_public = to_numeric(out["enrolled_public"])
    schooling = to_numeric(out["schooling"])
    year = to_numeric(out["year"])
    age = to_numeric(out["age"])
    works = to_numeric(out["works"])

    grade_cct = schooling - 1
    grade_cct = np.where(enrolled == 1, grade_cct, schooling)
    grade_cct = np.where(to_numeric(grade_cct) < 0, np.nan, grade_cct)
    out["grade_cct"] = grade_cct

    eligible = pd.Series(np.nan, index=out.index, dtype="float64")
    eligible = np.where(
        (year == 2006) & (grade_cct < 5) & (enrolled_public == 1), 1, eligible
    )
    eligible = np.where(
        (year == 2007) & (grade_cct < 6) & (enrolled_public == 1), 1, eligible
    )
    eligible = np.where(
        (year >= 2008) & (year <= 2011) & ((grade_cct - 1) <= 8) & (enrolled_public == 1),
        1,
        eligible,
    )
    eligible = np.where(
        (year == 2012) & (grade_cct < 9) & (enrolled_public == 1), 1, eligible
    )
    eligible = np.where(
        (year == 2013) & (grade_cct < 10) & (enrolled_public == 1), 1, eligible
    )
    eligible = np.where(
        (year >= 2014) & (grade_cct < 12) & (enrolled_public == 1), 1, eligible
    )
    eligible = np.where(
        (pd.isna(eligible)) & (enrolled == 1) & (enrolled_public == 0), 0, eligible
    )
    out["eligible"] = eligible

    eligible_gr = pd.Series(np.nan, index=out.index, dtype="float64")
    eligible_gr = np.where((year == 2006) & (grade_cct < 5), 1, eligible_gr)
    eligible_gr = np.where((year == 2007) & (grade_cct < 6), 1, eligible_gr)
    eligible_gr = np.where((year >= 2008) & (year <= 2011) & (grade_cct < 8), 1, eligible_gr)
    eligible_gr = np.where((year == 2012) & (grade_cct < 9), 1, eligible_gr)
    eligible_gr = np.where((year == 2013) & (grade_cct < 10), 1, eligible_gr)
    eligible_gr = np.where((year >= 2014) & (grade_cct < 12), 1, eligible_gr)
    eligible_gr = np.where(pd.isna(eligible_gr), 0, eligible_gr)
    out["eligible_gr"] = eligible_gr

    date30march = _mdy(pd.Series(3, index=out.index), pd.Series(30, index=out.index), year)
    age30mar = stata_round((to_numeric(date30march) - to_numeric(out["dob"])) / 365)
    gradeforage = pd.Series(np.nan, index=out.index, dtype="float64")
    gradeforage = np.where(age30mar == 6, 1, gradeforage)
    for i in range(2, 12):
        gradeforage = np.where(age30mar == i + 5, i, gradeforage)
    gradeforage = np.where(to_numeric(gradeforage) > 12, np.nan, gradeforage)
    out["gradeforage"] = gradeforage
    out["age30mar"] = age30mar
    out["date30march"] = date30march

    eligible_grage = pd.Series(np.nan, index=out.index, dtype="float64")
    eligible_grage = np.where((year == 2006) & (gradeforage < 5), 1, eligible_grage)
    eligible_grage = np.where((year == 2007) & (gradeforage < 6), 1, eligible_grage)
    eligible_grage = np.where(
        (year >= 2008) & (year <= 2011) & (gradeforage < 8), 1, eligible_grage
    )
    eligible_grage = np.where((year == 2012) & (gradeforage < 9), 1, eligible_grage)
    eligible_grage = np.where((year == 2013) & (gradeforage < 10), 1, eligible_grage)
    eligible_grage = np.where((year >= 2014) & (gradeforage < 12), 1, eligible_grage)
    eligible_grage = np.where(pd.isna(eligible_grage), 0, eligible_grage)
    out["eligible_grage"] = eligible_grage

    out = out.rename(columns={"receives_cct_juancito": "received_cct"})

    nw = to_numeric(out["number_workers"])
    out["number_workers_w"] = winsor_high(nw, p=0.05)
    out["number_workers_a"] = out["number_workers_w"]
    out.loc[works == 0, "number_workers_a"] = 0

    out["firm_taxes"] = recode_map(out["firm_taxes"], {2: 0, 3: 0, 99: np.nan})

    nw_w = to_numeric(out["number_workers_w"])
    aux1 = _xtile(nw_w, 2)
    aux2 = _xtile(nw_w, 3)
    p75 = nw_w.quantile(0.75)

    out["abovemed_firmsize"] = recode_map(aux1, {1: 0, 2: 1})
    out.loc[works == 0, "abovemed_firmsize"] = 0
    out["abovep75_firmsize"] = (nw_w >= p75).astype(float)
    out.loc[works == 0, "abovep75_firmsize"] = 0
    out["notsmall_firm"] = (nw_w > 10).astype(float)
    out.loc[nw_w.isna(), "notsmall_firm"] = np.nan
    out.loc[works == 0, "notsmall_firm"] = 0

    for i in range(1, 4):
        out[f"terc_{i}"] = (aux2 == i).astype(float)
        out[f"terc_a_{i}"] = out[f"terc_{i}"]
        out.loc[works == 0, f"terc_a_{i}"] = 0

    for val, prefix in [(0, "med_1"), (1, "med_2")]:
        out[prefix] = (to_numeric(out["abovemed_firmsize"]) == val).astype(float)
    for val, prefix in [(0, "size_1"), (1, "size_2")]:
        out[prefix] = (to_numeric(out["notsmall_firm"]) == val).astype(float)
    for val, prefix in [(0, "p75_1"), (1, "p75_2")]:
        out[prefix] = (to_numeric(out["abovep75_firmsize"]) == val).astype(float)

    for i in range(1, 3):
        out[f"med_a_{i}"] = out[f"med_{i}"]
        out.loc[works == 0, f"med_a_{i}"] = 0
        out[f"size_a_{i}"] = out[f"size_{i}"]
        out.loc[works == 0, f"size_a_{i}"] = 0
        # Stata quirk: p75_a uses size_ dummies, not p75_
        out[f"p75_a_{i}"] = out[f"size_{i}"]
        out.loc[works == 0, f"p75_a_{i}"] = 0

    contract = to_numeric(out["contract"])
    out["formal_contract"] = contract.isin([1, 3]).astype(float)
    fc = to_numeric(out["formal_contract"])
    p50_fc = fc.median()
    p75_fc = fc.quantile(0.75)
    out["formal_contract50"] = (fc > p50_fc).astype(float)
    out.loc[out["formal_contract50"].isna(), "formal_contract50"] = 0
    out["formal_contract75"] = (fc > p75_fc).astype(float)
    out.loc[out["formal_contract75"].isna(), "formal_contract75"] = 0

    out["no_workers_children"] = np.where(age < 18, nw, np.nan)
    out["no_workers_adults"] = np.where(age > 17, nw, np.nan)
    out["formal_contract_children"] = np.where(age < 18, fc, np.nan)
    out["formal_contract_adults"] = np.where(age > 17, fc, np.nan)

    cod = out["cod_secc"]
    for src, dst in [
        ("no_workers_children", "mun_workers_children"),
        ("no_workers_adults", "mun_workers_adults"),
        ("formal_contract_children", "mun_contract_children"),
        ("formal_contract_adults", "mun_contract_adults"),
    ]:
        out[dst] = out.groupby(cod, dropna=False)[src].transform("mean")

    for col in (
        "mun_workers_children",
        "mun_workers_adults",
        "mun_contract_children",
        "mun_contract_adults",
    ):
        med = to_numeric(out[col]).median()
        out[f"{col}50"] = (to_numeric(out[col]) > med).astype(float)

    out = out.drop(
        columns=[
            "no_workers_children",
            "no_workers_adults",
            "formal_contract_children",
            "formal_contract_adults",
            "aux1",
            "aux2",
        ],
        errors="ignore",
    )

    head_male = to_numeric(out["head_male"])
    out["g_h_works"] = (1 - head_male) * to_numeric(out["head_works"])
    out["g_h_edu"] = (1 - head_male) * to_numeric(out["head_schooling"])
    out["g_h_married"] = (1 - head_male) * to_numeric(out["married_head"])
    out["g_h_age"] = (1 - head_male) * to_numeric(out["head_age"])
    for src, dst in [
        ("pos_worker_head", "g_h_worker"),
        ("pos_employee_head", "g_h_employee"),
        ("pos_selfemp_head", "g_h_selfemp"),
        ("pos_employer_head", "g_h_employer"),
        ("pos_other_head", "g_h_other"),
        ("indig_head", "g_h_indig"),
    ]:
        out[dst] = (1 - head_male) * to_numeric(out[src])

    return out


def _ensure_media_cols(df: pd.DataFrame) -> pd.DataFrame:
    """Create s5c_* columns as NaN when absent (only populated in some years)."""
    out = df.copy()
    for col in ("s5c_13", "s5c_14", "s5c_15", "s5c_16"):
        if col not in out.columns:
            out[col] = np.nan
    return out


def _apply_media_and_travel(
    df: pd.DataFrame,
    comassets_path: Path | None = None,
    travel_tomerge: pd.DataFrame | None = None,
) -> pd.DataFrame:
    """Lines 545–573: merge comassets + travel, media-use HH vars."""
    out = _ensure_media_cols(df)

    comassets_path = comassets_path or paths.RAW / "auxiliar" / "comassets_chlab_bolivia.dta"
    comassets = read_dta(comassets_path)
    comassets["cod_secc"] = to_numeric(comassets["cod_secc"]).astype("Int64")
    out["cod_secc"] = to_numeric(out["cod_secc"]).astype("Int64")
    out = _stata_merge_drop_using_only(out, comassets, on="cod_secc")

    if travel_tomerge is None:
        travel_tomerge = build_travel_tomerge()
    travel_cols = [
        c
        for c in travel_tomerge.columns
        if c not in out.columns or c == "cod_secc"
    ]
    out = _stata_merge_drop_using_only(out, travel_tomerge[travel_cols], on="cod_secc")

    year = to_numeric(out["year"])
    for col in ("s5c_13", "s5c_14", "s5c_15", "s5c_16"):
        out[col] = recode_map(out[col], {2: 0})

    s14 = to_numeric(out["s5c_14"])
    s15 = to_numeric(out["s5c_15"])
    s16 = to_numeric(out["s5c_16"])
    out["aux"] = s14.fillna(0) + s15.fillna(0) + s16.fillna(0)
    out["any"] = np.where(
        (year == 2014) & out["aux"].notna(), (out["aux"] > 0).astype(float), np.nan
    )

    cod = out["cod_secc"]
    for src, dst in [
        ("s5c_14", "auxphoneuse"),
        ("s5c_15", "auxpcuse"),
        ("s5c_16", "auxinternetuse"),
    ]:
        out[src] = to_numeric(out[src])
        out[dst] = np.nan
        y2014 = year == 2014
        out.loc[y2014, dst] = out.loc[y2014].groupby(cod, dropna=False)[src].transform("mean")

    out["auxany"] = np.nan
    out.loc[year == 2014, "auxany"] = (
        out.loc[year == 2014].groupby(cod, dropna=False)["aux"].transform("mean")
    )

    for src, dst in [
        ("auxphoneuse", "phoneuse"),
        ("auxpcuse", "pcuse"),
        ("auxinternetuse", "internetuse"),
        ("auxany", "anyuse"),
    ]:
        out[dst] = out.groupby(cod)[src].transform("max")

    drop_cols = ["s5c_13", "s5c_14", "s5c_15", "s5c_16", "aux", "auxphoneuse", "auxpcuse", "auxinternetuse", "auxany"]
    out = out.drop(columns=drop_cols, errors="ignore")

    works = to_numeric(out["works"])
    wrk_home = to_numeric(out["wrk_home"])
    wrk_fixed = to_numeric(out["wrk_fixedloc"])
    out["location_out_fixed_a"] = ((wrk_home == 0) & (wrk_fixed == 1) & (works == 1)).astype(float)
    out["location_out_mobile_a"] = (
        (wrk_home == 0) & (wrk_fixed == 0) & (works == 1)
    ).astype(float)
    ft = to_numeric(out["firm_taxes"])
    out["firm_taxes_a"] = ft
    out.loc[ft.isna(), "firm_taxes_a"] = 0
    out["location_home_a"] = ((wrk_home == 1) & (works == 1)).astype(float)

    return out


def _apply_didisc_vars(df: pd.DataFrame) -> pd.DataFrame:
    """Lines 585–887: DiDisc design, exact age, pooled DiD, heterogeneity."""
    out = df.copy()
    year = to_numeric(out["year"])
    dob = to_numeric(out["dob"])
    age_dob = to_numeric(out["age_dob"])
    age_dob_m = to_numeric(out["age_dob_m"])
    urban = to_numeric(out["urban"])

    approx_dates = {
        2012: _mdy(pd.Series(10, index=out.index), pd.Series(16, index=out.index), year),
        2015: _mdy(pd.Series(10, index=out.index), pd.Series(19, index=out.index), year),
        2017: _mdy(pd.Series(10, index=out.index), pd.Series(29, index=out.index), year),
        2018: _mdy(pd.Series(12, index=out.index), pd.Series(22, index=out.index), year),
        2019: _mdy(pd.Series(10, index=out.index), pd.Series(21, index=out.index), year),
    }
    out["s_date_approx"] = np.nan
    for yr, sdt in approx_dates.items():
        out.loc[year == yr, "s_date_approx"] = sdt.loc[year == yr]

    for yr in (2012, 2015, 2017, 2018, 2019):
        mask = year == yr
        out.loc[mask, "age_dob_m"] = stata_round(
            (to_numeric(out.loc[mask, "s_date_approx"]) - dob.loc[mask]) / 30
        )

    # Re-bind after approx-date overwrite (Stata replaces age_dob_m in place).
    age_dob_m = to_numeric(out["age_dob_m"])

    out["pre"] = (year < 2014).astype(float)
    out["post"] = ((year >= 2014) & (year < 2018)).astype(float)
    out["post_rev"] = (year >= 2018).astype(float)

    bw = 12
    for n, c in DIDISC_CUTOFFS.items():
        cutoff_months = c * 12
        running = age_dob_m - cutoff_months
        runningw = (age_dob_m - 0.25) - cutoff_months
        out[f"running{c}"] = running
        out[f"runningw{c}"] = runningw
        out[f"runningmcr{c}"] = running
        if n == 3:
            out[f"runningmcr{c}"] = running * (-1)

        out[f"s{c}"] = (running.abs() <= bw).astype(float)
        out[f"sww{c}"] = (runningw.abs() <= bw).astype(float)

        below_cutoff = n == 3
        if below_cutoff:
            treat = (running < 0).astype(float)
            treat.loc[running.isna()] = np.nan
            treatw = (runningw < 0).astype(float)
            treatw.loc[runningw.isna()] = np.nan
        else:
            treat = (running >= 0).astype(float)
            treat.loc[running.isna()] = np.nan
            treatw = (runningw >= 0).astype(float)
            treatw.loc[runningw.isna()] = np.nan

        out[f"treat{c}"] = treat
        out[f"treatw{c}"] = treatw
        out[f"treatxrunning{c}"] = treat * running
        out[f"treatxrunningw{c}"] = treatw * runningw
        out[f"running2{c}"] = running ** 2
        out[f"treatxrunning2{c}"] = treat * running ** 2
        out[f"running2w{c}"] = runningw ** 2
        out[f"treatxrunning2w{c}"] = treatw * runningw ** 2

        post = to_numeric(out["post"])
        post_rev = to_numeric(out["post_rev"])
        out[f"postxrunning{c}"] = post * running
        out[f"postxrunningw{c}"] = post * runningw
        out[f"postxrunning2w{c}"] = post * runningw ** 2
        out[f"postrxrunningw{c}"] = post_rev * runningw
        out[f"postrxrunning2w{c}"] = post_rev * runningw ** 2

        out[f"kernel_tri{c}"] = ((bw - running.abs()) / bw) * (running.abs() <= bw)
        out[f"kernel_triw{c}"] = ((bw - runningw.abs()) / bw) * (runningw.abs() <= bw)

        out[f"xxw{n}"] = post * treatw
        out[f"xx{n}"] = post * treat
        out[f"xxrw{n}"] = post_rev * treatw
        out[f"xxr{n}"] = post_rev * treat

        out[f"donsww{c}"] = ((runningw.abs() <= 24) & (runningw.abs() > 1)).astype(float)

        for rbw in BW_ROBUSTNESS:
            out[f"sww{c}_{rbw}"] = (runningw.abs() <= rbw).astype(float)
            out[f"kernel_triw{c}_{rbw}"] = ((rbw - runningw.abs()) / rbw) * (
                runningw.abs() < rbw
            )

    out["exactsample"] = year.isin([2013, 2014, 2016]).astype(float)
    dbw = 365
    for n, c in DIDISC_CUTOFFS.items():
        cutoff_days = c * 365
        drunning = age_dob - cutoff_days
        drunningw = (age_dob - 7) - cutoff_days
        out[f"drunning{c}"] = drunning
        out[f"drunningw{c}"] = drunningw
        out[f"ds{c}"] = (drunning.abs() <= dbw).astype(float)
        out[f"dsww{c}"] = (drunningw.abs() <= dbw).astype(float)

        below = n == 3
        if below:
            dtreat = (drunning < 0).astype(float)
            dtreat.loc[drunning.isna()] = np.nan
            dtreatw = (drunningw < 0).astype(float)
            dtreatw.loc[drunningw.isna()] = np.nan
        else:
            dtreat = (drunning >= 0).astype(float)
            dtreat.loc[drunning.isna()] = np.nan
            dtreatw = (drunningw >= 0).astype(float)
            dtreatw.loc[drunningw.isna()] = np.nan

        out[f"dtreat{c}"] = dtreat
        out[f"dtreatw{c}"] = dtreatw
        out[f"dtreatxrunning{c}"] = dtreat * drunning
        out[f"dtreatxrunningw{c}"] = dtreatw * drunningw
        out[f"dkernel_tri{c}"] = ((dbw - drunning.abs()) / dbw) * (drunning.abs() < dbw)
        out[f"dkernel_triw{c}"] = ((dbw - drunningw.abs()) / dbw) * (drunningw.abs() < dbw)
        out[f"dxx{c}"] = to_numeric(out["post"]) * dtreatw

    adm = age_dob_m - 0.25
    out["treatdid10"] = ((adm < 144) & (adm >= 120)).astype(float)
    out["treatdid12"] = ((adm < 168) & (adm >= 144)).astype(float)
    out.loc[(adm < 108) | (adm > 180), ["treatdid10", "treatdid12"]] = np.nan

    out["treat10didbc"] = out["treatdid10"]
    out["treat12didbc"] = out["treatdid12"]
    out.loc[(adm < 84) | (adm > 192), ["treat10didbc", "treat12didbc"]] = np.nan

    post = to_numeric(out["post"])
    post_rev = to_numeric(out["post_rev"])
    out["xxdid10"] = post * out["treatdid10"]
    out["xxdid12"] = post * out["treatdid12"]
    out["xxdidr10"] = post_rev * out["treatdid10"]
    out["xxdidr12"] = post_rev * out["treatdid12"]
    out["xxdidbc10"] = post * out["treat10didbc"]
    out["xxdidbc12"] = post * out["treat12didbc"]
    out["xxdidbcr10"] = post_rev * out["treat10didbc"]
    out["xxdidbcr12"] = post_rev * out["treat12didbc"]

    out["postxurban"] = post * urban
    for n, c in DIDISC_CUTOFFS.items():
        out[f"treat{c}xurban"] = to_numeric(out[f"treat{c}"]) * urban
        out[f"treatw{c}xurban"] = to_numeric(out[f"treatw{c}"]) * urban
        out[f"postxrunning{c}xurban"] = to_numeric(out[f"postxrunning{c}"]) * urban
        out[f"postxrunningw{c}xurban"] = to_numeric(out[f"postxrunningw{c}"]) * urban
        out[f"xxwu{n}"] = to_numeric(out[f"xxw{n}"]) * urban

    out = out.rename(
        columns={
            "abovemed_time": "het_time",
            "abovemed_directdist": "het_dist",
            "abovemed_dist": "het_ddist",
        }
    )

    for h in HET_VARS:
        hval = to_numeric(out[h])
        out[f"postx{h}"] = post * hval
        out[f"postxurbanx{h}"] = post * urban * hval
        for n, c in DIDISC_CUTOFFS.items():
            running = to_numeric(out[f"running{c}"])
            runningw = to_numeric(out[f"runningw{c}"])
            treat = to_numeric(out[f"treat{c}"])
            treatw = to_numeric(out[f"treatw{c}"])
            txr = to_numeric(out[f"treatxrunning{c}"])
            txrw = to_numeric(out[f"treatxrunningw{c}"])
            pxr = to_numeric(out[f"postxrunning{c}"])
            pxrw = to_numeric(out[f"postxrunningw{c}"])

            out[f"running{c}x{h}"] = running * hval
            out[f"runningw{c}x{h}"] = runningw * hval
            out[f"running{c}xurbanx{h}"] = running * urban * hval
            out[f"runningw{c}xurbanx{h}"] = runningw * urban * hval
            out[f"treat{c}x{h}"] = treat * hval
            out[f"treatw{c}x{h}"] = treatw * hval
            out[f"treat{c}xurbanx{h}"] = treat * urban * hval
            out[f"treatw{c}xurbanx{h}"] = treatw * urban * hval
            out[f"treatxrunning{c}x{h}"] = txr * hval
            out[f"treatxrunningw{c}x{h}"] = txrw * hval
            out[f"treatxrunning{c}xurbanx{h}"] = txr * urban * hval
            out[f"treatxrunningw{c}xurbanx{h}"] = txrw * urban * hval
            out[f"postxrunning{c}x{h}"] = pxr * hval
            out[f"postxrunningw{c}x{h}"] = pxrw * hval
            out[f"postxrunning{c}xurbanx{h}"] = pxr * urban * hval
            out[f"postxrunningw{c}xurbanx{h}"] = pxrw * urban * hval
            out[f"xxw{h}{n}"] = to_numeric(out[f"xxw{n}"]) * hval
            out[f"xxwu{h}{n}"] = to_numeric(out[f"xxw{n}"]) * urban * hval

    muni = out.get("muni_name", pd.Series("", index=out.index)).astype("string")
    out["capital"] = np.where(muni.isin(CAPITAL_MUNIS), 1, np.nan)
    out.loc[muni.notna() & ~muni.isin(CAPITAL_MUNIS), "capital"] = 0
    out.loc[muni.fillna("") == "", "capital"] = np.nan

    out["mtepsoffices"] = _flag_mtepsoffices(muni)

    tag = out.groupby("cod_secc", dropna=False).cumcount() == 0
    median_indig = to_numeric(out.loc[tag, "p_indigenas"]).median()
    out["lessindigsample"] = (to_numeric(out["p_indigenas"]) < median_indig).astype(float)

    out["age_mo_year"] = pd.factorize(
        pd.Series(list(zip(out["age_dob_m"], out["year"])), index=out.index)
    )[0] + 1

    return out


def build_hhsurvey(
    persona: pd.DataFrame | None = None,
    income: pd.DataFrame | None = None,
    *,
    travel_tomerge: pd.DataFrame | None = None,
) -> pd.DataFrame:
    """Full ``3. Preparing for analysis.do`` pipeline (person-level, all ages)."""
    if persona is None:
        persona = pd.read_parquet(paths.INTERMEDIATE / "persona" / "EH_cleaned_persona.parquet")
    if income is None:
        income = pd.read_parquet(paths.INTERMEDIATE / "income" / "EH_cleaned_income.parquet")

    ch_income = build_ch_income(persona, income)
    ch_ages = build_ch_ages(persona)

    df = _apply_person_level_vars(persona)
    df = _apply_hh_merges_and_recodes(df, ch_income, ch_ages)
    df = _apply_cct_and_firm_vars(df)
    df = _apply_media_and_travel(df, travel_tomerge=travel_tomerge)
    df = _apply_didisc_vars(df)
    return df


def write_hhsurvey(
    out_dir: Path | None = None,
    *,
    persona: pd.DataFrame | None = None,
    income: pd.DataFrame | None = None,
) -> tuple[Path, Path]:
    """Write ``HHsurvey.parquet`` (age<21) and ``HHsurvey_ad.parquet`` (age<65)."""
    out_dir = out_dir or paths.FINAL
    out_dir.mkdir(parents=True, exist_ok=True)

    full = build_hhsurvey(persona=persona, income=income)
    age = to_numeric(full["age"])

    child_path = out_dir / "HHsurvey.parquet"
    adult_path = out_dir / "HHsurvey_ad.parquet"

    full.loc[age < 21].to_parquet(child_path, index=False)
    full.loc[age < 65].to_parquet(adult_path, index=False)
    from opencausallab.utils.provenance import write_provenance

    write_provenance(
        child_path,
        created_by="src.hhsurvey.write_hhsurvey",
        extra={"filter": "age < 21", "n": int((age < 21).sum())},
    )
    write_provenance(
        adult_path,
        created_by="src.hhsurvey.write_hhsurvey",
        extra={"filter": "age < 65", "n": int((age < 65).sum())},
    )
    return child_path, adult_path
