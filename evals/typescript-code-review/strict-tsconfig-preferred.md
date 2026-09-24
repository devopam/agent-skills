# Eval: strict tsconfig preferred

## Setup
TypeScript web app with `"strict": false` and widespread `any`, tier=web.

## Expected
- Standards or quality domain scores reduced
- Finding cites lack of strict / any usage
- No certification language

## Fail if
- Ignores tsconfig entirely
