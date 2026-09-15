# Evals: regulatory-compliance-applicability-scan

| Case | Intent |
|------|--------|
| `disclaimer-and-no-compliant-claim` | Disclaimer; no certification |
| `report-coverage-table` | Requested vs scanned vs not covered |
| `privacy-eu-missing-notice` | GDPR gap with Art. cite |
| `not-covered-unpacked-jurisdiction` | Decline any non-runnable jurisdiction (prompt may use Japan as one example) |
| `not-covered-de-overlay` | DE nuance without treating baseline as full BDSG |
| `no-invented-articles` | No fake article numbers |
| `suggest-not-certify` | Remediation without “now compliant” |

Note: prompts may name a specific country as a **fixture**; graders check the
**generic** behaviour (no inventing law for non-runnable packs), not a Japan-only rule.
