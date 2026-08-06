# Contributing

## Before opening a PR

From the **repo root**:

```bash
python -m pip install -e '.[replication,dev]'
export PYTHONPATH="$(pwd):$(pwd)/studies/lakdawala2025"

# Public tests (no microdata required):
pytest -q -m "not microdata and not causal_ml"

# Lakdawala case study (with microdata if available):
cd studies/lakdawala2025
python scripts/check_data_layout.py
python scripts/run_validation_audit.py
python scripts/run_verification.py
python scripts/ci_gate.py
```

Markers:

- `microdata` — needs Dataverse extracts or built parquet
- `causal_ml` — needs `pip install -e '.[causal-ml]'`

## Rules

1. Put reusable utilities in `opencausallab/`. Put paper-specific ETL/tables in `studies/<paper>/`.
2. Read the case study [`validation_protocol.md`](studies/lakdawala2025/docs/validation_protocol.md) before changing estimation.
3. Do not silently change identification choices — see [`identification.md`](studies/lakdawala2025/docs/identification.md).
4. Prefer documenting Near/Open discrepancies over forcing a match.
5. Never commit raw `.dta`, parquet microdata, or row-level ID dumps. Create ZIPs with `git archive`, not the working tree.

See [`docs/architecture.md`](docs/architecture.md) and [`docs/philosophy.md`](docs/philosophy.md).
