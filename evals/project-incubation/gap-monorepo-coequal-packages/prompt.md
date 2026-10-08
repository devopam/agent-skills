---
name: project-incubation-gap-monorepo-coequal-packages
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

New repo, structured as a monorepo with a pnpm workspace. It has
`apps/web` (a React SPA that only talks to our own `apps/api`), `apps/api`
(our own REST backend, owns the database), and `infra/` (Terraform for
the AWS resources both of those run on). All three ship on independent
schedules and are owned by different people on the team.

Help me set this repo up properly.

(Non-interactive run: you cannot ask follow-up questions. State your assumptions, then complete the skill's flow as far as it can go without user input, including the category you select for each package and your concrete recommendations.)
