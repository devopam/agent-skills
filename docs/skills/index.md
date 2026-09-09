# Skills overview

Five portable skills ship in **0.13.0**. Each follows the Agent Skills
spec: `SKILL.md` with `name` / `description`, optional `references/` and
`assets/`.

| Skill | Full instructions on GitHub |
|-------|-----------------------------|
| [project-incubation](project-incubation.md) | [`SKILL.md`](https://github.com/devopam/agent-skills/blob/main/skills/project-incubation/SKILL.md) |
| [python-code-review](python-code-review.md) | [`SKILL.md`](https://github.com/devopam/agent-skills/blob/main/skills/python-code-review/SKILL.md) |
| [ci-cd-plumber](ci-cd-plumber.md) | [`SKILL.md`](https://github.com/devopam/agent-skills/blob/main/skills/ci-cd-plumber/SKILL.md) |
| [pr-review](pr-review.md) | [`SKILL.md`](https://github.com/devopam/agent-skills/blob/main/skills/pr-review/SKILL.md) |
| [postgresql-review](postgresql-review.md) | [`SKILL.md`](https://github.com/devopam/agent-skills/blob/main/skills/postgresql-review/SKILL.md) |

Skills are designed to be **host-agnostic**: plain-text Q&A, no required
host-specific slash commands (unless a skill documents an optional
integration such as MCPg tools).
