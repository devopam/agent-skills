# Progressive Delivery

Pipeline-level support for releasing change gradually — canary, blue/green,
and decoupling **deploy** from **release** (feature flags).

This skill stays at the **pipeline and promotion** layer. Designing an
in-app feature-flag taxonomy or service-mesh traffic weights in depth is out
of scope; wiring CI/CD so those mechanisms *can* be used safely is in scope.

## Table of Contents

- [When it matters](#when-it-matters)
- [Patterns](#patterns)
- [Pipeline implications](#pipeline-implications)
- [Maturity expectations](#maturity-expectations)
- [Concrete checks](#concrete-checks)
- [Anti-patterns](#anti-patterns)
- [Sources](#sources)

---

## When it matters

- User-facing services with real production traffic.
- Changes that are hard to roll back quickly (migrations, irreversible
  side effects — those need extra care beyond traffic shifting).
- Teams pursuing higher deployment frequency without raising change-failure
  impact.

Prototype internal tools may honestly record "none" here.

---

## Patterns

| Pattern | Pipeline role |
|---|---|
| **Feature flags** | Deploy dark; release by flag. Pipeline may deploy continuously while flags stay off. |
| **Canary** | Promote artifact to a subset of instances/traffic; automate or gate full rollout on signals. |
| **Blue/green** | Deploy to idle environment; switch traffic; keep prior environment for rollback. |
| **Rolling** | Gradual instance replacement; simplest progressive form. |

---

## Pipeline implications

- Prod job should accept parameters: target environment, canary percent,
  or approval tokens — not only "deploy everything."
- Health/signal gates between canary and full rollout (even if signals are
  produced by another system).
- Rollback path documented and preferably automated.
- Database migrations ordered safely relative to app deploy (expand/
  contract); flag if the pipeline assumes instantaneous compatible
  migrations without evidence.

---

## Maturity expectations

| Posture | Progressive delivery expectation |
|---|---|
| Prototype | Optional |
| Standard service | Rollback story required; canary or flags recommended for risky paths |
| High-assurance | Documented progressive strategy + measurable gates |

---

## Concrete checks

1. Does any prod deploy automatically touch 100% of traffic with no staged
   step when risk warrants staging?
2. Is rollback a runbook myth or an automated job?
3. Are flags/config deployable independently of the binary when claimed?
4. Baseline records the chosen strategy honestly.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| Big-bang Friday prod deploys as the only mode | Concentrated risk |
| Canary without metrics gate | Theatre |
| Feature flags never cleaned up | Complexity debt (note; full flag lifecycle is app concern) |

---

## Sources

- Progressive delivery / DORA-aligned release management practices.
- Vendor deploy strategy docs (ECS/K8s rolling, canary, blue-green).

Synthesized 2026-09-01.
