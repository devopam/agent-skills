# Standards Compliance (TypeScript)

## Tier applicability
- **script**: `tsconfig` present; can compile
- **web**: `strict` (or documented exceptions), ESLint/Biome, consistent module settings
- **enterprise**: enforced CI typecheck + lint; `skipLibCheck` justified; no accidental `any` policy

## Checks
1. **tsconfig**: `strict` true preferred; `noImplicitAny`, `strictNullChecks`, `noUncheckedIndexedAccess` (enterprise+); sensible `module`/`moduleResolution` (`bundler` or `NodeNext` as appropriate).
2. **Tooling**: ESLint flat config or Biome; Prettier or Biome format; scripts for `typecheck` / `lint` in package.json.
3. **Package metadata**: `types`/`exports` correct for libraries; `sideEffects` when relevant.
4. **Generated code**: `.d.ts` and build output excluded from hand-review; source of truth is `.ts`.

## Critical
- Shipping library with `strict: false` and no documented rationale (enterprise).
- `allowJs` + large untyped JS without migration plan when claiming TypeScript.

## Important
- `any` / `as any` widespread without eslint restriction.
- Missing CI `tsc --noEmit`.
