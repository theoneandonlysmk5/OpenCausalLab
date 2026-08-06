# Vendor materials (reference only)

The `vendor/` tree holds **extracted copies of the authors’ Stata `.do` files** from the Harvard Dataverse replication package for Lakdawala, Martínez Heredia, and Vera-Cossio.

## Purpose

- Formal **specification** for the OpenCausalLab Python case study
- Line-by-line comparison when auditing discrepancies
- Provenance for “what did the published pipeline do?”

## Not for execution in this project

- Do **not** treat edits under `vendor/` as the way to “fix” the Python pipeline
- Do **not** redistribute these files outside Dataverse terms
- OpenCausalLab does not require a Stata license to **run** the Python path; equivalence is judged against this specification and the manuscript

## Layout

```text
studies/lakdawala2025/vendor/stata_dofiles/
  Master_00.do
  data_cleaning/…
  main_tables/…
  main_figures/…
  appendix_tables/…
  appendix_figures/…
```

Copyright and redistribution of these materials remain with the original authors / Dataverse deposit. OpenCausalLab’s MIT license covers **this repository’s Python code and documentation**, not the vendor do-files or survey microdata.
