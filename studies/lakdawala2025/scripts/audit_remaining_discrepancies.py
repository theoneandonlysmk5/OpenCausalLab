#!/usr/bin/env python3
"""Audits for remaining Table 5 wage / Table 6 firm-size / CL IPW discrepancies.

Writes CSVs under ``data/final/validation/``. See ``studies/lakdawala2025/docs/discrepancy_appendix.md``.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm

from pathlib import Path
import sys

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

from src import paths  # noqa: E402
from src.child_labor.design import AGE_HI, AGE_LO, STATA_SEED, SUBSAMPLE_FRAC  # noqa: E402
from src.child_labor.tables import load_cl, run_table5_cl  # noqa: E402
from opencausallab.causal.didisc_reg import DEMO, PERIOD, RD_W14, depto_year, didisc_formula, wls_cluster  # noqa: E402
from opencausallab.stata_semantics.stata_utils import to_numeric, winsor_high  # noqa: E402
from src.table3 import prepare_table3_sample  # noqa: E402

OUT = paths.FINAL / "validation"
OUT.mkdir(parents=True, exist_ok=True)


def audit_table5_wage(hh: pd.DataFrame) -> pd.DataFrame:
    y = to_numeric(hh["year"])
    df = hh.loc[(y >= 2012) & (y <= 2019)].copy()
    cols = [
        "wage_hour_w",
        "log_wage_hour_w",
        "hours_week_w",
        "sww14_18",
        "kernel_triw14_18",
        "runningw14",
        "xxw3",
        "xxrw3",
        "treatw14",
        "treatxrunningw14",
        "post",
        "post_rev",
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
        "eligible_gr",
        "depto",
        "age_mo_year",
        "pre",
        "number_workers_w",
        "paid",
        "id_year",
    ]
    for c in cols:
        if c in df.columns:
            df[c] = to_numeric(df[c])

    ctrl = [
        "xxw3",
        "xxrw3",
        "treatw14",
        "runningw14",
        "treatxrunningw14",
        "post",
        "post_rev",
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
        "eligible_gr",
    ]

    steps: list[dict] = []
    cur = df.copy()

    def log(step: str, mask=None, note: str = "") -> None:
        nonlocal cur
        if mask is not None:
            cur = cur.loc[mask].copy()
        steps.append({"step": step, "n": int(len(cur)), "note": note})

    log("0_years_2012_2019")
    log("1_sww14_18", cur["sww14_18"].eq(1), "abs(runningw14)<=18")
    log("2_kernel_gt0", cur["kernel_triw14_18"].fillna(0) > 0, "triangular kernel > 0")
    log("3_wage_hour_w_nonmiss", cur["wage_hour_w"].notna(), "bottleneck → Python N=715")
    log("4_wage_gt0", cur["wage_hour_w"] > 0, "no zero/neg in practice; do-file uses log(w+1)")
    log("5_log_finite", np.isfinite(cur["log_wage_hour_w"].astype(float)))
    log("6_hours_nonmiss", cur["hours_week_w"].notna())
    log("7_complete_controls", cur[ctrl].notna().all(axis=1))
    cur["depto_year"] = depto_year(cur)
    log(
        "8_fe_cluster_ids",
        cur["depto_year"].notna() & cur["age_mo_year"].notna(),
        "paper N=712 (−3)",
    )
    steps.append(
        {
            "step": "9_nw_nonmiss_NOT_in_reg",
            "n": int(cur["number_workers_w"].notna().sum()),
            "note": "Stata Mean uses number_workers_w; not a regressor",
        }
    )
    ledger = pd.DataFrame(steps)
    ledger.to_csv(OUT / "table5_wage_sample_ledger.csv", index=False)

    flags = pd.DataFrame(
        {
            "id_year": cur["id_year"],
            "wage_hour_w": cur["wage_hour_w"],
            "log_wage_hour_w": cur["log_wage_hour_w"],
            "runningw14": cur["runningw14"],
            "abs_r": cur["runningw14"].abs(),
            "kernel": cur["kernel_triw14_18"],
            "miss_wage": cur["wage_hour_w"].isna(),
            "zero_wage": cur["wage_hour_w"].eq(0),
            "neg_wage": cur["wage_hour_w"] < 0,
            "miss_hours": cur["hours_week_w"].isna(),
            "zero_hours": cur["hours_week_w"].eq(0),
            "log_finite": np.isfinite(cur["log_wage_hour_w"].astype(float)),
            "pos_kernel": cur["kernel_triw14_18"] > 0,
            "nw_nonmiss": cur["number_workers_w"].notna(),
            "paid": cur["paid"],
            "pre": cur["pre"],
        }
    )
    w = flags["kernel"].to_numpy(dtype=float)
    yw = flags["log_wage_hour_w"].to_numpy(dtype=float)
    flags["contrib_abs"] = w * np.abs(yw - np.average(yw, weights=w))
    flags.sort_values("contrib_abs", ascending=False).to_csv(
        OUT / "table5_wage_obs_flags.csv", index=False
    )
    return ledger


def audit_table6_firmsize(hh: pd.DataFrame) -> pd.DataFrame:
    pers = pd.read_parquet(paths.INTERMEDIATE / "persona" / "EH_cleaned_persona.parquet")

    def dist_row(name: str, s: pd.Series) -> dict:
        x = pd.to_numeric(s, errors="coerce").dropna().astype(float)
        if len(x) == 0:
            return {"stage": name}
        qs = np.quantile(x, [0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99])
        return {
            "stage": name,
            "count": int(len(x)),
            "mean": float(x.mean()),
            "std": float(x.std()),
            "min": float(x.min()),
            "p1": float(qs[0]),
            "p5": float(qs[1]),
            "p25": float(qs[2]),
            "median": float(qs[3]),
            "p75": float(qs[4]),
            "p95": float(qs[5]),
            "p99": float(qs[6]),
            "max": float(x.max()),
        }

    sample = prepare_table3_sample(hh)
    work = sample.loc[to_numeric(sample["works"]).eq(1)].copy()
    for c in [
        "number_workers",
        "number_workers_w",
        "number_workers_a",
        "xxw3",
        "xxrw3",
        *RD_W14,
        *PERIOD,
        *DEMO,
        "kernel_triw14",
        "age_mo_year",
        "depto",
        "pre",
    ]:
        work[c] = to_numeric(work[c])
    work["depto_year"] = depto_year(work)
    need = [
        "number_workers_a",
        "xxw3",
        "xxrw3",
        *RD_W14,
        *PERIOD,
        *DEMO,
        "kernel_triw14",
        "age_mo_year",
        "depto_year",
        "pre",
    ]
    reg = work.dropna(subset=need).copy()
    pre = reg["pre"].eq(1)

    rows = [
        dist_row("1_persona_raw_post888888", pers["number_workers"]),
        dist_row("2_persona_winsor_p05", winsor_high(to_numeric(pers["number_workers"]), 0.05)),
        dist_row("3_hh_number_workers", hh["number_workers"]),
        dist_row("4_hh_number_workers_w", hh["number_workers_w"]),
        dist_row("5_reg_raw", reg["number_workers"]),
        dist_row("6_reg_number_workers_w", reg["number_workers_w"]),
        dist_row("7_reg_number_workers_a", reg["number_workers_a"]),
        dist_row("8_reg_pre_number_workers_a", reg.loc[pre, "number_workers_a"]),
    ]
    dist = pd.DataFrame(rows)
    dist.to_csv(OUT / "table6_number_workers_distributions.csv", index=False)

    contrib = pd.DataFrame(
        {
            "nw_raw": reg.loc[pre, "number_workers"].astype(float).to_numpy(),
            "nw_a": reg.loc[pre, "number_workers_a"].astype(float).to_numpy(),
            "kernel": reg.loc[pre, "kernel_triw14"].astype(float).to_numpy(),
            "xxw3": reg.loc[pre, "xxw3"].astype(float).to_numpy(),
        }
    )
    contrib["abs_dev"] = (contrib["nw_a"] - contrib["nw_a"].mean()).abs()
    contrib["w_abs_dev"] = contrib["kernel"] * contrib["abs_dev"]
    contrib.sort_values("w_abs_dev", ascending=False).to_csv(
        OUT / "table6_firm_size_contributions.csv", index=False
    )

    # Cap sensitivity
    cap_rows = []
    for cap in [50, 60, 70, None]:
        r = reg.reset_index(drop=True).copy()
        if cap is None:
            r["number_workers_a"] = r["number_workers"].astype(float)
            label = "raw"
        else:
            r["number_workers_a"] = r["number_workers"].astype(float).clip(upper=cap)
            label = f"clip_{cap}"
        res = wls_cluster(didisc_formula("number_workers_a"), r, weight="kernel_triw14")
        cap_rows.append(
            {
                "spec": label,
                "xxw3": float(res.params["xxw3"]),
                "xxw3_se": float(res.bse["xxw3"]),
                "n": int(res.nobs),
                "mean_pre": float(r.loc[r["pre"].eq(1), "number_workers_a"].mean()),
            }
        )
    caps = pd.DataFrame(cap_rows)
    caps.to_csv(OUT / "table6_firmsize_cap_sensitivity.csv", index=False)
    return dist


def audit_cl_multiseed(cl: pd.DataFrame) -> pd.DataFrame:
    def reweight(df: pd.DataFrame, seed, full_sample: bool) -> pd.DataFrame:
        out = df.copy()
        out["post"] = to_numeric(out["year"]).eq(2016).astype(float)
        age_m = to_numeric(out["age_survey_m"])
        eligible = age_m.ge(AGE_LO) & age_m.le(AGE_HI) & age_m.notna()
        if full_sample:
            out["sample"] = eligible.astype(float)
        else:
            rng = np.random.RandomState(int(seed))
            s = pd.Series(np.nan, index=out.index, dtype=float)
            for post_val in (0.0, 1.0):
                m = eligible & out["post"].eq(post_val)
                s.loc[m] = (rng.random(int(m.sum())) <= SUBSAMPLE_FRAC).astype(float)
            out["sample"] = s
        covars = [
            "h_area",
            "c_gender",
            "hhsize",
            "h_age_head",
            "h_edu_head",
            "h_male_head",
            "indig_head",
        ]
        for c in covars:
            out[c] = to_numeric(out[c]).astype(float)
        out["indig_head"] = out["indig_head"].fillna(0.0)
        train = out["sample"].eq(1)
        X = sm.add_constant(out.loc[train, covars], has_constant="add")
        y = out.loc[train, "post"].astype(float)
        ok = X.notna().all(axis=1) & y.notna()
        model = sm.Probit(y.loc[ok].to_numpy(), X.loc[ok].to_numpy()).fit(disp=0)
        X_all = sm.add_constant(out[covars], has_constant="add")
        pred_ok = X_all.notna().all(axis=1)
        prob = pd.Series(np.nan, index=out.index, dtype=float)
        prob.loc[pred_ok] = model.predict(X_all.loc[pred_ok].to_numpy())
        prob = prob.clip(1e-6, 1 - 1e-6)
        out["probpost"] = prob
        out["weights"] = np.where(out["post"].eq(0), 1 / (1 - prob), 1 / prob)
        r = to_numeric(out["running"])
        ry = to_numeric(out["runningy"])
        bw = 12.0
        k = ((bw - r.abs()) / bw) * (r.abs() <= bw).astype(float)
        ky = ((bw - ry.abs()) / bw) * (ry.abs() <= bw).astype(float)
        out["kernel_tri"] = np.where(out["post"].eq(0), k / (1 - prob), k / prob)
        out["kernel_triy"] = np.where(out["post"].eq(0), ky / (1 - prob), ky / prob)
        return out

    seeds: list[int | None] = [None, STATA_SEED, 1, 2, 7, 42, 99, 123, 999, 12345]
    rows = []
    for seed in seeds:
        d = reweight(cl, seed=seed, full_sample=(seed is None))
        t = run_table5_cl(d)
        for _, row in t.iterrows():
            rows.append({"seed": "full" if seed is None else int(seed), **row.to_dict()})
    res = pd.DataFrame(rows)
    res.to_csv(OUT / "cl_ipw_multiseed_robustness.csv", index=False)
    return res


def main() -> None:
    hh = pd.read_parquet(paths.FINAL / "HHsurvey.parquet")
    print("=== Table 5 wage sample ledger ===")
    print(audit_table5_wage(hh).to_string(index=False))
    print("\n=== Table 6 number_workers distributions ===")
    print(audit_table6_firmsize(hh).to_string(index=False))
    print("\n=== CL IPW multi-seed ===")
    cl = load_cl()
    res = audit_cl_multiseed(cl)
    for outcome, sample in [("risks_a", "all"), ("injury_a", "all"), ("risks_a", "working")]:
        k = res.loc[res.outcome.eq(outcome) & res["sample"].eq(sample)]
        print(f"{outcome}/{sample}: xx∈[{k.xx.min():.4f},{k.xx.max():.4f}] n∈[{k.n.min()},{k.n.max()}]")
    print(f"\nWrote audits → {OUT}")
    print("See docs/discrepancy_appendix.md")


if __name__ == "__main__":
    main()
