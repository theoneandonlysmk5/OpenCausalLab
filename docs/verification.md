# Replication confidence argument

**Question this document answers:** Why should a reader believe the OpenCausalLab Python implementation is *equivalent* to the authors’ Stata implementation—not merely that a few printed table cells happen to match?

**Paper:** Lakdawala, Martínez Heredia, Vera-Cossio, *The Effects of Expanding Worker Rights to Children*  
**Release:** `v0.1.0-python-replication`  
**Regenerate audits:** `python scripts/run_verification.py`  
**Companion:** [`discrepancy_appendix.md`](discrepancy_appendix.md), [`validation_protocol.md`](validation_protocol.md), [`pipeline.md`](pipeline.md)

---

## 1. Code-level verification

### 1.1 Stata → Python map

Every primary analysis path has a named Python counterpart. Stata `.do` files under `vendor/stata_dofiles/` remain the formal specification.

| Stage | Stata | Python |
|-------|-------|--------|
| Master order | `Master_00.do` | scripts under `scripts/` (persona → income → HHsurvey → tables) |
| Persona year harmonize | `EH_Persona_YYYY.do` | `src/persona/yYYYY.py` |
| Persona compile / clean | `2.1` / `2.2` | `src/persona/compile_clean.py` |
| Income year harmonize | `EH_Income_YYYY.do` | `src/income/yYYYY.py` |
| Income compile / clean | `2.3` / `2.4` | `src/income/compile_clean.py` |
| Analysis file | `3. Preparing for analysis.do` | `src/hhsurvey.py` |
| Child Labor Survey 1–9 | `…/Child Labor Survey/*.do` | `src/child_labor/` |
| Table 1–2 descriptives | `Table_1_*.do`, `Table_2_*.do` | `src/main_tables.py` |
| Table 3 DiDisc | `Table_3_DDisc_Work.do` | `src/table3.py` |
| Table 4 distance het | `Table_4_DDisc_HeterogeneityDistanceToInspectors.do` | `src/main_tables.py` |
| Table 5 risk/injury/wages | `Table_5_DDisc_RiskInjuryWages.do` | `src/child_labor/tables.py`, `src/main_tables.py` |
| Table 6 location / firm size | `Table_6_DDisc_JobLocationFirmSize.do` | `src/main_tables.py` |
| Shared WLS + cluster | `reg … [aw=…] , vce(cluster …)` | `src/didisc_reg.py` (`wls_cluster`) |
| Stata `round` / float quirks | Stata built-ins | `src/stata_utils.py` |

### 1.2 Transformations that were verified to matter

These are not cosmetic: each was isolated by sample-flow / ladder audits before coefficients were trusted.

| Behavior | Stata | Python | Evidence |
|----------|-------|--------|----------|
| Half-away-from-zero age months | `round(age_dob/30)` | `stata_round` | N and Table 3 jump to paper after fix |
| Travel-time median | `gen median = r(p50)` → **float32** | `float(np.float32(median))` | Table 4A Aiquile tie → far |
| Attendance coding | `attendance_a` all; clear `attendance` if not work | `src/hhsurvey.py` | Table 1A |
| Equal-variance `ttest` | Stata default | `equal_var=True` | Table 2A p-values |
| CL indig missing → 0 before IPW | implicit / fill | fill in `child_labor` | Table 1C N=3477 |
| Table 5 CL means | `sum if year==2008 & ss` | same filter (not e(sample)) | Means match |

### 1.3 Regression specification equivalence (not just coefficients)

Artifact: `data/final/validation/spec_equivalence_table3.csv` (and `…_table4.csv`).

**Table 3 — item checklist**

| Item | Stata | Python | Match |
|------|-------|--------|-------|
| Outcome set | works, hours_week_a, self_employed_a, wrk_forother_a, forbidden_a, not_forbidden_a, lf_participation | same `YVARS` | ✅ |
| Years | 2012–2019 | `year ∈ [2012, 2019]` | ✅ |
| Treatment interaction | `xxw3 = post × treatw14` | `xxw3` | ✅ |
| Reversal | `xxrw3` | `xxrw3` | ✅ |
| Running variable | `runningw14` | `runningw14` | ✅ |
| Kernel | triangular | `kernel_triw14` | ✅ |
| Bandwidth | **12 months** (table notes) | `bw=12` | ✅ |
| Weights | `[aw=kernel_triw14]` | statsmodels WLS | ✅ |
| Survey factor weights | not used | not used | ✅ |
| FE | `i.depto#i.year` | `C(depto_year)` | ✅ |
| Cluster | `vce(cluster age_mo_year)` | `groups=age_mo_year` | ✅ |
| Pre-law mean | `sum y if e(sample) & pre` | mean on regression sample ∩ pre | ✅ |

Important correction to a common mis-statement of the design: Table 3 clusters on **`age_mo_year`**, not municipality, and uses **12-month** bandwidth (18 months appears in wage robustness `sww14_18`).

---

## 2. Data-level verification

### 2.1 Row counts and e(sample)

The estimation sample is **not** `HHsurvey`.

| Frame | N | Path |
|-------|---|------|
| Full HHsurvey | 125,368 | `data/final/HHsurvey.parquet` |
| Table 3 e(sample) | **11,991** | `data/final/samples/sample_table3.parquet` |
| Table 4A e(sample) | **7,650** | `data/final/samples/sample_table4.parquet` |

Artifact: `data/final/validation/esample_sizes.csv`.

Rebuild:

```bash
python scripts/run_verification.py
```

### 2.2 Merge integrity (`_merge`-style)

Artifact: `data/final/validation/merge_audit.csv`.

| Merge | Matched | Left only | Right only | Notes |
|-------|---------|-----------|------------|-------|
| persona `id_year` ⟕ income `id_year` | 218,360 | 77,122 | 0 | Income covers 2012–2017 only; later years left_only **by design** |
| HHsurvey `cod_secc` ⟕ travel | 291 | 1 | 48 | Kernel sample: 11,991; `het_time` miss = 4,341 (years outside travel window / unmatched) |

### 2.3 Variable moments (Table 3 sample)

Artifact: `data/final/validation/variable_moments_table3_sample.csv`.

Twenty core variables are summarized (min / max / mean / SD / missing / quantiles). Selected highlights on the **e(sample)** frame:

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

Full-panel distribution quantiles (winsor check): `distribution_quantiles.csv` — `number_workers` max 4500 vs `number_workers_w` capped at 60 (p95 winsor).

### 2.4 Sample flow

See `table3_sample_flow.csv` and the ladder in `docs/validation_protocol.md`. Rule: **match N before trusting coefficients.**

---

## 3. Statistical verification

### 3.1 Table-by-table status

Primary ledger: `data/final/tables/main_tables_ledger.csv` (+ CL ledger). Status counts at freeze: **93 match / 17 near / 0 open in ledger status field**; firm-size coefficient remains the substantive **Open** item in the discrepancy appendix (ledger marks it `near` by numeric tolerance but interpretation is still unresolved—see §4).

| Table | Status | Spec / notes |
|-------|--------|----------------|
| 1A–1B | Exact | Attendance coding; age_dob_m window |
| 1C / 2B | Exact / Near | indig fill; displayed precision |
| 2A | Exact | equal-variance t-tests |
| **3** | **Exact** | N=11,991; all outcomes to printed precision |
| 4A–4B | Exact | float32 median for driving time |
| 5 wage | Near / Explained | N 715 vs 712; published Mean = `number_workers_w` |
| 5 CL | Near / Explained | RNG / IPW; Ns −9/−10 all-child |
| 6 cols 1–6 | Exact | location outcomes |
| 6 col 7 firm size | Open | N exact; mean/coef gap |

### 3.2 Table 3 coefficient check (unrounded)

Artifact: `table3_spec_coef_check.csv`.

| Outcome | Paper (printed) | Python (raw) | \|Δ\| |
|---------|-----------------|--------------|------|
| works xxw3 | −0.039 | **−0.039351** | 3.5e−4 |
| hours_week_a | −0.969 | −0.969054 | 5e−5 |
| not_forbidden_a | −0.043 | −0.043013 | 1e−5 |
| N | 11,991 | 11,991 | 0 |

Unit test (replication validator):

```python
assert abs(coef + 0.039351) < 1e-4   # works xxw3
assert n == 11991
```

### 3.3 Fixed effects and weights (Table 3 sample)

Artifact: `fe_weight_audit_table3.json`.

| Check | Value |
|-------|-------|
| Observations | 11,991 |
| Clusters (`age_mo_year`) | 192 |
| FE groups (`depto_year`) | 72 |
| Singleton FE groups | 0 |
| Weight sum | 5,979.69 |
| Weight mean / min / max | 0.499 / 0.021 / 0.979 |
| Zero weights in sample | 0 |

Stata `[aw=]` does not renormalize weights for point estimates; statsmodels WLS with the same weights matches the published point estimates to printed precision. Cluster-robust SEs use the same grouping variable.

### 3.4 Bandwidth sensitivity (Table 3 `works`)

Artifact: `bandwidth_sensitivity_table3_works.csv`. Same formula; only triangular bandwidth changes.

| BW (months) | xxw3 | SE | N |
|-------------|------|-----|---|
| **12 (paper)** | **−0.0394** | 0.0167 | 11,991 |
| 15 | −0.0354 | 0.0152 | 15,076 |
| 18 | −0.0319 | 0.0141 | 18,235 |
| 24 | −0.0274 | 0.0125 | 24,340 |
| 30 | −0.0245 | 0.0115 | 30,065 |

Sign and significance are stable; magnitude attenuates smoothly with wider bandwidth (as expected for local DiDisc).

### 3.5 Cross-software validation (Tier 3)

We do **not** have a Stata license. An R (`fixest` / `rdrobust`) twin estimator is listed as optional future work. Confidence currently rests on:

1. Line-by-line specification match to the authors’ `.do` files  
2. Exact printed Table 3 (and most main tables)  
3. Documented semantics for every remaining gap  

Python ≈ R would further reduce package-specific risk; it is not yet a blocker given the Stata-spec + printed-table evidence.

---

## 4. Limitations

State clearly what is **not** identical:

| Item | Status | Why it does not overturn the design claim |
|------|--------|-------------------------------------------|
| Table 6 firm size mean / coef | **Open** | N=2,250 exact; locations exact. Pre-law mean 4.759 vs 4.796 (≈20 worker-units on 543 pre obs). Needs Stata export of `number_workers_w` on e(sample). Audits: `table6_*` under `data/final/validation/`. |
| Table 5 wage N | Near | 715 vs 712; bottleneck is nonmissing `wage_hour_w`. |
| Table 5 published Mean | Explained | Footer is mean of `number_workers_w`, not log wage. |
| CL IPW coefficients | Near / Explained | Stata RNG / bootstrap path not bit-identical; multi-seed cloud documented. |
| Expenses module | Not in main HHsurvey | Matches Stata: expenses used in appendix expenditure, not core DiDisc file. |
| No live Stata / R twin | Limitation | Equivalence is to the **published `.do` specification** and printed tables, not to a second runtime binary. |

---

## How to re-run the confidence suite

```bash
# From OpenCausalLab/ with HHsurvey.parquet present
python scripts/run_verification.py
# → data/final/validation/spec_equivalence_*.csv
# → data/final/validation/variable_moments_*.csv
# → data/final/validation/merge_audit.csv
# → data/final/validation/fe_weight_audit_table3.json
# → data/final/validation/bandwidth_sensitivity_table3_works.csv
# → data/final/samples/sample_table{3,4}.parquet

pytest tests/test_table3.py tests/test_verification.py -q
python scripts/run_main_tables.py   # rebuild ledger
```

CI sketch: `.github/workflows/replication-ci.yml` runs pytest on committed fixtures and fails if the ledger introduces unexplained `open` rows when microdata are available.

---

## Bottom line

Matching printed cells is necessary but not sufficient. This repository additionally shows:

1. **The same regression design** (outcomes, BW, kernel, FE, cluster, weights, controls).  
2. **The same constructed variables and merges**, with `_merge`-style audits.  
3. **The same estimation sample** (`e(sample)` exports, N ≠ full panel).  
4. **Explicit limits** where identity fails (firm size Open; CL RNG Near).

That is the replication confidence argument: evidence of design equivalence, not only of numerical agreement.
