# Contributing

## Before opening a PR

From the **repo root**:

```bash
python -m pip install -e '.[replication,dev]'
export PYTHONPATH="$(pwd):$(pwd)/studies/lakdawala2025"

# Public tests (no microdata required):
pytest -q -m "not microdata and not causal_ml"

# Root-friendly study commands:
ocl study lakdawala2025 check-data
ocl study lakdawala2025 table3
ocl study lakdawala2025 verify
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
