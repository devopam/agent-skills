# Eval: lockfile required for web tier

## Setup
package.json present, no package-lock/pnpm-lock/yarn.lock, tier=web.

## Expected
- Dependency/supply-chain domain flags missing lockfile
- Suggests committing lockfile and frozen CI install

## Fail if
- Treats missing lockfile as fine for web/enterprise
