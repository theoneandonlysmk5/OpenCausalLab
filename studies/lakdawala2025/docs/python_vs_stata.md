# Python vs Stata (implementation differences)

This page records **how** the two stacks differ. It is not a claim that one is better.

Formal specification for the Lakdawala et al. case study remains the authors’ `.do` files under `vendor/stata_dofiles/`.

| Aspect | Python (OpenCausalLab) | Stata (authors) |
|--------|------------------------|-----------------|
| Language / runtime | Python 3.10 + pandas / statsmodels | Stata (do-files) |
| Microdata I/O | `pyreadstat` / parquet intermediates | `.dta` throughout |
| Analysis file | `HHsurvey.parquet` | `HHsurvey.dta` |
| Rounding half-.5 | `stata_round` (half away from zero) | `round()` |
| Travel-time median type | Explicit `float32` then compare | `gen median = r(p50)` (float) |
| WLS with analytic weights | `statsmodels` WLS `[aw≡weights]` | `reg … [aw=kernel_…]` |
| Department × year FE | `C(depto_year)` in formula | `i.depto#i.year` |
| Cluster SE | `cov_type="cluster"`, `groups=age_mo_year` | `vce(cluster age_mo_year)` |
| Equal-variance t-test | `scipy` / pandas with `equal_var=True` | `ttest` default |
| Welch t-test | Available but **not** used for Table 2A | Not default |
| Missing indig before IPW | Filled 0 to match sample | Implicit / as coded in do-file |
| Child-labor IPW RNG | NumPy `RandomState(794758)` | `set seed 794758` + KISS `runiform` |
| Bit-identical RNG draws | No | Reference |
| Tables / logging | CSV ledgers + `logging` | `esttab` / log files |
| Validation artifacts | `data/final/validation/` | Manual / not shipped |
| Extensions (CATE) | Optional `econml` layer | Not in original package |

## What we match on purpose

- DiDisc geometry (running variable, treat, post, kernel, BW 12)
- Cluster and FE structure for Table 3
- Documented quirks that change samples or inference (round, float32 median, attendance overwrite, equal-var t-tests)

## What we do not claim

- Software identity (same binary, same RNG stream, same BLAS rounding)
- That every appendix table/figure is reproduced
- That Near/Open cells (wage N, firm size) are closed

See [`verification.md`](verification.md) Appendix D for design decisions not copied blindly.
