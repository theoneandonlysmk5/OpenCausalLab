# OpenCausalLab

![Replication: Table 3 PASS](https://img.shields.io/badge/Replication-Table%203%20PASS-brightgreen)
[![replication-ci](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml/badge.svg)](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml)

**OpenCausalLab** is an open framework for independently verifying empirical economics research in Python.

```text
core/                  reusable library
studies/<paper>/  everything specific to one paper
```

## First case study

**[`studies/lakdawala2025/`](studies/lakdawala2025/)** — Lakdawala, Martínez Heredia, Vera-Cossio, *The Effects of Expanding Worker Rights to Children* ([Dataverse](https://doi.org/10.7910/DVN/WJIQ6G)).

| Table 3 (main result) | Status |
|-----------------------|--------|
| Design / sample / coefs / SEs / inference | Pass (N = 11,991 Exact; matches manuscript values) |

Remaining Near/Open items (wage N, firm size) are documented in the case study — Table 3 success is not a claim that every cell matches.

## Quick start (Lakdawala)

```bash
pip install -r requirements.txt
cd studies/lakdawala2025
# place Dataverse raw .dta under data/raw/ …
python scripts/run_table3.py
python scripts/ci_gate.py
```

## Framework docs

| Doc | Topic |
|-----|-------|
| [`docs/philosophy.md`](docs/philosophy.md) | Design equivalence vs software identity |
| [`docs/architecture.md`](docs/architecture.md) | `core/` vs `studies/` |
| [`docs/roadmap.md`](docs/roadmap.md) | What’s next |

## Layout

```text
OpenCausalLab/
├── README.md
├── LICENSE
├── CITATION.cff
├── pyproject.toml
├── requirements.txt
├── docs/
│   ├── philosophy.md
│   ├── roadmap.md
│   └── architecture.md
├── core/
│   ├── validation/
│   ├── utils/
│   ├── stata_semantics/
│   ├── reporting/
│   └── causal/
├── studies/
│   └── lakdawala2025/
│       ├── README.md
│       ├── data/
│       ├── docs/
│       ├── src/
│       ├── scripts/
│       ├── tests/
│       ├── notebooks/
│       └── vendor/
└── examples/
```

## Development note

This repository was developed using AI-assisted programming tools (Cursor Agent) for code generation and refactoring.

All econometric design decisions, validation methodology, discrepancy analysis, and scientific conclusions were independently designed, verified, and reviewed by the repository author.

## License

Code and documentation: [MIT](LICENSE). Microdata and vendor `.do` files retain their original terms — see the case-study README.

## Citation

See [`CITATION.cff`](CITATION.cff). Cite Lakdawala et al. separately for the empirical findings.
