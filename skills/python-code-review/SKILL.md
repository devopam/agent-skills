---
name: python-code-review
description: Reviews Python code across 11 domains — standards compliance, code quality, security, dependency/supply-chain security, performance, concurrency & async correctness, idioms & patterns, architecture, observability, scalability & resilience, and testing — producing a scored report. Use when reviewing Python code for quality, security, or production-readiness, before a commit or PR, or for a periodic project health check.
---

# Python Code Review

Reviews a Python project (or just its changed files) across 11 domains and
produces a scored report with concrete, file-and-line findings. Portable:
reads code and reference files sequentially, one domain at a time — no
parallel subagent dispatch, no host-specific slash command, no assumption
that a particular rendering library is available. Any agentskills.io-
compliant client can run this.

## Determining scope and configuration

Look for `python-review-config.toml` in the project root. If present, read
it. If absent, use the defaults in
[`assets/review-config-template.toml`](assets/review-config-template.toml)
directly — don't require the user to copy the file first, just apply its
values.

Ask the user (in plain text, one question at a time — don't assume an
interactive tool exists) whatever the config and the request don't already
answer:

1. **Scope**: full project (scan all `.py` files) or diff (changed files
   only, via `git diff` against a base branch — default `main` unless the
   config or the user says otherwise)? A request phrased as "review my
   changes" or "review this PR" implies diff mode; "review this project"
   implies full.
2. **Tier**: `script` (a small/throwaway project — lighter check set),
   `web` (a typical service — the default), or `enterprise` (production
   infrastructure — the full check set, including checks that need real
   operational maturity to be worth flagging). Each domain's reference file
   states which checks apply at which tier.

## Reviewing each domain, in order

Work through the 11 domains sequentially — read the domain's reference
file, review the in-scope files against it, record a score (1–10) and a
findings list, then move to the next domain. Do not skip a domain's
reference file and review from memory; the specifics (exact thresholds,
exact library names, exact rule codes) live there, not in this router.

1. [Standards Compliance](references/standards-compliance.md) — project
   structure, `pyproject.toml`/tooling config, capability detection,
   CI/CD well-formedness, packaging & distribution (if publishable).
2. [Code Quality](references/code-quality.md) — types (including
   graduated mypy/pyright strictness), complexity, naming, docs, dead code.
3. [Security](references/security.md) — OWASP-driven: injection, secrets,
   crypto, auth, LLM-specific risks, configuration & secrets management.
4. [Dependency & Supply Chain Security](references/dependency-supply-chain-security.md) —
   SBOM, vulnerability scanning, lockfile discipline, CI/CD pipeline
   security, artifact integrity.
5. [Performance](references/performance.md) — N+1 queries, connection
   pooling, caching, GIL-as-throughput-bottleneck, profiling evidence.
6. [Concurrency & Async Correctness](references/concurrency-async-correctness.md) —
   asyncio pitfalls, structured concurrency, race conditions/deadlocks,
   free-threading thread-safety.
7. [Idioms & Patterns](references/idioms-and-patterns.md) — Pythonic
   code, modern syntax, immutability, dataclass-vs-Pydantic discipline.
8. [Architecture](references/architecture.md) — separation of concerns,
   DB access patterns, API/interface design & backward compatibility,
   deployment.
9. [Observability](references/observability.md) — structured logging, PII
   redaction, tracing/metrics instrumentation.
10. [Scalability & Resilience](references/scalability-and-resilience.md) —
    statelessness, circuit breakers, graceful degradation. **Distinctive:**
    this domain also reports the *absence* of a resilience pattern as a
    finding, not just what's actively broken — see its own doc for the
    scoring implication.
11. [Testing](references/testing.md) — fixture design, mocking
    correctness, test isolation, assertion quality, flaky-test patterns.

Each domain's reference file ends with its own Scoring Guide (how to map
findings to a 1–10 score) and a Required Evidence section (what every
finding must include — severity, file, line, why it matters, a concrete
fix). Follow those per-domain, don't invent a different format per run.

## Severity

| Level | Meaning |
|---|---|
| Critical | Security holes, data loss, broken functionality |
| Important | Standards gaps, anti-patterns, correctness/performance issues |
| Minor | Style, alternative idioms, nice-to-haves |
| Not Implemented *(Scalability & Resilience only)* | A resilience pattern is absent where the tier calls for it — flagged even if nothing is actively broken |

## Aggregating the scorecard

Per domain: **Pass** if score ≥ `pass_score` (default 7, overridable per
domain in config); **Needs attention** if between `floor_score` (default 5)
and `pass_score`; **Fail** if below `floor_score` OR the domain has any
Critical finding.

Overall: **PASS** if every domain passes. **CONDITIONAL PASS** if no domain
has a Critical finding but at least one needs attention. **FAIL** if any
domain has a Critical finding or scores below its floor.

This verdict is informational, not a host-enforced gate — this skill
doesn't assume a CI/pre-commit wrapper exists. If you're wiring the result
into your own automation, treat FAIL as blocking and PASS/CONDITIONAL PASS
as non-blocking; that mapping is your call to make, not this skill's to
enforce.

## Output

Always produce both:

1. **A rendered summary in the conversation** — the scorecard table,
   findings grouped by severity then domain, and the overall verdict. Plain
   text/markdown; don't assume a specific rendering library (the original
   Claude-Code-native version of this skill used Rich — this portable
   rebuild doesn't require it).
2. **A markdown report file**, populated from
   [`assets/report-template.md`](assets/report-template.md), written to
   `{report_dir}/python-review-report.md` (`report_dir` from config,
   default `./reports`).

PDF output is not supported by this portable rebuild (the original
Claude-Code-native version generated one via weasyprint, which needs native
libraries — pango/cairo/gdk-pixbuf — that aren't guaranteed available on an
arbitrary agentskills.io client). If PDF matters to you, render the
markdown report through your own toolchain after this skill finishes.

## Diff mode specifics

`git diff <base>...HEAD --name-only` (or the config's `diff_base`) for the
changed-files list. If `include_dependencies` is true (default), also
include files that import or are imported by a changed file, one hop —
catches a signature change's call sites without requiring a full-project
scan.
