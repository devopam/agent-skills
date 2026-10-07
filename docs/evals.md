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
fails with `invalid case.yaml: graders: Required`. Run `claude plugin eval .`
to score them.

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
