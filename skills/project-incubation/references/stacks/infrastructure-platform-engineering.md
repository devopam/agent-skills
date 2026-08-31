# Infrastructure & Platform Engineering — Architecture & Stack

This category covers Infrastructure as Code (IaC) tool selection and state
management, Kubernetes and container-orchestration decisions, the
platform-engineering layer of CI/CD (reusable workflows, promotion gates,
progressive delivery), secrets management as it intersects with IaC state,
and internal developer platforms. It's the one category in this skill where
**the deployment target itself — the cluster, the VPC, the IAM boundary —
is the thing being architected**, not a settled backdrop assumption another
category's own architecture rests on. The cross-cutting
[architecture-templates.md](../architecture-templates.md) doc explicitly
scopes "container-orchestration platform selection (Kubernetes vs. ECS vs.
Nomad specifics)" out of its own network-topology section as "deployment-target
detail... more naturally belongs with Backend & API Services or a future
deployment-focused doc" — this doc is that follow-through, not new scope
invented here. For where a single service's own request/response
architecture is decided (REST vs. gRPC, rate limiting, the service's own
resilience patterns), see
[Backend & API Services](backend-api-services.md); this doc picks up once
the question becomes "what does that service run on, and how does it get
there."

This category also has a genuinely rich, directly-inspectable local
example: `ubi-csr-tmf`, a sibling repository on the same machine this doc
was authored on, deploys three services (`agents`, `ubi-backend`,
`ubi-frontend`) to EKS via per-service Helm charts and a full suite of
GitHub Actions workflows using OIDC trusted deployment — but it demonstrates
only **half** of this category's own scope, worth naming up front. Real
per-service Helm charts exist, with a genuine `values.yaml`/`values-dev.yaml`
split carrying concrete, non-cosmetic differences (production requests
`cpu: "500m"`/limits `"800m"`; dev requests `cpu: "300m"`/limits `"500m"`,
different namespaces). Every deploy workflow builds an image, pushes to
ECR, and runs `helm upgrade --install ... --wait --timeout 5m` against
`ubi-coe-cluster`, authenticating via
`aws-actions/configure-aws-credentials@v4` and a role named literally
`GitHubActionsTerraformRole`. And yet: **zero `.tf`, `cdk.json`, or
CloudFormation files exist anywhere in that repository.** The role's own
name is the tell — it was almost certainly created by a Terraform run
elsewhere, in a repo not present on this machine, that also wired up its
own OIDC trust policy. This repository is real, working evidence for
"deploying an application onto a cluster" and demonstrates nothing at all
about "provisioning the cluster, VPC, and IAM that the application lands
on" — the two halves this doc treats as genuinely distinct rather than
blurring together, and several sections below return to it for further
evidence, including one genuinely useful cautionary example.

One convention carried through every section below: numeric claims
(exact per-resource pricing, comparative registry/provider counts,
service-count thresholds for "when to adopt Kubernetes") are stated only
where a primary source backs the specific figure, and are otherwise named
as a directional signal from secondary/aggregator sources rather than a
verified fact — several widely-repeated "5 services," "8 services," "10+
services" Kubernetes-adoption thresholds fall into the latter category and
are deliberately left out of the decision table below as a result.

## Table of contents

- [IaC tool selection](#iac-tool-selection)
- [State management](#state-management)
- [Drift detection](#drift-detection)
- [Blast-radius limiting](#blast-radius-limiting)
- [Secrets management](#secrets-management)
- [Idempotency, IaC-style](#idempotency-iac-style)
- [Kubernetes vs. simpler deployment targets](#kubernetes-vs-simpler-deployment-targets)
- [Kubernetes templating: Helm vs. Kustomize](#kubernetes-templating-helm-vs-kustomize)
- [CI/CD at the platform-engineering layer](#cicd-at-the-platform-engineering-layer)
- [Internal developer platforms](#internal-developer-platforms)
- [How this category specializes the cross-cutting patterns](#how-this-category-specializes-the-cross-cutting-patterns)
- [Where this doc stops](#where-this-doc-stops)
- [Sources](#sources)

## IaC tool selection

The licensing and governance state of this space genuinely changed enough
in the last few years that training-data-only knowledge is stale here in a
load-bearing way, not a cosmetic one.

**Terraform is Business Source License 1.1**, not fully open source, since
10 August 2023 — confirmed directly from HashiCorp's own license FAQ. IBM
completed its $6.4B acquisition of HashiCorp on 27 February 2025, so
Terraform is now an IBM-owned product, commercially licensed above a usage
threshold defined in BSL 1.1's "competitive offerings" restriction.
**OpenTofu** is the MPL-2.0 fork taken at Terraform 1.5.x (the last
MPL-2.0 release), genuinely open source, governed by the Linux Foundation,
and accepted into the CNCF as a Sandbox project on 23 April 2025 under a
licensing exception (CNCF normally requires Apache-2.0). It isn't merely
catching up to Terraform either: OpenTofu has shipped features its
upstream's own OSS binary lacks, including native state encryption and OCI
registry support.

| Tool | Language model | State model | Multi-cloud | Licensing / status |
|---|---|---|---|---|
| **Terraform** | HCL declarative DSL | Own state file (local or remote backend) mapping declared config to real resources | Yes, provider-plugin model | BSL 1.1 since 2023-08-10; IBM-owned since 2025-02-27 |
| **OpenTofu** | Same HCL, forked at 1.5.x | Same state-file model, drop-in compatible for most configs | Yes, same provider ecosystem | MPL-2.0, Linux Foundation-governed, CNCF Sandbox (2025-04-23) |
| **Pulumi** | Real general-purpose languages (TypeScript, Python, Go, C#, Java) | Own checkpoint model — Pulumi Cloud (managed, default) or a self-managed "DIY" backend (S3/Azure Blob/GCS/Minio/Ceph/Postgres/local); Pulumi's own docs state plainly that its state "does not include your cloud credentials" | Yes, many providers are generated from Terraform's own providers | CLI/SDKs Apache-2.0; Pulumi Cloud is the separate commercial layer on top |
| **AWS CloudFormation** | JSON/YAML declarative templates | No separate state file — AWS tracks the stack's resource mapping server-side, with drift detection as a first-class API (below) | No — AWS-only by design | AWS-proprietary, free to use (billed only for provisioned resources) |
| **AWS CDK** | Real languages, compiling to CloudFormation templates | Delegates entirely to CloudFormation's own stack state | No — AWS-only | Open-source CDK library (Apache-2.0) generating closed-model, AWS-only templates |
| **CDKTF** | Real languages, compiling to Terraform's JSON config format | Terraform's own state model | Yes, inherits Terraform's providers | **Deprecated by HashiCorp, effective 2025-12-10** — "did not find product-market fit at scale"; repo archived read-only |

CDKTF closing is worth stating plainly rather than glossing over: it had
been the one option offering real-language syntax over Terraform's own
provider ecosystem, and that middle ground no longer has a live occupant
as of this writing — older comparison content that still lists it as a
third live choice alongside Terraform and Pulumi is describing a dead
option.

**Practical default for a new project**: HCL-shaped IaC remains the
broadest starting point on ecosystem grounds — the largest provider/module
catalog, and HCL as what multiple 2026 comparison sources independently
called the industry's shared vocabulary (a qualitative framing, not an
independently measured share). Within that HCL choice, **OpenTofu is the
named default for a genuinely new project with no existing HCP
Terraform/Sentinel investment**, on the concrete licensing/governance facts
above — this is a decision made on checkable governance grounds, not a
popularity call. **Terraform remains a fully legitimate choice, not a
lesser fallback, in three concrete situations**: a team already
standardized on HCP Terraform/Terraform Enterprise and Sentinel, where
migrating that whole run-pipeline investment to OpenTofu is a real project
of its own rather than a free win; a team with an existing large Terraform
estate, since most existing configuration runs on OpenTofu unchanged
(commonly described as "swap the `terraform` binary for `tofu`") — but that
"usually" is a deliberate migration decision a team gets to make for
itself, not one this doc makes for them; and a team that specifically wants
the largest available pool of tutorials, Stack-Overflow-era reference
material, and provider-compatibility certainty, since Terraform's absolute
installed base and registry size are still larger than OpenTofu's in
absolute terms.

Reach for **Pulumi** specifically when the team wants infrastructure code
reviewed, tested, and abstracted with the same tooling — unit tests, loops,
shared functions, package imports — as its application code, and is willing
to trade HCL's ubiquity for that. Reach for **CloudFormation or CDK**
specifically when the project is deliberately, permanently AWS-only and
wants zero separate state-backend setup: both drift detection and state
tracking are a managed AWS API call away rather than infrastructure the
project stands up itself.

**The same BSL-vs-open-fork split recurs one layer over, in secrets
management**: HashiCorp Vault underwent the identical BSL 1.1/IBM-licensor
relicensing as Terraform itself — confirmed directly from `hashicorp/vault`'s
own `LICENSE` file, which names International Business Machines Corporation
as Licensor for "Vault Version 1.15.0 or later" — with **OpenBao** as its
own Linux Foundation-governed, MPL-2.0 fork. The same decision shape
applies: default to the open fork for new work, and treat Vault as
fully legitimate where an existing HCP investment already exists. This
isn't a one-off Terraform quirk; it's the same licensing fork pattern
recurring at the next layer of this category's own stack, and the
[Secrets Management](#secrets-management) section below picks it back up.

## State management

**State locking** is Terraform's automatic guard against the classic
failure mode of two concurrent `apply` runs corrupting the same state file
— HashiCorp's own docs state that "state locking happens automatically on
all operations that could write state," with a `force-unlock` escape hatch
for a stuck lock that explicitly warns unlocking someone else's active
lock "could cause multiple writers."

**The canonical S3-plus-DynamoDB-lock pattern is now legacy, not current
best practice**, and this is a genuinely time-sensitive fact worth getting
right: Terraform 1.10 introduced (experimentally) and 1.11 shipped
production-ready **native S3 state locking** — a lock file stored directly
in the S3 bucket via `use_lockfile = true` on the S3 backend block —  and
1.11 additionally marked the old `dynamodb_table` backend argument itself
as deprecated. OpenTofu is not behind on this: its own 1.10.0 release notes
state directly that native S3 locking is "eliminating the need for a
separate DynamoDB table," using the identical `use_lockfile = true`
parameter, confirmed by direct fetch of OpenTofu's own GitHub Releases API
— parity between Terraform ≥1.11 and OpenTofu ≥1.10.0, not a feature
OpenTofu is playing catch-up on. Any reference material still describing
"S3 backend plus a separate DynamoDB lock table" as the current
recommendation is describing the *previous* generation of this pattern; the
DynamoDB-lock shape remains supported for backward compatibility but isn't
the recommended new setup. **HCP Terraform / Terraform Cloud** is the
alternative to self-managing any of this — state storage, locking, and
encryption at rest are handled by the managed service, at the cost of
coupling to HashiCorp's own SaaS and its per-resource pricing tiers
(Essentials $0.10 / Standard $0.47 / Premium $0.99 per resource/month,
confirmed by direct fetch of HashiCorp's own pricing page).

**Pulumi's state model differs from Terraform's in a specific, checkable
way**: Pulumi's managed Pulumi Cloud backend uses "a transactional snapshot
called a checkpoint" for crash-consistency, and — a genuinely distinctive
detail — Pulumi state never contains cloud credentials at all; they stay
local to wherever the CLI runs. **Secrets exposure in Terraform state is a
real, documented risk, not a hypothetical**: Terraform's own docs state
plainly that local state "is a plaintext file, which includes any secret
values you defined in your configuration," and that even values marked
`sensitive` in configuration are still stored unencrypted "in both state
and plan files." The documented mitigation stack is remote storage plus
backend-native encryption at rest (S3's `encrypt` option, GCS
customer-managed keys, HCP Terraform's automatic encryption) plus access
controls plus audit logging — not one silver-bullet setting. This is
precisely the fact that motivates the Secrets Management section's own
practical default below: provision the *secrets-management resource*
through IaC, never the secret *value*.

**Import and drift reconciliation**: `terraform import` (or the newer
configuration-driven `import` block) brings an out-of-band-created real
resource under Terraform's management by writing a matching state entry
without recreating the resource — the mechanical inverse of drift, and the
standard remediation path once drift is detected and the team decides to
adopt the drifted-in-place resource rather than force it back to the
declared state.

## Drift detection

Concretely, drift is a `plan` (Terraform/OpenTofu, or Pulumi's `preview`)
or `detect-stack-drift` (CloudFormation) run surfacing an *unexpected*
difference between declared configuration and the live state of a
resource — "unexpected" is the operative word, since an expected diff is
just a pending change waiting for `apply`.

Terraform's own scriptable primitive is `terraform plan -detailed-exitcode`
(confirmed directly from HashiCorp's CLI docs): exit code `0` means no
changes, `1` means an error, `2` means changes are present — the mechanism
a cron job or scheduled CI run uses to alert on drift without parsing plan
output at all. Secondary sources commonly suggest hourly scheduling for
drift-sensitive production infrastructure; that cadence traces only to
practitioner write-ups, not a HashiCorp-stated recommendation, and is named
here only as a directional signal.

**Managed continuous drift detection**: HCP Terraform/Terraform Enterprise
run scheduled "health assessments" that execute `plan` on a defined
interval and surface drift without applying anything. Third-party
platforms — named only as a category here, specific products belong to
[preferred-libraries/infrastructure-platform-engineering.md](../preferred-libraries/infrastructure-platform-engineering.md)
— extend this further, including estate-wide tools that also detect
*unmanaged* resources never declared in any IaC config at all.

**CloudFormation's native equivalent is a first-class AWS API, not a
third-party add-on** — meaningfully more built-in than Terraform's story,
which needs either a scheduled `plan` job or a paid managed-service feature
for the same continuous coverage. The flow is `detect-stack-drift`
(asynchronous, polled via `describe-stack-drift-detection-status`), then
`describe-stack-resource-drifts`, returning a per-resource
`IN_SYNC`/`MODIFIED`/`DELETED`/`NOT_CHECKED` status and, for `MODIFIED`
resources, the exact property-level expected-vs-actual diff — confirmed
directly from AWS's own docs, whose worked example shows a drifted SQS
queue's `DelaySeconds` and `RedrivePolicy.maxReceiveCount` diverging from
their declared values.

## Blast-radius limiting

**Why a single monolithic state file for an entire organization is a
named anti-pattern, not exaggeration**: the concrete failure mode
repeatedly cited is a typo in a variable destroying production resources
when the intent was to change something in dev — a shared state file gives
that typo the blast radius of every environment sharing the backend. The
practical remediation is environment- and component-scoped state isolation:
each environment (dev/staging/prod), and ideally each independently
deployable component or region within an environment, gets its own state
file, so a mistaken or malicious change in one blast radius can't reach
another merely by sharing a backend.

**Workspaces vs. separate directories/backends is a real trade-off, not a
purity contest.** Terraform's own CLI workspaces (`terraform workspace
new`/`select`) optimize for reusing one configuration across environments;
separate directories, or separate root modules and backends entirely,
optimize for isolation and independent blast radius. The commonly-cited
guidance is directory-based separation for long-lived environments —
dev/staging/prod, especially under compliance requirements — reserving CLI
workspaces for short-lived, ephemeral contexts such as a feature-branch
preview environment or a temporary test stack.

**Policy-as-code gates before `apply`**: HashiCorp Sentinel is the
HCP Terraform/Terraform Enterprise-native policy engine — proprietary, and
a specific, checkable limitation worth stating directly: **it does not run
against OpenTofu at all.** For a team on OpenTofu, or any team wanting a
portable, vendor-neutral gate, **Open Policy Agent (OPA)**, typically
invoked via **Conftest** as a CLI wrapper, is the alternative. The
mechanism, confirmed directly from OPA's own Terraform integration doc:
`terraform show -json` converts the binary plan to JSON, then `opa exec`
evaluates Rego policies against that JSON in CI, before `apply` runs, not
after. OPA's own documented example is directly a blast-radius-limiting
policy worth naming verbatim: assigning weighted risk scores per
operation-type — `{"aws_autoscaling_group": {"delete": 100, "create": 10,
"modify": 1}}` — and rejecting any plan whose summed risk score crosses a
threshold. OPA's own docs are equally direct about a real limitation: "some
information may not be available at plan time" for unknown values, dynamic
blocks, and function calls resolved only during `apply` — a policy gate
built purely on plan-time JSON can't see everything a run will eventually
do.

**Practical default**: a policy-as-code gate belongs in CI before `apply`
runs for any environment with real production blast radius. OPA/Conftest
is the portable default — it works identically on Terraform or OpenTofu,
and generalizes to Kubernetes admission control too (see the cross-cutting
specialization section below) — reserving Sentinel for teams already fully
committed to HCP Terraform's managed platform.

## Secrets management

The architectural question this section answers is narrower than access
control (who's allowed to read a secret once retrieved): **where does a
secret live at rest, and by what mechanism does it reach a running
workload without ever landing in git history or IaC state as plaintext.**
Four patterns are currently distinct:

1. **A dedicated secrets-management server** (Vault, or its
   Linux-Foundation-governed open fork named in the IaC section above) —
   dynamic, short-lived, per-request credential issuance rather than a
   static secret sitting in a vault forever. The most capable option, and
   the most operationally heavy: it's itself a stateful service the team
   now has to run and secure.
2. **Cloud-native secret managers** (AWS Secrets Manager, Azure Key Vault,
   GCP Secret Manager) — zero extra infrastructure for a team already
   committed to one cloud, at the cost of the same single-cloud lock-in
   this doc's IaC section already names for CloudFormation/CDK.
3. **GitOps-native encrypted-file patterns** — a secret is encrypted with a
   KMS/PGP/age key and the *encrypted* file is committed straight into git
   alongside the rest of the IaC/config it belongs to, keeping GitOps's own
   "everything is declared in version control" property intact for secrets
   too. The cost: key rotation now needs a re-encrypt-and-recommit step
   rather than an in-place server-side update.
4. **Kubernetes-native secret injection/sync controllers** — a cluster-side
   controller either syncs a `Secret` object live from an external system
   (pattern 1 or 2) or one-way-decrypts a git-committed encrypted blob
   (pattern 3) into a real `Secret` object at apply time. This is the
   mechanism that connects patterns 1–3 to an actual running Kubernetes
   workload, not a fifth competing pattern.

**The direct, load-bearing connection to this doc's own State Management
section**: Terraform's documented plaintext-state risk — a
`sensitive`-marked value is still stored unencrypted in state and plan
files — means provisioning a secret's *initial value* via Terraform or
OpenTofu at all reintroduces exactly the exposure these four patterns exist
to avoid. The practical default worth stating explicitly: **use IaC to
provision the secrets-management resource itself** (a Vault instance, a
Secrets Manager entry, an IAM role trust policy) **but never to carry the
secret value through IaC state.** For a GitOps-driven cluster specifically,
reach for pattern 3 or pattern 4 — they're the only two patterns that
preserve GitOps's declarative-everything-in-git property without ever
putting a plaintext secret into that git history.

Pattern 4's own governance status is worth being precise about rather than
assuming: External Secrets Operator is an independently governed,
Apache-2.0, actively maintained project — it is not itself a CNCF project
(it doesn't appear on CNCF's own project listing), unlike Vault's open
fork or the GitOps tooling referenced elsewhere in this doc. Sealed
Secrets, the other commonly-named controller in this pattern, has
continued to be maintained despite Broadcom's 2025 changes to the Bitnami
image catalog it originally shipped alongside — the sealed-secrets image
specifically was confirmed unaffected by that broader shift. SOPS, the
tool most associated with pattern 3, is itself a CNCF Sandbox project,
accepted 2023-05-17. None of these governance facts changes which pattern
fits a given team's constraints, but a team evaluating "is this
Kubernetes-native or CNCF-native" as a criterion should have the actual
answer rather than an assumption — this is exactly the kind of
currently-checkable fact this doc's own opening convention says gets
stated only when backed, and this one now is.

## Idempotency, IaC-style

The same word means something concretely adjacent-but-distinct here from
an API or library context. A backend service's idempotency concern is
about a **single request** not double-executing its side effect on retry.
This category's idempotency is about a **whole declared configuration**
being safely re-appliable an arbitrary number of times: re-running
`terraform apply` (or `kubectl apply`, or a Helm `upgrade --install`)
against an unchanged configuration and an unchanged real environment should
produce **zero** changes, not a repeated action — precisely what a clean
`-detailed-exitcode` of `0` demonstrates.

Kubernetes makes this a formal, named architectural property rather than
an incidental nice-to-have. `kubectl apply`'s own documentation describes
create/update/delete operations as being "automatically detected
per-object," using a **patch**, not a **replace**, API operation
specifically so the same manifest can be applied repeatedly and safely.
The broader controller/reconciliation-loop pattern underneath every
Kubernetes controller — continuously observing actual system state and
working to make it match a declarative desired state — is explicitly
described in Kubernetes-ecosystem sources as needing to be idempotent:
running the same reconciliation multiple times with the same input must
produce the same result without side effects. The practical takeaway:
idempotency here is a property of the whole apply-and-reconcile loop,
verified by "did this run change anything it shouldn't have," not a
property of one individual mutating call.

## Kubernetes vs. simpler deployment targets

This is deliberately a decision rule, not a default. Several 2026
comparison sources converge on a consistent *qualitative* shape, even
though their specific numeric thresholds (a stated "5 services," "8
services," "10+ services" line) are exactly the kind of unverifiable,
no-primary-source precision this doc's own numeric-claims convention
excludes — named here as directional signals only:

| Signal pointing toward... | A single VM + Docker Compose | A managed container platform (ECS/Fargate, Cloud Run, Fly.io) | Kubernetes |
|---|---|---|---|
| Team size / expertise | Small team, no dedicated platform/ops role | Small-to-mid team wanting less operational surface than K8s | Dedicated (or budgeted) platform-engineering ownership |
| Service count / topology | A handful of services, one deployable unit conceptually | Several independently-deployable services, still single-cloud | Enough services/teams that per-service autonomy and a shared platform layer pay for themselves |
| Cloud commitment | Irrelevant — runs anywhere with Docker | Deliberately single-cloud (ECS/Cloud Run are provider-specific) | Cloud-portable by design — the same manifests target any conformant cluster |
| Scaling / traffic shape | Fixed, predictable load; vertical-scale one VM is enough | Elastic, request-driven, willing to trade fine control for near-zero ops (Cloud Run's scale-to-zero is the sharpest example) | Fine-grained per-pod autoscaling, custom scheduling constraints, or a rich ecosystem of K8s-native operators |
| Operational cost being traded | Near-zero — one server to patch/monitor | Low — no control plane to manage, but tied to that provider's own deployment model | Real and ongoing — cluster upgrades, node lifecycle, RBAC, CNI networking, ingress, and a policy layer all become the team's job unless a managed offering absorbs some of it |

`ubi-csr-tmf` is itself concrete evidence these targets aren't mutually
exclusive across one project's lifecycle: the same codebase runs Compose
locally (three services on a shared bridge network, health-checked
`depends_on`, bind mounts for hot-reload, a mounted `${HOME}/.aws` so local
containers assume the developer's own credentials) and Helm-on-EKS for
anything actually deployed. "Which orchestration model" gets answered
differently for local inner-loop development than for what serves real
traffic — a deliberate choice not to force Kubernetes onto the local
developer experience just because production runs on it, not an
inconsistency to resolve.

**Practical default for a new project without an existing driving signal**:
start with the simplest deployment target that fits the team's actual
current service count and cloud commitment — often Compose on a single VM,
or a managed container platform once more than one service exists — and
move to Kubernetes only once a real, present multi-service, multi-team, or
cloud-portability constraint appears. This is the same monolith-first
caution the cross-cutting `architecture-templates.md` doc applies to
microservices, generalized cleanly to orchestration-platform choice: don't
pay Kubernetes's real, ongoing operational cost for a problem the team
doesn't have yet.

## Kubernetes templating: Helm vs. Kustomize

At architecture depth (specific tool versions and comparison detail belong
to
[preferred-libraries/infrastructure-platform-engineering.md](../preferred-libraries/infrastructure-platform-engineering.md)):
**raw manifests** are viable only for a genuinely tiny, rarely-changing set
of resources with no cross-environment variation to manage. **Helm**
packages an application, or a dependency like a database or ingress
controller, as a versioned, installable/upgradable **release** with a real
templating language and a documented values-schema contract — the natural
choice either when consuming third-party charts (the
Prometheus/Grafana/cert-manager/ingress-controller ecosystem is
overwhelmingly Helm-first) or when an application's own deployment has real
lifecycle concerns — upgrade, rollback, subchart dependencies — beyond
"apply these YAML files." **Kustomize** takes plain, valid, un-templated
YAML and layers environment-specific **overlays/patches** on top with no
templating language at all — built directly into `kubectl` via
`kubectl apply -k`, which keeps the base manifests themselves fully
readable and valid on their own, with no templating syntax to mentally
strip out.

`ubi-csr-tmf` uses Helm exclusively — every deploy workflow calls
`helm upgrade --install`, with a distinct `values-dev.yaml`/`values.yaml`
pair per chart standing in for what a Kustomize-based setup would instead
express as environment overlays: production requests `memory: "3Gi"`/
`cpu: "500m"` (limits `4Gi`/`800m`) against dev's `memory: "3Gi"`/
`cpu: "300m"` (limits `3Gi`/`500m`), with `namespace: csr-tmf-portal` vs.
`namespace: csr-tmf-portal-dev`. A real, single-tool-choice data point, not
a comparison, but concrete evidence that Helm-plus-per-environment-values-
files is a genuinely viable, currently deployed pattern, not just a
textbook recommendation.

**Practical default**: Helm for anything consuming third-party charts or
needing real release lifecycle management; a Kustomize overlay-per-environment
approach for an internal app whose only cross-environment differences are
the kind `ubi-csr-tmf`'s own values-file pair already shows — replica
count, resource limits, namespace — where the team would rather avoid a
templating language entirely. The two compose rather than compete in
practice — "Helm for third-party applications, Kustomize for your own" is
one commonly-cited hybrid pattern — though this repo's own precedent shows
Helm-only is also a fully viable single-tool choice, not a compromise.

## CI/CD at the platform-engineering layer

Three concerns this category adds on top of "a repo has a CI pipeline,"
none of them about running one app's own tests.

**Shared, reusable workflow patterns** — a platform team standardizes
CI/CD once, and every app repo consumes it rather than hand-rolling its own
deploy YAML. GitHub Actions' own mechanism, confirmed directly from its
docs: a workflow declaring `on: workflow_call` becomes callable from
another workflow via `uses:`, with typed `with:`/`secrets:` inputs and
job-level `outputs:` flowing back to the caller. Two concrete limits are
worth naming rather than discovering the hard way: a maximum of **ten**
levels of nested reusable workflows with no cycles permitted, and secrets
propagate only through the direct call chain — a workflow two levels deep
receives only what the immediately-calling workflow explicitly re-passed,
not everything the original caller had. `ubi-csr-tmf` does **not** yet use
this mechanism — its `be-deploy-dev.yml`, `be-deploy-prod.yml`, and
`agents-deploy-dev.yml` workflows are near-duplicates of each other, same
build-image/configure-credentials/helm-upgrade shape with different
environment values, rather than one shared reusable workflow parameterized
per service — a real, named consolidation opportunity in a real repo, not
a hypothetical one.

**Environment-promotion gates**, matching this same repo's real dev/prod
split: dev deploys trigger automatically on push to `develop`, path-filtered
to only the service that actually changed, with a `[skip deploy]`
commit-message escape hatch and a concurrency guard against overlapping
deploys of the same branch; prod workflows are `workflow_dispatch`-only —
no automatic trigger exists for production at all. Every job additionally
declares a named GitHub Environment (`dev`/`production`), which *can* carry
a required-reviewer approval gate configured outside the workflow YAML, in
the repository's own Settings — a real, working instance of the
"automated for lower environments, gated for production" pattern this
category calls for, though whether a required-reviewer gate is actually
turned on for this repo's `production` environment can't be confirmed from
the YAML alone, a genuine limit on how deep "read the workflow files" can
verify an approval process.

**Progressive-delivery patterns**, at a conceptual level (specific
controller names belong to
[preferred-libraries/infrastructure-platform-engineering.md](../preferred-libraries/infrastructure-platform-engineering.md)):
**canary** — a new version receives a small, gradually increasing
percentage of production traffic while a metrics-analysis step decides
whether to keep shifting traffic, hold, or abort and roll back
automatically. **Blue-green** — two complete environments (the currently
live "blue" and the new "green") run simultaneously, the new one is
validated against real traffic-shaped smoke/integration checks, then
traffic cuts over all at once. Both are formalized as Kubernetes-native
Custom Resources by CNCF-ecosystem controllers, and their governance status
is worth stating precisely rather than glossing: **Flagger**, part of the
Flux family, does not itself carry an independent CNCF maturity listing —
only **Flux** appears on CNCF's own project page as Graduated, with Flagger
credited through that graduation rather than holding one of its own,
confirmed directly against `cncf.io/projects/`. **Argo Rollouts** borrows
its own CNCF standing the same way: it isn't separately listed either, but
inherits governance through **Argo** (the umbrella covering Argo CD,
Workflows, Events, and Rollouts), accepted to CNCF on 2020-03-26 and listed
Graduated. Both controllers borrow their maturity signal from a parent
project rather than holding an independent listing — worth getting right
precisely because it's the kind of claim easy to overstate from a
comparison-site summary rather than CNCF's own listing.

`ubi-csr-tmf`'s own `release: blue-green` Helm label is a genuinely useful
cautionary example here: every one of its three charts' values files sets
`labels: { release: blue-green }`, but nothing else in the chart — no
second release track, no traffic-splitting Service/Ingress configuration,
no Argo Rollouts or Flagger CRD — implements blue-green deployment. The
workflow's own "scale to 2 replicas after rollout" step is a plain rolling
update via `kubectl scale` plus `kubectl rollout status`, not a blue-green
cutover. Labeling something blue-green doesn't make it blue-green; this
repo is a real, concrete instance of that gap, not a hypothetical warning.

## Internal developer platforms

Platform engineering, per platformengineering.org's own definitional post,
is "the discipline of designing and building platforms that enable
self-service capabilities for teams... to automate the recurring aspects
of knowledge work." An internal developer platform (IDP) is the concrete
artifact: "a set of paved paths that give developers self-service access to
everything they need — environments, deployments, security scans — without
tickets or tribal knowledge." **"Platform as a product"** specifically
means treating the internal platform with the same discipline as an
externally sold product — driven by its own users' feedback rather than
technology trends, requiring ongoing maintenance and iteration rather than
a one-time build, and framed as "the sum of paths enabled by a set of
capabilities, exposed through interfaces" rather than a single dashboard
or tool.

The concrete connection to every other section of this doc: an IDP is the
self-service layer sitting *on top of* everything else here — Terraform or
Pulumi modules, Helm charts, CI/CD reusable workflows, policy-as-code
gates. An application team requests "a new service" or "a new environment"
through a paved-path interface — a service catalog, a golden-path
template, a self-service portal — instead of hand-writing its own
Terraform module or Helm chart from scratch every time.

This connects to, without duplicating,
[Developer Tooling & Libraries](developer-tooling-libraries.md)'s own
module/plugin-boundary framing: which internal module is stable public
surface a consumer can depend on versus an implementation detail free to
change at any time, there applied to a *library* consumed by other
developers' code. An IDP applies the identical idea to *infrastructure*
consumed by other developers' deploy pipelines: the paved path — "click a
button, get a new service scaffolded with its own Helm chart, CI workflow,
and monitoring dashboards already wired up" — is this category's version
of a well-designed public API surface; the Terraform modules and Helm
charts underneath it are the swappable implementation detail. Specific
service-catalog or golden-path-scaffolding products belong to
[preferred-libraries/infrastructure-platform-engineering.md](../preferred-libraries/infrastructure-platform-engineering.md),
not here.

## How this category specializes the cross-cutting patterns

[architecture-templates.md](../architecture-templates.md)'s network-topology
section frames a gateway (north-south traffic) as justified past the first
externally-facing service, and a mesh (east-west: mTLS, retries, tracing)
as justified only past a service-count and operational-maturity threshold
most early projects never cross — and explicitly names
container-orchestration platform selection as deployment-target detail it
scopes out of its own treatment. The
[Kubernetes vs. simpler deployment targets](#kubernetes-vs-simpler-deployment-targets)
section above is that deferred decision rule actually delivered, not new
scope invented here.

**Service mesh** is the one cross-cutting concern this category is the
correct home for, precisely because mesh adoption is itself a
platform-engineering decision — a shared, centrally operated layer other
teams' services opt into — rather than a single-service architectural
choice. This doc doesn't re-derive mesh internals (mTLS certificate
rotation mechanics, traffic-shifting CRD syntax); the fit signal worth
carrying forward is simply: multiple services, genuine east-west traffic
between them, and a team willing to operate the mesh control plane. Below
that threshold, a mesh is exactly the premature-adoption anti-pattern the
cross-cutting doc already names.

**Multi-region/multi-cluster topology** is similarly this category's
genuine home. The commonly-cited driver framing describes availability
posture (active-active vs. active-passive), disaster-recovery targets
(RPO/RTO), geographic latency, and compliance/data-residency as the
primary drivers, with a shared management/policy layer — RBAC, network
policy, admission control, fleet-wide observability — sitting above
independently schedulable per-region or per-cloud clusters. Named here as
the concept shape rather than a vendor's multi-cluster product, which
belongs to `preferred-libraries` if named at all.

**"Infra-as-a-deployment-target" is the framing this category adds that no
other category needs.** Every other stack doc in this skill treats "where
does this run" as a settled backdrop assumption its own architecture rests
on top of. This category is the one place the deployment target itself —
the cluster, the VPC, the IAM boundary — is the thing being architected,
provisioned, and versioned. That's exactly why IaC state management,
drift, and blast-radius limiting are this category's own distinctive
concerns, rather than variations on concerns already covered elsewhere in
this skill: no other category's own service has to worry about its own
state file getting corrupted by a concurrent write, because no other
category's own service *is* a state file.

## Where this doc stops

Specific IaC/orchestration/CI-platform tool names, their exact license
terms, pricing tiers beyond what's stated above as an architectural fact,
and comparative maintenance-signal numbers (stars, downloads, module-
registry counts) belong entirely to the companion
[preferred-libraries/infrastructure-platform-engineering.md](../preferred-libraries/infrastructure-platform-engineering.md).
This doc names a tool only where the tool's own behavior *is* the
architectural fact being described — Terraform/OpenTofu's and Vault/
OpenBao's licensing splits, CloudFormation's native `detect-stack-drift`
API, Sentinel's HCP-Terraform-only lock-in, Flagger's and Argo Rollouts'
borrowed rather than independent CNCF standing — not as a comparative
recommendation between products.

Deep service-mesh configuration mechanics (mTLS certificate rotation
internals, specific traffic-shifting CRD syntax) stay out of scope, as the
cross-cutting `architecture-templates.md` doc already scoped for itself;
this doc names only *where* mesh adoption belongs as a decision, not how
to configure one. Kubernetes cluster security hardening in depth (Pod
Security Standards, network-policy authoring, RBAC design patterns) is a
real, adjacent concern this doc doesn't cover — the drift and
blast-radius sections above address a different risk, unintended
infrastructure change, not intended-but-insecure configuration. Deep
secrets-engine internals (Vault's dynamic-secret-backend mechanics, KMS
envelope-encryption detail) stay below the concept-level treatment the
Secrets Management section gives them; OWASP's Secrets Management Cheat
Sheet, already the cross-cutting doc's canonical source, isn't re-derived
here. Observability/monitoring stack selection for infrastructure itself
belongs to whichever category ends up owning cross-cutting observability
concerns generally, not duplicated here even though CI/CD promotion gates
and progressive delivery both depend on metrics existing somewhere. Cost
modeling and cloud pricing comparisons stay out of scope beyond the one
pricing-tier figure named above as a primary-sourced fact, consistent with
every other doc in this skill. On-prem and air-gapped IaC/deployment
constraints remain a real, named gap the cross-cutting doc didn't find a
strong primary source for either, so it stays open here rather than
quietly treated as covered. ML/model-serving-specific platform concerns —
model registries, GPU scheduling, canary rollouts for models specifically —
belong to a still-pending MLOps / ML Platform Engineering category, which
may end up merging with this one once real content exists for both; this
doc doesn't pre-empt that call.

For where a single service's own request/response architecture, resilience
patterns, and API design are decided rather than what it deploys onto, see
[Backend & API Services](backend-api-services.md). For where a library or
CLI tool's own module-boundary and packaging concerns are decided, see
[Developer Tooling & Libraries](developer-tooling-libraries.md) — this
doc's Internal Developer Platforms section builds directly on that doc's
public-surface framing rather than repeating it.

## Sources

- https://www.hashicorp.com/en/license-faq — direct fetch: confirms
  Terraform's Business Source License 1.1, effective 2023-08-10, and the
  "competitive offerings" usage-limitation framing — retrieved 2026-08-31
- IBM/HashiCorp acquisition close — search-corroborated across IBM's own
  Newsroom release, TechCrunch, and SiliconANGLE: confirms close on
  2025-02-27, $6.4B / $35-per-share — retrieved 2026-08-31
- https://opentofu.org/manifesto/ — direct fetch: MPL-2.0 license, Linux
  Foundation governance, the 2023-08-10 BUSL change as the fork's stated
  trigger, 2023-08-25 public-fork date — retrieved 2026-08-31
- OpenTofu's CNCF Sandbox acceptance — search-corroborated across
  independent secondary sources (a Medium write-up, Palark's CNCF-Sandbox
  roundup, TheNewStack): 2025-04-23, TOC vote, Sandbox maturity, a licensing
  exception since MPL-2.0 differs from CNCF's normal Apache-2.0 requirement
  — retrieved 2026-08-31
- https://www.pulumi.com/docs/iac/concepts/state-and-backends/ — direct
  fetch: Pulumi Cloud vs. self-managed "DIY" backend options, "state does
  not include your cloud credentials," transactional-checkpoint state
  model — retrieved 2026-08-31
- Pulumi CLI/SDK licensing — search-corroborated (GitHub `pulumi/pulumi`
  LICENSE listing, Pulumi's own "Pulumi Loves Open Source" post: "does not
  and never will depend on BSL-licensed software") — retrieved 2026-08-31
- https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/detect-drift-stack.html
  — direct fetch: full native drift-detection API mechanics
  (`detect-stack-drift`/`describe-stack-drift-detection-status`/
  `describe-stack-resource-drifts`), per-resource status model, a worked
  SQS drift example — retrieved 2026-08-31
- CDKTF deprecation — search-corroborated across multiple sources (a
  Lobsters discussion, `envzero.com` and `khuonglab.dev` write-ups):
  effective 2025-12-10, GitHub repo archived read-only, stated reason "did
  not find product-market fit at scale" — retrieved 2026-08-31
- https://developer.hashicorp.com/terraform/language/state/locking — direct
  fetch: automatic locking on state-writing operations, `force-unlock`
  mechanics and warning — retrieved 2026-08-31
- Terraform native S3 state locking (no DynamoDB) — search-corroborated
  across multiple practitioner write-ups: experimental in 1.10.0,
  `use_lockfile = true` on the S3 backend, `dynamodb_table` deprecated as
  of 1.11 — retrieved 2026-08-31
- https://github.com/opentofu/opentofu/releases (GitHub Releases API) —
  direct fetch: v1.10.0 release notes state "Native S3 Locking...
  eliminating the need for a separate DynamoDB table" with the identical
  `use_lockfile = true` parameter — confirms OpenTofu/Terraform lockfile
  parity — retrieved 2026-08-31
- https://developer.hashicorp.com/terraform/language/state/sensitive-data
  — direct fetch: plaintext local-state warning, `sensitive`-marked values
  still stored unencrypted in state and plan files, documented mitigation
  stack — retrieved 2026-08-31
- https://www.hashicorp.com/en/products/terraform/pricing — direct fetch:
  confirms Essentials $0.10 / Standard $0.47 / Premium $0.99 per-resource/
  month tiers — retrieved 2026-08-31
- https://developer.hashicorp.com/terraform/cli/commands/plan — direct
  fetch: confirms `-detailed-exitcode` and its 0/1/2 exit-code meanings —
  retrieved 2026-08-31
- https://www.openpolicyagent.org/docs/latest/terraform — direct fetch:
  `terraform show -json` → `opa exec` mechanism, the weighted
  blast-radius-score policy example, the plan-time unknown-values
  limitation — retrieved 2026-08-31
- HashiCorp Sentinel vs. OPA/Conftest current positioning —
  search-corroborated across multiple 2026 comparison posts: Sentinel is
  HCP-Terraform/Terraform-Enterprise-only and does not run against
  OpenTofu; OPA/Conftest is portable and also covers Kubernetes admission
  control — retrieved 2026-08-31
- Terraform workspace vs. separate-state-file/directory best practice —
  search-corroborated across multiple sources including HashiCorp's own
  workspaces best-practices docs and practitioner posts — retrieved
  2026-08-31
- https://raw.githubusercontent.com/hashicorp/vault/main/LICENSE — direct
  fetch: confirms Vault is also BSL 1.1, Licensor IBM, "Vault Version
  1.15.0 or later" — the identical relicensing pattern as Terraform —
  retrieved 2026-08-31
- `github.com/openbao/openbao` (via GitHub API) — direct fetch: MPL-2.0,
  Linux Foundation-governed open fork of Vault — retrieved 2026-08-31
- Secrets-management controller/tool provenance (via GitHub API direct
  fetches of `hashicorp/vault`, `external-secrets/external-secrets`,
  `getsops/sops`, `bitnami-labs/sealed-secrets`): confirms
  External Secrets Operator's Apache-2.0 license and active maintenance
  (pushed 2026-08-28); SOPS's CNCF Sandbox status (accepted 2023-05-17)
  search-corroborated across `cncf.io/projects/sops/` and the `cncf/
  sandbox` GitHub issue tracker; Sealed Secrets' continued maintenance
  despite Broadcom's 2025 Bitnami-catalog changes search-corroborated via
  a `chkk.io` post — retrieved 2026-08-31
- https://www.cncf.io/projects/ — direct fetch, two passes: (1) confirms
  Flux, not Flagger, carries the independent Graduated listing — Flagger
  does not appear as its own separately listed project; (2) confirms
  External Secrets Operator and Argo Rollouts also do not appear as their
  own separately listed entries, while the umbrella **Argo** project
  (accepted 2020-03-26) is listed Graduated — Argo Rollouts borrows its
  CNCF standing from that umbrella the same way Flagger borrows from Flux
  — retrieved 2026-08-31
- https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/
  — direct fetch: declarative vs. imperative object management, the
  patch-not-replace mechanism enabling idempotent repeated `apply` —
  retrieved 2026-08-31
- Kubernetes reconciliation-loop idempotency framing — search-corroborated
  across multiple sources (a "Principle of Reconciliation" post, a
  Kubebuilder-adjacent explainer) — retrieved 2026-08-31
- Kubernetes vs. ECS vs. Cloud Run decision framing, and Docker Compose vs.
  Kubernetes for small teams — search-corroborated across multiple 2026
  comparison sites; specific numeric service-count thresholds traced only
  to secondary/SEO-aggregator sources with no primary-source backing, and
  are named in this doc's own table only as directional signals — retrieved
  2026-08-31
- Helm vs. Kustomize positioning — search-corroborated across multiple 2026
  comparison sites; the "Helm for third-party charts, Kustomize for your
  own apps" hybrid framing traces to this same source set, not a single
  primary source — retrieved 2026-08-31
- https://docs.github.com/en/actions/using-workflows/reusing-workflows —
  direct fetch: `workflow_call` trigger, `uses`/`with`/`secrets` mechanics,
  ten-level nesting limit with no cycles, secrets-propagate-only-through-
  direct-call-chain limitation — retrieved 2026-08-31
- Progressive delivery / canary / blue-green definitions and Flagger/Argo
  Rollouts positioning — search-corroborated across CNCF's own blog
  ("Flagger vs Argo Rollouts vs Service Meshes"), the `fluxcd/flagger`
  GitHub repo description, and Argo Rollouts' own hosted docs — retrieved
  2026-08-31
- https://opengitops.dev/ — direct fetch: the four OpenGitOps principles
  (declarative; versioned and immutable; pulled automatically; continuously
  reconciled), overseen by the CNCF Application Delivery TAG's GitOps
  Working Group — retrieved 2026-08-31
- https://platformengineering.org/blog/what-is-platform-engineering —
  direct fetch: platform engineering and IDP definitions, "platform as a
  product" framing — retrieved 2026-08-31
- Multi-cluster/multi-region Kubernetes topology framing —
  search-corroborated across multiple sources (Plural's own blog posts, an
  Azure Architecture Center AKS multi-region reference architecture); the
  availability/RPO-RTO/latency/compliance driver framing is repeated across
  sources but not confirmed against one single primary architectural
  reference — retrieved 2026-08-31
- Local precedent (not a web source, read directly):
  `/Users/devopammittra/GitHub/ubi-csr-tmf/.github/workflows/*.yml`,
  `charts/{agents,ubi-backend,ubi-frontend}/{Chart.yaml,values.yaml,
  values-dev.yaml}`, `aws/container/docker-compose.yml`, and a
  `find`/`git ls-files`/`git log` check confirming no `.tf`/`cdk.json`/
  CloudFormation file exists anywhere in that repository — read/checked
  2026-08-31
