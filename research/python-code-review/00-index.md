# Research Index: python-code-review

Status tracker for the portable `python-code-review` skill's 11 domain
baselines (see `research/python-code-review-domain-scoping.md` for how this
list was arrived at). Same conventions as `project-incubation`'s research:
each baseline lives here until reviewed and approved, then gets promoted
into `skills/python-code-review/references/<domain>.md`. Baselines stay in
the repo afterward as a provenance record (see `CONTRIBUTING.md`'s
retention policy).

This skill is a **portable rebuild** of an existing Claude-Code-native tool
(`python-code-review-skill-v1.1.tgz`) — the original's content is a real,
substantial starting point, not being re-derived from zero, but every
volatile claim (library/tooling landscape, security thresholds,
version-specific syntax) gets verified by direct fetch and dated, matching
`project-incubation`'s authoring discipline. See
`research/python-code-review-domain-scoping.md` for the gap analysis that
expanded the original's 9 domains to 11.

| Domain | Research file | Status | Checkpoint |
|---|---|---|---|
| Security | `research/python-code-review/security.md` | user-approved | A |
| Dependency & Supply Chain Security | `research/python-code-review/dependency-supply-chain-security.md` | user-approved | A |
| Testing | `research/python-code-review/testing.md` | user-approved | A |
| Code Quality | `research/python-code-review/code-quality.md` | not started | B |
| Concurrency & Async Correctness | `research/python-code-review/concurrency-async-correctness.md` | not started | B |
| Performance | `research/python-code-review/performance.md` | not started | B |
| Standards Compliance | `research/python-code-review/standards-compliance.md` | not started | C |
| Idioms & Patterns | `research/python-code-review/idioms-and-patterns.md` | not started | C |
| Architecture | `research/python-code-review/architecture.md` | not started | C |
| Observability | `research/python-code-review/observability.md` | not started | D |
| Scalability & Resilience | `research/python-code-review/scalability-and-resilience.md` | not started | D |

**Status values:** `not started` → `draft` (researched, awaiting review) →
`user-approved` (ready for authoring) → `promoted` (authored into
`references/`; the research file itself is kept, not deleted).
