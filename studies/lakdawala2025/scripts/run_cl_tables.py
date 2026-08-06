#!/usr/bin/env python3
"""Build CL survey (if needed) and replicate Tables 1C / 2B / 5 cols 1–4."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src import paths  # noqa: E402
from src.child_labor.build import build_rw_child_labor_survey  # noqa: E402
from src.child_labor.tables import (  # noqa: E402
    compare_cl_to_published,
    load_cl,
    run_table5_cl,
    table1_panel_c,
    table2_panel_b,
)


def main() -> None:
    out = paths.FINAL / "RW_child_labor_survey.parquet"
    if not out.exists():
        print("Building RW_child_labor_survey…")
        build_rw_child_labor_survey()
    else:
        print("Rebuilding RW_child_labor_survey…")
        build_rw_child_labor_survey()

    cl = load_cl()
    print(f"CL frame: {cl.shape[0]:,} × {cl.shape[1]}")

    # Descriptives: report both weighted (paper) and unweighted (diagnostic)
    t1c_w = table1_panel_c(cl, use_weights=True)
    t1c_u = table1_panel_c(cl, use_weights=False)
    t2b_w = table2_panel_b(cl, use_weights=True)
    t2b_u = table2_panel_b(cl, use_weights=False)
    t5 = run_table5_cl(cl)

    tables_dir = paths.FINAL / "tables"
    tables_dir.mkdir(parents=True, exist_ok=True)
    t1c_w.to_csv(tables_dir / "table1_c.csv", index=False)
    pd_t2 = __import__("pandas").DataFrame([t2b_w])
    pd_t2.to_csv(tables_dir / "table2_b.csv", index=False)
    t5.to_csv(tables_dir / "table5_cl.csv", index=False)

    print("\n=== Table 1C (weighted / unweighted) ===")
    for label, t in [("W", t1c_w), ("U", t1c_u)]:
        r = t.loc[t["variable"] == "risks_a"].iloc[0]
        i = t.loc[t["variable"] == "injury_a"].iloc[0]
        print(
            f"  [{label}] risks {r['all']:.3f}/{r['working']:.3f}  "
            f"injury {i['all']:.3f}/{i['working']:.3f}  "
            f"N={t.attrs['n_all']}/{t.attrs['n_work']}  "
            f"paper .294/.545 .178/.324 N 3477/1749"
        )

    print("\n=== Table 2B ===")
    for label, t in [("W", t2b_w), ("U", t2b_u)]:
        print(
            f"  [{label}] risks ext/fam {t['risks_ext']:.3f}/{t['risks_fam']:.3f}  "
            f"injury {t['injury_ext']:.3f}/{t['injury_fam']:.3f}  "
            f"N={t['n_ext']}/{t['n_fam']}  paper .679/.537 .447/.314 N 186/1741"
        )

    print("\n=== Table 5 CL ===")
    print(t5.to_string(index=False))
    print("paper xx: -0.008/-0.038/-0.015/-0.015  N 8372/2914/8411/3208")

    # Prefer weighted descriptives (paper method); IPW now close after edu recode.
    ledger = compare_cl_to_published(t1c_w, t2b_w, t5)
    ledger_path = tables_dir / "cl_tables_ledger.csv"
    ledger.to_csv(ledger_path, index=False)
    print(f"\nWrote {ledger_path}")
    print(ledger.groupby("status").size().to_string())
    print("\nOpen / near / match detail:")
    print(ledger.to_string(index=False))


if __name__ == "__main__":
    main()
