# Testing & Quality Gates

Which automated checks run in which pipeline layer, and which of them are
allowed to block merge or release.

This domain does **not** teach unit-testing strategy or framework choice —
that belongs to language-specific skills (e.g. `python-code-review`).
Here the question is only: **is the pipeline wiring the right gates at the
right stage with the right severity?**

## Table of Contents

- [Gate inventory](#gate-inventory)
- [Placement by layer](#placement-by-layer)
- [Blocking vs advisory](#blocking-vs-advisory)
- [Flaky tests](#flaky-tests)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Gate inventory

Typical gate classes in CI:

- Format / lint / typecheck
- Unit tests
- Integration / contract tests
- Security scanners (SAST, secret scan, dependency scan)
- License / policy checks
- Build of the release artifact
- Smoke / post-deploy checks (CD side)

Not every class is required for every maturity level; the baseline should
list what the project committed to.

---

## Placement by layer

| Gate | PR | Main | Release |
|---|---|---|---|
| Format/lint/typecheck | Yes (block) | Optional re-run | — |
| Unit tests | Yes (block) | Yes | — |
| Integration tests | If fast/stable enough | Yes | — |
| Secret scan | Yes (block on high confidence) | Yes | — |
| SAST / dependency scan | Lightweight or differential | Full | Policy-dependent |
| SBOM generation | Rarely | Often | On publish |
| Publish / deploy | No | No (or staging only) | Yes |

---

## Blocking vs advisory

- **Blocking:** failures prevent merge or prevent promoting a release.
- **Advisory:** visible in the UI / report but do not fail the job
  (use while rolling out a new scanner).

Rolling a new tool out as advisory first is fine; leaving it advisory
forever without a plan is a finding at standard+ maturity.

Required GitHub/GitLab status checks should match the blocking set — audit
for drift ("CI job exists but is not required").

---

## Flaky tests

- Quarantine or fix flaky tests; do not paper over them with infinite
  retries.
- Limited infra retries (runner lost) are acceptable; retrying assertion
  failures is not a strategy.
- Track flaky rate if it is consuming engineer time.

---

## Concrete checks

1. PR pipeline runs unit tests and basic static checks.
2. Main does not skip the suite that PR ran without reason.
3. Secret scanning is present for product repos.
4. Blocking set matches branch protection / required checks.
5. No deploy-to-prod job on PR events.
6. New scanners documented as advisory vs blocking in baseline.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| "CI green" but required checks unchecked in branch protection | Social green, technical bypass |
| Only manual testing before prod | Unscalable; regresses under load |
| Entire suite skipped on main to save time | Broken trunk risk |
| Flaky suite with auto-retry ×5 | Hides real races; burns minutes |

---

## Sources

- Continuous integration classic practices (fast feedback, test on
  integrate).
- Vendor docs on required status checks / protected branches.
- Layered quality-gate sequencing (fail fast, fail cheap).

Synthesized 2026-09-01.
