# Validation protocol (authors’ `.do` files as formal specification)

This protocol is intended for contributors extending the Python implementation. It specifies the **order** in which validation should be performed and the **criteria** used before statistical comparisons are considered trustworthy.

**This protocol should be executed before any causal-ML extension.**

Validate **stage by stage**. Do not start from final regression coefficients.

```text
Raw files
  ↓
Year-specific cleaned files
  ↓
Merged household/person dataset
  ↓
Constructed variables
  ↓
Regression sample (N first!)
  ↓
Descriptive tables
  ↓
Regression coefficients
  ↓
Standard errors
```

The first stage that differs is usually where the bug is.

## Commands

```bash
source ../.venv/bin/activate
python scripts/run_validation_audit.py
# → data/final/validation/
```

Key artifacts:

| File | Role |
|------|------|
| `stage_raw_counts.csv` | Raw `.dta` row counts |
| `raw_vs_relabel_counts.csv` | Raw − year-relabel deltas (should be 0) |
| `table3_sample_flow.csv` | Sample-flow N ladder |
| `table3_regression_ladder.csv` | Incremental specs M1–M6 |
| `discrepancy_ledger.csv` | Paper vs Python with status |
| `table3_variable_audit.csv` | Per-variable moments |
| `spec_equivalence_table3.csv` | Item-by-item Stata vs Python regression design |
| `merge_audit.csv` | `_merge`-style left/right/matched counts |
| `esample_sizes.csv` | Full df vs e(sample) N |
| `bandwidth_sensitivity_table3_works.csv` | BW robustness for Table 3 works |
| `sample_table{3,4}.parquet` | Exported regression samples (`data/final/samples/`) |

Status labels (**Exact** / matches manuscript values / **Near** / **Open**) are defined in [`replication_scope.md`](replication_scope.md).  
Full confidence write-up: [`verification.md`](verification.md).

## Golden values

Manuscript fixtures live in `src/validation/audit.py` → `GOLDEN`.

Tolerances:

- counts: exact preferred; ≤5 near for Table 3
- binary means: ~5e-4 to 5e-3
- coefficients: ~0.01 abs for binary outcomes
- SEs: looser until sandwich settings confirmed

## Known findings (2026-08-04 audit)

1. **Raw → persona relabel:** ΔN = 0 every year 2012–2019.
2. **Table 1 sample:** `age_dob_m ∈ [120, 180]` (not calendar age 10–15).
3. **Root cause of Table 3 N/coef gap:** `np.round` (banker's) ≠ Stata `round` (half away from zero) on `age_dob_m = round(age_dob/30)`. Also DiDisc used a stale `age_dob_m` before re-binding after approx survey dates.
4. **After `stata_round` fix + HHsurvey rebuild:** Table 3 N **11,991** exact; works `xxw3` **−0.039** (match); hours **−0.969** (match). Ledger ≈ all match.
5. **Regression ladder:** Full Table 3 spec (M6 + FE) now hits the printed coefficient; earlier M5≈paper was coincidental with the wrong age months.

## Stata semantic checklist

- Missing comparisons: never let NaN become 0 in eligibility/treatment
- `egen rowtotal` vs `sum(min_count=1)`
- `groupby(..., dropna=False)`
- Merges with `indicator=True` + `validate=`
- Age months: Stata `round(days/30)` (see Preparing for analysis.do)
- Analytic weights `[aw=kernel_triw14]` ≠ survey `f_weight` for Table 3

## Successful reproduction bar

- Identical or fully explained N
- Same coefficient sign and similar magnitude
- Same statistical conclusion
- Transparent discrepancy ledger for residuals
