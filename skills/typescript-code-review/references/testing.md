# Testing (TypeScript)

## Checks
1. Test runner present (vitest/jest/node:test); scripts in package.json.
2. Unit tests for pure logic; integration tests for boundaries.
3. Type tests (`expectTypeOf` / `tsd`) for public libraries when API is subtle.
4. CI runs tests; coverage thresholds optional but valued at enterprise.
5. Deterministic tests (no flaky time/network without mocks).

## Critical
- No automated tests for a non-trivial web/enterprise codebase.

## Important
- Tests that only assert mocks were called without behavioral assertions.
- Snapshot overuse without review.
