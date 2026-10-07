# Evals

Hand-authored trust cases live under `evals/<skill>/` in the repository
(`prompt.md` + `graders/*.md`). **150** cases in total.

| Skill | Cases |
|-------|------:|
| regulatory-compliance-applicability-scan | 72 |
| project-incubation | 17 |
| python-code-review | 13 |
| ui-system-review | 12 |
| ci-cd-plumber | 8 |
| pr-review | 7 |
| postgresql-review | 6 |
| react-code-review | 6 |
| typescript-code-review | 5 |
| nodejs-code-review | 5 |

Each case is a directory with `prompt.md` and `graders/*.md`; every grader file
needs YAML front matter (`type: llm`, `weight: 1`) or `claude plugin eval`
fails with `invalid case.yaml: graders: Required`. Run `claude plugin eval . --scaffold`
to score them (requires a Claude Code build that ships `claude plugin eval`; verified
with 2.1.292. Where the command is unavailable or gated to early access, the cases
remain the human-readable contract).

Conventions:

- Each case's `prompt.md` sets `name: <skill>-<case>`. Directory names are not
  unique across skills (e.g. `audit-scorecard-report-shape`), and the report
  keys on case name, so keep names unique.
- Every case has an `llm` rubric (`graders/criteria.md`) and a
  `graders/skill-fired.md` (`tool_used: Skill`, `arm: with-only`) that checks
  the skill actually fired. With the default with/without ablation, with-only
  graders are an indicator, not part of the score.
- Filter with `--case '<skill>-*'`; cap spend with `--max-cost-usd`.
- Results are written to `evals/results/` (git-ignored).

See [evals/README.md on GitHub](https://github.com/devopam/agent-skills/blob/main/evals/README.md).

- Code-review cases embed their target code in the prompt, and the rubric
  requires findings grounded in that code.
- Cases that test commencement/current legal status allow `WebSearch` and
  `WebFetch` so the skill can re-verify live law.
- Cases that describe repository files (UI audits, CI/CD audits, existing-repo
  audits) ship a `fixture.sh` + `case.yaml` (`context.scaffold_script`) that
  builds the files in the empty sandbox workspace. These need `--scaffold`;
  only pass it for suites you authored. `fixture.sh` must be self-contained
  (heredocs), since the script runs in an empty workspace.
- postgresql-review cases supply the MCPg tool results inline in the prompt;
  the plugin declares no MCP server, so there is nothing to mock.
- Inception cases that need user answers are marked non-interactive in the
  prompt, since a single turn cannot complete the interview.
- Keep rubrics short: a numbered "Pass if" list plus a one-line "Fail if".
  Long rubrics with "Should not show" lists made the judge fail responses that
  clearly met the requirements.
