"""Canonical random seeds for OpenCausalLab.

Table 3 DiDisc estimation is deterministic and does **not** use these seeds.
Child-labor IPW uses STATA_SEED to mirror the authors' ``set seed`` line;
NumPy's RNG is still not bit-identical to Stata KISS.
"""

from __future__ import annotations

# Authors' Child Labor Survey do-file: set seed 794758
STATA_SEED: int = 794758

# OpenCausalLab extensions (subgroups / CATE helpers that need RNG)
OPENCAUSAL_SEED: int = 20260804

# Alias used in docs / env examples
SEED: int = OPENCAUSAL_SEED
