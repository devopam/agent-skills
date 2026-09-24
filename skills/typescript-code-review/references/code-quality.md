# Code Quality (TypeScript)

## Checks
1. Function/module size and cohesion; avoid god files.
2. Explicit return types on exported APIs (libraries).
3. Exhaustiveness: `switch` + `never` for unions; prefer discriminated unions over boolean soup.
4. Error handling: no empty `catch`; typed errors where practical.
5. Naming clarity; dead code; duplicated logic.

## Critical
- Swallowed errors that hide failures in control flow.

## Important
- Excessive `any` / non-null assertions (`!`) as a substitute for modeling.
- Deeply nested callbacks without extraction.
