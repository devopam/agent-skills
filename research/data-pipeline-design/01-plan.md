# data-pipeline-design skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a portable `data-pipeline-design` skill (Design and Audit modes, 12 scored domains) with references, assets, evals and release docs.

**Architecture:** `SKILL.md` is a router (< 500 lines) that detects the mode, runs the phases or the audit, and links each domain reference at the point it is needed. `references/` holds one file per domain plus anti-patterns; `assets/` holds the baseline and design-record templates and an example gate-rules file. Evals follow the repo layout (`prompt.md` + `graders/`, `fixture.sh` + `case.yaml` where a repo is needed).

**Tech Stack:** Markdown (Agent Skills spec), YAML, bash fixtures; mkdocs for the site.

**Spec:** `research/data-pipeline-design/00-design.md`

## Global Constraints

- Frontmatter of `SKILL.md`: `name: data-pipeline-design` and `description` only. The description states what the skill does, then "Use when ..."; it never narrates the workflow.
- `SKILL.md` under 500 lines. References one level deep; a file over ~100 lines starts with a table of contents; references are linked inline where they become relevant.
- Plain-text interaction, one question at a time, no host-specific tools.
- Stack-agnostic rules. Examples only in `references/`, in generic Python and SQL (PostgreSQL dialect), with invented names (`orders`, `events`, `vendor_feed`, `raw.events_2025`, ...).
- **Genericity:** no file names a real project, dataset, vendor feed or table. The controller holds a list of forbidden terms and passes it in each dispatch; this plan does not record it. Every task ends with a grep for those terms over the files it touched, and it must print nothing.
- Scope: batch and micro-batch ingestion only. Streaming, database tuning (`postgresql-review`), CI/CD of the pipeline code (`ci-cd-plumber`), BI layers and feature stores are out of scope and named as such.
- The 12 domains, in this order and with these names: 1 Source analysis; 2 Identity and idempotency; 3 Bounded units and resume; 4 Failure policy; 5 Resource profile; 6 Contention; 7 Staging and typing; 8 Partitioning; 9 Sample gate and data quality; 10 Audit trail and lineage; 11 Observability; 12 Licensing and provenance.
- Severity: Critical — data loss, duplicate rows, a licence breach or an audit gap; High — a failure mode that costs hours of rework; Medium — throughput or operability; Low — hygiene.
- Score bands: copy the bands table from `skills/ci-cd-plumber/SKILL.md` (Scoring section) verbatim, so the two skills score alike.
- Baseline path in target repos: `docs/data-pipeline-baseline.md`.
- Release version **0.19.0** (0.18.0 is already released; the spec's "0.18.0" is superseded).
- Commits: `git add` explicit paths only; never `--no-verify`; trailer lines given by the controller.

## Review Focus

1. A repo with pipeline code but no baseline: the skill must ask the user whether they want Design or Audit, not guess. Test: eval `mode-ask-intent` (Task 6).
2. A domain that does not apply (for example licensing for purely internal data): scored N/A with a reason, never dropped, and excluded from the composite. Test: grader line in `audit-scorecard-shape` (Task 6).
3. A user in Design mode who asks the skill to "just write the loader": the skill writes the design record and may suggest file scaffolds, but does not generate pipeline code. Test: grader line in `design-new-file-source` (Task 6).
4. A `docs/project-incubation-baseline.md` already present: the skill reads the stack from it and does not ask again. Test: fixture and grader line in `design-new-file-source` (Task 6).
5. A request about streaming (Kafka consumer lag, watermarks): out of scope, point elsewhere, invent no rules. Test: eval `out-of-scope-streaming` (Task 6).

---

## File Structure

- Create `skills/data-pipeline-design/references/` (13 files, Tasks 1–3).
- Create `skills/data-pipeline-design/assets/` (3 files, Task 4).
- Create `skills/data-pipeline-design/SKILL.md` (Task 5).
- Create `evals/data-pipeline-design/` (README + 9 cases, Task 6).
- Modify `README.md`, `docs/index.md`, `docs/skills/data-pipeline-design.md` (create), `docs/llms.txt`, `docs/evals.md`, `mkdocs.yml`, `evals/README.md`, `.claude-plugin/plugin.json`, `CHANGELOG.md`, create `RELEASE-NOTES-v0.19.0.md`, and fix the version line in `research/data-pipeline-design/00-design.md` (Task 7).

## Reference file contract (Tasks 1–3)

Every domain reference has these sections, in this order:

1. `# <Domain name>` and a one-paragraph summary.
2. `## Contents` (only when the file is over ~100 lines).
3. `## The rule` — the practice in 3–6 imperative bullets.
4. `## Why it matters` — the failure it prevents, stated generically (for example "a single unit of work that runs for a day and fails near the end loses the whole day").
5. `## Design guidance` — what Design mode asks and records for this domain.
6. `## Audit: evidence to look for` — concrete things to grep or read in a repo (code patterns, config keys, log lines, docs), and what their absence means.
7. `## Scoring anchors` — what a 0, a 5 and a 10 look like for this domain.
8. `## Common violations` — 3–6 bullets, each with the severity it usually gets.
9. `## Example` — one short generic example (Python and/or SQL, invented names), 10–40 lines.
10. `## Related domains` — links to sibling reference files by relative path.

Target length 80–180 lines per file. Verification for each reference task:

```bash
cd skills/data-pipeline-design/references
for f in <files of this task>; do
  for h in "## The rule" "## Why it matters" "## Design guidance" "## Audit: evidence to look for" "## Scoring anchors" "## Common violations" "## Example" "## Related domains"; do
    grep -qF "$h" "$f" || echo "MISSING $h in $f"
  done
  n=$(wc -l < "$f"); [ "$n" -gt 100 ] && ! grep -q "^## Contents" "$f" && echo "NO TOC in $f ($n lines)"
done
grep -rniE "<forbidden-terms-from-dispatch>" <files of this task>   # must print nothing
```

Expected: no output.

---

### Task 1: References — domains 1–4

**Files:**
- Create: `skills/data-pipeline-design/references/source-analysis-and-sampling.md`, `identity-and-idempotency.md`, `bounded-units-and-resume.md`, `failure-policy.md`

**Interfaces:**
- Produces: the four file names above (SKILL.md links them in Task 5); each follows the reference file contract.

Required content beyond the contract:

- **source-analysis-and-sampling.md:** how to choose a representative sample (cover the full time range, every record variant, the largest records and known edge cases; never "first N rows"; stratify by file or partition); the shape checklist (types, null rates, key uniqueness, sort order, time columns and ranges, record-size distribution, encodings, how the data will be queried); "no schema or partitioning decision before the analysis is written"; example: a short SQL or Python profile over a sample (counts, null rate per column, min/max of a time column, uniqueness check).
- **identity-and-idempotency.md:** a stable input key derived from the path relative to the raw root (never the absolute path, never a bare file name that can collide across folders); success markers keyed on it; replace-by-key loads (delete-then-insert or merge per input key in one transaction); row-to-input lineage; the collision test and the re-run test; example: a Python `input_key(path, root)` function and a SQL replace of one input's rows inside a transaction.
- **bounded-units-and-resume.md:** cap each unit of work by rows and bytes; each part carries its own identity (`<input_key>__part00001`); one part = one transaction = one unit of restart; the parent's marker is written after its last part; a restart skips parts with markers and removes stale higher-numbered parts; sizing guidance (minutes, not hours, per part); example: a Python generator that splits a sorted record stream into parts with both caps.
- **failure-policy.md:** two policies — processing stages fail fast (bounded retries with backoff only for transient errors such as connection resets and lock timeouts; then stop with a clear message naming the unit), downloads record and continue (a failed-files list, retried later); never "log and continue" in processing; stop means cancel the server-side statement too; exit codes that distinguish "failed" from "nothing to do"; example: a Python retry wrapper that retries only a named set of transient exceptions, 3 attempts at 30/60/120 s.

- [ ] **Step 1:** Write the four files to the contract and the required content.
- [ ] **Step 2:** Run the contract verification for these four files. Expected: no output.
- [ ] **Step 3:** Commit.

```bash
git add skills/data-pipeline-design/references/source-analysis-and-sampling.md skills/data-pipeline-design/references/identity-and-idempotency.md skills/data-pipeline-design/references/bounded-units-and-resume.md skills/data-pipeline-design/references/failure-policy.md
git commit -m "feat(data-pipeline-design): references for domains 1-4"
```

---

### Task 2: References — domains 5–8

**Files:**
- Create: `skills/data-pipeline-design/references/resource-profile.md`, `contention-and-scheduling.md`, `staging-and-typing.md`, `partitioning.md`

**Interfaces:**
- Produces: the four file names above, to the reference file contract.

Required content beyond the contract:

- **resource-profile.md:** detect physical cores, RAM and disk kind (unknown disk = treat as rotational); one memory budget that covers the OS reserve, the database (shared buffers, maintenance memory, per-query work memory) and the pipeline; derive workers (cores − 1, capped by memory per worker), I/O concurrency (low on rotational disks, high on SSD), batch and part sizes from it; every value has an env override and the tool can print each value with its source (detected / rule / env); include a sample budget table for a 4-core/16 GB and a 16-core/64 GB machine, with the rule that produced each number; example: a Python `compute_profile(hw, overrides)` sketch that is a pure function.
- **contention-and-scheduling.md:** one heavy disk or database job at a time on shared storage; a heavy lock (file lock plus a database advisory lock) and a queue instead of parallel heavy jobs; spill and temp space on the fastest local disk, never the data disk; downloads can run beside light work but pause for heavy jobs; signs of contention to look for (disk queue length, long fsync, checkpoints in logs); example: a Python context manager that takes a non-blocking file lock and exits with a distinct code if busy.
- **staging-and-typing.md:** staging keeps raw values in generous types (unbounded text, wide numerics, timestamps with zone, a raw JSON column when the shape varies); never size a column from sample maxima; tighten types, add constraints and enumerations only in curated layers, from the analysis; record parse failures as data, not crashes; example: SQL for a staging table and the matching curated table.
- **partitioning.md:** partition by a time column first, sub-partition by the column(s) most used in filters, and give very large inputs or sources their own partition so replace, purge and analyse stay local; a default partition as a safety net; justify each choice from the source analysis; plan retention and maintenance per partition; write the design up for review before DDL; example: SQL for a range-by-time, list-by-source layout with a default partition.

- [ ] **Step 1:** Write the four files.
- [ ] **Step 2:** Run the contract verification for these four files. Expected: no output.
- [ ] **Step 3:** Commit.

```bash
git add skills/data-pipeline-design/references/resource-profile.md skills/data-pipeline-design/references/contention-and-scheduling.md skills/data-pipeline-design/references/staging-and-typing.md skills/data-pipeline-design/references/partitioning.md
git commit -m "feat(data-pipeline-design): references for domains 5-8"
```

---

### Task 3: References — domains 9–12 and anti-patterns

**Files:**
- Create: `skills/data-pipeline-design/references/sample-gate-and-data-quality.md`, `audit-trail-and-lineage.md`, `observability-and-run-status.md`, `licensing-and-provenance.md`, `anti-patterns.md`

**Interfaces:**
- Produces: the five file names above. The four domain files follow the reference file contract. `anti-patterns.md` has instead: `# Anti-patterns`, `## Contents`, and one `### <name>` entry per anti-pattern with **Looks like**, **Why it hurts**, **Domain**, **Usual severity**, **Fix**.

Required content beyond the contract:

- **sample-gate-and-data-quality.md:** a written rules file per stage (row counts against the sample, null and empty rates, key uniqueness, referential checks, value distributions, size outliers); the gate runs on the sample before any full run of a new or changed stage; a pass is tied to the hashes of the code and rules it ran with, so a change invalidates it; a skip needs a recorded reason and is audited; example: a YAML rules file and the shape of a gate report (JSON).
- **audit-trail-and-lineage.md:** append-only audit records for each step (who, what, when, inputs, outputs, counts, code version); tamper-evident (hash chain over records); overrides and gate skips are audited; row-to-input lineage; verification of the chain as a routine check; alignment with data-integrity expectations in regulated settings (attributable, legible, contemporaneous, original, accurate) without claiming certification; example: SQL for an audit table with a hash chain and a verification query.
- **observability-and-run-status.md:** a status file per run (stage, unit, counts, rate, last heartbeat); stall detection (no heartbeat for N minutes, longer during a known long statement); orphan work is cancelled on stop (client and server side); logs that name the unit and the cause; a done line that a wrapper can check, so a killed process is never read as success; example: a JSON status document and a stall check.
- **licensing-and-provenance.md:** a licence value per record from a controlled vocabulary; provenance (source, retrieval date, version) per input; exclusion rules enforced in code and tested (for example evaluation or benchmark sets that must not enter a training set, records whose licence forbids the intended use); download-only status for sources whose licence is unconfirmed; example: a Python filter with its test.
- **anti-patterns.md:** at least these entries: one giant transaction per input; log-and-continue in a loader; hard-coded worker counts and memory caps; parallel heavy jobs on one rotational disk; spill on the data disk; schema sized from a sample; partitioning chosen before analysis; absolute paths or bare file names as identity; no restart test; status inferred from a process exit code alone; unaudited overrides; licence decided per source but not stored per record.

- [ ] **Step 1:** Write the five files.
- [ ] **Step 2:** Run the contract verification for the four domain files; for `anti-patterns.md` check it has `## Contents` and at least 12 `### ` entries (`grep -c '^### ' anti-patterns.md`). Run the genericity grep over all five. Expected: no output from the checks, count >= 12.
- [ ] **Step 3:** Commit.

```bash
git add skills/data-pipeline-design/references/sample-gate-and-data-quality.md skills/data-pipeline-design/references/audit-trail-and-lineage.md skills/data-pipeline-design/references/observability-and-run-status.md skills/data-pipeline-design/references/licensing-and-provenance.md skills/data-pipeline-design/references/anti-patterns.md
git commit -m "feat(data-pipeline-design): references for domains 9-12 and anti-patterns"
```

---

### Task 4: Assets

**Files:**
- Create: `skills/data-pipeline-design/assets/baseline-template.md`, `design-record-template.md`, `gate-rules-example.yaml`

**Interfaces:**
- Produces: the templates SKILL.md (Task 5) tells the agent to copy. Section headings below are referenced by name in SKILL.md.

Required content:

- **baseline-template.md** (copied to `docs/data-pipeline-baseline.md`): `# Data Pipeline Baseline`; fields **Project**, **Baseline created**, **Last audited**, **Maturity target** (prototype / standard / regulated); `## Context` (stores, volumes, refresh pattern, hardware class, constraints, linked project-incubation baseline); `## Sources and stages` (a table: Source | Stages | Design record | Status); `## Domain targets` (a table of the 12 domains with a target score and N/A reason column); `## Last audit scores` (table: Domain | Score | Notes, plus Composite); `## Open findings` (table: ID | Severity | Domain | Finding | Evidence | Status); `## Drift log` (dated entries). Placeholders in angle brackets.
- **design-record-template.md** (one per source or stage): one `##` section per Design phase, in order: `## 1. Context`, `## 2. Source analysis`, `## 3. Identity and units of work`, `## 4. Staging and curated model`, `## 5. Partitioning`, `## 6. Failure policy and resources`, `## 7. Gates, audit and provenance`, `## 8. Decisions and open questions`. Each section lists the fields to fill (as bullet prompts in angle brackets), for example under section 2: sample selection method, sample size, column profile table, key uniqueness, sort order, time columns and ranges, record size distribution, query patterns.
- **gate-rules-example.yaml:** a commented example for a generic `orders` stage: `stage`, `sample` (path pattern, row count), `rules` list with `id`, `check` (one of `row_count_between`, `null_rate_max`, `unique`, `foreign_key`, `value_in`, `size_p99_max`), parameters, `severity` (`block` / `warn`); at least 6 rules covering each check type.

- [ ] **Step 1:** Write the three files.
- [ ] **Step 2:** Verify:

```bash
cd skills/data-pipeline-design/assets
for h in "## Context" "## Sources and stages" "## Domain targets" "## Last audit scores" "## Open findings" "## Drift log"; do grep -qF "$h" baseline-template.md || echo "MISSING $h"; done
[ "$(grep -c '^## [1-8]\. ' design-record-template.md)" = 8 ] || echo "design record needs 8 phase sections"
python -c "import yaml,sys; d=yaml.safe_load(open('gate-rules-example.yaml')); assert len(d['rules'])>=6; print('ok')"
grep -rniE "<forbidden-terms-from-dispatch>" .   # must print nothing
```

Expected: only `ok`.

- [ ] **Step 3:** Commit.

```bash
git add skills/data-pipeline-design/assets/baseline-template.md skills/data-pipeline-design/assets/design-record-template.md skills/data-pipeline-design/assets/gate-rules-example.yaml
git commit -m "feat(data-pipeline-design): baseline, design-record and gate-rules assets"
```

---

### Task 5: SKILL.md

**Files:**
- Create: `skills/data-pipeline-design/SKILL.md`

**Interfaces:**
- Consumes: the 13 reference files (Tasks 1–3) and 3 assets (Task 4), by relative path.
- Produces: the skill entry point. Section names below are what evals grade against.

Required structure (model the tone and layout on `skills/ci-cd-plumber/SKILL.md`):

```markdown
---
name: data-pipeline-design
description: Designs batch data pipelines and new sources from a representative-sample analysis, and audits existing pipelines across twelve scored domains — identity, bounded restartable units, fail-fast policy, hardware-sized parallelism, partitioning, data-quality gates, audit trail and licensing. Use when adding a data source, designing or reviewing an ingestion/ETL/ELT pipeline, planning partitioning or staging schemas, or when a load is slow, unrestartable or produces duplicates.
---
```

Then, in order:
1. `# Data Pipeline Design` — 2 short paragraphs: what it covers; the scope line (batch and micro-batch; out of scope: streaming, database tuning → `postgresql-review`, CI/CD → `ci-cd-plumber`, BI layers, feature stores); plain-text, one question at a time; reads `docs/project-incubation-baseline.md` when present and does not re-ask its answers.
2. `## Detecting which mode applies` — the 3-way rule from the spec (baseline → Audit; code but no baseline → ask Design or Audit; nothing → Design).
3. `## Design mode` — `### Phase 1: Context` … `### Phase 8: Write the records`, each 4–10 lines, each linking its reference inline at the point it is used, and each ending with what it writes into the design record (by the template's section name). Phase 2 states "no schema or partitioning decision before this section is written". Phase 8 says the skill may suggest file scaffolds but does not generate pipeline code.
4. `## Audit mode` — `### Domains (in order)` (numbered list of the 12, each with a one-line focus and its reference link); `### Scoring` (0–10 per domain; the score-band table copied from ci-cd-plumber; composite = mean of applicable domains; N/A with reason, never dropped); `### Severity` (the 4 levels from Global Constraints); `### Report format (required)` (header; scorecard table Domain | Score | Max (10) | Notes; findings by severity, each with evidence, risk, fix; quick wins; drift since last baseline); `### Close-out (required after every audit)` (update `docs/data-pipeline-baseline.md`: Last audited, Last audit scores, Open findings, Drift log; offer fixes individually, never bulk-apply without consent).
5. `## Out of scope` — the list, each with where to go instead.
6. `## Reference files` — a table of all 13 references and 3 assets with one line each.

- [ ] **Step 1:** Write SKILL.md.
- [ ] **Step 2:** Verify:

```bash
cd skills/data-pipeline-design
[ "$(wc -l < SKILL.md)" -lt 500 ] || echo "SKILL.md too long"
sed -n '2,3p' SKILL.md | grep -q '^name: data-pipeline-design$' || echo "bad name"
[ "$(awk '/^---$/{c++; next} c==1{print}' SKILL.md | grep -cE '^[a-z_-]+:')" = 2 ] || echo "frontmatter must have exactly name and description"
grep -oE '\((references|assets)/[^)#]+' SKILL.md | sed 's/^(//' | sort -u | while read -r p; do [ -f "$p" ] || echo "BROKEN LINK $p"; done
for f in references/*.md assets/*; do grep -qF "$f" SKILL.md || echo "NOT LINKED $f"; done
for n in "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5" "Phase 6" "Phase 7" "Phase 8"; do grep -qF "### $n" SKILL.md || echo "MISSING $n"; done
grep -rniE "<forbidden-terms-from-dispatch>" SKILL.md   # must print nothing
```

Expected: no output.

- [ ] **Step 3:** Commit.

```bash
git add skills/data-pipeline-design/SKILL.md
git commit -m "feat(data-pipeline-design): SKILL.md router (design and audit modes)"
```

---

### Task 6: Evals

**Files:**
- Create: `evals/data-pipeline-design/README.md` and 9 case directories, each with `prompt.md`, `graders/criteria.md`, `graders/skill-fired.md`; cases that need a repo also get `fixture.sh` and `case.yaml`.

**Interfaces:**
- Consumes: SKILL.md section names (Task 5), the baseline template (Task 4).

Formats (copy from `evals/ci-cd-plumber/audit-scorecard-report-shape/`):

`prompt.md` front matter: `name: data-pipeline-design-<case>`, `max_turns: 10`, `allowed_tools: [Read, Glob, Grep, Skill]`. `graders/criteria.md` front matter `type: llm`, `weight: 1`, then "Pass if the response:" numbered criteria and a "Fail if" line. `graders/skill-fired.md`:

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?data-pipeline-design"'
arm: with-only
---
```

`case.yaml`:

```yaml
schema_version: "1.1"
name: data-pipeline-design-<case>
context:
  scaffold_script: fixture.sh
```

`fixture.sh`: `#!/usr/bin/env bash`, `set -euo pipefail`, then `mkdir -p` and `cat > file <<'EOF_FIXTURE' ... EOF_FIXTURE` blocks. All fixture content is invented (an `orders`/`events` shop, a `vendor_feed` drop folder).

Cases and what each must contain:

| Case | Fixture | Prompt | Pass criteria (minimum) |
|---|---|---|---|
| `design-new-file-source` | `docs/project-incubation-baseline.md` (Python 3.12, PostgreSQL) and an empty `pipelines/` | "We receive daily gzip CSV drops from a vendor (about 40 GB a day). Design the ingestion. Then just write the loader." | Design mode; does not re-ask stack; asks for/plans a representative-sample shape analysis before any schema; covers identity, parts, failure policy; writes or offers the design record from the template; declines to generate the loader code, offers scaffolds instead |
| `design-partitioning-justified` | none (prompt only) | brief with query pattern "most queries filter by event_date range and by tenant_id"; a proposed staging DDL with `VARCHAR(64)` sized from a sample | partitions by time first, then tenant; cites the query pattern; rejects sample-sized VARCHAR in staging, proposes TEXT |
| `audit-unbounded-unit` | baseline + `pipelines/load_events.py` that reads a whole 100M-row file into one transaction | "Audit our pipeline." | Audit mode; flags the single transaction as High under Bounded units; proposes parts with row and byte caps and per-part identity |
| `audit-silent-continue` | baseline + loader that catches exceptions per file, logs and continues | "Audit our pipeline." | flags log-and-continue as High under Failure policy; distinguishes downloads (record and skip is fine) |
| `audit-hardcoded-parallelism` | baseline + code with `WORKERS = 3` and `memory_limit='4GB'` | "Audit our pipeline." | flags under Resource profile; proposes detected values with env overrides and a single budget |
| `audit-no-idempotency` | baseline + loader that INSERTs without replace-by-key and a marker keyed on bare file name | "Audit our pipeline." | flags duplicate rows on re-run as Critical under Identity; flags bare-file-name identity collision |
| `audit-scorecard-shape` | baseline (maturity standard; internal data only) + a small pipeline | "Audit our pipeline and give me the scorecard." | report sections in the required order; 12 rows; Licensing scored N/A with a reason and excluded from the composite; close-out updates the baseline |
| `mode-ask-intent` | pipeline code, no baseline | "Help me with our data pipeline." | asks whether the user wants Design (new source/stage) or Audit (existing); does not start either unasked |
| `out-of-scope-streaming` | none | "Our Kafka consumers lag; how should we set watermarks and handle late events?" | states streaming is out of scope; points to other resources; invents no streaming rules |

`evals/data-pipeline-design/README.md`: title, one paragraph matching `evals/ci-cd-plumber/README.md`, and a `## Cases` table of the 9 cases with their intent.

- [ ] **Step 1:** Write the README and the 9 cases.
- [ ] **Step 2:** Verify:

```bash
cd evals/data-pipeline-design
for d in */; do d=${d%/}; [ -f "$d/prompt.md" ] && [ -f "$d/graders/criteria.md" ] && [ -f "$d/graders/skill-fired.md" ] || echo "INCOMPLETE $d"; grep -q "^name: data-pipeline-design-$d$" "$d/prompt.md" || echo "BAD NAME $d"; [ -f "$d/fixture.sh" ] && { bash -n "$d/fixture.sh" || echo "BAD SH $d"; [ -f "$d/case.yaml" ] || echo "NO CASE.YAML $d"; }; done
[ "$(ls -d */ | wc -l)" = 9 ] || echo "need 9 cases"
here=$PWD; for d in */; do [ -f "$d/fixture.sh" ] || continue; t=$(mktemp -d); (cd "$t" && bash "$here/$d/fixture.sh") || echo "FIXTURE FAILS $d"; rm -rf "$t"; done
grep -rniE "<forbidden-terms-from-dispatch>" .   # must print nothing
```

Expected: no output.

- [ ] **Step 3:** Commit.

```bash
git add evals/data-pipeline-design
git commit -m "test(data-pipeline-design): 9 eval cases"
```

(`git add` of the one new directory is explicit: it contains only this task's files.)

---

### Task 7: Docs and release 0.19.0

**Files:**
- Create: `docs/skills/data-pipeline-design.md`, `RELEASE-NOTES-v0.19.0.md`
- Modify: `README.md` (skills table row, "Current version" line, plugin version line), `docs/index.md` (skills table row), `docs/llms.txt` (two lines, next to the ci-cd-plumber lines), `docs/evals.md` (inventory row: 9), `mkdocs.yml` (nav entry next to ci-cd-plumber), `evals/README.md` (inventory row `~9`), `.claude-plugin/plugin.json` (`version` 0.19.0; add the skill to `description`), `CHANGELOG.md` (`## [0.19.0] - <today>` with `### Added`), `research/data-pipeline-design/00-design.md` (release line says 0.19.0)

**Interfaces:**
- Consumes: everything above.

Content:
- `docs/skills/data-pipeline-design.md`: same layout as `docs/skills/ci-cd-plumber.md` (summary, **Use when**, `## Modes`, `## Domains (summary)`, `## Canonical sources` with links to SKILL.md, references/, evals/).
- README row: `| [`data-pipeline-design`](skills/data-pipeline-design/) | Batch pipeline design and 12-domain audit. | New sources, ETL/ELT design, slow or unrestartable loads. |`
- CHANGELOG `### Added`: one bullet for the skill (modes, 12 domains, references, assets), one for the 9 evals, one for the plugin version.
- Release notes: same shape as `RELEASE-NOTES-v0.17.0.md` (Highlights table, Docs, Boundaries: suggests scores and findings, does not certify; batch only).

- [ ] **Step 1:** Make the edits.
- [ ] **Step 2:** Verify:

```bash
grep -q '"version": "0.19.0"' .claude-plugin/plugin.json || echo "plugin version"
grep -q 'data-pipeline-design' .claude-plugin/plugin.json README.md docs/index.md docs/llms.txt docs/evals.md mkdocs.yml evals/README.md CHANGELOG.md || echo "missing mention"
for f in README.md docs/index.md docs/llms.txt docs/evals.md mkdocs.yml evals/README.md; do grep -q data-pipeline-design "$f" || echo "NO MENTION $f"; done
claude plugin validate . 2>&1 | tail -3
pip install -q -r requirements-docs.txt && mkdocs build --strict -q 2>&1 | tail -5
grep -rniE "<forbidden-terms-from-dispatch>" skills/data-pipeline-design evals/data-pipeline-design docs/skills/data-pipeline-design.md RELEASE-NOTES-v0.19.0.md   # must print nothing
```

Expected: validate passes; mkdocs builds (if `--strict` fails on pre-existing warnings, record them and run without `--strict`; new warnings from this task are not allowed); no other output.

- [ ] **Step 3:** Commit.

```bash
git add docs/skills/data-pipeline-design.md RELEASE-NOTES-v0.19.0.md README.md docs/index.md docs/llms.txt docs/evals.md mkdocs.yml evals/README.md .claude-plugin/plugin.json CHANGELOG.md research/data-pipeline-design/00-design.md
git commit -m "docs: data-pipeline-design skill and release 0.19.0"
```
