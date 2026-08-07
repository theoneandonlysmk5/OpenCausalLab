# OpenCausalLab

> Learning causal inference by rebuilding published research in Python.

[![replication-ci](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml/badge.svg)](https://github.com/theoneandonlysmk5/OpenCausalLab/actions/workflows/replication-ci.yml)
![Python](https://img.shields.io/badge/Python-3.10+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Why I started this project

Hi! I'm a high school student who is interested in using quantitative methods to study causal inference.

When I wanted to learn from an empirical economics paper that interested me, I found that its replication code was written in Stata. Since I didn't have a Stata license, I decided to rebuild the analysis in Python instead.

The goal of this project is **not** to replace the original Stata code or claim that Python is better than Stata. Rebuilding the analysis from scratch forced me to understand each step of the original research instead of simply running the provided code.

Instead, my goal is to understand the paper well enough to reproduce the published results using Python while preserving the original research design.

Along the way, I document every important implementation decision, every discrepancy I find, and how each issue is investigated and resolved.

---

## Why make this public?

Many high school students and independent learners don't have access to Stata.

I hope this repository makes it easier for anyone with Python to learn how empirical causal inference research works by studying a complete, transparent implementation.

If this project helps another student get started with causal inference, then it has achieved its purpose.

---

## Current case study

### Lakdawala et al. (2025)

**The Effects of Expanding Worker Rights to Children**

This repository currently contains one complete replication study: [`studies/lakdawala2025/`](studies/lakdawala2025/).

Current status:

| Item | Status |
|------|--------|
| Data pipeline | ✅ |
| Tables 1–4 | ✅ Reproduced |
| Table 5 | 🟡 Minor documented differences |
| Table 6 | 🟡 One documented open issue |

The main empirical results have been reproduced, and the remaining differences are documented rather than hidden.

For a five-minute review of the case study, start at the [study README](studies/lakdawala2025/README.md).

---

## Repository structure

```text
OpenCausalLab/
├── opencausallab/          # reusable Python utilities
├── studies/
│   └── lakdawala2025/      # first replication project
├── docs/
├── examples/
└── tests/
```

---

## Documentation

If you'd like to understand the replication process, I recommend reading these documents in order:

1. [Replication Scope](studies/lakdawala2025/docs/replication_scope.md)
2. [Design](studies/lakdawala2025/docs/DESIGN.md)
3. [Verification](studies/lakdawala2025/docs/verification.md)
4. [Discrepancy Appendix](studies/lakdawala2025/docs/discrepancy_appendix.md)

These explain what was replicated, how the Python implementation was validated, and which differences are still under investigation.

If you only have a few minutes, I recommend starting with the [Verification](studies/lakdawala2025/docs/verification.md) document.

---

## Data

This repository **does not include** the original survey microdata.

The original replication package is available from Harvard Dataverse:

https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/WJIQ6G

The original Stata `.do` files are included unchanged as reference materials for verification.

---

## Quick start

```bash
python -m pip install -e '.[replication,dev]'
```

After installation, the `ocl` command-line tool can reproduce and validate the study:

```bash
ocl study lakdawala2025 table3
ocl study lakdawala2025 verify
```

(`pyproject.toml` is the dependency source of truth.)

---

## What I hope to learn next

This project is still a work in progress.

Some topics I'm interested in exploring are:

- heterogeneous treatment effects
- Double Machine Learning
- Causal Forests
- modern causal inference methods
- replicate more empirical economics papers in Python

---

## Feedback

I'm still learning, so I'd really appreciate feedback, corrections, or suggestions. If you notice a bug, find a discrepancy, or have ideas for improving the implementation, please feel free to open an issue or contact me.

Thanks for visiting OpenCausalLab!
