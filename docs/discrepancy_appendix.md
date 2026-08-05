# Discrepancy appendix — Python replication of Leah et al.

**Release tag:** `v0.1.0-python-replication`  
**Manuscript:** Expanding Worker Rights to Children (JDE R1 / July 18, 2024 tables)  
**Pipeline:** OpenCausalLab (no Stata runtime)

## Status legend

| Status | Meaning |
|--------|---------|
| **Exact** | Same underlying value or displayed precision |
| **Near** | Small implementation difference; sign, interpretation, and inference unchanged |
| **Explained** | Difference caused by RNG, software semantics, or paper labeling |
| **Open** | Cause not yet identified |

## Completion standard

Replication phase is **complete** when:

1. Table 3 remains exact.
2. Every remaining discrepancy has a reproducible explanation *or* is documented as Open with an audit trail.
3. No mismatch changes a sign, substantive interpretation, or inference.
4. The Python pipeline is deterministic and documented.

## Table-by-table ledger

| Table | Result | Status | Notes |
|-------|--------|--------|-------|
| 1A | Descriptives (HH) | Exact | Attendance coding fixed (`attendance_a` = all; `attendance` cleared for non-workers) |
| 1B | Job attributes (HH) | Exact | |
| 1C | Risk/injury (CL) | Exact / Near | Means & Ns match displayed precision after `indig_head` fill |
| 2A | By employer (HH) | Exact | `ttest` equal-variance (Stata default), not Welch |
| 2B | By employer (CL) | Exact / Near | Follows Table 1C sample |
| 3 | Main DiDisc | Exact | N=11,991; coefficients/SEs/means to displayed precision |
| 4A | Driving-time het | Exact | Stata `gen median=r(p50)` float32 puts median-tie Aiquile in *far* |
| 4B | Direct-distance het | Exact | |
| 5 cols 1–4 | Risk/injury DiDisc (CL) | Near / Explained | Means now Exact (Stata `sum if year==2008 & ss`); working Ns Exact; all-child N −9/−10; injury-work coef −0.016 vs −0.015 displayed |
| 5 col 5 | Log hourly wage (HH) | Near / Explained | N 715 vs 712; coef 0.099 vs 0.103; published “Mean” is not log wage |
| 6 cols 1–6 | Job location | Exact | User-confirmed to published precision |
| 6 col 7 | Firm size | Open | N exact; mean shortfall ≈ +20 on 543 pre obs; see audit |

---

## 1. Table 5 wage (Near / Explained)

### Published “Mean” is mislabeled

Stata (`Table_5_DDisc_RiskInjuryWages.do`):

```stata
reg log_wage_hour_w xx xxrw3 ... [aw=kernel_triw14_18] if sww14_18==1, ...
sum number_workers_w if e(sample)==1 & pre==1
estadd scalar Mean=r(mean)
```

The table footer “Mean” is the pre-law mean of **`number_workers_w`**, not of log hourly wage.  
Python reports that statistic separately as `mean_number_workers_pre` and does **not** alter the wage regression to chase 6.656.

### Sample ledger (exclusion audit)

| Step | N | Rule |
|------|---|------|
| Years 2012–2019 | 125,368 | |
| `sww14_18==1` | 18,235 | \|runningw14\| ≤ 18 |
| Kernel > 0 | 18,235 | Triangular weight; Stata uses \|r\| < 18 for kernel |
| `wage_hour_w` nonmissing | **715** | Bottleneck |
| Wage > 0 | 715 | No zeros/negatives in sample |
| Finite `log_wage_hour_w` | 715 | Code uses `log(wage_hour_w+1)` (matches do-file) |
| Complete controls | 715 | |
| FE / cluster IDs | 715 | |
| (Optional) `number_workers_w` nonmiss | 613 | **Not** in regression; only in published Mean |

Paper N = **712** (−3). Artifacts:

- `data/final/validation/table5_wage_sample_ledger.csv`
- `data/final/validation/table5_wage_obs_flags.csv`

### What the three observations are not

- Not listwise deletion on `number_workers_w` (that would drop 102).
- Not `paid==1` (that would drop to 582 and flip the sign).
- Not zero/negative wage under `log(w)` (do-file uses `log(w+1)`; no nonpositive wages in sample).
- Dropping the three smallest-kernel (or largest \|r\|) edge cases yields N=712 but **xxw3 ≈ 0.0986** (unchanged vs 0.0985) — so the N gap alone does not explain the coefficient gap.

### Classification

**Near / Explained:** coefficient and SE agree to two displayed digits after rounding pressure; +3 wage observations are unidentified without Stata’s `e(sample)` export; published Mean is a labeling quirk.

---

## 2. Table 5 CL (Near / Explained) — means fixed

### Mean definition bug (fixed)

Stata does **not** use `e(sample)` for the footer Mean:

```stata
sum `y' if year==2008 & ss==1              // risks, all
sum `y' if year==2008 & ss==1 & d_worked==1 // risks, working
sum `y' if year==2008 & ssy==1             // injury analogs
```

Python previously averaged the outcome on the regression subsample (after listwise deletion).  
It now matches the Stata `sum if year==2008 & ss/ssy` rule. All four means round to the paper:

| Column | Paper | Python |
|--------|-------|--------|
| Risk, all | 0.281 | 0.281271 |
| Risk, working | 0.536 | 0.535960 |
| Injury, all | 0.188 | 0.188092 |
| Injury, working | 0.327 | 0.326842 |

### Remaining CL gaps

| Item | Paper | Python | Notes |
|------|-------|--------|-------|
| All-child N | 8372 / 8411 | 8363 / 8401 | −9 / −10; stable across IPW seeds |
| Working N | 2914 / 3208 | exact | |
| Injury, working xx | −0.015 | −0.015937 | Rounds to −0.016; economically negligible |
| Other xx / SE | | | Round to published precision |

### IPW multi-seed check

Artifact: `data/final/validation/cl_ipw_multiseed_robustness.csv`.  
Paper coefficients fall inside the NumPy seed cloud. All-child N does **not** move with seeds.

### Classification

**Near / Explained:** means Exact after the `sum if` fix; residual N/coef display gaps do not change inference.

---

## 3. Table 6 firm size (Open)

User confirmation (latest CSV check): columns **1–6 Exact**; column **7 still Open**.

| Statistic | Paper | Python |
|-----------|-------|--------|
| N | 2,250 | 2,250 |
| Post-law coef | −0.726 | −0.673 |
| SE | 0.473 | 0.447 |
| Pre-law mean | 4.796 | 4.759 |

Sample spans 2012–2019 after correct `year` indexing; location cols on the same working DiDisc sample match → **levels of `number_workers_a`**, not sample filters.

### Smoking gun on the mean

Pre-law e(sample) has **543** observations; sum of `number_workers_a` = 2584 vs paper-implied **2604.2** (**shortfall ≈ 20.2**).  
Replacing the single pre-law capped value **60 → 80** yields mean **4.7956 ≈ 4.796**, but does **not** recover the −0.726 coefficient.  
That pre-law obs has raw firm size **180** (id `2012334260401313`); winsor p(0.05) high on the full persona frame caps it at **60** (persona p95).

### Transformation audit

| Stage | N | Mean | P95 | Max |
|-------|---|------|-----|-----|
| Persona raw (888888→.) | 135,757 | 21.91 | 60 | 25,000 |
| Persona winsor p(0.05) high | 135,757 | 9.18 | 60 | 60 |
| Table 6 reg (`_a`) | 2,250 | 4.27 | 8 | 60 |
| Reg ∩ pre | 543 | 4.76 | 8 | 60 |

Counterfactual caps (N stays 2250):

| Cap | xxw3 | Pre mean |
|-----|------|----------|
| 60 (current / do-file) | −0.673 | 4.759 |
| 70 | −0.700 | 4.777 |
| Raw (no winsor) | −1.231 | 4.980 |
| Paper | −0.726 | 4.796 |

Codes 97/98/99 as missing do not change the regression sample.  
Artifacts under `data/final/validation/table6_*`.

### Classification

**Open:** faithful do-file winsor gives cap 60; paper mean is consistent with ~20 extra units of pre-law mass (one large firm coded differently), but the coefficient gap is not closed by that single swap. Needs Stata `number_workers_w` export or byte-identical winsor intermediate. Sign/inference unchanged.

---

## Fixes applied in this replication (not discrepancies)

1. **Attendance** — match Stata `attendance_a` / `attendance` split.  
2. **CL `indig_head`** — missing indigenous belonging → 0 before IPW (restores Table 1C N=3,477).  
3. **Table 2A** — equal-variance t-tests.  
4. **Table 4A median** — Stata float storage of `r(p50)` for travel time.

## Recommended next phase

Freeze this tree as **`v0.1.0-python-replication`**.  
Begin causal-ML / modern extensions using **Table 3 any-work** (exact) as the primary outcome; avoid carrying unresolved wage or firm-size coding into CATE models until Open items are closed or explicitly scoped out.
