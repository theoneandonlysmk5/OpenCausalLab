# Replication scope

One-page answer to: what this repository claims, what it does not claim, and where to look for evidence.

**Paper:** Lakdawala, Martínez Heredia, Vera-Cossio, *The Effects of Expanding Worker Rights to Children*  
**Formal specification:** authors’ `.do` files in [`../vendor/stata_dofiles/`](../vendor/stata_dofiles/)  
**Design primer:** [`DESIGN.md`](DESIGN.md)  
**Full evidence:** [`verification.md`](verification.md) · discrepancies: [`discrepancy_appendix.md`](discrepancy_appendix.md)

---

## What was replicated

| Domain | Scope |
|--------|-------|
| Household Survey ETL | Persona (2012–2019), Income (2012–2017), analysis merge → `HHsurvey.parquet` |
| Child Labor Survey ETL | ETI 2008 / ENNA 2016 path → `RW_child_labor_survey.parquet` |
| Main tables | Tables **1–6** |
| Design | Age-14 DiDisc: triangular kernel, BW 12, department×year FE, cluster `age_mo_year` |
| Validation | Spec checklists, merge audits, `e(sample)` exports, bandwidth sensitivity, unit tests |

**Primary claim:** an independent Python implementation preserves the published empirical design. Table 3 **matches manuscript values** (N = 11,991 Exact).

---

## What was intentionally not replicated

| Item | Reason |
|------|--------|
| Bit-identical floating-point / RNG paths | Unavoidable across numerical libraries |
| Expenses → HHsurvey merge | Authors also omit expenses from the core analysis file |
| Every appendix table / figure | Out of scope for v0.1 |
| Redistribution of microdata | Dataverse terms; users obtain raw `.dta` themselves |
| Second-runtime twin in R | Optional future cross-check |

---

## Assumptions

1. Authors’ `.do` files are the correct target (not silent journal edits unless noted).
2. Printed manuscript cells are numerical targets when intermediate `.dta` exports are unavailable.
3. Where the original pipeline’s semantics are documented (e.g. equal-variance `ttest`, float median, half-away-from-zero `round`), the Python port matches those semantics—not “improved” modern defaults.
4. Modern causal ML is an **exploratory extension**, not part of the paper replication claim.

---

## Status vocabulary

| Status | Definition |
|--------|------------|
| **Exact** | Numerically identical within floating-point tolerance. |
| **Published precision** | Rounds to the manuscript value at reported decimals. Elsewhere we say **matches manuscript values**. |
| **Near** | Small documented difference; inference unchanged. |
| **Open** | Difference not yet fully explained. |

---

## Evidence supporting equivalence

1. Code map — every main `.do` → Python module ([`stata_python_map.md`](stata_python_map.md))  
2. Spec checklist — outcomes, RV, kernel, BW, weights, FE, cluster  
3. Data audits — merge rates; `len(HHsurvey) ≠ len(e(sample))`  
4. Statistical — Table 3 matches manuscript; bandwidth robustness  
5. Evidence trail — attendance, float32 median, equal-var `ttest`, rounding, indig fill  
6. Limitations — firm size Open; wage N Near  

---

## Architecture

```text
Harvard Dataverse
        │
        ▼
   Raw survey .dta
        │
        ▼
   Python ETL
        │
        ▼
 HHsurvey.parquet
        │
        ▼
   Validation
        │
        ▼
 Replication confidence
        │
        ▼
   Tables 1–6 (outputs)
```

Start: [`../../../README.md`](../../../README.md) → [`../README.md`](../README.md) → this file → [`DESIGN.md`](DESIGN.md) → [`verification.md`](verification.md) if needed.
