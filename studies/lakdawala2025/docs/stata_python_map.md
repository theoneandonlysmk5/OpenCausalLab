# Stata `.do` → Python `.py` map

File-by-file map of the authors’ specification under [`../vendor/stata_dofiles/`](../vendor/stata_dofiles/) to this study’s Python modules under [`../src/`](../src/). Dataset lineage (what each `.do` reads and writes) stays in [`pipeline.md`](pipeline.md) and [`data_lineage.csv`](data_lineage.csv). Implementation differences are in [`python_vs_stata.md`](python_vs_stata.md).

Paths below are relative to `studies/lakdawala2025/`. Stata paths omit the `vendor/stata_dofiles/` prefix.

| Status | Meaning |
|--------|---------|
| **Ported** | Dedicated Python translation of that script |
| **Folded** | Logic lives in a shared module (not 1:1) |
| **Not ported** | Out of current replication scope |
| **Extension** | Python-only; not a `.do` translation |

---

## Household Survey ETL

| Stata `.do` | Python | Status |
|-------------|--------|--------|
| `data_cleaning/Household Survey/1. Harmonizing/Persona/EH_Persona_2012.do` | `src/persona/y2012.py` | Ported |
| `…/Persona/EH_Persona_2013.do` | `src/persona/y2013.py` | Ported |
| `…/Persona/EH_Persona_2014.do` | `src/persona/y2014.py` | Ported |
| `…/Persona/EH_Persona_2015.do` | `src/persona/y2015.py` | Ported |
| `…/Persona/EH_Persona_2016.do` | `src/persona/y2016.py` | Ported |
| `…/Persona/EH_Persona_2017.do` | `src/persona/y2017.py` | Ported |
| `…/Persona/EH_Persona_2018.do` | `src/persona/y2018.py` | Ported |
| `…/Persona/EH_Persona_2019.do` | `src/persona/y2019.py` | Ported |
| `…/2. Compiling/2.1.EH_Persona_compiling.do` | `src/persona/compile_clean.py` (`compile_persona`) | Ported |
| `…/2. Compiling/2.2.EH_Persona_cleaned.do` | `src/persona/compile_clean.py` (`clean_persona`) | Ported |
| `…/Income/EH_Income_2012.do` | `src/income/y2012.py` | Ported |
| `…/Income/EH_Income_2013.do` | `src/income/y2013.py` | Ported |
| `…/Income/EH_Income_2014.do` | `src/income/y2014.py` | Ported |
| `…/Income/EH_Income_2015.do` | `src/income/y2015.py` | Ported |
| `…/Income/EH_Income_2016.do` | `src/income/y2016.py` | Ported |
| `…/Income/EH_Income_2017.do` | `src/income/y2017.py` | Ported |
| `…/2. Compiling/2.3.EH_Income_compiling.do` | `src/income/compile_clean.py` (`compile_income`) | Ported |
| `…/2. Compiling/2.4.EH_Income_cleaned.do` | `src/income/compile_clean.py` (`clean_income`) | Ported |
| `…/3. Preparing for analysis.do` | `src/hhsurvey.py` | Ported |
| `…/Expenses/EH_Expenses_2012.do`–`2019.do` | — (planned `src/expenses.py`) | Not ported |
| `…/2. Compiling/2.5.EH_Expenses_compiling.do` | — | Not ported |
| `…/2. Compiling/2.6.EH_Expenses_cleaned.do` | — | Not ported |

Persona year files share helpers in `src/persona/common.py`. Income year files share `src/income/common.py`. `src/household.py` and `src/income_api.py` are facades over those packages, not extra Stata translations. UPM / municipality merges from `2.1.EH_Persona_compiling.do` live in `compile_persona`, not a separate `municipality.py`.

Expenses are omitted from `HHsurvey` in the authors’ prepare script as well; they are used later (e.g. Table A8).

---

## Child Labor Survey ETL

Nine `.do` files map onto the `src/child_labor/` package. `src/child_labor/build.py` orchestrates scripts **1–3, 5–7, and 9**.

| Stata `.do` | Python | Status |
|-------------|--------|--------|
| `data_cleaning/Child Labor Survey/1-cleaning_database_2008_child.do` | `src/child_labor/raw.py` (`load_child_2008`) | Folded |
| `…/2-cleaning_database_2008_household.do` | `src/child_labor/raw.py` (`load_household_2008`) | Folded |
| `…/3-calculating_variables_2008.do` | `src/child_labor/variables.py` (2008 helpers) | Folded |
| `…/4-harmonizedvar_child_2008.do` | — (label / overwrite stage) | Not ported |
| `…/5-cleaning_database_2016_child.do` | `src/child_labor/raw.py` (`load_child_2016`) | Folded |
| `…/6-cleaning_database_2016_household.do` | `src/child_labor/raw.py` (`load_household_2016`) | Folded |
| `…/7-calculating_variables_2016.do` | `src/child_labor/variables.py` (2016 helpers) | Folded |
| `…/8-harmonizedvar_child_2016.do` | — (label / overwrite stage) | Not ported |
| `…/9-Cleaning child survey data.do` | `src/child_labor/merge.py`, `household.py`, `design.py` | Folded |

`src/child_labor/utils.py` has shared Stata-style helpers (`mdy`, merge keep rules, person `id`).

---

## Main tables

| Stata `.do` | Python | Status |
|-------------|--------|--------|
| `main_tables/Table_1_Desc_Statistics.do` | `src/main_tables.py` (`table1_panel_a`, `table1_panel_b`); CL Panel C in `src/child_labor/tables.py` | Ported |
| `main_tables/Table_2_Desc_Statistics_by_employer_type.do` | `src/main_tables.py` (`table2_panel_a`); CL Panel B in `src/child_labor/tables.py` | Ported |
| `main_tables/Table_3_DDisc_Work.do` | `src/table3.py` | Ported |
| `main_tables/Table_4_DDisc_HeterogeneityDistanceToInspectors.do` | `src/main_tables.py` (`run_table4`); also `src/subgroup.py` | Ported |
| `main_tables/Table_5_DDisc_RiskInjuryWages.do` | CL cols 1–4: `src/child_labor/tables.py`; wage cols: `src/main_tables.py` (`run_table5_wage`) | Ported |
| `main_tables/Table_6_DDisc_JobLocationFirmSize.do` | `src/main_tables.py` (`run_table6`) | Ported |

---

## Main figures

| Stata `.do` | Python | Status |
|-------------|--------|--------|
| `main_figures/Fig2_DDiscEvtStudy.do` | — | Not ported |
| `main_figures/Fig3_RDgraphs_14.do` | — | Not ported |
| `main_figures/Fig4_Distance_ContractsInsurance.do` | — | Not ported |

---

## Appendix

| Stata `.do` | Python | Status |
|-------------|--------|--------|
| `appendix_tables/Table_A3_DDisc_HeterogeneityByGender.do` | `src/subgroup.py` | Ported |
| All other `appendix_tables/Table_A*.do` (A2, A4–A20) | — | Not ported |
| All `appendix_figures/Figure_A*.do` | — | Not ported |

Table A8 (expenditure) would also need the unported expenses ETL.

---

## Orchestration and runners

| Stata `.do` | Python | Status |
|-------------|--------|--------|
| `Master_00.do` | `ocl study lakdawala2025 …` and `scripts/run_*.py` | Folded |

CLI scripts are entry points, not extra translations: `run_persona_all_years.py`, `run_persona_compile_clean.py`, `run_income_all_years.py`, `run_income_compile_clean.py`, `run_hhsurvey.py`, `run_table3.py`, `run_subgroups.py`, `run_causal_ml.py`.

---

## Python-only modules (no `.do` counterpart)

| Python | Role |
|--------|------|
| `src/causal_ml.py` | Exploratory CATE / forest layer — **extension**, not in the replication claim |
| `src/validation/` | Spec checklists, merge audits, bandwidth checks |
| `src/paths.py` | Study path constants |
| `src/persona/common.py`, `src/income/common.py`, `src/child_labor/utils.py` | Shared helpers |
| `opencausallab/stata_semantics/stata_utils.py` | Shared Stata semantics (`round`, `inlist`, `recode`, …) |

---

## How to use this map

1. Open the `.do` file as the specification.
2. Open the listed `.py` module (or function) as the translation.
3. For data flow and row counts, use [`pipeline.md`](pipeline.md).
4. For numerical agreement, use [`verification.md`](verification.md).
