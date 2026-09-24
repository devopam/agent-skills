# Architecture (TypeScript)

## Checks
1. Clear boundaries: domain vs infrastructure vs UI (as applicable).
2. Public API surface of packages documented and minimal.
3. Circular dependencies between modules/packages.
4. Config and feature flags centralized.
5. Monorepo: workspace boundaries respected (packages don't reach into app internals).

## Important
- Business logic embedded only in transport adapters (HTTP handlers) with no domain layer when complexity warrants it (web/enterprise).
