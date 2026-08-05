# OpenCausalLab

Open-source reconstruction of empirical economics pipelines in Python, starting with:

> *The Effects of Expanding Worker Rights to Children*  
> Lakdawala, Martínez Heredia, Vera-Cossio (Dataverse DOI [10.7910/DVN/WJIQ6G](https://doi.org/10.7910/DVN/WJIQ6G))

**Thesis of the project:** systematically translate Stata empirical workflows into an open Python stack **without breaking identification**.

## Status

| Phase | Goal | Status |
|-------|------|--------|
| 1 | Reverse-engineer data lineage (no translation yet) | Done — [`docs/pipeline.md`](docs/pipeline.md) |
| 2 | Translate modules one at a time | Persona + Income + HHsurvey + Table 3 + **subgroups / CATE** |
| 3 | Validate each module vs Stata semantics | Partial (sanity checks; full Stata parity pending) |
| 4 | Build `HHsurvey.parquet` and replicate tables in Python | Table 3 + subgroup DiDisc + local CATE done |
| 5 | Modern causal ML (local CATE / exploratory heterogeneity) | **MVP done** — honest GRF on DiDisc score |

### Module A quickstart

```bash
source ../.venv/bin/activate
python scripts/run_persona_all_years.py
# → data/intermediate/persona/EH{YEAR}_Persona_relabel.parquet
```

## Layout

```text
OpenCausalLab/
├── data/           # raw → intermediate → final (parquet)
├── src/            # Python ETL modules (Phase 2+)
├── notebooks/      # exploration and reports
├── docs/           # lineage, identification, variable roles
├── tests/          # validation against expected moments
├── scripts/        # lineage parser and utilities
└── vendor/         # extracted original .do files (reference only)
```

## Table 3 (age-14 DiDisc)

```bash
source ../.venv/bin/activate
python scripts/run_table3.py
```

## Main tables (1–6)

```bash
python scripts/run_main_tables.py
# → data/final/tables/main_tables_ledger.csv
```

HHsurvey-based panels are implemented. Child Labor Survey panels (Table 1C, 2B, Table 5 cols 1–4) need `RW_child_labor_survey.parquet` (pipeline in progress).

```bash
python scripts/run_validation_audit.py
# → data/final/validation/discrepancy_ledger.csv
```

See [`docs/validation_protocol.md`](docs/validation_protocol.md). Stata `.do` files are the formal specification.

## Subgroup DiDisc + local CATE

```bash
python scripts/run_subgroups.py    # gender / urban / indig / MTEPS distance
python scripts/run_causal_ml.py    # cross-fitted DiDisc score + honest GRF
# → data/final/tables/subgroup_*.csv, cate_*.csv
```

Reports **local CATE summaries only** (no individual ITEs).

## Immediate next step

Holdout-validated deep dives on forest-discovered splits; optional BART robustness.

## Environment

From the parent research folder:

```bash
source ../.venv/bin/activate   # if using the shared venv in research/001
```

Raw Stata microdata remain in `../dataverse_files.zip` until extracted into `data/raw/`.
