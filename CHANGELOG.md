# Changelog

All notable changes to OpenCausalLab are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
for tagged releases (`VERSION`).

## [Unreleased]

### Added

- `ocl` / `python -m opencausallab` CLI (`study <id> table3|verify|check-data`)
- `SECURITY.md` (microdata / credential disclosure)
- Issue templates (discrepancy, study, data-layout, docs, framework bug) and PR checklist
- Restricted-data CI job rename + secret/URL handling notes

### Changed

- **Major layout:** reusable library in `opencausallab/`; Lakdawala paper fully under `studies/lakdawala2025/` (data, src, scripts, tests, docs, vendor)
- Framework docs at `docs/{philosophy,architecture,roadmap}.md`; root README is framework-first
- `pyproject.toml` is the dependency source of truth; `requirements.txt` only wraps `-e ".[all]"`
- Public CI matrix (3.10–3.12) runs `pytest -m "not microdata and not causal_ml"`; optional restricted-data job
- Stop tracking row-level validation dumps (`table5_wage_obs_flags.csv`, `table6_firm_size_contributions.csv`)

### Fixed

- `table3_audit` import after move to `opencausallab.validation.audit`
- Package rename: `core` → `opencausallab` (import path matches distribution name)
- Lazy-import `pyreadstat` / `econml` so test collection works without optional stacks

### Added

- `tests/opencausallab/` unit tests for reusable library
- `studies/lakdawala2025/study.yaml`, `scripts/check_data_layout.py`
- `examples/.gitkeep`
- Case-study `tests/conftest.py` for `PYTHONPATH`
- `SOFTWARE.md`, `CONTRIBUTING.md`, `.github/CODEOWNERS`, `CHANGELOG.md`
- `docs/REPRODUCTION.md` (runtime ~4s Table 3 / ~9–14s main tables; RAM/disk)
- `docs/python_vs_stata.md`, `docs/pipeline_dag.md`, `vendor/README.md`
- `src/seeds.py`, `src/provenance.py`, `src/logutil.py`, `scripts/hash_outputs.py`
- `data/final/validation/variable_dictionary.csv`, `output_hashes.json`
- Intermediate stage ladder (`src/validation/stage_ladder.py`)
- GitHub Actions replication CI (`scripts/ci_gate.py`) + optional coverage step
- Optional `HHSURVEY_PARQUET_URL` secret for full live rebuild on CI

### Changed

- README framed as a reusable verification **framework** (Lakdawala as first case study)
- Documentation vocabulary: design equivalence vs software identity; “matches manuscript values”
- HHsurvey writes emit provenance sidecars; CL seed centralized in `src/seeds.py`

## [0.1.0-python-replication] — 2026-08-05

### Added

- Independent Python ETL for Household Survey (persona, income, HHsurvey) and Child Labor Survey
- Main Tables 1–6 replication path and Table 3 DiDisc matching manuscript values (N = 11,991 Exact)
- Replication confidence suite: `docs/verification.md`, `docs/replication_scope.md`, `docs/DESIGN.md`
- Spec equivalence, merge audits, e(sample) exports, bandwidth sensitivity, unit tests
- Discrepancy appendix with Evidence Trail for resolved Stata-semantic differences
- Subgroup DiDisc and exploratory local CATE (extension layer; not part of paper claim)
- Validation protocol and CI sketch under `.github/workflows/`

### Known issues

- Table 5 wage sample N Near (715 vs 712)
- Table 6 firm size mean/coef Open (N Exact); documented with audit trail

[Unreleased]: https://github.com/theoneandonlysmk5/OpenCausalLab/compare/v0.1.0-python-replication...HEAD
[0.1.0-python-replication]: https://github.com/theoneandonlysmk5/OpenCausalLab/releases/tag/v0.1.0-python-replication
