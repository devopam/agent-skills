# Baseline: Infrastructure & Platform Engineering — Architecture & Stack
Status: draft      Date: 2026-08-31

## Local precedent

Unlike Backend & API Services (no local example found) and closer in spirit to
Developer Tooling & Libraries' dual precedent, this category has a genuinely
rich, directly-inspectable local example — the richest of any category
researched so far — but it demonstrates only **half** of the category's own
scope, and that half/half split is itself the most important finding of this
pass.

**`/Users/devopammittra/GitHub/ubi-csr-tmf`** — read directly this pass,
`.github/workflows/*.yml`, `charts/*/Chart.yaml`, `charts/*/values*.yaml`,
`aws/container/docker-compose.yml`:

- **Real per-service Helm charts**: `charts/agents/`, `charts/ubi-backend/`,
  `charts/ubi-frontend/`, each a genuine `apiVersion: v2` chart (`Chart.yaml`
  + `values.yaml` + `values-dev.yaml` + a `templates/` directory with
  `*-deployment.yaml`, `*-service.yml`, `*-hpa.yml`, `*-sa.yaml`). A separate,
  sibling `ubi-csr-tmf-helm-charts/` directory also exists at the repo root
  but is **empty** (`git ls-files` shows it tracked, `ls -la` shows zero
  entries) — confirmed this pass by direct inspection, not present in the
  prior scouting pass's notes; most plausibly an orphaned leftover from the
  repo's own history (`git log` shows a "Restructure: Consolidate to
  root-level backend/frontend" commit that post-dates this directory's last
  content), worth naming as a real, honest example of infra-as-code
  reorganization leaving stale artifacts behind — the same "worth garbage
  collecting" concern that applies to any code repo, not unique to IaC.
- **Per-environment values-file separation, not Helm's `--namespace`
  parameterization alone**: `values.yaml` (prod) and `values-dev.yaml` exist
  side by side per chart, with concrete, meaningfully different values, not
  just cosmetic ones — e.g. `ubi-backend`'s prod `values.yaml` requests
  `memory: "3Gi"` / `cpu: "500m"` (limits `4Gi`/`800m`) versus dev's
  `memory: "3Gi"` / `cpu: "300m"` (limits `3Gi`/`500m`), and `namespace:
  csr-tmf-portal` vs `namespace: csr-tmf-portal-dev`. This is a real,
  concrete instance of the "environment separation via values files" pattern
  named in the In-scope Kubernetes-templating section below, not a
  hypothetical.
- **A full suite of GitHub Actions deploy workflows** — confirmed by direct
  read of `be-deploy-prod.yml`, `be-deploy-dev.yml`, `fe-deploy-prod.yml`,
  `agents-deploy-dev.yml`, plus `build-validation.yml`/`ci-cd.yml`:
  - **OIDC trusted-deployment, not long-lived AWS keys**: every deploy
    workflow declares `permissions: id-token: write` and calls
    `aws-actions/configure-aws-credentials@v4` with `role-to-assume:
    arn:aws:iam::025066239748:role/GitHubActionsTerraformRole` — the exact
    same short-lived-OIDC-credential shift documented across every package
    registry in the Developer Tooling & Libraries baseline's Sources
    (PyPI/npm/crates.io Trusted Publishing), here applied to cloud
    deployment rather than package publishing. **The role's own name —
    `GitHubActionsTerraformRole` — is a real, load-bearing clue**: it
    strongly implies this repo's CI/CD was originally scaffolded expecting
    Terraform-driven infrastructure provisioning (the role was presumably
    created *by* a Terraform run, elsewhere, that also wired up its own
    OIDC trust policy), even though no `.tf` file exists anywhere in the
    repo today — corroborating rather than contradicting this baseline's
    central finding that provisioning happens **out-of-band** from this
    repo, most plausibly in a separate, not-locally-present infrastructure
    repo.
  - **Build → ECR → EKS-via-Helm, in that order, every time**: every deploy
    workflow builds a Docker image (`docker buildx build`, with a registry
    cache: `--cache-from type=registry,...:buildcache`), pushes to ECR
    (`csr-tmf-portal/backend`, `csr-tmf-portal/agents`,
    `ubi/reg-gen/frontend`), then `aws eks update-kubeconfig --name
    ubi-coe-cluster --region ap-south-1` followed by `helm upgrade
    --install <RELEASE_NAME> charts/<chart> --namespace <NAMESPACE> --values
    charts/<chart>/values.yaml --set image=<uri> --wait --timeout 5m`, then
    `kubectl rollout status ... --timeout=5m`.
  - **Image tags are resolved from git, not hand-typed**: `git describe
    --tags --always` (falling back to `0.0.0-<commit-count>-<short-sha>` if
    no tags exist) computes a `vX.Y.Z`-shaped tag automatically, with an
    optional manual `workflow_dispatch` input override — real, working
    "auto-version from git" mechanics, not aspirational.
  - **The dev→prod promotion gate is real but implicit, not a written
    approval workflow**: dev deploy workflows trigger automatically
    (`on: push: branches: [develop]`, path-filtered to only the
    service that actually changed, e.g. `paths: ['aws/container/backend/**',
    'charts/ubi-backend/**', ...]`, with a `[skip deploy]` commit-message
    escape hatch and a `concurrency: group: backend-deploy-dev-...,
    cancel-in-progress: false` guard against overlapping dev deploys of the
    same branch); prod workflows are **`workflow_dispatch`-only** — no
    automatic trigger exists for production at all. Every job additionally
    declares `environment: name: production` (or `name: dev`) — GitHub's own
    Environments feature, which supports required-reviewer approval gates
    and environment-scoped secrets configured in the repository's own
    Settings UI, **not visible in the workflow YAML itself**; this pass
    could not confirm from the files alone whether a required-reviewer gate
    is actually configured on the `production` environment, which is a real
    limit on how deep "read the workflow files" can verify an approval
    process — worth naming as an open question rather than assumed either
    way.
  - **No rollback automation**: `.github/workflows/deployment-rollback.md`
    exists as a filename but is a genuinely **empty file (0 bytes)** —
    confirmed by direct `wc -l` — a real, honest gap: the repo has a
    placeholder for a rollback runbook/workflow that was never filled in,
    worth naming rather than glossing over.
  - **A `release: blue-green` label sits in `values.yaml` without any
    matching blue-green mechanism**: every one of the three charts' values
    files carries `labels: { release: blue-green }`, but nothing else in
    the chart (no second release track, no traffic-splitting Service/
    Ingress config, no Argo Rollouts/Flagger CRD) implements blue-green
    deployment — the workflow's own "scale to 2 replicas after rollout"
    step in `be-deploy-prod.yml` is a plain rolling update via
    `kubectl scale` + `kubectl rollout status`, not a blue-green cutover.
    This is worth naming precisely as a **label that names an aspiration,
    not an implemented pattern** — a useful, concrete cautionary example for
    the authored doc's progressive-delivery section: labeling something
    blue-green doesn't make it blue-green.
- **`aws/container/docker-compose.yml`** is a genuinely separate,
  local-development-only path: three services (`frontend`, `backend`,
  `agents`) on a shared bridge network, with `healthcheck:` blocks
  (`curl -f http://localhost:8000/health`, a Python urllib check for the
  agents service) gating `depends_on: condition: service_healthy`, bind
  mounts for hot-reload (`WATCHFILES_FORCE_POLLING`, `CHOKIDAR_USEPOLLING`),
  and an `${HOME}/.aws:...:ro` mount so local containers can assume the
  developer's own AWS credentials. This is real evidence for the authored
  doc's Kubernetes-vs-simpler-alternatives decision section: **the same
  repository deliberately runs two different orchestration models
  side by side for two different jobs** — Compose for inner-loop local dev
  (fast, disposable, no cluster needed) and Helm-on-EKS for anything
  actually deployed — rather than forcing Kubernetes onto the local
  developer experience too.
- **Confirmed absent, checked directly this pass**: no Terraform, Pulumi,
  CDK, or CloudFormation files anywhere in the repo
  (`find . -iname "*.tf" -o -iname "cdk.json" -o -iname "*cloudformation*"
  -o -iname "*.tfvars"` returns nothing). **This is the single most
  important framing fact for this whole baseline**: this repo is a strong,
  real worked example of **Kubernetes application deployment via CI +
  Helm**, but demonstrates **zero IaC for provisioning the infrastructure
  itself** — the EKS cluster (`ubi-coe-cluster`), the VPC, the ECR
  repositories, and the IAM role the workflows assume are all provisioned
  out-of-band from this repo, not declared as code within it. The
  authored doc must keep these as two distinct halves of the category
  ("deploying an app onto a cluster" vs. "provisioning the cluster/VPC/IAM
  that the app lands on") rather than blurring them — this repo is real
  evidence for only the first half.

**`/Users/devopammittra/GitHub/agent-skills`** (this repo) — checked
directly this pass: `.github/` contains only `ISSUE_TEMPLATE/`, no
`workflows/` directory at all, and there is no Dockerfile, Helm chart, or
IaC file anywhere in the tree — expected and unsurprising, since this repo
is a prompt-only Claude Code plugin with no deployment target of its own
(its own distribution model, git-hosted plugin marketplace rather than a
package registry, was already the subject of the Developer Tooling &
Libraries baseline). Noted briefly per this pass's instructions rather than
skipped, not because it adds anything new to this category.

## In scope

- **IaC tool selection: Terraform/OpenTofu vs. Pulumi vs. CloudFormation vs.
  AWS CDK — verified current licensing/adoption state, not assumed from
  training data** — impact: high — depth: table. This is the single most
  time-sensitive fact-check in the whole category, and training-data-only
  knowledge would be stale here in a load-bearing way:
  | Tool | Language model | State model | Multi-cloud | Current licensing/status (verified this pass) |
  |---|---|---|---|---|
  | **Terraform** | HCL (declarative DSL) | Own state file (local or remote backend) tracking a resource-to-real-world mapping | Yes, provider-plugin model across clouds | **Business Source License 1.1** since **10 August 2023** (confirmed by direct fetch of HashiCorp's own license FAQ) — not fully open-source; **IBM completed its $6.4B acquisition of HashiCorp on 27 February 2025** (search-corroborated across TechCrunch/IBM Newsroom/SiliconANGLE), so Terraform is now an IBM-owned product |
  | **OpenTofu** | HCL (same language, forked at Terraform 1.5.x, the last MPL-2.0 release) | Same state-file model as Terraform, drop-in compatible for most configs | Yes, same provider ecosystem | **MPL-2.0**, genuinely open source, governed by the **Linux Foundation** (confirmed by direct fetch of `opentofu.org/manifesto`); accepted into the **CNCF as a Sandbox project on 23 April 2025** under a licensing exception (CNCF normally requires Apache-2.0) — search-corroborated across multiple sources including CNCF's own project page. Diverged with its own features Terraform's OSS binary lacks: native state encryption, provider iteration with `for_each`, OCI registry support (search-corroborated, not independently re-verified per-feature) |
  | **Pulumi** | Real general-purpose languages (TypeScript, Python, Go, C#, Java) — "loops, functions, and unit tests, not a DSL" | Own state/checkpoint model — Pulumi Cloud (managed, default) or a self-managed "DIY" backend (S3/Azure Blob/GCS/Minio/Ceph/Postgres/local); confirmed by direct fetch of `pulumi.com/docs/iac/concepts/state-and-backends/`: unlike Terraform, "Pulumi state does not include your cloud credentials" — credentials stay local to the CLI's own runtime, not embedded in the state artifact | Yes, same provider-bridge model as Terraform (many Pulumi providers are themselves generated from Terraform providers) | Pulumi CLI/SDKs are **Apache-2.0** (confirmed via search of the `pulumi/pulumi` GitHub `LICENSE` file and Pulumi's own "Pulumi Loves Open Source" post: "does not and never will depend on BSL-licensed software"); **Pulumi Cloud** (managed state/secrets/RBAC/audit-log/policy) is the separate commercial product layered on top |
  | **AWS CloudFormation** | JSON/YAML declarative templates | No separate state file — AWS itself tracks the stack's resource mapping server-side; **native drift detection is a first-class AWS API** (confirmed by direct fetch of `docs.aws.amazon.com/.../detect-drift-stack.html`: `detect-stack-drift` → `describe-stack-drift-detection-status` → `describe-stack-resource-drifts`, returning a per-resource `IN_SYNC`/`MODIFIED`/`DELETED`/`NOT_CHECKED` status and, for `MODIFIED` resources, an exact expected-vs-actual property diff) | **No** — AWS-only by design | AWS-proprietary, free to use (billed only for the resources it provisions), not a separate licensable product |
  | **AWS CDK** | Real languages (TypeScript, Python, Java, Go, C#) compiling down to CloudFormation templates | Delegates entirely to CloudFormation's own stack state — "your state is the CloudFormation stack" (search-corroborated framing, consistent with CDK's documented synth-to-CloudFormation model) | **No** — AWS-only, same as CloudFormation | AWS-proprietary, open-source CDK library (Apache-2.0) generating closed-model AWS-only templates |
  | **CDKTF** (CDK for Terraform) | Real languages, compiling to Terraform's own JSON configuration format | Terraform's own state model (inherits Terraform's, not a new one) | Yes, inherits Terraform's provider ecosystem | **Deprecated by HashiCorp effective 10 December 2025** (search-corroborated across multiple sources including a Lobsters discussion of the announcement and HashiCorp's own upgrade-guide pages still being live but the project itself archived read-only on GitHub) — HashiCorp's stated reason: "did not find product-market fit at scale," recommending migration back to plain Terraform/HCL. This closes what several 2026 comparison pieces called the "real-language-syntax-with-Terraform's-provider-ecosystem" middle ground between Pulumi and Terraform — worth flagging as a genuinely dead option now, not a live third choice, despite still appearing in older comparison content |
  **Practical default for a new project, stated per user decision
  (post-Checkpoint-F review) as a named default rather than a fully
  neutral list — but with Terraform kept a genuinely first-class, not
  merely tolerated, option**: HCL-shaped IaC remains the most
  broadly-applicable starting point — largest provider/module ecosystem,
  HCL as what multiple 2026 sources independently called "the industry's
  shared vocabulary" (search-corroborated framing, not independently
  verified as a measured fact) — and **within that HCL choice, OpenTofu is
  the named default for a genuinely new project with no existing
  HCP-Terraform/Sentinel investment**, on the concrete, checkable
  licensing/governance facts above (MPL-2.0, Linux-Foundation-governed,
  CNCF Sandbox, real feature additions Terraform's own OSS binary lacks),
  not a popularity judgment. **Terraform remains the right, fully
  legitimate choice — not a lesser fallback — for any of three concrete,
  real situations**: a team already standardized on HCP Terraform/
  Terraform Enterprise and Sentinel (migrating that whole run-pipeline
  investment to OpenTofu is a real, non-trivial project of its own, not a
  free win); an existing large Terraform estate, since most Terraform
  configuration runs on OpenTofu unchanged (search-corroborated: "migration
  usually just swapping the terraform binary for tofu," Boeing/Capital One/
  AMD named as production OpenTofu adopters in the same source, not
  independently confirmed by those companies' own statements this pass) but
  that "usually" is still a real migration decision a team gets to make
  deliberately, not a default the authored doc should make for them; and a
  team that specifically wants the largest possible pool of existing
  tutorials/Stack-Overflow-era reference material and provider-compatibility
  certainty, since Terraform's absolute installed base and registry size
  are still larger than OpenTofu's in absolute terms (OpenTofu's own
  3,900+ providers/23,600+ modules figure is large but wasn't independently
  compared against Terraform's own registry counts this pass). Reach for
  **Pulumi** specifically when the team wants infrastructure code
  reviewed, tested, and abstracted with the same tooling (unit tests, loops,
  shared functions, package imports) as its application code, and is willing
  to trade HCL's ubiquity for that. Reach for **CloudFormation/CDK**
  specifically when the project is deliberately, permanently AWS-only and
  wants zero separate state-backend setup (drift detection and state
  tracking are both a managed AWS service call away, not infrastructure the
  project has to stand up itself). **CDKTF is no longer a live choice** for
  a new project as of this pass. **Notably, this same BSL-vs-open-fork
  split recurs one layer over**: HashiCorp Vault — the dedicated
  secrets-management server named in the Secrets Management section below
  — underwent the **identical** BSL 1.1/IBM-licensor relicensing as
  Terraform itself (confirmed by direct fetch of `hashicorp/vault`'s own
  `LICENSE` file: "Licensor: International Business Machines Corporation
  (IBM)... Licensed Work: Vault Version 1.15.0 or later"), with **OpenBao**
  as its own Linux-Foundation-governed, MPL-2.0 open fork — the same
  decision shape (default-to-the-open-fork-for-new-work,
  Vault-remains-legitimate-for-an-existing-HCP-investment) applies there
  too, not a one-off Terraform-specific situation.

- **State management — the category's single most distinctive mechanical
  concern** — impact: high — depth: section. **State locking**: Terraform
  automatically locks state during any operation that could write it
  (confirmed by direct fetch of `developer.hashicorp.com/terraform/language/
  state/locking`: "State locking happens automatically on all operations
  that could write state... Not all backends support locking"), preventing
  the classic two-concurrent-`apply`s-corrupt-the-state-file failure mode; a
  stuck lock is recoverable via `force-unlock` with an explicit warning
  that unlocking someone else's active lock "could cause multiple writers."
  **The canonical S3+DynamoDB-lock pattern is now legacy, not current best
  practice**: Terraform 1.10 (experimental) and 1.11+ (production-ready)
  introduced **native S3 state locking via a lock file stored directly in
  the S3 bucket** (`use_lockfile = true` on the S3 backend block) — search-
  corroborated across multiple independent practitioner write-ups
  describing the same mechanism and citing the same version numbers;
  Terraform 1.11 additionally marked the old `dynamodb_table` backend
  argument itself as deprecated. **This is a genuinely time-sensitive fact
  the authored doc should get right**: any reference material describing
  "S3 backend + separate DynamoDB lock table" as the current
  recommendation is describing the *previous* generation of the pattern,
  not today's; the DynamoDB-lock-table shape remains supported for
  backward compatibility but is no longer the recommended new setup.
  **HCP Terraform / Terraform Cloud** offers the alternative to
  self-managing any of this: state storage, locking, and encryption at
  rest are handled by the managed service, at the cost of coupling to
  HashiCorp's own SaaS. **Pulumi's own state model** differs in a
  specific, checkable way from Terraform's: Pulumi's managed Pulumi Cloud
  backend uses "a transactional snapshot called a checkpoint" for
  crash-consistency (confirmed by direct fetch of Pulumi's own
  state-and-backends doc) and — a genuinely distinctive detail — **Pulumi
  state never contains cloud credentials at all** (they stay local to
  wherever the CLI runs), whereas Terraform's plaintext state can and
  does capture secret values defined in configuration. **Secrets exposure
  is a real, documented Terraform risk, not a hypothetical**: Terraform's
  own docs (confirmed by direct fetch of
  `developer.hashicorp.com/terraform/language/state/sensitive-data`) state
  plainly that local state "is a plaintext file, which includes any secret
  values you defined in your configuration," and that even values marked
  `sensitive` in configuration are still stored unencrypted "in both state
  and plan files" — the documented mitigation stack is remote storage +
  backend-native encryption at rest (S3's `encrypt` option, GCS
  customer-managed keys, HCP Terraform's automatic encryption) + access
  controls + audit logging, not a single silver-bullet fix. **Import/
  drift-reconciliation**: `terraform import` (or the newer configuration-
  driven `import` block) brings an out-of-band-created real resource under
  Terraform's management by writing a matching state entry without
  recreating the resource — the mechanical inverse of drift, and the
  standard remediation path once drift is detected and the decision is made
  to adopt the drifted-in-place resource rather than force it back to the
  declared state.

- **Drift detection — what it concretely means and current tooling beyond a
  manual `plan`** — impact: high — depth: section. Concretely: a `plan`
  (Terraform/OpenTofu/Pulumi `preview`) or `detect-stack-drift`
  (CloudFormation) run showing an unexpected difference between declared
  configuration and the real, live state of a resource — "unexpected"
  being the operative word, since an *expected* diff is just a pending
  change waiting for `apply`. **Terraform's own scriptable primitive**:
  `terraform plan -detailed-exitcode` (confirmed by direct fetch of
  HashiCorp's own CLI docs) returns exit code `0` for "no changes," `1` for
  an error, and `2` for "changes present" — the mechanism a cron job or CI
  schedule uses to alert on drift without needing to parse plan output at
  all; search-corroborated guidance suggests hourly scheduling for
  drift-sensitive production infrastructure, though that specific cadence
  number traces to secondary practitioner sources, not a HashiCorp-stated
  recommendation, and is named here only as a directional signal, not a
  verified threshold. **Managed continuous drift detection**: HCP
  Terraform/Terraform Enterprise run scheduled "health assessments" that
  execute `plan` on a defined interval and surface drift without applying
  anything (search-corroborated); third-party platforms (Spacelift,
  env0, and dedicated estate-wide tools like driftctl/Firefly that also
  detect *unmanaged* resources never declared in any IaC config at all) are
  named here only as the category of tool that exists, per this doc's
  own convention of leaving specific vendor comparison to `libraries.md`.
  **CloudFormation's native equivalent** is a first-class AWS API, not a
  third-party add-on: `detect-stack-drift` (async, polled via
  `describe-stack-drift-detection-status`) followed by
  `describe-stack-resource-drifts`, returning a per-resource
  `IN_SYNC`/`MODIFIED`/`DELETED`/`NOT_CHECKED` status and, for `MODIFIED`
  resources, the exact property-level expected-vs-actual diff (confirmed
  by direct fetch of AWS's own documentation, including a real worked
  example showing a drifted SQS queue's `DelaySeconds` and
  `RedrivePolicy.maxReceiveCount` properties) — a meaningfully more
  first-class, no-extra-tooling-required drift story than Terraform's,
  which requires either a scheduled `plan` job or a paid managed-service
  feature to get the same continuous coverage.

- **Blast-radius limiting — workspace/stack separation and policy-as-code
  gates before apply** — impact: high — depth: section. **Why a single
  monolithic state file for an entire org is a real, named anti-pattern,
  not a slippery-slope exaggeration**: search-corroborated guidance
  converges on "a typo in a variable could destroy production resources
  when you meant to change something in dev" as the concrete failure mode
  a shared state file enables, and the practical remediation is
  environment- and component-scoped state isolation — each environment
  (dev/staging/prod) and, ideally, each independently-deployable component
  or region within an environment gets its own state file, so a mistaken
  or malicious change in one blast radius cannot reach into another merely
  by sharing a state backend. **Workspaces vs. separate directories/
  backends, as a real, checkable trade-off, not a purity contest**:
  Terraform's own CLI workspaces (`terraform workspace new/select`)
  optimize for code reuse across environments sharing the same
  configuration; separate directories (or separate root modules/backends
  entirely) optimize for isolation and independent blast radius —
  search-corroborated guidance recommends directory-based separation for
  long-lived environments (dev/staging/prod, especially under compliance
  requirements) and reserving CLI workspaces for short-lived, ephemeral
  contexts (a feature-branch preview environment, a temporary test stack).
  **Policy-as-code gates before `apply`**: **HashiCorp Sentinel** is the
  HCP Terraform/Terraform Enterprise-native policy engine — proprietary,
  runs only inside HashiCorp's own managed service, and (a specific,
  checkable limitation search-corroborated across multiple 2026 comparison
  sources) **does not run against OpenTofu at all**. **Open Policy Agent
  (OPA)**, typically invoked via **Conftest** as a CLI wrapper, is the
  portable, vendor-neutral alternative: the mechanism (confirmed by direct
  fetch of OPA's own Terraform integration doc) is `terraform show -json`
  converting the binary plan to JSON, then `opa exec` evaluating Rego
  policies against that JSON in CI — before `apply` runs, not after. OPA's
  own documented example is directly a **blast-radius-limiting policy**:
  assigning weighted risk scores per operation-type
  (`{"aws_autoscaling_group": {"delete": 100, "create": 10, "modify": 1}}`)
  and rejecting a plan whose summed risk score crosses a threshold — a
  concrete, load-bearing mechanic worth naming in the authored doc
  verbatim, alongside OPA's documented limitation that "some information
  may not be available at plan time" for unknown values, dynamic blocks,
  and function calls resolved only during `apply`. Practical default for
  the authored doc: a policy-as-code gate belongs in CI before `apply` runs
  for any environment with real production blast radius, using OPA/Conftest
  as the portable default (works identically on Terraform or OpenTofu,
  and generalizes to Kubernetes admission control too — see the
  cross-cutting specialization note below) and reserving Sentinel only for
  teams already fully committed to HCP Terraform's managed platform.

- **Secrets management — added per user request (post-Checkpoint-F
  review); a real, distinct axis this pass had scoped out, now brought in
  given how directly it touches this doc's own State Management and
  blast-radius sections** — impact: high — depth: section. The
  architectural question this section answers: **where does a secret
  live at rest, and by what mechanism does it reach a running workload
  without ever landing in git history or IaC state as plaintext** — a
  distinct concern from *access control* (who is allowed to read a
  secret once retrieved, already the IAM/RBAC concern threaded through
  the rest of this doc). Four real, currently-distinct patterns: **(1)
  A dedicated secrets-management server** (HashiCorp Vault or its
  Linux-Foundation-governed open fork, named in `libraries.md`) — dynamic,
  short-lived, per-request credential issuance rather than a static
  secret sitting in a vault forever; the most capable but also the most
  operationally heavy option, since it's itself a stateful service a team
  now has to run and secure. **(2) Cloud-native secret managers** (AWS
  Secrets Manager, Azure Key Vault, GCP Secret Manager) — the
  zero-extra-infrastructure option for a team already committed to one
  cloud, at the cost of that same single-cloud lock-in this doc's IaC
  section already names for CloudFormation/CDK. **(3) GitOps-native
  encrypted-file patterns** (SOPS-style) — a secret is encrypted with a
  KMS/PGP/age key and the *encrypted* file is committed straight into git
  alongside the rest of the IaC/config it belongs to, keeping the GitOps
  "everything is declared in version control" property (the four
  OpenGitOps principles this doc's CI/CD section already cites) intact
  for secrets too, at the cost of key-rotation now needing a
  re-encrypt-and-recommit step rather than an in-place server-side
  update. **(4) Kubernetes-native secret injection/sync controllers**
  (External Secrets Operator, Sealed Secrets) — a cluster-side controller
  either syncs a `Secret` object live from an external system (Vault,
  a cloud secret manager) or one-way-decrypts a git-committed encrypted
  blob into a real `Secret` object at apply time; this is the mechanism
  that connects patterns (1)/(2)/(3) to an actual running Kubernetes
  workload, not a fifth competing pattern. **The direct, load-bearing
  connection to this doc's own State Management section**: Terraform's
  documented plaintext-state risk (a `sensitive`-marked value is still
  stored unencrypted in state and plan files) means that provisioning a
  secret's *initial* value via Terraform/OpenTofu at all reintroduces the
  exact exposure this section's patterns are trying to avoid — the
  practical default worth naming explicitly: use IaC to provision the
  *secrets-management resource itself* (a Vault instance, a Secrets
  Manager entry, an IAM role trust policy) but not to carry the *secret
  value* through IaC state, and reach for pattern (3) or (4) specifically
  for a GitOps-driven cluster since they're the only two patterns that
  preserve GitOps's own declarative-everything-in-git property without
  ever putting a plaintext secret into that git history.

- **Idempotency for IaC and Kubernetes — the same word meaning something
  concretely adjacent-but-distinct from an API/library context** — impact:
  high — depth: paragraph. The backend-api-services baseline's idempotency
  concern (a client-generated `Idempotency-Key` guaranteeing a retried
  mutating HTTP request doesn't double-execute) is about a **single
  request** not double-applying its side effect. This category's
  idempotency is about a **whole declared configuration being safely
  re-appliable an arbitrary number of times**: re-running `terraform apply`
  (or `kubectl apply`, or a Helm `upgrade --install`) against an unchanged
  configuration and an unchanged real environment should produce **zero**
  changes, not a repeated action — this is precisely what a clean
  `-detailed-exitcode` of `0` (no drift) demonstrates. Kubernetes makes
  this a formal, named architectural property rather than an incidental
  nice-to-have: `kubectl apply`'s own documentation (confirmed by direct
  fetch of `kubernetes.io/docs/concepts/overview/working-with-objects/
  object-management/`) describes create/update/delete operations being
  "automatically detected per-object," using a **patch**, not a
  **replace**, API operation specifically so the same manifest can be
  applied repeatedly and safely; the broader controller/reconciliation-loop
  pattern underneath every Kubernetes controller (search-corroborated: a
  controller "continuously observes actual system state and works to make
  it match a declarative desired state") is explicitly described in
  Kubernetes-ecosystem sources as needing to be idempotent — "running the
  same reconciliation multiple times with the same input must produce the
  same result without side effects." The practical takeaway for the
  authored doc: idempotency here is a property of **the whole
  apply-and-reconcile loop**, verified by "did this run change anything it
  shouldn't have," not a property of one individual mutating call.

- **Kubernetes/container orchestration — a decision rule, not a default**
  — impact: high — depth: table. The task framing explicitly asked for a
  decision-rule section rather than "K8s is the default," and this pass's
  search results (several from SEO-aggregator "2026 guide" sites, the same
  category of source the backend-api-services baseline flagged and
  excluded specific numbers from) converged on a consistent *qualitative*
  shape even though their specific numeric thresholds (a stated "5
  services," "8 services," "10+ services" line) are exactly the kind of
  unverifiable, no-primary-source precision this repo's research standard
  excludes — named here as directional signals only, not verified facts:
  | Signal pointing toward... | A single VM + Docker Compose | A managed container platform (ECS/Fargate, Cloud Run, Fly.io) | Kubernetes |
  |---|---|---|---|
  | Team size / K8s expertise | Small team, no dedicated platform/ops role | Small-to-mid team wanting less operational surface than K8s | A team with (or budgeting for) dedicated platform engineering ownership |
  | Service count / topology | A handful of services, one deployable unit conceptually | Several independently-deployable services, still single-cloud | Enough services/teams that per-service autonomy and a shared platform layer pay for themselves |
  | Cloud commitment | Irrelevant — runs anywhere with Docker | Deliberately single-cloud (ECS/Cloud Run are provider-specific managed services) | Cloud-portable by design — the same manifests target any conformant cluster |
  | Scaling/traffic shape | Fixed, predictable load; vertical scaling of the one VM is enough | Elastic, request-driven, willing to trade fine-grained control for near-zero ops (Cloud Run's scale-to-zero is the sharpest example) | Workloads needing fine-grained per-pod autoscaling, custom scheduling constraints (node affinity/taints), or a rich ecosystem of K8s-native operators |
  | Operational cost being traded | Near-zero — one server to patch/monitor | Low — no control plane to manage, but tied to that provider's own deployment model | Real and ongoing — cluster upgrades, node lifecycle, RBAC, networking (CNI), ingress, and the OPA/policy layer above all become the team's job unless a managed offering (EKS/GKE/AKS) absorbs some of it |
  This repo's own local precedent (`ubi-csr-tmf`) is itself evidence that
  these aren't mutually exclusive across a project's lifecycle: the same
  codebase runs Compose locally (inner-loop dev) and EKS-via-Helm in
  deployed environments (dev/prod) — "which orchestration model" can be
  answered differently for local development than for what actually
  serves traffic, without that being an inconsistency to resolve.
  **Practical default for a new project without an existing driving
  signal**: start with the simplest deployment target that fits the
  team's actual current service count and cloud commitment (often Compose
  on a single VM, or a managed container platform once more than one
  service exists) and move to Kubernetes only once a real, present
  multi-service/multi-team/cloud-portability constraint appears — the same
  "monolith-first" caution the cross-cutting `architecture-templates.md`
  doc already applies to microservices generalizes cleanly to
  orchestration-platform choice.

- **Kubernetes templating-layer choice: Helm vs. Kustomize vs. raw
  manifests** — impact: med — depth: paragraph, at architecture depth
  only (specific tool versions/comparison tables belong to `libraries.md`).
  **Raw manifests** are viable only for a genuinely tiny, rarely-changing
  set of resources with no cross-environment variation to manage. **Helm**
  packages an application (or a dependency like Postgres/Redis/an ingress
  controller) as a versioned, installable/upgradable **release** with a
  real templating language and a documented values-schema contract — the
  natural choice when either consuming third-party charts (the
  Prometheus/Grafana/cert-manager/ingress-controller ecosystem is
  overwhelmingly Helm-first) or when an application's own deployment has
  real lifecycle concerns (upgrade/rollback, subchart dependencies) beyond
  "apply these YAML files." **Kustomize** takes plain, valid, un-templated
  YAML and layers environment-specific **overlays/patches** on top with no
  templating language at all — built directly into `kubectl`
  (`kubectl apply -k`), which keeps the base manifests themselves fully
  readable and valid on their own. This repo's own local precedent uses
  Helm exclusively (every deploy workflow calls `helm upgrade --install`,
  with a distinct `values-dev.yaml`/`values.yaml` per chart standing in for
  what a Kustomize-based setup would instead express as environment
  overlays) — a real, single-tool-choice data point, not a comparison, but
  worth naming as evidence Helm-plus-per-environment-values-files is a
  genuinely viable, currently-deployed pattern, not just a textbook
  recommendation. Practical default: Helm for anything consuming
  third-party charts or needing real release lifecycle management; a
  Kustomize overlay-per-environment approach for an internal app whose
  only cross-environment differences are the kind of thing this repo's own
  `values.yaml`/`values-dev.yaml` pair already shows (replica count,
  resource limits, namespace) and where the team would rather avoid a
  templating language entirely. The two compose rather than compete in
  practice (search-corroborated: "Helm for third-party applications... and
  Kustomize for your own applications" as one commonly-cited hybrid
  pattern), though this repo's own precedent shows Helm-only is also a
  fully viable single-tool choice.

- **CI/CD at the platform-engineering layer — distinct from ordinary
  app-repo CI** — impact: high — depth: section. Three concerns this
  category adds on top of "a repo has a CI pipeline," none of them about
  running one app's own tests: **shared/reusable workflow patterns** — a
  platform team standardizes CI/CD once and every app repo consumes it,
  rather than each repo hand-rolling its own deploy YAML. GitHub Actions'
  own mechanism (confirmed by direct fetch of
  `docs.github.com/en/actions/using-workflows/reusing-workflows`): a
  workflow declaring `on: workflow_call` becomes callable from another
  workflow via `uses:`, with typed `with:`/`secrets:` inputs and job-level
  `outputs:` flowing back to the caller — a real platform-engineering
  primitive (update the deploy logic once, centrally, and every consuming
  repo picks it up), with two documented, concrete limits worth naming: a
  maximum of **ten** levels of nested reusable workflows (no cycles
  permitted), and secrets propagate only through the direct call chain — a
  workflow two levels deep only receives what the immediately-calling
  workflow explicitly re-passed, not everything the original caller had.
  This repo's own local precedent does **not** yet use this mechanism —
  `ubi-csr-tmf`'s `be-deploy-dev.yml`/`be-deploy-prod.yml`/
  `agents-deploy-dev.yml` are near-duplicates of each other (same
  build-image/configure-credentials/helm-upgrade shape, different env
  values) rather than one shared reusable workflow parameterized per
  service — a real, named opportunity for consolidation, not a
  hypothetical one. **Environment-promotion gates, matching this repo's
  own real dev/prod split**: this repo's own workflows demonstrate the
  concrete shape — automatic-on-push-to-`develop` for dev (path-filtered
  per service), manual-`workflow_dispatch`-only for prod, both scoped to a
  named GitHub Environment (`dev`/`production`) that *can* carry a
  required-reviewer approval gate (configured outside the YAML, in
  repository Settings) — this is a real, working instance of the
  "automated-for-lower-environments, gated-for-production" promotion
  pattern the category calls for, even though this pass could not confirm
  whether the reviewer gate is actually turned on for this specific repo's
  `production` environment (see Open Questions). **Progressive-delivery
  patterns, at a conceptual level** (specific controller/tool names belong
  to `libraries.md`): **canary** — a new version receives a small,
  gradually-increasing percentage of production traffic while a metrics
  analysis step decides whether to keep shifting traffic, hold, or abort
  and roll back automatically; **blue-green** — two complete environments
  (the currently-live "blue" and the new "green") run simultaneously, the
  new one is validated against real traffic-shaped smoke/integration
  checks, then traffic is cut over all at once. Both patterns are
  formalized as Kubernetes-native **Custom Resources** by CNCF-ecosystem
  controllers (**Flagger**, part of the Flux family of GitOps tools — **a
  correction, follow-up pass 2026-08-31**: direct fetch of CNCF's own
  `cncf.io/projects/` listing shows only **Flux** itself carrying an
  independent Graduated status; Flagger appears solely as a Flux-family
  subproject with no separately-listed maturity level of its own, so the
  authored doc should credit Flagger's maturity signal through Flux's
  graduation rather than claim Flagger is independently CNCF Graduated —
  and **Argo Rollouts**, which replaces the standard
  `Deployment` object with a `Rollout` CRD supporting step-based traffic
  weights, pauses, and automated analysis-driven promotion/abort) — named
  here as the concept anchor, not a recommendation between the two
  specific tools, which is `libraries.md`'s job. This repo's own
  `release: blue-green` Helm label (see Local Precedent above) is a
  concrete, real cautionary example worth carrying into the authored doc:
  a label naming a pattern is not the same as implementing it — the
  workflow underneath is a plain rolling `kubectl scale` step, with no
  actual traffic-splitting or dual-environment mechanism present.

- **Internal developer platforms (IDPs) — "platform as a product," and how
  it connects without duplicating the Developer Tooling & Libraries
  module-boundary framing** — impact: high — depth: section. Platform
  engineering (confirmed by direct fetch of `platformengineering.org`'s own
  definitional post) is "the discipline of designing and building platforms
  that enable self-service capabilities for teams... to automate the
  recurring aspects of knowledge work"; an IDP is the concrete artifact —
  "a set of paved paths that give developers self-service access to
  everything they need — environments, deployments, security scans —
  without tickets or tribal knowledge." **"Platform as a product"**
  specifically means treating the internal platform with the same
  discipline as an externally-sold product: driven by the platform's own
  users' feedback rather than technology trends, requiring ongoing
  maintenance and iteration rather than being a one-time build, and framed
  as "the sum of paths enabled by a set of capabilities, exposed through
  interfaces" rather than a single dashboard or tool. **The concrete
  connection to this category's other sections, stated explicitly**: an
  IDP is the self-service layer sitting *on top of* everything else in
  this doc — Terraform/Pulumi modules, Helm charts, CI/CD reusable
  workflows, policy-as-code gates — so an application team requests "a new
  service" or "a new environment" through a paved-path interface (a
  service catalog, a golden-path template, a self-service portal) instead
  of hand-writing its own Terraform module or Helm chart from scratch.
  **How this differs from, and connects to, Developer Tooling &
  Libraries' module/plugin-boundary framing**: that baseline's core
  architectural concern was "which internal module is stable public
  surface vs. a freely-changeable implementation detail" for a *library*
  consumed by other developers' code; an IDP applies the identical
  underlying idea — a stable, deliberately-designed interface hiding
  changeable implementation detail — to *infrastructure* consumed by other
  developers' deploy pipelines rather than to a function/class API. The
  paved path (e.g. "click a button, get a new service scaffolded with its
  own Helm chart, CI workflow, and monitoring dashboards already wired up")
  is this category's version of a well-designed public API surface; the
  Terraform modules/Helm charts/CI templates underneath it are this
  category's version of swappable implementation detail. Specific IDP
  product names/tooling (a service-catalog/portal product, specific
  golden-path-scaffolding tools) belong to `libraries.md`, not here — this
  section stays at the "what the term means and why it matters
  architecturally" depth the task specified.

- **How this category specializes the cross-cutting
  `architecture-templates.md` pattern catalog** — impact: high — depth:
  section. That doc's gateway-vs-mesh framing ("mesh only past a
  service-count/maturity threshold most early projects don't cross") and
  its explicit scoping-out of "container-orchestration platform selection
  (Kubernetes vs. ECS vs. Nomad specifics)... more naturally belongs with
  Backend & API Services or a future deployment-focused doc" both point
  directly at this category as the place that "future deployment-focused
  doc" actually is — this baseline's Kubernetes-decision-rule section
  above is that promised follow-through, not new scope invented here.
  **Service mesh** (mTLS rotation, retry/traffic-shifting configuration at
  the mesh layer) is the one cross-cutting concern this category is the
  correct home for going *past* the cross-cutting doc's own explicitly-
  deferred boundary, precisely because mesh adoption is itself a
  platform-engineering decision (a shared, centrally-operated layer other
  teams' services opt into) rather than a single-service architectural
  choice — though this pass did not do the deep mesh-configuration
  research the cross-cutting doc already flagged as out of scope for
  itself; the authored doc should name mesh adoption's fit signal
  (multiple services, genuine east-west traffic between them, a team
  willing to operate the mesh control plane) without re-deriving mesh
  internals from scratch. **Multi-region/multi-cluster topology** is
  similarly this category's genuine home: search-corroborated framing
  describes the primary drivers as availability posture (active-active vs.
  active-passive), disaster-recovery targets (RPO/RTO), geographic
  latency, and compliance/data-residency, with a shared management/policy
  layer (RBAC, network policy, admission control, fleet-wide observability)
  sitting above independently-schedulable per-region/per-cloud clusters —
  named here as the concept shape rather than a specific vendor's
  multi-cluster product, which belongs in `libraries.md` if named at all.
  **Infra-as-a-deployment-target** is the framing this category adds that
  no other category needs: every other stack baseline treats "where does
  this run" as a settled backdrop assumption; this category is the one
  place the deployment target itself (the cluster, the VPC, the IAM
  boundary) is the thing being architected, provisioned, and versioned —
  which is exactly why IaC state management, drift, and blast-radius
  limiting are this category's own distinctive concerns rather than
  variations on concerns already covered elsewhere.

## Explicitly out of scope

- Specific IaC/orchestration/CI-platform tool names, their exact license
  text, pricing tiers, and comparative maintenance-signal numbers (stars,
  downloads, module-registry counts) — belongs entirely to the companion
  `libraries.md` baseline being produced in parallel. This doc names a
  tool only where the tool's own behavior *is* the architectural fact
  being described (e.g. CloudFormation's native `detect-stack-drift` API,
  or Sentinel's HCP-Terraform-only lock-in) — illustrative anchors for a
  pattern, not this doc encroaching on `libraries.md`'s comparative-table
  job.
- Deep service-mesh configuration mechanics (mTLS certificate rotation
  internals, specific traffic-shifting CRD syntax) — the cross-cutting
  `architecture-templates.md` doc already scoped this out for itself, and
  this doc only names *where* mesh adoption belongs as a decision, not how
  to configure one; a dedicated deep-dive would need its own research pass
  if this category's authored doc later needs one.
- Kubernetes cluster security hardening in depth (Pod Security Standards,
  network-policy authoring, RBAC design patterns) — a real, adjacent
  concern this pass did not research; flagged as a gap rather than
  silently covered by the drift/blast-radius sections above, which
  address a different kind of risk (unintended infra change, not
  intended-but-insecure infra configuration).
- Deep secret-engine internals (Vault's dynamic-secret-backend mechanics,
  KMS envelope-encryption implementation details) beyond the architectural
  concept-level treatment now in the Secrets Management section below —
  the cross-cutting `architecture-templates.md` doc already names OWASP's
  Secrets Management Cheat Sheet as the canonical secrets-lifecycle
  source; this doc doesn't re-derive that.
- Observability/monitoring stack selection (metrics/logging/tracing
  platform choice) for infrastructure itself — belongs to whichever
  category ends up owning cross-cutting observability concerns generally
  (the Scalability & Resilience domain of `python-code-review`, or a
  future cross-cutting doc), not duplicated here even though CI/CD
  promotion gates and progressive delivery both depend on metrics
  existing.
- Cost modeling / cloud pricing comparisons (managed Kubernetes control
  plane pricing, HCP Terraform seat pricing, egress costs of a multi-
  region topology) — same no-pricing convention as every other baseline
  in this repo.
- On-prem/air-gapped IaC and deployment constraints — named in the
  cross-cutting `architecture-templates.md` doc's own Open Questions as a
  real gap it didn't find a strong primary source for either; this pass
  didn't independently research it, so it stays an open gap rather than a
  covered concern.
- ML/model-serving-specific platform concerns (model registries, GPU
  scheduling, canary rollouts *for models* specifically as opposed to
  services generally) — belongs to the still-pending MLOps / ML Platform
  Engineering roadmap category, which the roadmap doc explicitly notes may
  end up merging with this one once real content exists for both; this
  pass does not pre-empt that judgment call.

## Sources

- https://www.hashicorp.com/en/license-faq — direct fetch: confirms
  Terraform's **Business Source License 1.1**, effective **10 August
  2023**, usage-limitation framing ("competitive offerings" restriction);
  does not itself mention the IBM acquisition — retrieved 2026-08-31
- IBM/HashiCorp acquisition close — search-corroborated across IBM's own
  Newsroom press release, TechCrunch, and SiliconANGLE (not independently
  direct-fetched this pass, IBM Newsroom URL returned in search results but
  not opened): confirms close on **27 February 2025**, $6.4B / $35-per-share
  — retrieved 2026-08-31
- https://opentofu.org/manifesto/ — direct fetch: confirms OpenTofu's
  MPL-2.0 license, Linux Foundation governance, the 10 August 2023 BUSL
  change as the fork's stated trigger, and the 25 August 2023 public-fork
  date — retrieved 2026-08-31
- OpenTofu's CNCF Sandbox acceptance — search-corroborated (the direct
  CNCF announcement URL guessed this pass, `cncf.io/announcements/2025/
  04/09/...`, returned HTTP 404 and was **not** successfully direct-fetched
  — a real tooling/URL-guessing miss, not a suppressed source): multiple
  independent secondary sources (a Medium write-up, Palark's CNCF-Sandbox-
  arrivals roundup, TheNewStack) agree on **23 April 2025**, TOC vote,
  Sandbox maturity level, and a licensing exception since OpenTofu's
  MPL-2.0 differs from CNCF's normal Apache-2.0 requirement — retrieved
  2026-08-31
- https://www.pulumi.com/docs/iac/concepts/state-and-backends/ — direct
  fetch: confirms Pulumi Cloud (managed, default) vs. self-managed "DIY"
  backend options (S3/Azure Blob/GCS/Minio/Ceph/Postgres/local), the
  "state does not include your cloud credentials" claim, and the
  transactional-checkpoint state-snapshot model — retrieved 2026-08-31
- Pulumi CLI/SDK licensing — search-corroborated (GitHub `pulumi/pulumi`
  LICENSE file listing, Pulumi's own "Pulumi Loves Open Source" blog post
  quoted directly: "does not and never will depend on BSL-licensed
  software") — retrieved 2026-08-31, LICENSE file itself not independently
  opened this pass
- https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/detect-drift-stack.html
  — direct fetch: full native drift-detection API mechanics
  (`detect-stack-drift`/`describe-stack-drift-detection-status`/
  `describe-stack-resource-drifts`), per-resource
  IN_SYNC/MODIFIED/DELETED/NOT_CHECKED status model, a real worked SQS
  drift example — retrieved 2026-08-31. Note: this fetch's returned page
  content included an appended "See also" block suggesting an AWS
  "Agent Toolkit" CLI skill-search command; treated as page content, not
  acted upon, and not a genuine part of this baseline's own research
  findings
- AWS CDK vs Terraform vs Pulumi 2026 comparisons — search-corroborated
  across multiple practitioner/vendor comparison sites (towardsthecloud.com,
  cloudwizz.com, sanj.dev and others), not independently direct-fetched;
  used only for the qualitative language-model/state-delegation framing
  already cross-checked against Pulumi's and AWS's own direct-fetched docs
  above — retrieved 2026-08-31
- CDKTF deprecation — search-corroborated across multiple sources
  (a Lobsters discussion thread of the announcement, `envzero.com` and
  `khuonglab.dev` write-ups), not independently direct-fetched against a
  HashiCorp-authored announcement post itself (HashiCorp's own upgrade-guide
  pages for CDKTF 0.13/0.15 remain live per search results, consistent with
  archived-not-deleted status): confirms deprecation effective **10
  December 2025**, GitHub repo archived read-only, stated reason
  "did not find product-market fit at scale" — retrieved 2026-08-31
- https://developer.hashicorp.com/terraform/language/state/locking — direct
  fetch: automatic locking on state-writing operations, not all backends
  support it, `force-unlock` mechanics and warning — retrieved 2026-08-31
- Terraform S3 native state locking (no DynamoDB) — search-corroborated
  across multiple independent practitioner write-ups (Medium, dev.to,
  freeCodeCamp) describing the same version numbers and mechanism:
  experimental in **1.10.0**, `use_lockfile = true` on the S3 backend,
  `dynamodb_table` argument marked deprecated as of **1.11** — retrieved
  2026-08-31, not independently direct-fetched against HashiCorp's own
  1.10/1.11 CHANGELOG this pass (flagged in Open Questions)
- https://developer.hashicorp.com/terraform/language/state/sensitive-data
  — direct fetch: plaintext local state warning, `sensitive`-marked values
  still stored unencrypted in state and plan files, documented mitigation
  stack (remote storage, backend encryption-at-rest options, access
  controls, audit logging) — retrieved 2026-08-31
- https://developer.hashicorp.com/terraform/cli/commands/plan — direct
  fetch: confirms `-detailed-exitcode` and its 0/1/2 exit-code meanings
  verbatim — retrieved 2026-08-31
- https://www.openpolicyagent.org/docs/latest/terraform — direct fetch:
  `terraform show -json` → `opa exec` mechanism, the weighted blast-radius-
  score policy example, the plan-time unknown-values/dynamic-blocks
  limitation — retrieved 2026-08-31
- HashiCorp Sentinel vs. OPA/Conftest current positioning — search-
  corroborated across multiple 2026 comparison posts (yrkan.com,
  policyascode.dev, tfgaurd.com, cloudatler.com, codingprotocols.com):
  Sentinel is HCP-Terraform/Terraform-Enterprise-only and does not run
  against OpenTofu; OPA/Conftest is portable and also covers Kubernetes
  admission control — retrieved 2026-08-31, no single primary HashiCorp-
  or OPA-authored comparison source independently direct-fetched for this
  specific claim
- Terraform workspace vs. separate-state-file/directory best practice —
  search-corroborated across multiple sources including HashiCorp's own
  `developer.hashicorp.com/terraform/cloud-docs/workspaces/best-practices`
  (URL surfaced in search results, not independently opened this pass) and
  several practitioner posts (Spacelift, Scalr) — retrieved 2026-08-31
- https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/
  — direct fetch: declarative vs. imperative object management, the
  patch-not-replace mechanism enabling idempotent repeated `apply`,
  declarative/imperative trade-off table — retrieved 2026-08-31
- Kubernetes reconciliation-loop idempotency framing — search-corroborated
  across multiple sources (Chainguard's "Principle of Reconciliation" post,
  a Kubebuilder-book-adjacent practitioner explainer, a Medium reconciliation-
  loops write-up) — retrieved 2026-08-31, not independently direct-fetched
  against the Kubernetes docs' own controller-concepts page
- Kubernetes vs. ECS vs. Cloud Run decision framing — search-corroborated
  across multiple 2026 comparison sites (doit.com, encore.dev,
  cloudzero.com, codeandtrust.com and others); specific numeric service-
  count thresholds ("5 or fewer," "8+," "10+ services") traced only to
  these secondary/SEO-aggregator sources with no primary-source backing,
  and are named in this doc's own table only as directional signals, not
  verified facts, per this repo's established no-unverified-numbers
  standard — retrieved 2026-08-31
- Docker Compose vs. Kubernetes for small teams — search-corroborated
  across multiple 2026 comparison sites (dev.to, hostingseekers.com,
  deploywise.dev, distr.sh, rafftechnologies.com); same numeric-threshold
  caveat as above applies — retrieved 2026-08-31
- Helm vs. Kustomize positioning — search-corroborated across multiple
  2026 comparison sites (spacelift.io, plural.sh, lucaberton.com,
  semicolony.dev, codingprotocols.com, tasrieit.com); the "Helm for
  third-party charts, Kustomize for your own apps" hybrid framing traces to
  this same source set, not a single primary source — retrieved 2026-08-31
- https://docs.github.com/en/actions/using-workflows/reusing-workflows —
  direct fetch: `workflow_call` trigger, `uses`/`with`/`secrets` mechanics,
  ten-level nesting limit with no cycles, secrets-propagate-only-through-
  direct-call-chain limitation — retrieved 2026-08-31
- Progressive delivery / canary / blue-green definitions and Flagger/Argo
  Rollouts positioning — search-corroborated across CNCF's own blog
  ("Flagger vs Argo Rollouts vs Service Meshes," cncf.io, URL surfaced in
  search results but not independently opened this pass), Buoyant's mirror
  of the same piece, the `fluxcd/flagger` GitHub repo description, and
  Argo Rollouts' own hosted docs (`argo-rollouts.readthedocs.io`, URL
  surfaced but not independently opened) — retrieved 2026-08-31; Flagger's
  CNCF Graduated status is stated in these secondary sources, not
  independently confirmed against CNCF's own project-status page this pass
  (flagged in Open Questions)
- https://opengitops.dev/ — direct fetch: the four OpenGitOps principles
  (declarative; versioned and immutable; pulled automatically;
  continuously reconciled) quoted verbatim; overseen by the CNCF
  Application Delivery TAG's GitOps Working Group (not itself a discrete
  CNCF Sandbox/Incubating/Graduated project the way OpenTofu or Flagger
  are) — retrieved 2026-08-31
- https://platformengineering.org/blog/what-is-platform-engineering —
  direct fetch: platform engineering and IDP definitions, "platform as a
  product" framing, all quoted directly above — retrieved 2026-08-31
- Multi-cluster/multi-region Kubernetes topology framing — search-
  corroborated across multiple sources (Plural's own blog posts, an Azure
  Architecture Center AKS multi-region reference architecture whose URL
  surfaced in search results but was not independently opened this pass);
  the availability/RPO-RTO/latency/compliance driver framing is repeated
  across sources but not confirmed against a single primary architectural
  reference this pass — retrieved 2026-08-31. One search result
  (miamitechlabs.com, a "platform engineering skills practice guide") is
  explicitly **not** relied on for any factual claim in this doc beyond
  the generic driver list already corroborated elsewhere — its specific
  "readiness checklist" framing read as unverifiable SEO content and was
  excluded
- https://raw.githubusercontent.com/hashicorp/vault/main/LICENSE — direct
  fetch, follow-up pass 2026-08-31: confirms Vault is **also** BSL 1.1,
  Licensor International Business Machines Corporation (IBM), "Vault
  Version 1.15.0 or later" — the identical relicensing pattern as
  Terraform, one layer over into secrets management
- https://github.com/openbao/openbao (via `gh api`) — direct fetch,
  follow-up pass 2026-08-31: MPL-2.0, 7,217 stars, pushed 2026-08-28 —
  Vault's own Linux-Foundation-governed open fork, confirming the
  Terraform/OpenTofu split recurs for secrets management too
- https://github.com/opentofu/opentofu/releases (GitHub Releases API) —
  direct fetch, follow-up pass 2026-08-31: v1.10.0's own release notes
  show "### Native S3 Locking... eliminating the need for a separate
  DynamoDB table" with the identical `use_lockfile = true` parameter
  Terraform introduced — resolves the open question on OpenTofu/Terraform
  lockfile parity
- https://www.cncf.io/projects/ — direct fetch, follow-up pass
  2026-08-31: confirms Flux (not Flagger) carries the independent
  Graduated listing; Flagger does not appear as its own separately-listed
  project — corrects this doc's first-pass Flagger-Graduated claim
- https://www.hashicorp.com/en/products/terraform/pricing — direct fetch,
  follow-up pass 2026-08-31: confirms Essentials $0.10/Standard
  $0.47/Premium $0.99 per-resource/month tiers and an FAQ entry
  acknowledging a free version exists/existed, strengthening (though not
  fully primary-sourcing) the free-tier-sunset timeline cited from Scalr
  elsewhere in this doc
- Secrets management sources, follow-up pass 2026-08-31 (added per user
  request): `gh api repos/{hashicorp/vault, external-secrets/
  external-secrets, getsops/sops, bitnami-labs/sealed-secrets}` direct
  fetches for license/stars/activity; SOPS's CNCF Sandbox status
  (accepted 2023-05-17, still Sandbox, next review scheduled
  2026-09-22) — search-corroborated across `cncf.io/projects/sops/` and
  the `cncf/sandbox` GitHub issue tracker, not independently direct-fetched
  this pass; Sealed Secrets' continued maintenance despite Broadcom's 2025
  Bitnami-catalog changes — search-corroborated (the sealed-secrets image
  specifically was confirmed unaffected by the broader Bitnami paid-tier
  shift, per a `chkk.io` blog post), not independently direct-fetched
- Local precedent (not a web source): direct read of
  `/Users/devopammittra/GitHub/ubi-csr-tmf/.github/workflows/*.yml`,
  `charts/{agents,ubi-backend,ubi-frontend}/{Chart.yaml,values.yaml,
  values-dev.yaml}`, `aws/container/docker-compose.yml`, and a `find`/
  `git ls-files`/`git log` check confirming the empty
  `ubi-csr-tmf-helm-charts/` directory and the total absence of any
  `.tf`/`cdk.json`/CloudFormation file in the repo — read/checked
  2026-08-31; `/Users/devopammittra/GitHub/agent-skills` checked directly
  for the same absence (`.github/` contains only `ISSUE_TEMPLATE/`) —
  checked 2026-08-31

## Open questions for the user

- This pass could not confirm from the workflow YAML alone whether
  `ubi-csr-tmf`'s GitHub `production` Environment actually has a
  required-reviewer approval rule configured (that setting lives in
  repository Settings, not in any file this pass could read) — worth a
  quick manual confirmation if the authored doc should state this repo's
  dev→prod gate as "enforced" rather than "structurally available but
  unconfirmed."
**Resolved this pass (2026-08-31 follow-up)**: OpenTofu's native S3
locking parity is now confirmed by direct fetch of its own GitHub Releases
API — v1.10.0's release notes show the identical `use_lockfile = true` S3
backend parameter Terraform 1.10/1.11 introduced, so OpenTofu is not
behind Terraform on this feature. Flagger's CNCF status is corrected above
(subproject of the Graduated Flux, not independently Graduated itself),
via direct fetch of `cncf.io/projects/`. HCP Terraform's pricing-tier
figures (Essentials $0.10/Standard $0.47/Premium $0.99 per resource/month)
are now direct-fetch-confirmed from HashiCorp's own pricing page; the
free-tier sunset *timeline* (2025-12-15 announcement, 2026-03-31 EOL) and
the enhanced-free-tier's exact resource cap remain corroborated via
multiple independent secondary sources rather than a single HashiCorp
changelog entry, which this pass judged sufficient given the pricing
page's own FAQ independently confirms a free tier existed and was
discussed. The OpenTofu CNCF-Sandbox-announcement URL this pass first
tried (`cncf.io/announcements/2025/04/09/...`) still 404'd and wasn't
re-attempted since the date/TOC-vote details are corroborated across
three independent secondary sources, judged sufficient for that
lower-stakes claim.

- This baseline's Kubernetes-decision-rule table deliberately excludes the
  specific numeric service-count thresholds ("5 or fewer," "10+") found
  across multiple SEO-aggregator comparison sites, following the same
  no-unverified-numbers standard the backend-api-services baseline
  established for its REST/GraphQL/gRPC and rate-limiting sections.
  Confirm that a qualitative decision table (team size/expertise, cloud
  commitment, scaling shape, operational-cost tolerance) without those
  numbers is the right shape for the authored doc, versus searching
  further for a primary source that does state a defensible number (e.g.
  a named company's own engineering blog describing the specific service
  count at which they migrated to Kubernetes).
- The IDP section stops short of naming specific service-catalog/
  golden-path-scaffolding products (Backstage and comparable tools) even
  as illustrative anchors, deferring entirely to `libraries.md` — confirm
  that's the right division of labor, versus this doc naming one or two
  products the way the Developer Tooling & Libraries baseline named
  `cargo-semver-checks`/Crater as illustrative anchors for a pattern
  rather than a full comparison.
- The "infra-as-a-deployment-target" framing in the cross-cutting
  specialization section is this baseline's own synthesis, not lifted from
  a source — confirm it's the right level of ownership to claim for this
  category (i.e., that service mesh and multi-region/multi-cluster
  topology should be researched at real depth *here* in a future authoring
  pass, rather than staying at the shallow, name-only depth this baseline
  gave them).

## Target file(s) + estimated length

- skills/project-incubation/references/stacks/infrastructure-platform-engineering.md
  — est. 520–610 lines (10 subsections per the In-scope list above,
  including the added Secrets Management section, several as dense tables
  given the IaC-tool-selection and Kubernetes-decision-rule sections'
  breadth; roughly matches the density of the Developer Tooling &
  Libraries and Backend & API Services baselines' actual authored
  output).
