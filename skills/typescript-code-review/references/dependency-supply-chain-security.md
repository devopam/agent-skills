# Dependency & Supply Chain Security (TypeScript)

## Checks
1. Lockfile committed (`package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` / `bun.lockb`).
2. CI installs with frozen lockfile.
3. Dependency audit tooling (npm audit, pnpm audit, snyk/socket — any consistent process).
4. Pin or range policy for production deps; avoid floating `*`.
5. `postinstall` scripts reviewed for untrusted packages.

## Critical
- Known critical CVEs in direct dependencies with no mitigation (enterprise).
- Installing dependencies in CI without lockfile.

## Important
- Unmaintained critical path deps.
- Excessive dependency tree for a small library surface.
