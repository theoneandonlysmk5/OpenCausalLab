# OpenCausalLab

[![replication-ci](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml/badge.svg)](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml)

**OpenCausalLab** is an open framework for independently verifying empirical economics research through transparent Python implementations.

```text
opencausallab/                  reusable library (experimental internal API before v1.0)
studies/<paper>/       everything specific to one paper
```

This repository does **not** redistribute survey microdata. Place Dataverse extracts locally under each study’s `data/raw/` (gitignored). Prefer release archives via `git archive`, not a working-tree ZIP.

## First case study

**[`studies/lakdawala2025/`](studies/lakdawala2025/)** — Lakdawala, Martínez Heredia, Vera-Cossio, *The Effects of Expanding Worker Rights to Children* ([Dataverse](https://doi.org/10.7910/DVN/WJIQ6G)).

| Table 3 (main result) | Status |
|-----------------------|--------|
| Design / sample / coefs / SEs / inference | Matches manuscript (N = 11,991 Exact) |

Remaining Near/Open items (wage N, firm size) are documented in the case study — Table 3 success is not a claim that every cell matches.

## Quick start (Lakdawala)

```bash
python -m pip install -e '.[replication,dev]'
# optional extensions: python -m pip install -e '.[causal-ml]'
cd studies/lakdawala2025
python scripts/check_data_layout.py   # after placing Dataverse raw files
# with HHsurvey.parquet already built (or after ETL):
python scripts/run_table3.py
python scripts/ci_gate.py
```

Public tests (no microdata):

```bash
pytest -q -m "not microdata and not causal_ml"
```

## Framework docs

| Doc | Topic |
|-----|-------|
| [`docs/philosophy.md`](docs/philosophy.md) | Design equivalence vs software identity |
| [`docs/architecture.md`](docs/architecture.md) | `opencausallab/` vs `studies/` |
| [`docs/roadmap.md`](docs/roadmap.md) | What’s next |
| [`SOFTWARE.md`](SOFTWARE.md) | Short software map |

## Layout

```text
OpenCausalLab/
├── README.md
├── LICENSE
├── CITATION.cff
├── pyproject.toml
├── requirements.txt
├── docs/
├── tests/opencausallab/            # reusable library unit tests
├── opencausallab/
├── studies/
│   └── lakdawala2025/
└── examples/
```

## Development note

This repository was developed using AI-assisted programming tools (Cursor Agent) for code generation and refactoring.

All econometric design decisions, validation methodology, discrepancy analysis, and scientific conclusions were independently designed, verified, and reviewed by the repository author.

## License

Code and documentation: [MIT](LICENSE). Microdata and vendor `.do` files retain their original terms — see [`studies/lakdawala2025/vendor/README.md`](studies/lakdawala2025/vendor/README.md). The MIT license does **not** cover `vendor/` or survey data.

## Citation

See [`CITATION.cff`](CITATION.cff). Cite Lakdawala et al. separately for the empirical findings.
