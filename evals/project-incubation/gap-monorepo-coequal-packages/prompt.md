New repo, structured as a monorepo with a pnpm workspace. It has
`apps/web` (a React SPA that only talks to our own `apps/api`), `apps/api`
(our own REST backend, owns the database), and `infra/` (Terraform for
the AWS resources both of those run on). All three ship on independent
schedules and are owned by different people on the team.

Help me set this repo up properly.
