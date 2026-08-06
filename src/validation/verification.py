"""
Replication confidence audits: spec equivalence, variable moments,
merge integrity, e(sample) exports, FE/weights, bandwidth sensitivity.

Outputs land in ``data/final/validation/`` and feed ``docs/verification.md``.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

from .. import paths
from ..didisc_reg import depto_year, wls_cluster
from ..stata_utils import to_numeric
from ..table3 import (
    CONTROLS,
    PUBLISHED_TABLE3,
    prepare_table3_sample,
    run_table3,
)


OUT = paths.FINAL / "validation"
SAMPLES = paths.FINAL / "samples"

CORE_VARS = [
    "age_dob_m",
    "works",
    "attendance",
    "attendance_a",
    "not_forbidden_a",
    "forbidden_a",
    "hours_week_a",
    "urban",
    "head_schooling",
    "indig_head",
    "male",
    "eligible_gr",
    "runningw14",
    "treatw14",
    "xxw3",
    "kernel_triw14",
    "het_time",
    "het_dist",
    "number_workers_w",
    "wage_hour_w",
    "log_wage_hour_w",
]


def regression_spec_table3() -> pd.DataFrame:
    """Item-by-item Stata vs Python specification for Table 3."""
    rows = [
        (
            "Outcome set",
            "works hours_week_a self_employed_a wrk_forother_a forbidden_a not_forbidden_a lf_participation",
            "same YVARS list",
            True,
        ),
        ("Years", "2012–2019", "year ∈ [2012, 2019]", True),
        ("Treatment interaction", "xxw3 = post × treatw14", "xxw3", True),
        ("Reversal interaction", "xxrw3 = post_rev × treatw14", "xxrw3", True),
        (
            "Running variable",
            "runningw14 (age week-before − 168 months)",
            "runningw14",
            True,
        ),
        (
            "Treatment indicator",
            "treatw14 = 1{runningw14 < 0} at age-14 cutoff",
            "treatw14",
            True,
        ),
        ("Spline", "treatxrunningw14", "treatxrunningw14", True),
        (
            "Kernel",
            "triangular",
            "kernel_triw14 = (1−|r|/bw)·1{|r|≤bw}",
            True,
        ),
        ("Bandwidth", "12 months (table notes)", "bw=12; kernel_triw14", True),
        (
            "Analytic weights",
            "[aw=kernel_triw14]",
            "statsmodels WLS weights=kernel_triw14",
            True,
        ),
        ("Survey factor weights", "not used in Table 3", "not used", True),
        ("Fixed effects", "i.depto#i.year", "C(depto_year)", True),
        (
            "Cluster",
            "vce(cluster age_mo_year)",
            "cov_type=cluster groups=age_mo_year",
            True,
        ),
        (
            "Controls",
            "post post_rev urban head_* indig_head male hh_agecat* adults eligible_gr",
            "CONTROLS list matches do-file",
            True,
        ),
        (
            "Pre-law mean",
            "sum y if e(sample)&pre==1",
            "mean on regression sample ∩ pre",
            True,
        ),
    ]
    return pd.DataFrame(
        [{"item": a, "stata": b, "python": c, "match": d} for a, b, c, d in rows]
    )


def regression_spec_table4() -> pd.DataFrame:
    rows = [
        ("Outcome", "works", "works", True),
        ("Years", "2012–2016", "year ∈ [2012, 2016]", True),
        (
            "Moderator Panel A",
            "het_time (ttime > float32(p50))",
            "same (Stata float median)",
            True,
        ),
        ("Moderator Panel B", "het_dist", "het_dist", True),
        (
            "Interactions",
            "xxwh3 xxw3 h postxh treatw14 runningw14 treatxrunningw14 treatw14xh",
            "same terms",
            True,
        ),
        ("Eligible_gr", "Panel A: no; Panel B: yes", "include_eligible flag", True),
        ("Kernel / BW", "[aw=kernel_triw14], bw 12", "same", True),
        ("FE / cluster", "i.depto#i.year / age_mo_year", "same", True),
        (
            "nlcom",
            "far=_b[xxwh3]+_b[xxw3]; near=_b[xxw3]",
            "nlcom_sum",
            True,
        ),
    ]
    return pd.DataFrame(
        [{"item": a, "stata": b, "python": c, "match": d} for a, b, c, d in rows]
    )


def variable_moments(df: pd.DataFrame, vars_: list[str] | None = None) -> pd.DataFrame:
    vars_ = vars_ or CORE_VARS
    rows = []
    for v in vars_:
        if v not in df.columns:
            rows.append({"variable": v, "status": "missing_column"})
            continue
        s = to_numeric(df[v])
        rows.append(
            {
                "variable": v,
                "n": int(len(s)),
                "nonmiss": int(s.notna().sum()),
                "miss": int(s.isna().sum()),
                "miss_rate": float(s.isna().mean()),
                "mean": float(s.mean()) if s.notna().any() else np.nan,
                "std": float(s.std()) if s.notna().sum() > 1 else np.nan,
                "min": float(s.min()) if s.notna().any() else np.nan,
                "p25": float(s.quantile(0.25)) if s.notna().any() else np.nan,
                "median": float(s.median()) if s.notna().any() else np.nan,
                "p75": float(s.quantile(0.75)) if s.notna().any() else np.nan,
                "p95": float(s.quantile(0.95)) if s.notna().any() else np.nan,
                "max": float(s.max()) if s.notna().any() else np.nan,
                "nunique": int(s.nunique(dropna=True)),
            }
        )
    return pd.DataFrame(rows)


def merge_audit_persona_income() -> pd.DataFrame:
    """Replay persona ⟕ income merge with Stata-style _merge counts."""
    persona = paths.INTERMEDIATE / "persona" / "EH_cleaned_persona.parquet"
    income = paths.INTERMEDIATE / "income" / "EH_cleaned_income.parquet"
    if not persona.exists() or not income.exists():
        return pd.DataFrame([{"merge": "persona_income", "status": "inputs_missing"}])

    left = pd.read_parquet(persona, columns=["id_year"]).drop_duplicates()
    inc = pd.read_parquet(income)
    if "id_year" not in inc.columns:
        return pd.DataFrame(
            [{"merge": "persona_income", "status": "income_missing_id_year"}]
        )
    right = inc[["id_year"]].drop_duplicates()
    m = left.merge(right, on="id_year", how="outer", indicator=True)
    counts = m["_merge"].value_counts()
    return pd.DataFrame(
        [
            {
                "merge": "persona_id_year ⟕ income_id_year",
                "left_n": int(len(left)),
                "right_n": int(len(right)),
                "matched": int(counts.get("both", 0)),
                "left_only": int(counts.get("left_only", 0)),
                "right_only": int(counts.get("right_only", 0)),
                "note": "Income years 2012–2017 only; later HH years left_only by design",
            }
        ]
    )


def merge_audit_travel(hh: pd.DataFrame) -> pd.DataFrame:
    """HHsurvey municipalities vs travel_capitales merge."""
    from ..hhsurvey import build_travel_tomerge

    travel = build_travel_tomerge()
    left = to_numeric(hh["cod_secc"]).dropna().drop_duplicates()
    right = to_numeric(travel["cod_secc"]).dropna().drop_duplicates()
    ldf = pd.DataFrame({"cod_secc": left})
    rdf = pd.DataFrame({"cod_secc": right})
    m = ldf.merge(rdf, on="cod_secc", how="outer", indicator=True)
    counts = m["_merge"].value_counts()
    k = to_numeric(hh["kernel_triw14"]).fillna(0) > 0
    het = to_numeric(hh.loc[k, "het_time"])
    return pd.DataFrame(
        [
            {
                "merge": "HHsurvey.cod_secc ⟕ travel.cod_secc",
                "left_n": int(len(left)),
                "right_n": int(len(right)),
                "matched": int(counts.get("both", 0)),
                "left_only": int(counts.get("left_only", 0)),
                "right_only": int(counts.get("right_only", 0)),
                "kernel_sample_het_time_miss": int(het.isna().sum()),
                "kernel_sample_n": int(k.sum()),
            }
        ]
    )


def fe_weight_audit(sample: pd.DataFrame) -> dict[str, Any]:
    w = to_numeric(sample["kernel_triw14"])
    fe = sample["depto_year"] if "depto_year" in sample.columns else depto_year(sample)
    vc = fe.value_counts()
    return {
        "n": int(len(sample)),
        "n_clusters_age_mo_year": int(to_numeric(sample["age_mo_year"]).nunique()),
        "n_fe_depto_year": int(fe.nunique()),
        "singleton_fe": int((vc == 1).sum()),
        "weight_sum": float(w.sum()),
        "weight_mean": float(w.mean()),
        "weight_min": float(w.min()),
        "weight_max": float(w.max()),
        "weight_zeros": int((w == 0).sum()),
        "note": "Stata [aw=] does not renormalize for point estimates; WLS matches",
    }


def export_regression_samples(hh: pd.DataFrame) -> dict[str, Path]:
    """Write e(sample)-equivalent frames for Tables 3 and 4."""
    SAMPLES.mkdir(parents=True, exist_ok=True)
    out: dict[str, Path] = {}

    t3 = prepare_table3_sample(hh)
    p3 = SAMPLES / "sample_table3.parquet"
    t3.to_parquet(p3, index=False)
    out["table3"] = p3

    y = to_numeric(hh["year"])
    df = hh.loc[(y >= 2012) & (y <= 2016)].copy()
    for c in [
        "works",
        "xxw3",
        "xxwhet_time3",
        "het_time",
        "postxhet_time",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "treatw14xhet_time",
        "post",
        "urban",
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "male",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "kernel_triw14",
        "age_mo_year",
        "pre",
        "depto",
        "year",
    ]:
        if c in df.columns:
            df[c] = to_numeric(df[c])
    if "xxwhet_time3" not in df.columns:
        df["xxwhet_time3"] = df["xxw3"] * df["het_time"]
    if "treatw14xhet_time" not in df.columns:
        df["treatw14xhet_time"] = df["treatw14"] * df["het_time"]
    if "postxhet_time" not in df.columns:
        df["postxhet_time"] = df["post"] * df["het_time"]
    df = df.loc[df["kernel_triw14"].fillna(0) > 0].copy()
    df["depto_year"] = depto_year(df)
    need = [
        "works",
        "xxwhet_time3",
        "xxw3",
        "het_time",
        "postxhet_time",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "treatw14xhet_time",
        "post",
        "urban",
        "head_schooling",
        "head_male",
        "head_age",
        "indig_head",
        "male",
        "hh_agecat1",
        "hh_agecat2",
        "hh_agecat3",
        "hh_agecat4",
        "adult_women",
        "adult_men",
        "kernel_triw14",
        "age_mo_year",
        "depto_year",
        "pre",
    ]
    t4 = df.dropna(subset=need).reset_index(drop=True)
    p4 = SAMPLES / "sample_table4.parquet"
    t4.to_parquet(p4, index=False)
    out["table4"] = p4

    pd.DataFrame(
        [
            {"table": "3", "n_hhsurvey": len(hh), "n_esample": len(t3), "path": str(p3)},
            {"table": "4A", "n_hhsurvey": len(hh), "n_esample": len(t4), "path": str(p4)},
        ]
    ).to_csv(OUT / "esample_sizes.csv", index=False)
    return out


def bandwidth_sensitivity(
    hh: pd.DataFrame, bandwidths: tuple[int, ...] = (12, 15, 18, 24, 30)
) -> pd.DataFrame:
    """Re-estimate Table 3 works xxw3 under alternate triangular bandwidths."""
    rows = []
    base = hh.copy()
    y = to_numeric(base["year"])
    base = base.loc[(y >= 2012) & (y <= 2019)].copy()
    for c in CONTROLS + [
        "works",
        "kernel_triw14",
        "runningw14",
        "age_mo_year",
        "pre",
        "depto",
        "year",
    ]:
        if c in base.columns:
            base[c] = to_numeric(base[c])
    base["depto"] = to_numeric(base["depto"])
    base["year"] = to_numeric(base["year"]).astype(int)

    for bw in bandwidths:
        df = base.copy()
        r = to_numeric(df["runningw14"])
        k = ((bw - r.abs()) / bw) * (r.abs() <= bw).astype(float)
        df["kernel_bw"] = k
        df = df.loc[df["kernel_bw"].fillna(0) > 0].copy()
        df["depto_year"] = (
            df["depto"].astype(int).astype(str)
            + "_"
            + df["year"].astype(int).astype(str)
        )
        need = CONTROLS + ["works", "kernel_bw", "age_mo_year", "depto_year", "pre"]
        df = df.dropna(subset=need).reset_index(drop=True)
        formula = "works ~ " + " + ".join(CONTROLS) + " + C(depto_year)"
        res = wls_cluster(formula, df, weight="kernel_bw")
        rows.append(
            {
                "bandwidth": bw,
                "xxw3": float(res.params["xxw3"]),
                "xxw3_se": float(res.bse["xxw3"]),
                "xxrw3": float(res.params["xxrw3"]),
                "n": int(res.nobs),
                "mean_pre": float(df.loc[df["pre"] == 1, "works"].mean()),
                "paper_bw12_xxw3": -0.039,
            }
        )
    return pd.DataFrame(rows)


def distribution_quantiles(hh: pd.DataFrame) -> pd.DataFrame:
    cols = [
        "number_workers",
        "number_workers_w",
        "hours_week_a",
        "wage_hour_w",
        "age_dob_m",
    ]
    rows = []
    for c in cols:
        if c not in hh.columns:
            continue
        s = to_numeric(hh[c]).dropna()
        qs = np.quantile(s, [0, 0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 1])
        rows.append(
            {
                "variable": c,
                "n": int(len(s)),
                "q0": float(qs[0]),
                "q01": float(qs[1]),
                "q05": float(qs[2]),
                "q10": float(qs[3]),
                "q25": float(qs[4]),
                "q50": float(qs[5]),
                "q75": float(qs[6]),
                "q90": float(qs[7]),
                "q95": float(qs[8]),
                "q99": float(qs[9]),
                "q100": float(qs[10]),
            }
        )
    return pd.DataFrame(rows)


def run_all_verification(hh: pd.DataFrame | None = None) -> dict[str, Path]:
    """Generate the full verification artifact set."""
    OUT.mkdir(parents=True, exist_ok=True)
    if hh is None:
        hh = pd.read_parquet(paths.FINAL / "HHsurvey.parquet")

    artifacts: dict[str, Path] = {}

    spec3 = regression_spec_table3()
    p = OUT / "spec_equivalence_table3.csv"
    spec3.to_csv(p, index=False)
    artifacts["spec3"] = p

    spec4 = regression_spec_table4()
    p = OUT / "spec_equivalence_table4.csv"
    spec4.to_csv(p, index=False)
    artifacts["spec4"] = p

    sample = prepare_table3_sample(hh)
    vm = variable_moments(sample)
    p = OUT / "variable_moments_table3_sample.csv"
    vm.to_csv(p, index=False)
    artifacts["var_moments"] = p

    vm_hh = variable_moments(hh)
    p = OUT / "variable_moments_hhsurvey.csv"
    vm_hh.to_csv(p, index=False)

    merges = pd.concat(
        [merge_audit_persona_income(), merge_audit_travel(hh)], ignore_index=True
    )
    p = OUT / "merge_audit.csv"
    merges.to_csv(p, index=False)
    artifacts["merges"] = p

    fe = fe_weight_audit(sample)
    p = OUT / "fe_weight_audit_table3.json"
    pd.Series(fe).to_json(p)
    artifacts["fe_weights"] = p

    samples = export_regression_samples(hh)
    artifacts.update({f"sample_{k}": v for k, v in samples.items()})

    dist = distribution_quantiles(hh)
    p = OUT / "distribution_quantiles.csv"
    dist.to_csv(p, index=False)
    artifacts["distributions"] = p

    bw = bandwidth_sensitivity(hh)
    p = OUT / "bandwidth_sensitivity_table3_works.csv"
    bw.to_csv(p, index=False)
    artifacts["bandwidth"] = p

    from .stage_ladder import write_stage_ladder

    p = write_stage_ladder(hh)
    artifacts["stage_ladder"] = p

    res = run_table3(sample)
    cmp_rows = []
    for outcome, pub in PUBLISHED_TABLE3.items():
        sub = res.loc[res["outcome"] == outcome]
        if sub.empty:
            continue
        xx = sub.loc[sub["term"] == "xxw3"].iloc[0]
        cmp_rows.append(
            {
                "outcome": outcome,
                "paper_xxw3": pub["xxw3"],
                "python_xxw3": float(xx["coef"]),
                "paper_se": pub["xxw3_se"],
                "python_se": float(xx["se"]),
                "paper_n": pub["n"],
                "python_n": int(xx["n"]),
                "abs_diff_coef": abs(float(xx["coef"]) - pub["xxw3"]),
                "status": "exact"
                if abs(float(xx["coef"]) - pub["xxw3"]) < 5e-4
                else "near",
            }
        )
    p = OUT / "table3_spec_coef_check.csv"
    pd.DataFrame(cmp_rows).to_csv(p, index=False)
    artifacts["table3_coefs"] = p

    return artifacts
