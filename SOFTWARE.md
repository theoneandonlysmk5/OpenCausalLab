# Software architecture

OpenCausalLab is a **verification framework**: transparent Python implementations of published empirical designs, with validation before any research extension.

This document describes how the software is organized. For the economics design, see [`docs/DESIGN.md`](docs/DESIGN.md). For replication status, see [`docs/verification.md`](docs/verification.md).

---

## Design philosophy

1. **Design equivalence over software identity.** Match the published identification strategy, sample construction, and estimands. Do not chase bit-identical floating-point paths across packages.
2. **Authors’ specification is law.** For each case study, `.do` files (or equivalent) under `vendor/` define the target. Python may match awkward semantics (Stata `round`, float32 medians, equal-variance `ttest`) when they affect results.
3. **Validate before extending.** Causal-ML and subgroup tools sit *above* a verified analysis layer. Changing identification choices is a new research design ([`docs/identification.md`](docs/identification.md)).
4. **Stage-by-stage debugging.** Prefer sample-flow and merge audits over coefficient chasing ([`docs/validation_protocol.md`](docs/validation_protocol.md)).
5. **Case studies are modules; the framework is reusable.** Lakdawala et al. is the first case study, not the whole product. Planned layout:

```text
OpenCausalLab/
  src/                    # shared ETL / estimation / validation toolkit
  case-studies/
    lakdawala-worker-rights/   # paper-specific docs + ledgers (future)
  vendor/                 # formal .do specifications per paper
```

Today the first case study still lives at the repo root for simplicity; the framework boundary is already `src/` + `docs/` + validation.

---

## Layered architecture

```text
ETL
  raw .dta → year modules → compile/clean → analysis files
        │
        ▼
Analysis
  DiDisc / descriptives → Tables 1–6
        │
        ▼
Validation
  audits, e(sample), spec checks, CI gate
        │
        ▼
Extensions
  subgroups, local CATE (after verification)
```

---

## Module boundaries

| Layer | Package / entry | Responsibility | Must not |
|-------|-----------------|----------------|----------|
| Paths | `src/paths.py` | Data roots only | Business logic |
| Stata semantics | `src/stata_utils.py` | `stata_round`, numeric coercion, winsor | Estimation |
| ETL — Persona | `src/persona/`, `src/household.py` | Year harmonize → compile → clean | Tables |
| ETL — Income | `src/income/` | Year harmonize → compile → clean | Tables |
| ETL — HHsurvey | `src/hhsurvey.py` | Analysis merge + design variables | Causal ML |
| ETL — Child labor | `src/child_labor/` | CL survey build | HH tables |
| Estimation helpers | `src/didisc_reg.py` | Shared WLS + cluster + FE | Data cleaning |
| Analysis — Table 3 | `src/table3.py` | Main DiDisc work outcomes | Extensions |
| Analysis — main tables | `src/main_tables.py` | Tables 1–2, 4–6 (HH path) | ETL |
| Analysis — CL tables | `src/child_labor/tables.py` | 1C, 2B, Table 5 CL | HH ETL |
| Validation | `src/validation/` | Audits, verification suite | Changing estimates silently |
| Extensions | `src/subgroup.py`, `src/causal_ml.py` | Heterogeneity / local CATE | Altering Table 3 design |
| Scripts | `scripts/` | CLI entry points only | Heavy logic (lives in `src/`) |
| Vendor | `vendor/stata_dofiles/` | Formal specification (read-only) | Edits as “Python fixes” |

### Dependency direction

```text
scripts → src.analysis / src.validation / src.etl
src.extensions → src.table3 / src.didisc_reg   (read design sample)
src.analysis → src.didisc_reg / src.stata_utils / src.paths
src.etl → src.stata_utils / src.paths
src.validation → src.table3 / src.etl outputs
```

Extensions may **consume** analysis samples; they must not rewrite ETL or the Table 3 specification.

---

## Data layout

```text
data/
  raw/            # Dataverse .dta (not in git)
  intermediate/   # year / compile / clean parquet (not in git)
  final/
    HHsurvey.parquet
    RW_child_labor_survey.parquet
    tables/       # committed CSV outputs
    validation/   # committed audit CSVs
    samples/      # e(sample) exports (parquet gitignored)
```

---

## Entry points

| Task | Command |
|------|---------|
| Persona / income / HHsurvey build | `scripts/run_persona_*.py`, `run_income_*.py`, `run_hhsurvey.py` |
| Table 3 | `scripts/run_table3.py` |
| Tables 1–6 | `scripts/run_main_tables.py` |
| Validation audit | `scripts/run_validation_audit.py` |
| Verification suite | `scripts/run_verification.py` |
| CI gate | `scripts/ci_gate.py` |
| Subgroups / CATE | `scripts/run_subgroups.py`, `run_causal_ml.py` |

---

## Testing and CI

- **Unit:** `tests/test_stata_round.py` (no microdata)
- **Replication validators:** `tests/test_table3.py`, `tests/test_verification.py` (need `HHsurvey.parquet`)
- **CI:** `.github/workflows/replication-ci.yml` → `scripts/ci_gate.py`  
  `pytest → rebuild Table 3 → verification → PASS` when microdata is available

Install: `pip install -r requirements.txt`.
