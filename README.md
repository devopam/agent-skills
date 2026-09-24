# agent-skills

A collection of [Agent Skills](https://agentskills.io/) — portable,
version-controlled procedural knowledge for AI coding agents, following the
open Agent Skills spec.

**Current version:** `0.17.0` (see [CHANGELOG.md](CHANGELOG.md)).

**Documentation:** [devopam.github.io/agent-skills](https://devopam.github.io/agent-skills/) · **Agent index:** [llms.txt](https://devopam.github.io/agent-skills/llms.txt)

## Skills

| Skill | What it does | Use when |
|---|---|---|
| [`project-incubation`](skills/project-incubation/) | Repo structure, architecture, tech-stack baseline at inception and re-audit. | New or existing repos vs incubation baseline. |
| [`python-code-review`](skills/python-code-review/) | Python review across 11 domains with a scored report. | Quality/security/production readiness. |
| [`typescript-code-review`](skills/typescript-code-review/) | TypeScript review across 11 domains with a scored report. | TS libraries, apps, shared packages. |
| [`nodejs-code-review`](skills/nodejs-code-review/) | Node.js service/API review across 11 domains. | Express/Fastify/Hono/Nest, workers, CLIs. |
| [`react-code-review`](skills/react-code-review/) | React/Next UI review across 11 domains. | Components, hooks, client security/perf. |
| [`ci-cd-plumber`](skills/ci-cd-plumber/) | CI/CD scaffold and audit with scored domains. | Pipelines, release automation. |
| [`pr-review`](skills/pr-review/) | Pre-submit / PR readiness. | Before or during PR review. |
| [`postgresql-review`](skills/postgresql-review/) | Live PostgreSQL review after MCPg readiness. | Postgres health, schema, security. |
| [`ui-system-review`](skills/ui-system-review/) | UI system consistency (Web / Apple / Android). | Design-system drift, form factors. |
| [`regulatory-compliance-applicability-scan`](skills/regulatory-compliance-applicability-scan/) | Privacy/domain **applicability** scan (global packs). Suggests, does not certify. Not legal advice. | Multi-market privacy gap orientation. |

### Stack code-review siblings

- **typescript-code-review** — language and package quality  
- **nodejs-code-review** — runtime, HTTP, workers  
- **react-code-review** — UI/hooks (pairs with **ui-system-review** for tokens/components)  
- **python-code-review** — Python services and libraries  

## Using a skill

Point any agentskills.io-compliant agent at this repo (or copy `skills/<name>/`).

### Claude Code plugin

[`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) — validate with
`claude plugin validate .`. Plugin version tracks **0.17.0**.

## Evals

See [`evals/README.md`](evals/README.md).

## Roadmap

- Deepen TS/Node/React domain reference docs toward Python skill depth
- Optional registry URL mirror and remaining thin EU overlays for regulatory skill
- More evals and smoke tests on public repos

## Code of Conduct

[Contributor Covenant](CODE_OF_CONDUCT.md) v3.0 — [devopam@gmail.com](mailto:devopam@gmail.com)
or [GitHub Issue](https://github.com/devopam/agent-skills/issues/new).

## License

[MIT](LICENSE).
