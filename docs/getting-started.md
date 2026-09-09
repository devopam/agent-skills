# Getting started

## Prerequisites

- An [agentskills.io](https://agentskills.io/)-compliant agent client
- Optional: [Claude Code](https://docs.anthropic.com/en/docs/claude-code) for
  the bundled plugin manifest (`.claude-plugin/plugin.json`)

## Install options

### Point the agent at the repo

Clone or reference [github.com/devopam/agent-skills](https://github.com/devopam/agent-skills)
(or a release tag such as `v0.13.0`). The client discovers each skill from
`skills/<name>/SKILL.md` frontmatter and loads full instructions when a task
matches.

### Vendor a single skill

Copy `skills/<name>/` into your project's skills directory. Follow your
client's install instructions in the [client showcase](https://agentskills.io/clients).

### Claude Code plugin

This repository **is** a Claude Code plugin:

```bash
git clone https://github.com/devopam/agent-skills.git
cd agent-skills
claude plugin validate .
# when enrollment allows:
claude plugin eval . --ablation with-without --runs 1 --no-publish
```

Enable the plugin via Claude Code's local-plugin or marketplace flow against
this repo or tag `v0.13.0`.

## Invoking a skill

Ask the agent in natural language for work that matches a skill's
`description` (e.g. "incubate this new repo", "review this Python package",
"audit our GitHub Actions", "pre-submit check this PR", "review this Postgres
database with MCPg"). The agent should load `SKILL.md` and follow its phases.

## Source of truth

Documentation on this site is a **human-oriented overview**. Authoritative
skill behaviour lives in the repository:

- `skills/<name>/SKILL.md` — router and flow
- `skills/<name>/references/` — domain depth
- `research/<name>/` — research provenance
- `evals/<name>/` — hand-authored trust cases
