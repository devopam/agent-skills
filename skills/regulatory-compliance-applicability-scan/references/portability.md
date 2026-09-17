# Portability (IDE install)

This skill must work when copied or installed as:

```text
<skill-root>/
  SKILL.md
  assets/
  references/
    packs/
    sources-index.md
    coverage.md
    portability.md
```

## Rules

1. **SKILL.md** only links to paths under `<skill-root>`.
2. **Do not** require `../../../compliance-sources/` or `../../../research/`.
3. Packs are self-contained markdown under `references/packs/`.
4. Monthly source-hash refresh is a **monorepo** workflow, not a runtime dependency of the installed skill.

Same pattern as sibling skills (`ci-cd-plumber`, `postgresql-review`, …).
