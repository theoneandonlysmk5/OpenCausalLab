# Data Pipeline Lineage Map

**Paper:** *The Effects of Expanding Worker Rights to Children* (Lakdawala, Martínez Heredia, Vera-Cossio)  
**Source package:** Harvard Dataverse DOI 10.7910/DVN/WJIQ6G  
**Phase:** 1 — reverse engineering (no code translation yet)  
**Primary analysis file:** `3.CleanData/1. Household Survey/HHsurvey.dta` → target `data/final/HHsurvey.parquet`

This document maps every major dataset that flows through the authors’ Stata pipeline. Intermediate files under `3.CleanData/` are **not** shipped in the Dataverse package; they must be rebuilt.

---

## High-level architecture

Two independent survey pipelines feed analysis. Main results (Tables 1–6, Figures 2–4) use the **Household Survey (EH)** path ending in `HHsurvey`. Child Labor Survey (ETI 2008 / ENNA 2016) is a **secondary** path for risk/injury and stacked robustness.

```text
RAW (1.RawData)
 │
 ├── Household Survey 2012–2019  ──────────────────────────────┐
 │     Persona / Income / Expenses / UPM crosswalks            │
 │                                                             ▼
 │   Harmonize year-by-year → Compile → Clean → Prepare
 │                                                             │
 │   Auxiliar: travel_capitales, comassets_chlab_bolivia       │
 │                                                             ▼
 │                                              HHsurvey.dta   ◄── MAIN
 │                                              HHsurvey_ad.dta
 │
 └── Child Labor Survey 2008 & 2016  ──────────────────────────┐
       child + household + UPM                                 │
                                                               ▼
                         RW_child_labor_survey.dta  ◄── SECONDARY
```

`Master_00.do` execution order:

1. Household: Persona (2012–2019) → Income (2012–2017) → Expenses (2012–2019)  
2. Compile + clean Persona / Income / Expenses  
3. `3. Preparing for analysis.do` → **`HHsurvey.dta`**  
4. Child Labor Survey scripts 1–9 → **`RW_child_labor_survey.dta`**  
5. Figures and tables (consume cleaned outputs)

---

## Pipeline A — Household Survey → `HHsurvey`

### Stage A0 — Raw inputs (shipped)

| Dataset | Location | Role |
|---------|----------|------|
| `EH{YYYY}_Persona.dta` | `1.RawData/Household Survey/{YYYY}/` | Person-level demographics & labor (all years 2012–2019) |
| `EH{YYYY}_vivienda.dta` | some years | Dwelling; merged into Persona for 2013, 2014, 2016 |
| `EH{YYYY}_GastosAlimentarios.dta` | most years | Food expenses |
| `EH{YYYY}_GastosNoAlimentarios.dta` | most years | Non-food expenses |
| `EH{YYYY}_Equipamiento.dta` | most years | Durable goods / equipment |
| `upm_2001-2013_relabeled.dta` | `1.RawData/Household Survey/` | UPM → municipality crosswalk |
| `upm_2015-2017_relabeled.dta` | same | UPM crosswalk |
| `upm_2016_relabeled.dta` | same | UPM crosswalk |
| `travel_capitales.dta` | `1.RawData/auxiliar/` | Distance / travel time to labor offices |
| `comassets_chlab_bolivia.dta` | `1.RawData/auxiliar/` | Municipality assets / connectivity |
| `baselineCL.dta` | `1.RawData/auxiliar/` | 2012 baseline child-labor rates (**used in some tables, not in HHsurvey build**) |
| `articledata.dta` | `1.RawData/auxiliar/` | Media articles (**Figure A2 only**) |

**Note:** Income harmonization scripts exist only for **2012–2017**. Expenses and Persona cover **2012–2019**.

### Stage A1 — Year-wise harmonizing (relabel / rename)

Produced under `3.CleanData/1. Household Survey/`:

| Produced by | Reads | Writes |
|-------------|-------|--------|
| `EH_Persona_YYYY.do` (×8) | Raw Persona (+ vivienda some years) | `Persona/EH{YYYY}_Persona_relabel` |
| `EH_Income_YYYY.do` (×6) | Raw Persona | `Income/EH{YYYY}_Income_relabel` |
| `EH_Expenses_YYYY.do` (×8) | Food / non-food / equipment (+ Persona some years) | `Expenses/EH{YYYY}_expenses_relabel` (+ year-specific intermediate gasto files) |

### Stage A2 — Compile across years

| Produced by | Reads | Writes |
|-------------|-------|--------|
| `2.1.EH_Persona_compiling.do` | All `EH*_Persona_relabel` + 3 UPM files | `Persona/EH_compiled_persona` |
| `2.3.EH_Income_compiling.do` | All `EH*_Income_relabel` | `Income/EH_compiled_income` |
| `2.5.EH_Expenses_compiling.do` | All `EH*_expenses_relabel` | `Expenses/EH_compiled_expenses` |

### Stage A3 — Clean compiled panels

| Produced by | Reads | Writes |
|-------------|-------|--------|
| `2.2.EH_Persona_cleaned.do` | `EH_compiled_persona` | `Persona/EH_cleaned_persona` |
| `2.4.EH_Income_cleaned.do` | `EH_compiled_income` | `Income/EH_cleaned_income` |
| `2.6.EH_Expenses_cleaned.do` | `EH_compiled_expenses` | `Expenses/EH_cleaned_expenses` |

### Stage A4 — Final analysis merge (`3. Preparing for analysis.do`)

```text
travel_capitales.dta
        │
        ▼
travel_capitales_tomerge.dta     (medians, capital/MTEPS flags)
        │
EH_cleaned_persona.dta ─────────┐
        │                       │
        │  joinby id_year       │
        ▼                       │
EH_cleaned_income ──► tempfile ch_income (hhsize, child_income, income_q, …)
        │                       │
EH_cleaned_persona ──► tempfile ch_ages (hh_agecat1–4)
        │                       │
        ▼                       │
  person-level panel ◄──────────┘  merge folio×year
        │
        ├── merge comassets_chlab_bolivia (cod_secc)
        ├── merge travel_capitales_tomerge (cod_secc)
        ├── construct outcomes, CCT eligibility, DiDisc design vars
        │
        ▼
   HHsurvey.dta          ◄── consumed by Table 3 and most main exhibits
   HHsurvey_ad.dta       ◄── adult / alternate sample cut
```

**Expenses** (`EH_cleaned_expenses`) are **not** merged into `HHsurvey` in this script; they are used later (e.g. Table A8 expenditure).

**Critical design variables created here (not earlier):** `pre` / `post` / `post_rev`, running variables `running14` / `runningw14`, bandwidth samples `s14` / `sww14`, treatment `treat14`, plus work outcomes and household moderators.

---

## Pipeline B — Child Labor Survey → `RW_child_labor_survey`

| Stage | Script | Reads | Writes |
|-------|--------|-------|--------|
| B1 | `1-cleaning_database_2008_child.do` | `ETI_2008.dta` | `childworkbo_2008.dta` |
| B2 | `2-cleaning_database_2008_household.do` | `ETI_2008_household.dta` | `household_2008.dta` |
| B3 | `3-calculating_variables_2008.do` | child + hh + `upm_2001-2013.dta` | municipality / bdate temps; updates child & hh |
| B4 | `4-harmonizedvar_child_2008.do` | `childworkbo_2008.dta` | same (overwrite) |
| B5 | `5-cleaning_database_2016_child.do` | `ENNA_2016.dta` | `childworkbo_2016.dta` |
| B6 | `6-cleaning_database_2016_household.do` | `ENNA_2016_household.dta` | `household_2016.dta` |
| B7 | `7-calculating_variables_2016.do` | child/hh + `upm_2016.dta` (+ briefly uses `HHsurvey.dta`) | municipality / belonging temps |
| B8 | `8-harmonizedvar_child_2016.do` | `childworkbo_2016.dta` | same (overwrite) |
| B9 | `9-Cleaning child survey data.do` | 2008+2016 child/hh + `travel_capitales_tomerge` | `RD_2008.dta`, `RD_2016.dta`, **`RW_child_labor_survey.dta`** |

**Dependency note:** Script 7 reads `HHsurvey.dta`, so Pipeline A must finish before the later Child Labor stages if running the full master file in order.

---

## Analysis consumers (what uses what)

| Consumer | Primary input |
|----------|---------------|
| Tables 1–6, Figures 2–4 (main) | `HHsurvey.dta` |
| Table A8 (expenditure) | `HHsurvey` + expenses path |
| Tables A16–A19, Figure A12 (risk/injury) | `RW_child_labor_survey.dta` / stacked CS |
| Table A10 / A4 (baseline CL robustness) | `HHsurvey` + `baselineCL.dta` |
| Figure A2 | `articledata.dta` |

---

## OpenCausalLab Python module map

File-by-file `.do` → `.py` mapping: [`stata_python_map.md`](stata_python_map.md). Status notes below stay here because they record row counts and outputs.

### Module A status (Persona 2012–2019 + compile/clean)

Year-level relabel outputs:

| Year | Rows | Output |
|------|------|--------|
| 2012 | 31,935 | `EH2012_Persona_relabel.parquet` |
| 2013 | 35,693 | `EH2013_Persona_relabel.parquet` |
| 2014 | 36,618 | `EH2014_Persona_relabel.parquet` |
| 2015 | 37,364 | `EH2015_Persona_relabel.parquet` |
| 2016 | 38,549 | `EH2016_Persona_relabel.parquet` |
| 2017 | 38,201 | `EH2017_Persona_relabel.parquet` |
| 2018 | 37,517 | `EH2018_Persona_relabel.parquet` |
| 2019 | 39,605 | `EH2019_Persona_relabel.parquet` |

Compile + clean:

| Dataset | Rows | Notes |
|---------|------|-------|
| `EH_compiled_persona.parquet` | 295,482 | Append 2012–2019 + UPM merges |
| `EH_cleaned_persona.parquet` | 295,482 | Analysis names (`works`, `male`, `cod_secc`, …) |

- Run years: `python scripts/run_persona_all_years.py`
- Run compile/clean: `python scripts/run_persona_compile_clean.py`
- **Note:** Stata only builds `cod_prov`/`cod_secc` for 2012–2016 (and 2014 via `mun`). 2017–2019 municipality codes are missing in the original script; Python preserves that.
- Next: **Expenses** module (`src/expenses.py`) or **Child Labor Survey** (`src/child_labor_survey.py`)

### Module B status (Income 2012–2017 + compile/clean)

Run years: `python scripts/run_income_all_years.py`  
Run compile/clean: `python scripts/run_income_compile_clean.py`

Outputs under `data/intermediate/income/`:

| Year | Rows | Output |
|------|------|--------|
| 2012 | 31,935 | `EH2012_Income_relabel.parquet` |
| 2013 | 35,693 | `EH2013_Income_relabel.parquet` |
| 2014 | 36,618 | `EH2014_Income_relabel.parquet` |
| 2015 | 37,364 | `EH2015_Income_relabel.parquet` |
| 2016 | 38,549 | `EH2016_Income_relabel.parquet` |
| 2017 | 38,201 | `EH2017_Income_relabel.parquet` |

Compile + clean:

| Dataset | Rows |
|---------|------|
| `EH_compiled_income.parquet` | 218,360 |
| `EH_cleaned_income.parquet` | 218,360 |

**Quirks preserved from Stata:** 2014 `aguinaldo_yearly_main` uses `s6c_26a`; 2014 `extra_wages_main` excludes aguinaldo; 2016 sec occupation uses `s06g_48a`/`g_50`/`g_51`; 2017 sec wage `s06g_47a`, revenue `g_49`, updated FX rates; `y_labor_main` uses total `y_nw_labor` not main-only.

### Module C status (HHsurvey — `3. Preparing for analysis.do`)

Run: `python scripts/run_hhsurvey.py`

Reads:

| Input | Rows |
|-------|------|
| `EH_cleaned_persona.parquet` | 295,482 |
| `EH_cleaned_income.parquet` | 218,360 |
| `travel_capitales.dta` | 339 municipalities |
| `comassets_chlab_bolivia.dta` | 339 municipalities |

Outputs under `data/final/`:

| Dataset | Rows | Filter |
|---------|------|--------|
| `HHsurvey.parquet` | 125,368 | `age < 21` |
| `HHsurvey_ad.parquet` | 275,288 | `age < 65` |

614 columns including DiDisc design vars (`running14`, `treatw14`, `sww14`, `kernel_triw14`, heterogeneity interactions, pooled DiD).

**Quirks preserved from Stata:** `joinby unmatched(both)` for ch_income; `lang_spa_h` without `h_hh==1`; `p75_a_*` uses `size_*` dummies; treat14 cutoff uses `running < 0`, cutoffs 10/12 use `running >= 0`; approximate survey dates refill `age_dob_m` for 2012/2015/2017/2018/2019; `s5c_13–16` created as NaN when absent.

### Module D status (Table 3 — `Table_3_DDisc_Work.do`)

Run: `python scripts/run_table3.py`

Spec: WLS on `kernel_triw14`, bandwidth 12 months, triangular kernel, `vce(cluster age_mo_year)`, controls + `depto×year` FE. Focal coeffs: `xxw3` (post×treat) and `xxrw3` (post_rev×treat).

| Output | Path |
|--------|------|
| Long / wide estimates | `data/final/tables/table3_didisc_work*.csv` |
| vs manuscript deltas | `data/final/tables/table3_vs_published.csv` |
| Local sample for CATE | `data/final/table3_local_sample.parquet` |

Python vs manuscript (works `xxw3`): about **−0.036 (0.017)** vs printed **−0.039 (0.017)**; N 11,992 vs 11,991. Residual gap is expected without Stata-built `HHsurvey.dta` (microdata + WLS sandwich numerics).

### Module E status (subgroup DiDisc + local CATE)

Runs:

```bash
python scripts/run_subgroups.py
python scripts/run_causal_ml.py
```

| Output | Path |
|--------|------|
| Subgroup DiDisc | `data/final/tables/subgroup_didisc*.csv` |
| CATE summary / importance | `data/final/tables/cate_*.csv` |

Fixes: `to_numeric` now handles bool travel flags (`het_time` / `het_dist`); HHsurvey het interactions patched.

Notes: Table A3 Stata `nlcom` labels swap girls/boys relative to `male=0/1` coding — we store both. Forest uses predetermined moderators only; drops 2017–2019 when distance is missing (N≈7,653).

---

## Machine-readable edges

Raw parser output (use / save / merge / append / do calls):  
[`lineage_edges_raw.csv`](lineage_edges_raw.csv)

Curated dataset inventory:  
[`data_lineage.csv`](data_lineage.csv)

Re-run parser:

```bash
source ../.venv/bin/activate
python scripts/parse_stata_lineage.py
```
