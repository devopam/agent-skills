# Evals: postgresql-review

Hand-authored cases (prompt.md + graders/criteria.md). Not machine-scored
until `claude plugin eval` enrollment allows (see repo `evals/README.md`).

| Case | Intent |
|------|--------|
| `readiness-fail-no-mcpg` | Block full review; guide install; no fake scorecard |
| `readiness-wrong-schema` | Invalid schema name → list + re-prompt |
| `audit-scorecard-shape` | Seven-domain scores + severity order |
| `suggest-not-apply-ddl` | Suggest INDEX; do not apply DDL |
