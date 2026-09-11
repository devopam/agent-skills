# Evals: ui-system-review

Hand-authored cases for the `ui-system-review` skill (`prompt.md` +
`graders/criteria.md`). Not machine-scored until `claude plugin eval`
enrollment allows (see repo `evals/README.md`).

| Case | Intent |
|------|--------|
| `audit-scorecard-report-shape` | Domain table + severity order + remediation section |
| `token-hardcode-hex-drift` | Widespread hex/magic spacing → Tokens domain + evidence |
| `dual-component-libraries` | Two full UI kits for same primitives → Critical/Important |
| `mixed-icon-libraries` | Uncoordinated icon packs → Icons & media |
| `remediation-section-required` | Remediation with What/Why/direction/Evidence |
| `suggest-not-rewrite-ui` | Suggest only; no bulk rewrite unless asked |
| `evidence-required-no-invent` | No findings without file/path evidence |
| `no-ui-surface-stop` | Backend-only tree → stop, no fake UI scores |
| `apple-hardcoded-colors` | SwiftUI Color.* drift + iPad without adaptive nav |
| `android-dual-theme-xml-compose` | XML+Compose dual theme, raw Color, tablet claim |
