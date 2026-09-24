# Idioms & Patterns (TypeScript)

## Checks
1. Prefer `unknown` over `any` at boundaries; narrow with type guards.
2. Readonly / `as const` where mutation is not intended.
3. Branded types or zod/io-ts/valibot for runtime validation at trust boundaries.
4. Avoid enums when union of string literals suffices (team style may vary — be consistent).
5. ESM vs CJS: consistent `type: module` / extensions / import style.

## Important
- Type-only correctness that is unsound at runtime (lying types without validation).
- Overuse of inheritance where composition fits better.
