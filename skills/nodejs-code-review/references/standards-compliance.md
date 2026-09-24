# Standards Compliance (Node.js)

## Checks
1. `engines.node` set to supported LTS range; CI tests that range.
2. `type: module` or consistent CJS; no accidental dual-module breakage.
3. ESLint/Biome + format scripts; TypeScript optional but if present, `tsc` in CI.
4. Environment config via env vars — not committed secrets.

## Critical
- Targeting end-of-life Node without justification (enterprise).
