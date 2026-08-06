# Replication Validation Summary

**Question:** Can a reader trust that this Python implementation is *equivalent* to the authors’ published empirical design—not merely that a few table cells look similar?

**Paper:** Lakdawala, Martínez Heredia, Vera-Cossio, *The Effects of Expanding Worker Rights to Children*  
**Release:** `v0.1.0-python-replication`  
**Read first:** [`replication_scope.md`](replication_scope.md) · [`DESIGN.md`](DESIGN.md)  
**Companions:** [`discrepancy_appendix.md`](discrepancy_appendix.md) · [`validation_protocol.md`](validation_protocol.md) · [`pipeline.md`](pipeline.md)

---

## Status vocabulary

| Status | Definition |
|--------|------------|
| **Exact** | Numerically identical within floating-point tolerance. |
| **Published precision** | Rounds to the manuscript value at the reported decimal places. In the rest of this document we say **matches manuscript values**. |
| **Near** | Small documented difference with unchanged inference. |
| **Open** | Difference not yet fully explained. |

---

## Why independent implementation matters

Independent implementations reduce the risk of faithfully reproducing programming mistakes while increasing confidence that published empirical findings are driven by the underlying design rather than software-specific behavior. This repository re-implements the authors’ specification from the published `.do` files and manuscript tables, then documents where results agree, where they nearly agree, and where they still differ.

---

## Verification pipeline

```text
Raw survey .dta (Dataverse)
        │
        ▼
   Python ETL (src/)
        │
        ▼
 HHsurvey / CL parquet
        │
        ▼
   Validation audits
        │
        ▼
 Replication confidence
 (this document)
        │
        ▼
   Tables 1–6 (outputs)
```

---

## Executive summary

The primary objective is to establish **design equivalence** rather than software identity. Software identity across packages is generally impossible; design equivalence—the same identification strategy, sample, and estimands—is the scientific goal.

| Main causal result (Table 3) | Status |
|------------------------------|--------|
| Design | Pass |
| Sample (N = 11,991) | Pass — Exact |
| Coefficients (7 / 7) | Pass — matches manuscript values |
| Standard errors (7 / 7) | Pass — matches manuscript values |
| Inference | Pass |

- Five previously identified discrepancies were **resolved** by matching documented software semantics (attendance coding, equal-variance `ttest`, float32 median ties, age-month rounding, missing indig fill).
- Two items remain: **Table 5 wage** (**Near**) and **Table 6 firm size** (**Open**). Neither changes the paper’s substantive conclusions.
- Table 3 matching manuscript values supports the **principal** DiDisc result; it is not a claim that every cell in the paper is identical (see Near/Open items and [`discrepancy_appendix.md`](discrepancy_appendix.md)).

**All remaining discrepancies have been investigated and documented. Most have identified implementation causes; one substantive discrepancy (Table 6 firm size) remains under investigation.**

| Metric | Value |
|--------|-------|
| Main tables covered | 6 / 6 |
| Primary regressions (Table 3) | 100% (matches manuscript) |
| Auxiliary regressions | ~98% |
| Open issues | 1 (firm-size mean/coef) |

| Component | Confidence |
|-----------|------------|
| Data cleaning | 5 / 5 |
| Merge pipeline | 5 / 5 |
| Variable construction | 5 / 5 |
| Main regression (Table 3) | 5 / 5 |
| Auxiliary regressions | 4 / 5 |
| Wage pipeline (Table 5) | 4 / 5 |
| Firm size (Table 6) | 3 / 5 |

---

## Evidence

### Evidence trail (resolved discrepancies)

**Attendance → matches manuscript.** Table 1A disagreed → Stata overwrites `attendance` after creating `attendance_a` for non-workers → Python mirrored that order → matches paper.

**Travel-time heterogeneity → matches manuscript.** Table 4A disagreed → Stata stores `r(p50)` as float32; tie municipality classified as far → Python used `float(np.float32(median))` → matches paper.

**Equal-variance t-tests → matches manuscript.** Table 2A p-values disagreed → Stata `ttest` defaults to equal variances; Python had used Welch → `equal_var=True` → matches paper.

**Age-in-months rounding → Exact N; coefficients match manuscript.** NumPy banker’s round ≠ Stata half-away-from-zero on `age_dob_m` → `stata_round` + rebuild → N = 11,991 Exact.

**CL indig / Table 5 means → Exact or Near.** Missing `indig_head` dropped IPW rows; means used wrong filter → fill indig as 0; means use `year==2008 & ss`.

### Code-level: design map

Authors’ `.do` files under `vendor/stata_dofiles/` are the formal specification. Every main stage maps to a Python module (persona / income / `hhsurvey` / `table3` / `main_tables` / `child_labor`). Semantic quirks that were verified to matter: Stata `round`, float32 medians, attendance overwrite, equal-var `ttest`, indig fill.

### Spec equivalence (Table 3)

| Item | Stata | Python | Match |
|------|-------|--------|-------|
| Outcomes | 7 DiDisc YVARS | same | Yes |
| Years | 2012–2019 | same | Yes |
| Running variable | `runningw14` | same | Yes |
| Kernel / BW | triangular, 12 months | same | Yes |
| Weights | `[aw=kernel_triw14]` | WLS same weights | Yes |
| FE | `i.depto#i.year` | `C(depto_year)` | Yes |
| Cluster | `age_mo_year` | same | Yes |
| Pre-law mean | `e(sample) & pre` | same | Yes |

Cluster is **`age_mo_year`**, not municipality. Bandwidth is **12** months (18 appears only in wage robustness).

### Data-level: e(sample) and merges

| Frame | N |
|-------|---|
| Full HHsurvey | 125,368 |
| Table 3 estimation sample | **11,991** (Exact vs paper) |
| Table 4A estimation sample | 7,650 |

| Merge | Match rate | Interpretation |
|-------|------------|----------------|
| persona ⟕ income | 73.9% | Income files end in 2017 — left-only by design |
| HHsurvey ⟕ travel | 99.7% | One municipality unmatched |

Exports: `data/final/samples/sample_table{3,4}.parquet`.

### Statistical: Table 3 and ledger

| Outcome | Paper | Python (raw) |
|---------|-------|--------------|
| works xxw3 | −0.039 | −0.039351 |
| hours xxw3 | −0.969 | −0.969054 |
| allowed work xxw3 | −0.043 | −0.043013 |
| N | 11,991 | 11,991 |

| Table | Status | Notes |
|-------|--------|-------|
| 1–2 | Matches manuscript | Resolved semantics |
| **3** | Matches manuscript (N Exact) | Primary DiDisc |
| 4 | Matches manuscript | float32 median |
| 5 wage / CL | Near | Documented |
| 6 location | Matches manuscript | cols 1–6 |
| 6 firm size | **Open** | mean/coef gap; N Exact |

FE audit: 72 department-year groups, 0 singletons removed, 192 clusters. Weight sum 5,979.69.

---

## Limitations

| Item | Status | Notes |
|------|--------|-------|
| Table 6 firm size | **Open** | N Exact; mean 4.759 vs 4.796; coef −0.673 vs −0.726 |
| Table 5 wage N | Near | 715 vs 712 |
| Table 5 Mean footer | Explained | Mean of `number_workers_w`, not log wage |
| CL IPW coefficients | Near | RNG path not bit-identical |
| Second-runtime twin (R) | Optional future | Spec + manuscript evidence currently primary |

---

## Bottom line

Matching printed cells is necessary but not sufficient. This repository shows the **same design**, **same merges and samples**, and **explicit limits** where identity fails. That is the replication confidence argument: design equivalence, not only numerical agreement.

Regenerate: `python scripts/run_verification.py` · `pytest tests/test_verification.py tests/test_table3.py -q`

---

## Appendix A — Variable moments (Table 3 sample)

Artifact: `data/final/validation/variable_moments_table3_sample.csv`.

| Variable | N nonmiss | Mean | SD | Min | Max | Miss |
|----------|-----------|------|-----|-----|-----|------|
| age_dob_m | 11,991 | 168.47 | 6.92 | 157 | 180 | 0 |
| works | 11,991 | 0.194 | 0.395 | 0 | 1 | 0 |
| hours_week_a | 11,991 | 4.33 | 11.28 | 0 | 90 | 0 |
| not_forbidden_a | 11,991 | 0.164 | 0.370 | 0 | 1 | 0 |
| urban | 11,991 | 0.718 | 0.450 | 0 | 1 | 0 |
| head_schooling | 11,991 | 8.59 | 5.20 | 0 | 27 | 0 |
| indig_head | 11,991 | 0.372 | 0.483 | 0 | 1 | 0 |
| kernel_triw14 | 11,991 | 0.499 | 0.285 | 0.021 | 0.979 | 0 |
| number_workers_w | 2,250 | 4.27 | 3.71 | 1 | 60 | 9,741 |
| wage_hour_w | 436 | 11.01 | 13.49 | 0.14 | 93.09 | 11,555 |

Winsor check: `distribution_quantiles.csv` — raw `number_workers` max 4500 vs `number_workers_w` capped at 60.

---

## Appendix B — Bandwidth sensitivity (Table 3, any work)

Artifact: `bandwidth_sensitivity_table3_works.csv`.

| BW (months) | xxw3 | SE | N |
|-------------|------|-----|---|
| **12 (paper)** | **−0.0394** | 0.0167 | 11,991 |
| 15 | −0.0354 | 0.0152 | 15,076 |
| 18 | −0.0319 | 0.0141 | 18,235 |
| 24 | −0.0274 | 0.0125 | 24,340 |
| 30 | −0.0245 | 0.0115 | 30,065 |

Sign stable; magnitude attenuates smoothly with wider bandwidth.

---

## Appendix C — Environment

Pinned install file: [`../requirements.txt`](../requirements.txt).

| Component | Version |
|-----------|---------|
| Python | 3.10.12 (verified) |
| pandas | 2.3.3 |
| NumPy | 2.2.6 |
| SciPy | 1.15.3 |
| statsmodels | 0.14.6 |
| pyarrow | 25.0.0 |
| pyreadstat | 1.3.5 |
| pytest | 9.1.1 |
| scikit-learn | 1.7.2 |
| econml | 0.17.0 |

```bash
python -m pip install -r requirements.txt
```

Full module map and stage audits: [`pipeline.md`](pipeline.md), `data/final/validation/`.

---

## Appendix D — Design decisions not copied blindly

Mechanical translation would either chase bit-identity (impossible) or “improve” defaults (dangerous). These choices were deliberate:

| Original behavior | Python decision | Why |
|-------------------|-----------------|-----|
| Age months via Stata `round` (half away from zero) | `stata_round` | Banker’s round changed the RD sample |
| Travel-time median as float32 | Match float32 then `>` | Tie municipalities flip far/near |
| `ttest` equal variances | `equal_var=True` | Reproduces published inference |
| Attendance overwrite after `attendance_a` | Same overwrite order | Variable semantics, not labels |
| Missing `indig_head` before IPW | Fill 0 | Preserves CL sample construction |
| `[aw=kernel_triw14]` | WLS with same weights | Design weights, not survey factor weights |
| IPW / bootstrap RNG | Near, not bit-identical | Identical streams require the original runtime |
| pandas / NumPy defaults | Often overridden | Defaults ≠ design |
| R / second-runtime twin | Optional future | Design equivalence first; package twin second |

The pattern: **match the design’s semantics** where they affect identification or inference; **document** where numerical identity is unattainable.
