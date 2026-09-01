# Speed & Efficiency

How long feedback takes, and whether the pipeline wastes compute on work
that cannot change the decision to merge or release.

Structure (what layers exist) lives in
[pipeline-structure](pipeline-structure.md). This file owns **caching,
parallelism, path filters, and timeouts** inside those layers.

## Table of Contents

- [Goals](#goals)
- [Path filters and change detection](#path-filters-and-change-detection)
- [Caching](#caching)
- [Parallelism and matrices](#parallelism-and-matrices)
- [Timeouts and interruptible jobs](#timeouts-and-interruptible-jobs)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Goals

- PR critical path stays within the budget recorded in the baseline.
- Caches speed installs without creating cross-trust poisoning paths.
- Expensive jobs run only when their inputs changed.
- Stuck jobs die cleanly instead of burning the runner quota.

---

## Path filters and change detection

Especially important for monorepos:

- Run package-A tests only when `packages/A/**` (or shared libs) change.
- Still run a small always-on critical path (e.g. secret scan, basic lint)
  so structural safety is not path-filtered away.
- Document shared library paths that must invalidate downstream packages.

GitHub: `paths` / `paths-ignore` on workflows, or change-detection actions.
GitLab: `rules:changes`.

---

## Caching

Good caching:

- Key includes lockfile hash (and runtime version when relevant).
- Scope is pull-only on untrusted events if the platform supports it.
- Separate caches per package or per high-level toolchain when collision
  risk or size warrants it.
- Periodic pruning / expiry so caches do not grow forever.

Security note: a writeable cache shared from low-trust jobs into high-trust
release jobs is a poisoning vector — coordinate with
[security-and-permissions](security-and-permissions.md).

---

## Parallelism and matrices

- Shard tests when wall-clock time is dominated by a serial suite.
- Matrix OS/runtime only when the project genuinely supports them; idle
  matrix cells are pure cost.
- Fan-out then fan-in: parallel jobs should gate a single green/red decision
  for the layer.

---

## Timeouts and interruptible jobs

- Set explicit job/workflow timeouts (platform defaults can be very long).
- Mark PR jobs interruptible where supported so newer pushes cancel stale
  runs.
- Retries: limited, and only for known flaky infrastructure classes — not
  as a substitute for fixing flaky tests (see testing domain).

---

## Concrete checks

1. Measured or estimated PR duration vs baseline budget.
2. Presence of path filters in multi-package repos.
3. Cache keys include lockfile (not only branch name).
4. Job timeouts set.
5. Redundant full monorepo builds on docs-only PRs.
6. Matrices that multiply jobs without product need.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Single cache key `build-cache` for all branches and trust levels | Poisoning + incorrect hits |
| No timeout on integration suites | Runner hostage events |
| Running the full release pipeline on every PR | Slow feedback; secret exposure risk |
| Disabling CI because "it's too slow" | Loses the safety net entirely |

---

## Sources

- GitHub Actions and GitLab CI caching documentation (keys, policies,
  protected branch cache separation).
- DORA-oriented guidance: fast feedback loops as a prerequisite for high
  deployment frequency.

Synthesized 2026-09-01.
