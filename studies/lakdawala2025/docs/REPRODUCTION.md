# Reproduction guide

How long it takes, what resources you need, how to verify you built the same files, and where randomness lives.

Measured on Linux WSL2, Python 3.10.12, pinned [`requirements.txt`](../requirements.txt), with `HHsurvey.parquet` already built (2026-08).

---

## Wall-clock time (analysis already built)

| Command | Typical time |
|---------|----------------|
| `python scripts/run_table3.py` | **~4 s** |
| `python scripts/run_main_tables.py` | **~9–14 s** |
| `python scripts/run_verification.py` | **~11 s** |
| `python scripts/ci_gate.py` (full) | **~25–40 s** |

Cold ETL (raw → parquet), order of magnitude on this machine:

| Stage | Typical time |
|-------|----------------|
| Persona all years + compile/clean | ~2–5 min (I/O heavy) |
| Income all years + compile/clean | ~1–3 min |
| `run_hhsurvey.py` | ~1–2 min |
| Child labor build | ~30–90 s |

**Full pipeline from raw Dataverse extract → Tables 1–6:** plan on **~10–20 minutes**, not hours.

Stata wall times are not measured here (no Stata runtime). Python Table 3 ≈ **4 seconds** once `HHsurvey` exists.

---

## Hardware requirements

| Resource | Recommended | Notes |
|----------|-------------|--------|
| **RAM** | **8 GB** | Peak RSS ~3.5–4.2 GB observed for Table 3 / main tables / verification on this host (FE expansion + pandas). 16 GB comfortable. |
| **Disk** | **≥ 5 GB free** | Raw ~1.6 GB + intermediate ~0.1 GB + final ~0.1 GB; leave headroom for caches. |
| **CPU** | 2+ cores | Estimation is mostly single-threaded WLS; more cores help ETL I/O concurrency only modestly. |
| **OS** | Linux / macOS / WSL2 | Developed on WSL2 Linux. |

---

## Deterministic seeds

Single source of truth: [`src/seeds.py`](../src/seeds.py).

| Constant | Value | Used for |
|----------|-------|----------|
| `STATA_SEED` | `794758` | Child-labor IPW subsample (`set seed` in authors’ do-file) |
| `OPENCAUSAL_SEED` | `20260804` | OpenCausalLab extensions (e.g. exploratory splits); **not** Table 3 |

**Important:** NumPy `RandomState(794758)` ≠ Stata KISS `runiform()` with the same seed. Table 3 DiDisc does **not** use RNG. CL IPW weights are Near for that reason ([`docs/discrepancy_appendix.md`](discrepancy_appendix.md)).

---

## Output hashes (SHA-256)

After building analysis files:

```bash
python scripts/hash_outputs.py
# → data/final/validation/output_hashes.json
```

Reference hash for this release’s `HHsurvey.parquet` (committed in `output_hashes.json`):

```text
0f340ba027736e3ef9e214de884bcd5e6f938a147e89f886bc57fddf0323523f
```

If your SHA-256 differs, your ETL or raw inputs differ — stop before comparing coefficients.

---

## Provenance sidecars

Parquet writes through `src.provenance.write_parquet` also emit `*.provenance.json` with:

- `created_by` (script / function)
- `timestamp` (UTC ISO)
- `git_hash` (when available)
- `python` / package versions (when recorded)

---

## Quick verify

```bash
pip install -r requirements.txt
python scripts/hash_outputs.py          # compare SHA-256
python scripts/run_table3.py            # ~4 s
python scripts/ci_gate.py               # full PASS gate
```
