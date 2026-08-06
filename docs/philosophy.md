# Philosophy

OpenCausalLab independently verifies published empirical economics research in open Python.

## Design equivalence, not software identity

The goal is to show that a second implementation preserves the **identification strategy**, sample construction, and estimands of a published design. Bit-identical floating-point paths across languages are not required—and often impossible.

## Authors’ specification is law

For each case study, the original analysis code (e.g. Stata `.do` files) is the formal specification. Python may deliberately match awkward software semantics when they affect samples or inference.

## Validate before extending

Modern causal tools (subgroup effects, local CATE) sit **above** a verified replication layer. Changing bandwidth, clusters, or running variables is a **new research design**, not a replication tweak.

## Framework vs case study

- **`core/`** — reusable library (Stata semantics, validation helpers, estimation utilities).
- **`studies/<paper>/`** — everything specific to one paper: data, ETL, tables, docs, vendor specs, tests.
