#!/usr/bin/env python3
"""
Stage-by-stage validation audit for OpenCausalLab.

Order: raw/year-cleaned → merge → constructed → sample → descriptives
       → regression ladder → coefficients/SEs → discrepancy ledger.

Does NOT start from final coefficients alone.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

import pandas as pd  # noqa: E402

from src import paths  # noqa: E402
from opencausallab.stata_semantics.stata_utils import to_numeric  # noqa: E402
from src.table3 import load_hhsurvey  # noqa: E402
from opencausallab.validation.audit import audit_frame  # noqa: E402
from src.validation.table3_audit import (  # noqa: E402
    build_table3_ledger,
    regression_ladder,
    table3_sample_flow,
)


def audit_persona_years(out_dir: Path) -> pd.DataFrame:
    rows = []
    persona_dir = paths.INTERMEDIATE / "persona"
    for year in range(2012, 2020):
        path = persona_dir / f"EH{year}_Persona_relabel.parquet"
        if not path.exists():
            rows.append({"name": f"persona_{year}", "rows": None, "status": "missing"})
            continue
        df = pd.read_parquet(path)
        key = [c for c in ("folio", "nro", "id") if c in df.columns]
        if "folio" in df.columns and "nro" in df.columns:
            key = ["folio", "nro"]
        info = audit_frame(df, f"persona_{year}_relabel", key, as_dict=True)
        info["year"] = year
        info["path"] = str(path.relative_to(paths.ROOT))
        rows.append(info)
    # compiled / cleaned
    for name in ("EH_compiled_persona.parquet", "EH_cleaned_persona.parquet"):
        path = persona_dir / name
        if path.exists():
            df = pd.read_parquet(path)
            key = ["folio", "year", "nro"] if all(
                c in df.columns for c in ("folio", "year", "nro")
            ) else None
            info = audit_frame(df, name, key, as_dict=True)
            info["path"] = str(path.relative_to(paths.ROOT))
            rows.append(info)
    out = pd.DataFrame(rows)
    out.to_csv(out_dir / "stage_persona_audit.csv", index=False)
    return out


def audit_income_years(out_dir: Path) -> pd.DataFrame:
    rows = []
    inc_dir = paths.INTERMEDIATE / "income"
    for year in range(2012, 2018):
        path = inc_dir / f"EH{year}_Income_relabel.parquet"
        if not path.exists():
            continue
        df = pd.read_parquet(path)
        key = ["folio", "nro"] if all(c in df.columns for c in ("folio", "nro")) else None
        info = audit_frame(df, f"income_{year}_relabel", key, as_dict=True)
        info["year"] = year
        rows.append(info)
    for name in ("EH_compiled_income.parquet", "EH_cleaned_income.parquet"):
        path = inc_dir / name
        if path.exists():
            df = pd.read_parquet(path)
            key = ["id_year"] if "id_year" in df.columns else None
            info = audit_frame(df, name, key, as_dict=True)
            rows.append(info)
    out = pd.DataFrame(rows)
    out.to_csv(out_dir / "stage_income_audit.csv", index=False)
    return out


def audit_raw_counts(out_dir: Path) -> pd.DataFrame:
    """Raw .dta person-file row counts (first divergence checkpoint)."""
    from src.persona.common import read_dta

    rows = []
    for year in range(2012, 2020):
        try:
            from src.paths import raw_household_persona

            path = raw_household_persona(year)
            # row count only via pyreadstat metadata if possible
            import pyreadstat

            _, meta = pyreadstat.read_dta(str(path), metadataonly=True)
            n = int(meta.number_rows) if meta.number_rows is not None else None
            if n is None:
                df = read_dta(path)
                n = len(df)
            rows.append(
                {
                    "year": year,
                    "raw_persona_rows": n,
                    "path": str(path.relative_to(paths.ROOT)),
                }
            )
        except Exception as e:
            rows.append({"year": year, "raw_persona_rows": None, "error": str(e)})
    out = pd.DataFrame(rows)
    out.to_csv(out_dir / "stage_raw_counts.csv", index=False)
    return out


def main() -> None:
    out_dir = paths.FINAL / "validation"
    out_dir.mkdir(parents=True, exist_ok=True)

    print("=== Stage 0: raw annual counts ===")
    raw = audit_raw_counts(out_dir)
    print(raw.to_string(index=False))

    print("\n=== Stage 1: year-specific persona ===")
    persona = audit_persona_years(out_dir)
    print(persona[["name", "rows", "columns", "duplicate_keys"]].to_string(index=False))

    print("\n=== Stage 2: income ===")
    income = audit_income_years(out_dir)
    print(income[["name", "rows", "columns"]].to_string(index=False))

    print("\n=== Stage 3–4: HHsurvey + constructed / sample flow ===")
    hh = load_hhsurvey()
    hh_info = audit_frame(
        hh,
        "HHsurvey",
        ["id_year"] if "id_year" in hh.columns else ["folio", "year", "nro"],
        as_dict=True,
    )
    pd.DataFrame([hh_info]).to_csv(out_dir / "stage_hhsurvey_audit.csv", index=False)
    print(f"HHsurvey rows={hh_info['rows']} cols={hh_info['columns']} "
          f"dup_keys={hh_info.get('duplicate_keys')}")

    flow = table3_sample_flow(hh)
    flow.to_csv(out_dir / "table3_sample_flow.csv", index=False)
    print(flow.to_string(index=False))

    print("\n=== Stage 5–7: ledger + variable audit + regression ladder ===")
    ledger, extras = build_table3_ledger(hh)
    ledger.to_csv(out_dir / "discrepancy_ledger.csv", index=False)
    extras["var_audit"].to_csv(out_dir / "table3_variable_audit.csv")
    extras["binary_audit"].to_csv(out_dir / "table3_binary_audit.csv", index=False)
    extras["comparison"].to_csv(out_dir / "table3_coef_comparison.csv", index=False)

    ladder = regression_ladder(hh)
    ladder.to_csv(out_dir / "table3_regression_ladder.csv", index=False)

    diag = extras["diagnostics"]
    with open(out_dir / "table3_sample_diagnostics.json", "w", encoding="utf-8") as f:
        # make JSON-safe
        payload = {
            k: (v if not isinstance(v, dict) else {str(a): b for a, b in v.items()})
            for k, v in diag.items()
            if k != "crosstab_treat_period"
        }
        payload["crosstab_treat_period"] = {
            str(k): {str(a): int(b) for a, b in inner.items()}
            for k, inner in diag["crosstab_treat_period"].items()
        }
        payload["table1"] = extras["table1"]
        json.dump(payload, f, indent=2)

    print("\nDiscrepancy ledger (open/near first):")
    show = ledger.copy()
    show["_ord"] = show["status"].map({"open": 0, "near": 1, "match": 2}).fillna(3)
    show = show.sort_values(["_ord", "result"]).drop(columns="_ord")
    print(show.head(25).to_string(index=False))

    print("\nRegression ladder (WLS kernel, xxw3):")
    print(
        ladder.loc[ladder["estimator"] == "wls_kernel_cluster",
                   ["spec", "xxw3", "xxw3_se", "n"]].to_string(index=False)
    )

    # Persona vs raw row match
    if not raw.empty and not persona.empty:
        merge = raw.merge(
            persona.loc[persona["name"].str.startswith("persona_"), ["year", "rows"]],
            on="year",
            how="left",
            validate="m:1",
        )
        merge["delta_raw_minus_relabel"] = merge["raw_persona_rows"] - merge["rows"]
        merge.to_csv(out_dir / "raw_vs_relabel_counts.csv", index=False)
        print("\nRaw vs persona relabel deltas:")
        print(merge[["year", "raw_persona_rows", "rows", "delta_raw_minus_relabel"]].to_string(index=False))

    print(f"\nWrote validation artifacts → {out_dir}")


if __name__ == "__main__":
    main()
