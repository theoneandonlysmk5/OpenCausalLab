# Contributing

## Before opening a PR

From the **repo root**:

```bash
pip install -r requirements.txt
export PYTHONPATH="$(pwd):$(pwd)/studies/lakdawala2025"

# Lakdawala case study (with microdata if available):
cd studies/lakdawala2025
python scripts/run_validation_audit.py
python scripts/run_verification.py
python scripts/ci_gate.py
```

Without microdata:

```bash
export PYTHONPATH="$(pwd):$(pwd)/studies/lakdawala2025"
pytest studies/lakdawala2025/tests/test_stata_round.py -q
```

## Rules

1. Put reusable utilities in `core/`. Put paper-specific ETL/tables in `studies/<paper>/`.
2. Read the case study [`validation_protocol.md`](studies/lakdawala2025/docs/validation_protocol.md) before changing estimation.
3. Do not silently change identification choices — see [`identification.md`](studies/lakdawala2025/docs/identification.md).
4. Prefer documenting Near/Open discrepancies over forcing a match.

See [`docs/architecture.md`](docs/architecture.md) and [`docs/philosophy.md`](docs/philosophy.md).
