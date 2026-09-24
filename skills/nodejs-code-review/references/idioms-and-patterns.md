# Idioms & Patterns (Node.js)

## Checks
1. Middleware ordering (auth before business).
2. Prefer structured errors over thrown strings.
3. 12-factor config; no ambient global singletons without need.
4. Graceful patterns for HTTP servers (`server.close`).

## Important
- Mixing callback and promise styles without clarity.
