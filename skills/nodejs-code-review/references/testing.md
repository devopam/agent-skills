# Testing (Node.js)

## Checks
1. Unit + HTTP integration tests (supertest/inject).
2. Testcontainers or equivalent for DB at enterprise when practical.
3. CI runs tests on LTS Node.
4. Contract tests for public APIs optional but valued.

## Critical
- No tests for a non-trivial API surface (web/enterprise).
