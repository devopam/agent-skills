# project-incubation

Sets up a new project with best-practice structure and architecture guidance,
then re-audits an existing repo against its baseline over time.

**Use when:** starting a repository, scaffolding a project, or checking an
existing repo against the conventions it was incubated with.

## Modes

- **Inception** — new or near-empty repo: shape, category, structure, principles, preferred libraries, baseline record
- **Audit** — existing `docs/project-incubation-baseline.md`: drift, gaps, updates

## Highlights

- Ten software stack categories (data, business apps, APIs, agentic/MCP, ML, MLOps, frontend, infra, integration, developer tooling)
- Explicit monorepo / multi-category handling
- Handoff to **ci-cd-plumber** for real pipeline design (structure only at incubation)

## Canonical sources

- [SKILL.md](https://github.com/devopam/agent-skills/blob/main/skills/project-incubation/SKILL.md)
- [references/](https://github.com/devopam/agent-skills/tree/main/skills/project-incubation/references)
- [research/project-incubation/](https://github.com/devopam/agent-skills/tree/main/research/project-incubation)
