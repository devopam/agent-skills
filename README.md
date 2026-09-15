# agent-skills

A collection of [Agent Skills](https://agentskills.io/) — portable,
version-controlled procedural knowledge for AI coding agents, following the
open Agent Skills spec.

**Current version:** `0.14.0` (see [CHANGELOG.md](CHANGELOG.md)).  
**On main (Unreleased):** `regulatory-compliance-applicability-scan` — first-wave
privacy packs plus **CN/KR/JP/RU** orientation packs; **0.15.0 not cut yet**.

**Documentation:** [devopam.github.io/agent-skills](https://devopam.github.io/agent-skills/) · **Agent index:** [llms.txt](https://devopam.github.io/agent-skills/llms.txt)

## Skills

| Skill | What it does | Use when |
|---|---|---|
| [`project-incubation`](skills/project-incubation/) | Repo structure, architecture, tech-stack baseline at inception and re-audit. | New or existing repos vs incubation baseline. |
| [`python-code-review`](skills/python-code-review/) | Python review across 11 domains with a scored report. | Quality/security/production readiness. |
| [`ci-cd-plumber`](skills/ci-cd-plumber/) | CI/CD scaffold and audit with scored domains. | Pipelines, release automation. |
| [`pr-review`](skills/pr-review/) | Pre-submit / PR readiness. | Before or during PR review. |
| [`postgresql-review`](skills/postgresql-review/) | Live PostgreSQL review after MCPg readiness. | Postgres health, schema, security. |
| [`ui-system-review`](skills/ui-system-review/) | UI system consistency (Web / Apple / Android). | Design-system drift, form factors. |
| [`regulatory-compliance-applicability-scan`](skills/regulatory-compliance-applicability-scan/) | **(Unreleased)** Privacy/domain **applicability** scan for runnable packs (EU±DE/FR/IT, IN, US-CA, CA, BR, AE, SA, **CN, KR, JP, RU**, fintech, healthcare). Declines missing jurisdictions. Not legal advice. | Multi-market privacy gap orientation. |

## Using a skill

Point any agentskills.io-compliant agent at this repo (or copy `skills/<name>/`).

### Claude Code plugin

[`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) — validate with
`claude plugin validate .`. Current published plugin version remains **0.14.0**
until 0.15.0 is intentionally cut.

## Evals

See [`evals/README.md`](evals/README.md) (**75** cases on main).

## Roadmap

- Shipped **0.14.0:** six skills including `ui-system-review`
- Main: regulatory skill coverage expansion; release when depth is a logical win

## Code of Conduct

[Contributor Covenant](CODE_OF_CONDUCT.md) v3.0 — [devopam@gmail.com](mailto:devopam@gmail.com)
or [GitHub Issue](https://github.com/devopam/agent-skills/issues/new).

## License

[MIT](LICENSE).
