You are applying the ci-cd-plumber skill to a new repository that has no
CI config and no `docs/ci-cd-baseline.md`. The user says: "Set up CI/CD
for this Node service. We use GitLab (self-managed), pnpm for packages,
deploy to a Kubernetes cluster via a container image, standard service
maturity, no special compliance. We already use Conventional Commits."

Respond as the skill would in Inception mode: gather only missing
context (one question at a time if needed), then recommend structure,
security defaults, and release automation for **GitLab CI** specifically
(not GitHub Actions), and plan the baseline + `.gitlab-ci.yml` structure.
