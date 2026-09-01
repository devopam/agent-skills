# Pipeline Observability & Reliability

Whether humans notice pipeline failure quickly, whether the pipeline itself
is operable, and whether basic delivery metrics *can* be derived.

Application APM is out of scope. This is about the **delivery system**.

## Table of Contents

- [Notifications](#notifications)
- [Retries and failure handling](#retries-and-failure-handling)
- [Logs and audit trail](#logs-and-audit-trail)
- [DORA-oriented signals](#dora-oriented-signals)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## Notifications

- Failures on main/release should notify a channel people actually watch.
- PR failures should surface on the PR (platform default) without spammy
  duplicate bots unless useful.
- Avoid paging on flaky PR jobs; do page (or equivalent urgency) on broken
  trunk or failed prod promote.

---

## Retries and failure handling

- Limited automatic retries for runner/infrastructure faults.
- Clear distinction between failed check and cancelled/superseded runs.
- Stuck jobs terminated by timeout (see speed domain).

---

## Logs and audit trail

- CI logs retained long enough to debug a bad release.
- Who triggered a production deploy is reconstructable (actor, workflow,
  SHA).
- Release approvals leave a record when used.

---

## DORA-oriented signals

The pipeline need not implement a full metrics stack, but high-maturity
teams should be able to answer:

- How often do we deploy to production? (deployment frequency)
- How long from commit to production? (lead time)
- How often do deploys cause incidents? (change failure rate)
- How fast do we recover? (MTTR — often outside CI, but deploy events help)

Emit or log deployment events on successful prod promotes when possible.

---

## Concrete checks

1. Broken main is visible without manually opening the Actions tab daily.
2. Prod deploys attributable to SHA + actor.
3. Timeouts present.
4. No silent `continue-on-error` on critical release steps.
5. Optional: deployment events or release records for metrics.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| `continue-on-error: true` on deploy | False green |
| Notifications only to an abandoned channel | Slow response |
| No retention on CI logs | Cannot investigate |

---

## Sources

- DORA metrics definitions and instrumentation notes.
- Platform docs on environments, approvals, and deployment logging.

Synthesized 2026-09-01.
