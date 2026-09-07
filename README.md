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
| [`python-code-review`](skills/python-code-review/) | Reviews Python code across 11 domains (standards compliance, code quality, security, dependency/supply-chain security, performance, concurrency & async correctness, idioms & patterns, architecture, observability, scalability & resilience, testing) with a scored report. Portable rebuild of a Claude-Code-native tool — no subagent dispatch, no host-specific slash command. | Reviewing Python code for quality/security/production-readiness, before a commit or PR, or for a periodic project health check. |
| [`ci-cd-plumber`](skills/ci-cd-plumber/) | Scaffolds production-grade CI/CD pipelines and audits existing ones for structure, security, speed, reproducibility, progressive delivery, and release documentation — with a scored domain table and severity-ordered findings. | Setting up CI/CD for a new project, hardening or reviewing an existing pipeline, improving release automation, or generating/checking changelogs and release notes. |
| [`pr-review`](skills/pr-review/) | Reviews a local change set or open PR for pre-submit readiness — hooks/lint/tests, blast radius, tests for the change, docs/changelog hygiene, CI readiness, and diff-scoped security footguns — with a merge-readiness verdict. | Before opening or updating a PR, when reviewing someone else's PR, or when you want to catch rework triggers before CI does. |

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

`project-incubation` covers all 10 stack categories originally envisioned
across v1 and `research/taxonomy-roadmap.md`'s v2 backlog, now fully
shipped as of 2026-08-31.

`ci-cd-plumber` v0 is complete for general use. `pr-review` v0 adds
pre-submit / PR readiness as a fourth skill. Next: execute and tune evals
when `claude plugin eval` enrollment is available; deepen examples from
live use.

## Repo conventions

See [CONTRIBUTING.md](CONTRIBUTING.md) for how skills are authored, reviewed,
and versioned in this repo — including the research-before-authoring workflow
used to build `project-incubation`'s reference material.

## License

[MIT](LICENSE).
