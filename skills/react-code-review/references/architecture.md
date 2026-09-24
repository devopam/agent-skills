# Architecture (React)

## Checks
1. Feature-based or clear layered folder structure.
2. API client isolation; no scatter of fetch URLs.
3. Routing structure matches IA.
4. Design-system usage — deep token/component consistency is `ui-system-review`.
5. State library choice (server state vs client state) coherent (React Query/SWR vs Redux etc.).

## Important
- Business rules duplicated across many components with no shared module.
