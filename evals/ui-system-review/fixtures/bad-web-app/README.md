# Fixture: bad-web-app (intentional anti-patterns)

**Not a real application.** Synthetic tree for `ui-system-review` effectiveness
checks. Known injected problems:

1. Dual full UI kits: `@mui/material` + `@chakra-ui/react` + both providers
2. Token file exists but product UI hardcodes hex / magic spacing
3. Three icon libraries with no policy
4. Fixed pixel shell only — no responsive breakpoints
5. Clickable `div` primary action (a11y footgun)

Expected audit outcome: multiple **Important/Critical** findings, non-trivial
remediation section, Tokens / System foundation / Icons / Form factors scored
low.
