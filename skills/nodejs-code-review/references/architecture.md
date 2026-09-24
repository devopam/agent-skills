# Architecture (Node.js)

## Checks
1. Clear module boundaries; layered or modular monolith as appropriate.
2. API versioning strategy when public.
3. Background jobs separated from web process when needed.
4. Health/readiness endpoints distinct from liveness (enterprise/k8s).

## Important
- Business rules only inside framework route files at scale (web+).
