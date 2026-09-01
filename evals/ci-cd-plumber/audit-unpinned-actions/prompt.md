You are applying the ci-cd-plumber skill. The repo has
`.github/workflows/ci.yml` that uses `actions/checkout@v4` and
`actions/setup-python@v5` (tag pins, not SHAs), workflow-level
`permissions: write-all`, and a `docs/ci-cd-baseline.md` that claims
"full SHA digests" and "contents: read at workflow level". User asks:
"Audit our CI/CD."

Produce findings with severity, referencing the baseline drift and the
security / supply-chain domains.
