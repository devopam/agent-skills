# ci-cd-plumber

Scaffolds production-grade CI/CD and audits existing pipelines with a domain
scorecard and severity-ordered findings.

**Use when:** setting up CI/CD, hardening pipelines, release automation, or
changelog / release-note hygiene.

## Modes

- **Inception** — green-field pipelines (GitHub Actions, GitLab CI, …)
- **Audit** — score existing workflows; baseline at `docs/ci-cd-baseline.md` when used that way

## Domains (summary)

Security & permissions, structure, supply chain & reproducibility, speed,
testing gates, artifacts & promotion, progressive delivery, observability,
release documentation, anti-patterns.

## Canonical sources

- [SKILL.md](https://github.com/devopam/agent-skills/blob/main/skills/ci-cd-plumber/SKILL.md)
- [references/](https://github.com/devopam/agent-skills/tree/main/skills/ci-cd-plumber/references)
- [evals/ci-cd-plumber/](https://github.com/devopam/agent-skills/tree/main/evals/ci-cd-plumber)
