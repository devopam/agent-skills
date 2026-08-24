---
name: python-code-review
description: Use when reviewing Python code for quality, security, performance, and standards compliance — before commits, during PR review, or for project health checks. Triggers on /python-review command or pre-commit gate usage.
---

# Python Code Review

Review Python projects across 8 domains with a scored report.

## Invocation

- `/python-review` or `/python-review full` — full project review (default)
- `/python-review diff` — scoped review of changed files only (PR/pre-commit mode)
- `/python-review diff --base=develop` — diff against specific branch

**Arguments:** $ARGUMENTS

## Workflow

1. **Load config** — read `python-review-config.toml` from project root, fall back to defaults in this skill directory
2. **Determine scope** — full (scan all `.py` files) or diff (`git diff` against base + immediate imports)
3. **Dispatch domain reviews** — launch parallel subagents, one per enabled domain. Each subagent:
   - Receives the file list and its domain reference from `review-domains/`
   - Returns: score (1-10), issues list (severity, file, line, description, fix)
4. **Aggregate** — collect scores, deduplicate cross-domain issues (same file+line -> merge domain tags), apply thresholds
5. **Output** — render scorecard and issues to configured formats

## Scorecard

| Verdict | Condition |
|---------|-----------|
| **Pass** | Score >= `pass_score` (default 7) |
| **Needs attention** | Score between `floor_score` and `pass_score` |
| **Fail** | Score < `floor_score` (default 5) OR any Critical issue |

**Overall:** PASS (all pass) / CONDITIONAL PASS (no critical, some attention) / FAIL (any critical or any domain below floor)

## Gate Behavior

- PASS / CONDITIONAL PASS -> exit 0
- FAIL -> exit 1 (blocks commit/PR)

## Output Formats

- **Console** (Rich) — always
- **Markdown** — always, written to `{report_dir}/python-review-report.md`
- **PDF** — opt-in via config, rendered from markdown via weasyprint + `report-style.css`

## Severity

| Level | Meaning | Gate impact |
|-------|---------|-------------|
| Critical | Security holes, data loss, broken functionality | Hard fail |
| Important | Standards gaps, anti-patterns, performance issues | Affects score |
| Minor | Style, alternative idioms, nice-to-haves | Informational |

## Issue Format

Each issue includes:
- `[DOMAIN]` tag and severity
- File path and line number
- What is wrong — specific description
- Why it matters — reference to domain criteria
- Suggested fix — concrete code when applicable

## Tier-Based Depth

Set `tier` in config: `script` | `web` | `enterprise`. Higher tiers activate more checks per domain. See individual domain references for tier applicability tables.

## Config

Default config template: `python-review-config.toml` in this directory. Copy to project root to customize. Key settings:
- `project.tier` — review depth
- `thresholds.pass_score` / `floor_score` — verdicts
- `domains.enabled` — which domains to run
- `output.formats` — add `"pdf"` for PDF output
- `standards.recommended_libraries` — team library suggestions (capability detection, not mandates)

## Domain References

Each domain has its own reference file in `review-domains/`:
- `standards-compliance.md` — project structure, tooling, capability detection
- `code-quality.md` — types, complexity, naming, docs, dead code
- `security.md` — OWASP, injection, secrets, crypto, dependencies
- `performance.md` — N+1, pooling, GIL, caching, async correctness
- `idioms-and-patterns.md` — Pythonic code, modern syntax, immutability
- `architecture.md` — separation, DB segregation, API design, deployment
- `observability.md` — logging, SLI/SLO, tracing, metrics
- `scalability-and-resilience.md` — HA, DR, horizontal scaling, circuit breakers, graceful degradation

## Subagent Dispatch

For each enabled domain, dispatch a parallel subagent with this prompt template:

> You are reviewing Python code for the **{domain_name}** domain.
>
> **Tier:** {tier}
> **Scope:** {scope_mode}
> **Files to review:**
> {file_list}
>
> **Review criteria:** (contents of review-domains/{domain}.md)
>
> **Instructions:**
> 1. Review each file against the criteria for the configured tier
> 2. Score the code 1-10 using the Scoring Guide
> 3. List every issue found with: severity (Critical/Important/Minor), file path, line number, description, why it matters, suggested fix
> 4. Return your response as structured data:
>    - score: integer 1-10
>    - issues: list of {severity, file, line, description, reason, fix}
>    - summary: 1-2 sentence domain summary

## Console Output

Use Rich to render:
1. Project header (name, tier, scope, file count)
2. Scorecard table with colored verdicts (green=Pass, yellow=Attention, red=Fail)
3. Issues grouped by severity, then by domain
4. Overall verdict banner

## Report Generation

1. Populate `report-template.md` with review results
2. Write to `{report_dir}/python-review-report.md`
3. If PDF enabled:
   - Convert markdown to HTML (use markdown library)
   - Apply `report-style.css`
   - Render to PDF via weasyprint
   - Write to `{report_dir}/python-review-report.pdf`
