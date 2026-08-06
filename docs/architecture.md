# Architecture

```text
OpenCausalLab/
├── core/                 # reusable, paper-agnostic
│   ├── validation/
│   ├── utils/
│   ├── stata_semantics/
│   ├── reporting/
│   └── causal/
├── studies/
│   └── lakdawala2025/    # one paper, end-to-end
│       ├── data/
│       ├── docs/
│       ├── src/
│       ├── scripts/
│       ├── tests/
│       ├── notebooks/
│       └── vendor/
├── docs/                 # framework-level docs
└── examples/
```

## `core/`

| Package | Role |
|---------|------|
| `stata_semantics` | `stata_round`, recodes, winsor, numeric coercion |
| `utils` | logging, provenance, seeds, SHA-256 |
| `causal` | shared WLS + cluster helpers |
| `validation` | generic audit primitives |
| `reporting` | shared ledger / hash helpers |

## `studies/lakdawala2025/`

Paper-specific ETL (persona, income, HHsurvey, child labor), Tables 1–6, verification narrative, vendor `.do` files, and pytest validators.

Import pattern in case-study scripts:

```python
CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))  # core
sys.path.insert(0, str(CASE_ROOT))  # src
```

## Data flow (Lakdawala)

```text
vendor .do (spec) + Dataverse .dta
        → case-study src ETL
        → data/final/*.parquet
        → validation + tables
        → optional causal extensions
```
