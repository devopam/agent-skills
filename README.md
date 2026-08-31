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

## Roadmap

`project-incubation` covers 9 stack categories (Data & Analytics
Platforms, Business Applications, Integration & Event-Driven Systems,
Backend & API Services, Agentic & MCP Platforms, Developer Tooling &
Libraries, Infrastructure & Platform Engineering, ML / AI Model
Development, MLOps / ML Platform Engineering) plus a software/non-software
fork for documentation/research-only projects. Confirmed for later
addition: Frontend / Client Applications — see
`research/taxonomy-roadmap.md` for scope notes.

## Repo conventions

See [CONTRIBUTING.md](CONTRIBUTING.md) for how skills are authored, reviewed,
and versioned in this repo — including the research-before-authoring workflow
used to build `project-incubation`'s reference material.

## License

[MIT](LICENSE).
