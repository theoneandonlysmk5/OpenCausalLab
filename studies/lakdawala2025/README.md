# Case study: Lakdawala et al. (2025)

**Paper:** *The Effects of Expanding Worker Rights to Children*  
Lakdawala, Martínez Heredia, Vera-Cossio — [Dataverse 10.7910/DVN/WJIQ6G](https://doi.org/10.7910/DVN/WJIQ6G)

Everything in this folder is **specific to this paper**. Shared library code lives in repo-root [`opencausallab/`](../../opencausallab/).

## Status

| Check | Status |
|-------|--------|
| Table 3 design / N / coefs / SEs | Pass |
| Tables 1–4, 6 location | Match manuscript |
| Table 5 wage | Near |
| Table 6 firm size | Open |

## Layout

| Path | Role |
|------|------|
| `docs/` | Design, verification, discrepancies, reproduction |
| `vendor/` | Authors’ `.do` files (specification only) |
| `src/` | Paper ETL + tables |
| `scripts/` | CLI entry points |
| `tests/` | Pytest validators |
| `data/` | raw / intermediate / final (microdata not in git) |

## Run (from this directory)

```bash
# from repo root first:
#   pip install -r requirements.txt
python scripts/run_table3.py
python scripts/ci_gate.py
```

## Docs

1. [DESIGN.md](docs/DESIGN.md)  
2. [replication_scope.md](docs/replication_scope.md)  
3. [verification.md](docs/verification.md)  
4. [discrepancy_appendix.md](docs/discrepancy_appendix.md)  
5. [REPRODUCTION.md](docs/REPRODUCTION.md)
