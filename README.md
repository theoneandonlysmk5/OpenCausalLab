# OpenCausalLab

[![replication-ci](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml/badge.svg)](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml)

**OpenCausalLab** is an open framework for independently verifying empirical economics research through transparent Python implementations.

```text
opencausallab/         reusable library (experimental internal API before v1.0)
studies/<paper>/       everything specific to one paper
```

This repository does **not** redistribute survey microdata. Place Dataverse extracts locally under each study’s `data/raw/` (gitignored). Prefer release archives via `git archive`, not a working-tree ZIP.

## First case study

**[`studies/lakdawala2025/`](studies/lakdawala2025/)** — Lakdawala, Martínez Heredia, Vera-Cossio, *The Effects of Expanding Worker Rights to Children* ([Dataverse](https://doi.org/10.7910/DVN/WJIQ6G)).

| Table 3 (main result) | Status |
|-----------------------|--------|
| Design / sample / coefs / SEs / inference | Matches manuscript (N = 11,991 Exact) |

Remaining Near/Open items (wage N, firm size) are documented in the case study — Table 3 success is not a claim that every cell matches. For a five-minute faculty review, start at [`studies/lakdawala2025/README.md`](studies/lakdawala2025/README.md) (Scope → Verification → Discrepancy Appendix).

## Quick start (Lakdawala)

**Dependencies:** [`pyproject.toml`](pyproject.toml) is authoritative. `requirements.txt` only wraps `pip install -e ".[all]"` for tools that expect a requirements file.

```bash
python -m pip install -e '.[replication,dev]'
# optional: python -m pip install -e '.[causal-ml]'

# From the repo root (after placing Dataverse raw files / building HHsurvey):
ocl study lakdawala2025 check-data
ocl study lakdawala2025 table3
ocl study lakdawala2025 verify
# equivalent: python -m opencausallab study lakdawala2025 table3
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
| [`SECURITY.md`](SECURITY.md) | Microdata / disclosure reporting |

## Layout

```text
OpenCausalLab/
├── README.md
├── LICENSE
├── CITATION.cff
├── pyproject.toml          # dependency source of truth
├── requirements.txt        # thin wrapper → pip install -e ".[all]"
├── docs/
├── tests/opencausallab/
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
