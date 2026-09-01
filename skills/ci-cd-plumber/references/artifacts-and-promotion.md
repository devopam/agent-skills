# Artifacts & Promotion

How build outputs are stored, named, and moved across environments without
being rebuilt or silently swapped.

## Table of Contents

- [Build once, promote always](#build-once-promote-always)
- [Artifact types](#artifact-types)
- [Naming and retention](#naming-and-retention)
- [Promotion paths](#promotion-paths)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Build once, promote always

The artifact that passed main/trunk verification should be the **same
bytes** deployed to staging and production (or published to the package
registry). Rebuilding per environment invites "works in staging" drift.

Exceptions (rare — document in baseline):

- Environment-specific binary features that cannot be feature-flagged
  (prefer flags/config).
- Genuine multi-arch rebuilds from the same commit with documented matrix.

---

## Artifact types

- Container images (digest-addressed preferred)
- Language packages (wheel, crate, npm package, jar)
- Tarballs / binaries
- Static site bundles
- SBOMs and attestation files alongside the primary artifact

Prefer content-addressed references (digest, hash) over mutable tags alone.
Tags like `staging` / `prod` may point at digests but should not be the only
identity.

---

## Naming and retention

- Include version / git SHA in artifact metadata.
- Retention: long enough for rollback and audit; not infinite without
  policy.
- CI intermediate artifacts (test reports) differ from release artifacts —
  do not confuse retention of both.

---

## Promotion paths

Typical:

```text
PR checks → merge → main builds artifact → (optional staging deploy)
  → release tag / approval → production promote
```

Promotion should record who/what authorized it (protected environment,
approval rule, or automated policy).

---

## Concrete checks

1. Is the prod deploy job consuming an existing artifact reference?
2. Are image tags mutable without digests recorded?
3. Can you map a production version back to a git SHA quickly?
4. Are release assets attached to the GitHub/GitLab Release?
5. Retention policy exists for the artifact store?

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| `docker build` again in the prod job | Non-identical bits |
| Only `:latest` tags | Ambiguous rollback |
| Artifact overwrote in place without version history | Cannot recover |
| Publishing from a developer laptop | Untrusted builder identity |

---

## Sources

- CD literature on immutable artifacts and environment promotion.
- Registry best practices (digest pinning, tag immutability options).

Synthesized 2026-09-01.
