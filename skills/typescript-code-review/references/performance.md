# Performance (TypeScript)

## Checks
1. Unnecessary O(n²) patterns on hot paths; large sync work on request path.
2. Bundle-oriented: accidental Node-only imports in browser entry (if full-stack).
3. Excessive object allocation in tight loops; missing pagination on large collections.
4. JSON parse of unbounded input.

## Important
- Sync CPU-heavy work blocking the event loop (server).
- Importing entire utility libraries when a few functions suffice (bundle size).
