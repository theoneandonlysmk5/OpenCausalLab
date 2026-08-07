# Security policy

OpenCausalLab is research software for verifying empirical economics designs.
The primary security concerns are **data governance** and **accidental disclosure**,
not typical web-application vulnerabilities.

## Please report privately

Use GitHub’s private vulnerability reporting (Security → Advise a vulnerability)
or email the repository owner listed in [`CITATION.cff`](CITATION.cff) for:

- Accidental commit or upload of survey microdata (`.dta`, `.parquet`, extracts)
- Exposed credentials, API tokens, or **signed download URLs** (including Actions secrets pasted into issues/PRs)
- Row-level validation dumps with household/person IDs committed to git or released in ZIPs
- Logs, CI artifacts, or screenshots that reveal microdata cells
- Uncertainty about whether Dataverse / survey terms allow temporary processing on GitHub-hosted runners

Do **not** open a public issue that pastes secrets, signed URLs, or row-level data.

## What maintainers will do

1. Remove or rotate exposed credentials / URLs immediately.
2. Scrub sensitive files from the default branch; if they entered history, plan a `git filter-repo` rewrite and notify collaborators.
3. Document whether a disclosure requires contacting Dataverse depositors.

## Contributor expectations

- Never commit files under `studies/*/data/raw/` or intermediate/final person-level parquet.
- Prefer `git archive` for release ZIPs (tracked files only).
- Aggregate validation outputs may be committed; **row-level** audits with IDs must stay local / gitignored.
- Optional CI secret `HHSURVEY_PARQUET_URL` must be short-lived or access-controlled; the workflow must not upload that parquet as an artifact or print the URL.

## Out of scope for “security” tickets

Ordinary replication discrepancies (Near/Open table cells) belong in a
**Replication discrepancy** issue, not a security report—unless the discrepancy
artifact itself would disclose microdata.
