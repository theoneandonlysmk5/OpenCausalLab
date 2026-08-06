# Contributing

Thanks for interest in OpenCausalLab. The project prioritizes **design equivalence** and stage-by-stage validation over drive-by coefficient edits.

## Before opening a PR

From the repo root, with dependencies installed (`pip install -r requirements.txt`) and analysis files built if you change estimation or ETL:

```bash
python scripts/run_validation_audit.py
python scripts/run_verification.py
pytest tests/test_stata_round.py tests/test_table3.py tests/test_verification.py -q
# Or the full CI gate (preferred when HHsurvey.parquet exists):
python scripts/ci_gate.py
```

If you lack microdata, still run:

```bash
pytest tests/test_stata_round.py -q
python scripts/ci_gate.py   # unit + committed artifact gates
```

## Rules of thumb

1. Read [`docs/validation_protocol.md`](docs/validation_protocol.md) before changing cleaning or estimation. **Run that protocol before any causal-ML extension.**
2. Do not change identification choices (running variable, kernel, bandwidth, FE, cluster) silently — see [`docs/identification.md`](docs/identification.md). That is a new design, not a replication fix.
3. Prefer documenting Near/Open discrepancies over forcing a match.
4. Keep logic in `src/`; keep `scripts/` thin.
5. Architecture overview: [`SOFTWARE.md`](SOFTWARE.md).

## PR checklist

- [ ] Validation / verification (or `ci_gate.py`) run locally as applicable
- [ ] New or updated CSV artifacts under `data/final/tables/` or `data/final/validation/` if outputs changed
- [ ] Docs updated if behavior or status vocabulary changed
- [ ] No microdata (`.dta` / large parquet) committed

## Code of collaboration

Be precise about status labels (**Exact** / matches manuscript / **Near** / **Open**). Evidence trails beat unexplained “fixes.”
