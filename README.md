# agent-skills

A collection of [Agent Skills](https://agentskills.io/) — portable,
version-controlled procedural knowledge for AI coding agents, following the
open Agent Skills spec (a `SKILL.md` file with `name`/`description`
frontmatter, plus optional `references/`, `scripts/`, and `assets/`
subfolders). Skills here work with any agentskills.io-compliant client —
Claude Code, and the broader [client showcase](https://agentskills.io/clients).

**Current version:** `0.14.0` (see [CHANGELOG.md](CHANGELOG.md)).

**Documentation:** [devopam.github.io/agent-skills](https://devopam.github.io/agent-skills/) · **Agent index:** [llms.txt](https://devopam.github.io/agent-skills/llms.txt)

## Skills

| Skill | What it does | Use when |
|---|---|---|
| [`project-incubation`](skills/project-incubation/) | Guides a project through best-practice repo structure, architecture principles, and tech-stack template selection at inception, then re-audits an existing repo against that baseline throughout its lifecycle. | Starting a new repo, or periodically checking an existing one against the baseline it was incubated with. |
| [`python-code-review`](skills/python-code-review/) | Reviews Python code across 11 domains with a scored report. Portable — no subagent dispatch, no host-specific slash command. | Reviewing Python code for quality/security/production-readiness, before a commit or PR, or for a periodic project health check. |
| [`ci-cd-plumber`](skills/ci-cd-plumber/) | Scaffolds and audits CI/CD pipelines with a scored domain table and severity-ordered findings. | Setting up or hardening CI/CD, release automation, changelogs/release notes. |
| [`pr-review`](skills/pr-review/) | Pre-submit / PR readiness — hooks, blast radius, tests, docs/changelog, CI readiness, diff-scoped security. | Before opening or updating a PR, or reviewing someone else's PR. |
| [`postgresql-review`](skills/postgresql-review/) | Live PostgreSQL review (health, schema, indexes, workload, maintenance, security, hygiene) after **MCPg readiness** (install/config/reachability for the target DB and schemas). Scored report; suggested remediations only. | Auditing Postgres, production readiness, performance or security posture when MCPg can reach the database. |
| [`ui-system-review`](skills/ui-system-review/) | Audits UI **system** consistency — tokens, shared components, themes, icons/media, form factors (**Web** responsive; **Apple/SwiftUI**; **Android/Compose**) — scored report plus remediation suggestions. | Design-system drift, mixed component libraries, token hardcoding, responsive/tablet discipline on an existing app. |

## Using a skill

Point any agentskills.io-compliant agent at this repo (or vendor/copy the
specific `skills/<name>/` folder into your project's own skills directory —
see each client's install instructions in the
[client showcase](https://agentskills.io/clients)). The agent discovers each
skill from its `SKILL.md` frontmatter and loads the full instructions only
when a task matches.

### Claude Code plugin

This repository **is already** a Claude Code plugin: it ships
[`.claude-plugin/plugin.json`](.claude-plugin/plugin.json). From a clone:

```bash
claude plugin validate .
# when enrollment allows:
claude plugin eval . --ablation with-without --runs 1 --no-publish
```

Install / enable the plugin using Claude Code's usual local-plugin or
marketplace flow against this repo (or a released tag such as `v0.14.0`).
No separate “plugin product” is required beyond this manifest + the
`skills/` tree — that *is* the plugin surface.

## Evals

Hand-authored trust cases live under [`evals/`](evals/) — one suite per skill
(**62** cases in 0.14.0). See [`evals/README.md`](evals/README.md).

## Knowledge graph (graphify)

Optional corpus map of this repo lives under [`graphify-out/`](graphify-out/)
(`GRAPH_REPORT.md`, `graph.html`, `graph.json`). It is regenerated after
substantive skill changes for navigation and consistency checks; machine-local
cache paths are gitignored. Not a runtime dependency of any skill.

## Roadmap

- **Shipped (0.14.0):** six skills, including `ui-system-review` with Web +
  Apple + Android packs
- Deeper remediation playbooks; optional live browser/device checks when users
  provide tooling
- Evals execution when `claude plugin eval` enrollment allows

## Repo conventions

See [CONTRIBUTING.md](CONTRIBUTING.md) for how skills are authored, reviewed,
and versioned — including research-before-authoring.

## Code of Conduct

This project adopts the [Contributor Covenant](CODE_OF_CONDUCT.md) (v3.0).
Report concerns to [devopam@gmail.com](mailto:devopam@gmail.com) or via a
[GitHub Issue](https://github.com/devopam/agent-skills/issues/new) (prefer
email when privacy matters).

## License

[MIT](LICENSE).
