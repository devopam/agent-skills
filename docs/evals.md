# Evals

Hand-authored trust cases live under `evals/<skill>/` in the repository
(`prompt.md` + `graders/criteria.md`). **51** cases in 0.13.0.

| Skill | Cases |
|-------|------:|
| project-incubation | 17 |
| python-code-review | 13 |
| ci-cd-plumber | 8 |
| pr-review | 7 |
| postgresql-review | 6 |

Each case is a directory with `prompt.md` and `graders/*.md`; every grader file
needs YAML front matter (`type: llm`, `weight: 1`) or `claude plugin eval`
fails with `invalid case.yaml: graders: Required`. Run `claude plugin eval .`
to score them.

See [evals/README.md on GitHub](https://github.com/devopam/agent-skills/blob/main/evals/README.md).
