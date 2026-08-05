# Identification (preserved target)

The paper’s design is a **local difference-in-discontinuities (DiDisc)** around age cutoffs—primarily **age 14**—comparing pre-law, law-period, and post-reversal years.

OpenCausalLab must preserve, not replace:

- Local bandwidth around the age running variable (paper default: 12 months)
- Age running-variable splines
- Law / reversal period indicators (`pre`, `post`, `post_rev`)
- Triangular kernel weights
- Survey weights where required
- Clustered uncertainty (age-in-months × year in main specs)

Modern causal ML enters only as **heterogeneity exploration on top of this design** (local CATE / subgroup effects). Individual treatment effects are out of scope.
