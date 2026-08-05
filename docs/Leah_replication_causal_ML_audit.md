# Replication Package Audit: Modern Causal Analysis

Paper: *The Effects of Expanding Worker Rights to Children*  
Package: Harvard Dataverse DOI 10.7910/DVN/WJIQ6G

## Verified package structure

- 134 files total
- 75 Stata `.do` files
- 46 Stata `.dta` files
- Raw household surveys: 2012–2019
- Harmonized income scripts: 2012–2017 only
- Child labor surveys: 2008 and 2016
- Auxiliary municipality files: enforcement-office travel time/distance, 2012 baseline child labor, municipality assets/digital access
- Stata 17.1/18 workflow; generated `3.CleanData` files are not included and must be reconstructed

## Core identification

The paper uses a local difference-in-discontinuities design around age cutoffs, primarily age 14, comparing pre-law, law-period, and post-reversal years. The target is an intent-to-treat local policy effect. Modern ML must preserve this design rather than treat the policy indicator as an ordinary observational treatment.

## Household income finding

The main household-survey pipeline merges a harmonized income dataset and constructs:

- `y_household`
- `child_income`
- `income_adults = y_household - child_income`
- `income_adults_pc = income_adults / hhsize`
- `income_q` (five contemporaneous income quintiles)

However:

1. Income harmonization scripts exist only for 2012–2017, not 2018–2019.
2. Adult household income is measured in the survey year, after policy exposure for post-2014 observations.
3. The policy may affect adult labor supply, household composition, transfers, or reporting.
4. Subtracting child earnings removes a direct child-income component but does not make adult income predetermined.

Conclusion: `income_adults_pc` and `income_q` are unsuitable as primary CATE moderators across the full design. They may be used only in explicitly labeled exploratory analyses, restricted-period analyses, or as outcomes/mechanisms.

## Recommended predetermined moderators

### Strong candidates

- `male` — child sex
- `urban` — urban/rural location
- `indig_head` — household head indigenous identity
- `lang_spa_head` — household head childhood language / Spanish indicator
- `head_schooling` — household head schooling
- `head_age` — household head age
- `head_male` — household head sex
- `married_head` — household head marital status
- `hh_agecat1`–`hh_agecat4` — counts of other children by age group
- `adult_women`, `adult_men` — adult household composition
- municipality-level 2012 baseline child-labor rates from `baselineCL.dta`
- municipality-level census assets/connectivity from `comassets_chlab_bolivia.dta`
- distance/travel time to labor offices from `travel_capitales.dta`
- department and survey year

### Conditional-use candidates

- `hhsize`: likely mostly predetermined but can respond to policy through migration/composition; test sensitivity
- household-head occupation/work status: may respond to policy and should not be a primary moderator without timing justification
- CCT eligibility: partly constructed from contemporaneous schooling/enrollment and therefore unsafe as a generic baseline feature

### Do not use as CATE features

- child work status, hours, occupation, wages, earnings
- schooling attendance/enrollment
- permits
- injuries and hazardous work
- firm size, employer type, contracts, taxes, job location
- contemporaneous income or expenditure
- any variable explicitly constructed from an outcome or mechanism

## Best causal-ML extension

### Main estimand

Local conditional average treatment effects near the age-14 cutoff:

> How does the local intent-to-treat effect of the law vary across predetermined child, household, municipality, and enforcement characteristics?

### Preferred method sequence

1. Reproduce the original age-14 DiDisc estimate.
2. Reproduce transparent interaction/subgroup specifications.
3. Construct an orthogonalized DiDisc score or pseudo-outcome while retaining:
   - local bandwidth
   - age-running-variable splines
   - law and reversal periods
   - triangular kernel weights
   - survey weights where required
   - clustered uncertainty
4. Fit an honest causal forest / generalized random forest to the pseudo-outcome.
5. Use sample splitting or cross-fitting.
6. Validate discovered heterogeneity with conventional interaction regressions in a held-out sample.
7. Report CATEs and subgroup effects, not individual treatment effects.

## Method ratings

| Method | Rating | Comment |
|---|---:|---|
| Pre-specified subgroup DiDisc | 5/5 | Essential benchmark and easiest to defend |
| Honest causal forest on DiDisc score | 4.5/5 | Best modern extension |
| Double/debiased ML for nuisance functions | 4/5 | Useful if adapted to the quasi-experimental score |
| BART heterogeneity | 3.5/5 | Useful secondary robustness approach |
| Generic EconML treatment learner | 2.5/5 | Requires custom treatment/design handling |
| TARNet / DragonNet | 1.5/5 | Poor first choice: deterministic eligibility, weak overlap, tabular/local sample |
| Individual treatment effects | 1/5 | Not identified credibly in this design |

## Strongest project framing

**Machine-Learning-Assisted Heterogeneity in a Difference-in-Discontinuities Design: Evidence from Bolivia’s Child Labor Reform**

This should be framed as an exploratory extension of the original quasi-experimental design, not as deep learning replacing econometric identification.

## Immediate build steps

1. Edit `Master_00.do` to point to the local package directory.
2. Run the Stata cleaning pipeline to generate `HHsurvey.dta`.
3. Export the age-14 analysis sample to a portable format (`.csv` or `.parquet`).
4. Produce a variable-level audit: type, label, year coverage, missingness, and causal role.
5. Replicate Table 3 before fitting any ML model.
6. Implement subgroup DiDisc benchmarks.
7. Implement the cross-fitted forest extension.
