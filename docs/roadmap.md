# Roadmap

## Near term

- [ ] Stabilize `opencausallab/` API (versioned, documented)
- [x] Root-friendly study CLI (`ocl study …`)
- [ ] Second case study scaffold (`studies/_template/`)
- [ ] Optional R twin estimator for Table 3
- [ ] Resolve Lakdawala Table 6 firm-size Open item (needs Stata export)

## Medium term

- [ ] Move more generic audit/reporting helpers from case studies into `opencausallab/reporting`
- [ ] Coverage badge with Codecov / uploaded `coverage.xml`
- [ ] Example notebook in `examples/` walking through a minimal verification

## Principles

1. New papers become new folders under `studies/` — do not fork the whole repo.
2. Anything that must work for every paper belongs in `opencausallab/`.
3. Extensions that change identification are documented as new designs, not silent replication edits.
