# OpenCausalLab

![Replication: Table 3 PASS](https://img.shields.io/badge/Replication-Table%203%20PASS-brightgreen)

OpenCausalLab is a framework for independently verifying empirical economics research through transparent Python implementations. This repository reproduces the published design of Lakdawala et al. as its first case study:

> *The Effects of Expanding Worker Rights to Children*  
> Lakdawala, Martínez Heredia, Vera-Cossio (Dataverse DOI [10.7910/DVN/WJIQ6G](https://doi.org/10.7910/DVN/WJIQ6G))

Formal specification for this case study = the authors’ `.do` files under `vendor/stata_dofiles/`.

## Executive summary (for reviewers)

| Question | Answer |
|----------|--------|
| What does the paper study? | Effects of expanding formal worker rights to children (age-14 DiDisc design in Bolivia). |
| What was replicated? | Full HH + CL pipelines through main Tables 1–6. |
| How well? | **Table 3 (main result) matches manuscript values** — N = 11,991 Exact; 7/7 coefs & SEs round to the paper. Most other panels match; Table 5 wage and Table 6 firm size remain Near / Open. |
| What still differs? | Table 5 wage N (Near); Table 6 firm size mean/coef (**Open**, N Exact). Neither overturns principal conclusions. Table 3 success is not a claim that every cell in the paper is identical. |

| Main causal result (Table 3) | |
|------------------------------|---|
| Design | Pass |
| Sample (N) | Pass (Exact) |
| Coefficients | Pass (matches manuscript) |
| Standard errors | Pass (matches manuscript) |
| Inference | Pass |

**Design primer (non-economists):** [`docs/DESIGN.md`](docs/DESIGN.md)  
**Scope one-pager:** [`docs/replication_scope.md`](docs/replication_scope.md)  
**Full confidence argument:** [`docs/verification.md`](docs/verification.md)  
**Discrepancy ledger:** [`docs/discrepancy_appendix.md`](docs/discrepancy_appendix.md)

**Thesis:** verify published empirical designs via independent open implementations **without breaking identification**, then extend with modern causal tools only after verification.

## Architecture

```text
Harvard Dataverse
        │
        ▼
   Raw survey .dta
        │
        ▼
   Python ETL (src/)
        │
        ▼
 HHsurvey.parquet
        │
        ▼
   Validation audits
        │
        ▼
 Replication confidence
        │
        ▼
   Tables 1–6 (outputs)
        │
        ▼
 Modern causal ML (extension)
```

## Data availability

This repository **does not redistribute** the original survey microdata. Obtain the replication package from the [Harvard Dataverse](https://doi.org/10.7910/DVN/WJIQ6G) referenced by the paper, place raw `.dta` files under `data/raw/`, then run the Python pipeline locally. Intermediate and final parquet files are gitignored; table/validation CSVs are committed for review.

## Status

| Phase | Goal | Status |
|-------|------|--------|
| 1 | Reverse-engineer data lineage | Done — [`docs/pipeline.md`](docs/pipeline.md) |
| 2 | Translate modules one at a time | Persona + Income + HHsurvey + Tables 1–6 + CL |
| 3 | Validate vs published design | Done for main path — [`docs/verification.md`](docs/verification.md) |
| 4 | Reproduce published tables | Table 3 matches manuscript; see discrepancy appendix for Near/Open |
| 5 | Modern causal ML (local CATE) | MVP — only after Table 3 verification |

### Module A quickstart

```bash
source ../.venv/bin/activate
python scripts/run_persona_all_years.py
# → data/intermediate/persona/EH{YEAR}_Persona_relabel.parquet
```

## Layout

```text
OpenCausalLab/
├── data/           # raw → intermediate → final (parquet; microdata not in git)
├── src/            # Python ETL + tables
├── notebooks/      # exploration
├── docs/           # DESIGN, scope, verification, lineage
├── tests/          # replication validators (pytest)
├── scripts/        # build + audit entry points
└── vendor/         # original .do files (reference only)
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

python scripts/run_validation_audit.py
python scripts/run_verification.py
```

Protocol for contributors: [`docs/validation_protocol.md`](docs/validation_protocol.md). Run that protocol **before any causal-ML extension**.

## Subgroup DiDisc + local CATE

```bash
python scripts/run_subgroups.py
python scripts/run_causal_ml.py
```

Reports **local CATE summaries only** (no individual ITEs). Not part of the paper-replication claim.

## Environment

| Component | Version |
|-----------|---------|
| Python | 3.10.12 |
| pandas | 2.3.3 |
| NumPy | 2.2.6 |
| SciPy | 1.15.3 |
| statsmodels | 0.14.6 |

```bash
source ../.venv/bin/activate
```
