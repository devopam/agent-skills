# Performance (React)

## Checks
1. Unnecessary re-renders; memoization only where measured need.
2. Code-splitting / lazy routes for large apps.
3. Image sizing and modern formats; avoid layout thrash.
4. Virtualization for long lists.
5. Client bundle size awareness (tree-shaking, import paths).

## Important
- Fetching in deeply nested components causing request waterfalls (prefer lifted data or RSC patterns when on Next).
- Huge uncontrolled controlled-inputs lag.
