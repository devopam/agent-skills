# Design: data-pipeline-design skill
Status: draft      Date: 2026-10-19

## Purpose

A portable skill that helps an agent **design** a new batch data pipeline (or a
new source in an existing one) and **audit** an existing pipeline against a set
of operating practices. The practices come from running large, restartable
ingestion on constrained hardware: bounded units of work, fail fast and resume,
parallelism sized to the machine, analysis before modelling, and an audit trail
that a regulated environment can trust.

The skill is stack-agnostic. `SKILL.md` states every rule in neutral terms.
`references/` adds generic examples in Python and SQL (PostgreSQL dialect)
where an example makes a rule concrete. No reference names a real project,
dataset, vendor feed or table.

## Scope

In scope: batch and micro-batch ingestion — file and API sources, raw / staging
/ curated layers, loads into a relational database or a lakehouse, the
downloads that feed them, and the run tooling around them.

Out of scope (the skill says so and points elsewhere): streaming semantics
(watermarks, late data, exactly-once delivery, backpressure, consumer lag);
database health and tuning (`postgresql-review`); CI/CD for the pipeline's own
code (`ci-cd-plumber`); BI and semantic layers; ML feature stores.

## Layout

```
skills/data-pipeline-design/
├── SKILL.md                          # router, < 500 lines
├── references/                       # one file per domain + anti-patterns
│   ├── source-analysis-and-sampling.md
│   ├── identity-and-idempotency.md
│   ├── bounded-units-and-resume.md
│   ├── failure-policy.md
│   ├── resource-profile.md
│   ├── contention-and-scheduling.md
│   ├── staging-and-typing.md
│   ├── partitioning.md
│   ├── sample-gate-and-data-quality.md
│   ├── audit-trail-and-lineage.md
│   ├── observability-and-run-status.md
│   ├── licensing-and-provenance.md
│   └── anti-patterns.md
└── assets/
    ├── baseline-template.md          # -> docs/data-pipeline-baseline.md
    ├── design-record-template.md     # one record per source or stage
    └── gate-rules-example.yaml
evals/data-pipeline-design/           # 8 scenarios (see Evals)
```

Repo conventions apply (CONTRIBUTING.md): frontmatter is `name` and
`description` only; the description states what the skill does, then "Use
when ..."; references stay one level deep, with a table of contents when over
~100 lines, and are linked inline where they become relevant; plain-text
interaction, one question at a time, no host-specific tools.

## Mode detection

1. `docs/data-pipeline-baseline.md` exists → **Audit** against it.
2. No baseline, pipeline code present → ask whether the user wants Design (for
   a new source or stage) or Audit (of what exists). Intent decides, not files.
3. No pipeline code → **Design**.

If `docs/project-incubation-baseline.md` exists, read it for language, stack
and compliance signals and do not re-ask them.

## Design mode

Phases, one question at a time; each phase writes its section of the design
record (`assets/design-record-template.md`).

1. **Context.** Target store; expected volume (rows, bytes, per input and in
   total); refresh pattern (one-off, periodic full, incremental); hardware
   class (cores, RAM, disk kinds); regulatory or licence constraints.
2. **Source analysis on a representative sample.** Choose a slice that is
   logically like the full load (covers the time range, the variants and the
   largest records; not "the first N rows"). Record: column types and null
   rates; key uniqueness and sort order; time columns and their ranges; record
   size distribution and outliers; encoding issues; how the data will be
   queried. Rule: no schema or partitioning decision before this section is
   written.
3. **Identity and units of work.** A stable input key per input (independent
   of the absolute path); a part size with both a row cap and a byte cap, so
   one failure costs one part; each part carries its own identity; success
   markers; lineage from row to input. A restart test and a duplicate-input
   (collision) test exist from the first commit.
4. **Staging and curated model.** Staging uses generous types (unbounded
   text, wide numerics, timestamps with zone) and keeps raw values. Types and
   constraints tighten only in curated layers, from the analysis, never from
   sample maxima.
5. **Partitioning.** Partition by a time column first, sub-partition by the
   column(s) most used in filters, and give very large inputs their own
   partition so their maintenance (replace, purge, analyse) does not touch
   others. Each choice cites the phase 2 analysis. Written up for review
   before any DDL: partitioning is hard to change later.
6. **Failure policy and resources.** Processing stages (extract, transform,
   load) fail fast: bounded retries with backoff for transient errors only,
   then stop with a clear message; a re-run resumes at the failed part.
   Downloads are different: record the failed file, continue, retry later.
   The resource profile (workers, memory caps, batch sizes, I/O concurrency,
   database memory settings) is detected from the machine, one memory budget
   covers the pipeline and the database together, and every value has an
   override. One heavy disk or database job at a time on shared storage;
   spill to the fastest local disk.
7. **Gates, audit and provenance.** A sample gate with written rules (row
   counts, null and empty rates, key uniqueness, referential checks,
   distributions) runs on the sample before any full run of a new or changed
   stage; a skip needs a recorded reason. An append-only, tamper-evident audit
   trail records each step, each override and each skip. Each record carries
   its licence; exclusion rules (for example evaluation or benchmark data that
   must not enter a training set) are enforced in code and tested.
8. **Write the records.** The design record per source, and the baseline
   (`assets/baseline-template.md`) if none exists. The skill may suggest file
   scaffolds; it does not generate the pipeline code.

## Audit mode

Score each domain 0–10 against the baseline's maturity target, from evidence in
code, configuration, run logs and docs; ask only when the repo cannot answer.

| # | Domain | Evidence of good practice |
|---|---|---|
| 1 | Source analysis | a written shape analysis of a representative sample per source |
| 2 | Identity and idempotency | stable input key; re-run never duplicates rows; collision test |
| 3 | Bounded units and resume | no unit of work too large to redo cheaply; restart at the failed part |
| 4 | Failure policy | processing fails fast after bounded retries; downloads record and skip; no silent continue |
| 5 | Resource profile | no hard-coded workers or memory caps; detected values with overrides; one budget |
| 6 | Contention | heavy jobs serialised on shared storage; spill on fast local disk |
| 7 | Staging and typing | generous staging types; tightening only in curated layers |
| 8 | Partitioning | time first, then usage columns; justified by analysis; large inputs isolated |
| 9 | Sample gate and data quality | written rules; gate before full runs; skips audited |
| 10 | Audit trail and lineage | every step recorded; tamper-evident; row-to-input lineage |
| 11 | Observability | run status with heartbeats; stall detection; orphan work cancelled on stop |
| 12 | Licensing and provenance | licence per record; exclusion rules enforced and tested |

**Score bands** as in `ci-cd-plumber`. **Composite** = mean of applicable
domains; a non-applicable domain is N/A with its reason in the notes, never
dropped silently.

**Severity:** Critical — data loss, duplicate rows, a licence breach or an
audit gap; High — a failure mode that costs hours of rework (unbounded units,
silent continue, no resume); Medium — throughput or operability; Low —
hygiene.

**Report (required, in order):** header (mode, target, date, composite);
domain scorecard (Domain | Score | Max | Notes); findings by severity, each
with evidence (`file:line` or a log line), risk and fix; quick wins; drift
since the last baseline.

**Close-out (required):** update `docs/data-pipeline-baseline.md` with the
date, the scores and the open findings as a backlog.

## Evals

`evals/data-pipeline-design/<scenario>/prompt.md` + `graders/`, same shape as
the sibling skills. All fixtures are small invented repos or briefs.

| Scenario | The skill must |
|---|---|
| `design-new-file-source` | ask for a sample shape analysis before any schema; write a design record |
| `design-partitioning-justified` | choose time then usage partitioning from the stated query pattern; reject a sample-sized VARCHAR in staging |
| `audit-unbounded-unit` | flag one input loaded as a single huge transaction (High); propose parts with row and byte caps |
| `audit-silent-continue` | flag a loader that logs a failed unit and continues (High) |
| `audit-hardcoded-parallelism` | flag fixed worker count and memory cap; propose detected values with overrides |
| `audit-no-idempotency` | flag a re-run that duplicates rows (Critical) |
| `audit-scorecard-shape` | produce the report sections in order, with N/A plus reason |
| `out-of-scope-streaming` | state that streaming is out of scope and point elsewhere; invent no rules |

## Docs and release

README skills table; `docs/skills/data-pipeline-design.md`; `docs/llms.txt`;
`mkdocs.yml` nav; `evals/README.md` inventory; `.claude-plugin/plugin.json`
version 0.18.0 and description; `CHANGELOG.md`; `RELEASE-NOTES-v0.18.0.md`;
`claude plugin validate .` passes.

## Genericity check

Before each commit, a grep over `skills/data-pipeline-design/` and
`evals/data-pipeline-design/` for the originating project's name, its source
names and its table names returns nothing. The list of terms lives outside this
repo (in the author's session), so the repo never records them.

## Delivery

One branch (`feat/data-pipeline-design`), one PR; built with subagent-driven
development from a written plan; lower priority than other active work.
