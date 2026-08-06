# Vendor materials (reference only)

The `vendor/` tree holds **extracted copies of the authors’ Stata `.do` files** from the Harvard Dataverse replication package for Lakdawala, Martínez Heredia, and Vera-Cossio.

| Field | Value |
|-------|-------|
| Source | Harvard Dataverse replication package |
| Authors | Lakdawala, Martínez Heredia, Vera-Cossio |
| Dataverse DOI | [10.7910/DVN/WJIQ6G](https://doi.org/10.7910/DVN/WJIQ6G) |
| Included content | Authors’ `.do` files under `stata_dofiles/` (specification reference) |

## License / terms

- **OpenCausalLab’s MIT license does not apply to files under `vendor/`.**
- Copyright and redistribution terms remain with the original authors and the Dataverse deposit.
- These files are included only as a local specification for independent verification.
- Do **not** redistribute `vendor/` outside the terms of the Dataverse package.
- Survey microdata are never part of this repository.

If Dataverse terms for your download do not clearly allow keeping a local copy of the `.do` files inside a third-party repo, delete `vendor/stata_dofiles/` and obtain them only from Dataverse for private use.

## Purpose

- Formal **specification** for the OpenCausalLab Python case study
- Line-by-line comparison when auditing discrepancies
- Provenance for “what did the published pipeline do?”

## Not for execution in this project

- Do **not** treat edits under `vendor/` as the way to “fix” the Python pipeline
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
