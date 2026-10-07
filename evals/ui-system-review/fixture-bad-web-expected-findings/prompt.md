---
name: ui-system-review-fixture-bad-web-expected-findings
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Run ui-system-review Web pack against the fixture at
`evals/ui-system-review/fixtures/bad-web-app/`.

The tree intentionally contains: dual MUI+Chakra providers, tokens.css unused
by features, hex/magic spacing in FeatureA/B, three icon packs, fixed 1200px
shell, clickable div for Delete.

Produce a full scored report with remediation.
