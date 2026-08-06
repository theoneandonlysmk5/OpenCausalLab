# Empirical design (for non-economists)

This note explains **what** the paper estimates and **why** the econometric choices matter. It is not a validation report. For replication status see [`verification.md`](verification.md); for identification constraints on causal-ML extensions see [`identification.md`](identification.md).

---

## What question does the paper ask?

Bolivia expanded formal labor protections to children around a legal age threshold, then later reversed parts of the reform. The authors ask whether those legal changes shifted children’s work, school, and job characteristics.

The main challenge: age and calendar time both matter. Children just below and just above a birthday cutoff may differ for many reasons. A naive before/after comparison confounds the law with other trends.

---

## What is a Difference-in-Discontinuities (DiDisc)?

Think of two building blocks:

1. **Regression discontinuity (RD).** Compare units just below vs just above a cutoff in a running variable (here: age). Local to the cutoff, assignment to “treated by age rule” is as-good-as-random if the running variable cannot be precisely manipulated.
2. **Difference-in-differences (DiD).** Compare changes across periods (pre-law vs law vs reversal).

**Difference-in-discontinuities** combines them: estimate the **RD gap at the age cutoff**, then see how that gap **changes** when the legal regime changes. The object of interest is not “are 13-year-olds different from 14-year-olds?” but “did the law change the discontinuity at age 14?”

In code this appears as interactions such as `xxw3 = post × treatw14` (law period × below-cutoff), with a reversal counterpart `xxrw3`.

---

## Why age 14?

Age **14** is the legally relevant birthday for the reform the authors study. The running variable is age in months relative to that cutoff (`runningw14`). Children just under 14 are on one side of the rule; those just over are on the other. Concentrating identification at that birthday is what makes the design local and causal under standard RD assumptions.

---

## Why a triangular kernel and a 12-month bandwidth?

RD estimates are **local**. Observations far from the cutoff should not dominate.

- **Bandwidth (12 months):** only ages within one year of the cutoff enter the main Table 3 sample (via kernel weight &gt; 0). Wider bandwidths bring more data but more bias from far-away ages.
- **Triangular kernel:** weight falls linearly to zero at the bandwidth edge. Units nearest the cutoff get the most weight. This is a standard local-linear RD weighting choice; the authors implement it as analytic weights `[aw=kernel_triw14]`.

Robustness: re-estimate at other bandwidths (15, 18, 24, 30). Sign should be stable if the local effect is real (see verification Appendix B).

---

## Why cluster by age-month × year (`age_mo_year`)?

Standard errors must reflect dependence. Children observed in the same age-in-months cell in the same survey year share common shocks (cohort/age composition, survey design, local labor conditions timed by age). Clustering on **`age_mo_year`** allows arbitrary correlation within those cells.

This is **not** the same as clustering on municipality. Mis-stating the cluster variable changes inference even if coefficients match.

---

## Why department × year fixed effects?

`i.depto#i.year` (department-by-year FE) absorbs place-and-time shocks: regional labor markets, survey waves, macro conditions. Identification of `xxw3` then comes from within department-year variation in the age discontinuity across legal regimes—not from comparing rich vs poor departments over time.

---

## What Table 3 is claiming (in one sentence)

Around the age-14 cutoff, with local triangular weights and department-year FE, the law-period interaction shows a reduction in children’s work (and related outcomes) that is not mirrored by the reversal interaction—consistent with a causal effect of the legal expansion under the DiDisc assumptions.

---

## What this project must preserve

| Choice | Role |
|--------|------|
| Running variable `runningw14` | Defines the discontinuity |
| Treat / post / reversal interactions | DiDisc contrasts |
| Triangular kernel, BW 12 | Local weighting |
| `i.depto#i.year` | Absorb place-time shocks |
| Cluster `age_mo_year` | Correct dependence for SEs |
| Pre-law mean on `e(sample)` | Comparable baseline |

Changing any of these changes the **design**, not just the software. OpenCausalLab treats that list as inviolable when translating to Python and when adding causal-ML extensions.
