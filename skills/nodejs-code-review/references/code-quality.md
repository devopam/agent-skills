# Code Quality (Node.js)

## Checks
1. Router/handler cohesion; fat controllers vs services.
2. Consistent async error propagation to centralized handler.
3. Input validation at the edge (zod/joi/valibot/openapi).
4. Clear separation of config, domain, and infrastructure.

## Important
- Unhandled stream errors; missing `error` listeners on critical streams.
