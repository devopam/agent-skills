# agent-skills

A collection of [Agent Skills](https://agentskills.io/) — portable,
version-controlled procedural knowledge for AI coding agents, following the
open Agent Skills spec (a `SKILL.md` file with `name`/`description`
frontmatter, plus optional `references/`, `scripts/`, and `assets/`
subfolders). Skills here work with any agentskills.io-compliant client —
Claude Code, and the broader [client showcase](https://agentskills.io/clients).

## Skills

| Skill | What it does | Use when |
|---|---|---|
| [`project-incubation`](skills/project-incubation/) | Guides a project through best-practice repo structure, architecture principles, and tech-stack template selection at inception, then re-audits an existing repo against that baseline throughout its lifecycle. | Starting a new repo, or periodically checking an existing one against the baseline it was incubated with. |
| [`python-code-review`](skills/python-code-review/) | Reviews Python code across 11 domains with a scored report. Portable — no subagent dispatch, no host-specific slash command. | Reviewing Python code for quality/security/production-readiness, before a commit or PR, or for a periodic project health check. |
| [`ci-cd-plumber`](skills/ci-cd-plumber/) | Scaffolds and audits CI/CD pipelines with a scored domain table and severity-ordered findings. | Setting up or hardening CI/CD, release automation, changelogs/release notes. |
| [`pr-review`](skills/pr-review/) | Pre-submit / PR readiness — hooks, blast radius, tests, docs/changelog, CI readiness, diff-scoped security. | Before opening or updating a PR, or reviewing someone else's PR. |
| [`postgresql-review`](skills/postgresql-review/) | Live PostgreSQL review (health, schema, indexes, workload, maintenance, security, hygiene) after **MCPg readiness** (install/config/reachability for the target DB and schemas). Scored report; suggested remediations only. | Auditing Postgres, production readiness, performance or security posture when MCPg can reach the database. |

## Using a skill

Point any agentskills.io-compliant agent at this repo (or vendor/copy the
specific `skills/<name>/` folder into your project's own skills directory —
see each client's own install instructions in the
[client showcase](https://agentskills.io/clients)). The agent discovers each
skill from its `SKILL.md` frontmatter and loads the full instructions only
when a task matches.

For Claude Code specifically: `claude plugin validate .` / `claude plugin eval`
can be run against this repo directly, since it carries a
`.claude-plugin/plugin.json` manifest.

## Evals

Hand-authored trust cases live under [`evals/`](evals/) — one suite per skill.
See [`evals/README.md`](evals/README.md) for inventory and how to run
`claude plugin eval` when access is available.

## Roadmap

Five skills shipped through **0.12.0**, including `postgresql-review` v0
(MCPg-backed). Next: execute and tune evals when enrollment allows; deepen
from live use.

## Repo conventions

See [CONTRIBUTING.md](CONTRIBUTING.md) for how skills are authored, reviewed,
and versioned — including research-before-authoring.

## License

[MIT](LICENSE).
