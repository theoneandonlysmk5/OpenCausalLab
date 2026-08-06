# Pipeline DAG (Lakdawala et al. case study)

```text
Harvard Dataverse (.dta)
        │
        ├──────────────────────┐
        ▼                      ▼
  Persona (2012–2019)    Income (2012–2017)
        │                      │
        ▼                      ▼
  compile + clean         compile + clean
        │                      │
        └──────────┬───────────┘
                   ▼
            travel / assets
                   │
                   ▼
             HHsurvey.parquet
                   │
                   ├─────────────┐
                   ▼             ▼
              Validation      Table 3
                   │         (DiDisc)
                   ▼             │
            Replication ←────────┘
             confidence
                   │
                   ▼
            Tables 1–6 CSV
                   │
                   ▼
         Extensions (CATE)   [after verification]
```

Child Labor Survey is a **parallel** branch → `RW_child_labor_survey.parquet` → Tables 1C / 2B / 5 CL.

```mermaid
flowchart TD
  DV[Harvard Dataverse raw .dta]
  P[Persona ETL]
  I[Income ETL]
  HH[HHsurvey.parquet]
  V[Validation audits]
  T3[Table 3 DiDisc]
  RC[Replication confidence]
  T[Tables 1-6]
  CL[Child Labor ETL]
  RW[RW_child_labor_survey.parquet]
  EXT[Causal ML extensions]

  DV --> P
  DV --> I
  DV --> CL
  P --> HH
  I --> HH
  CL --> RW
  HH --> V
  HH --> T3
  V --> RC
  T3 --> RC
  RC --> T
  HH --> T
  RW --> T
  RC --> EXT
```

See [`pipeline.md`](pipeline.md) for file-level lineage and [`SOFTWARE.md`](../../../SOFTWARE.md) for module boundaries.
