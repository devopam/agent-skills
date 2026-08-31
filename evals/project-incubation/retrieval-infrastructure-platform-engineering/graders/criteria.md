# Grading criteria: retrieval — Infrastructure & Platform Engineering

Tests whether `project-incubation` picks the right category for a
platform-team project whose deliverable IS the infrastructure/deployment
tooling itself (not Backend & API Services, and not the individual app
teams' own service categories), and applies this category's central
IaC-tool decision rule correctly for a **no-existing-HCP/Sentinel-
investment** scenario specifically — designed to trigger the OpenTofu
branch, not the "stick with Terraform" branch.

## Must show

- Selects **Infrastructure & Platform Engineering** as the category — the
  deliverable here is the deployment target itself (cluster, VPC, IAM,
  paved-path tooling), not a request/response service (Backend & API
  Services) or an end-user-facing app (Business Applications).
- Names **OpenTofu** as the default IaC tool for this scenario specifically
  (or reasons through why: no existing Terraform Cloud/Sentinel
  investment to preserve, and OpenTofu's MPL-2.0/Linux-Foundation
  governance versus Terraform's BSL/IBM-owned status) — not defaulting to
  Terraform without comment, and not presenting Terraform as the only
  option.
- Does NOT claim Terraform is simply "deprecated" or "no longer usable" —
  the skill should present Terraform as a fully legitimate choice for
  teams with an existing investment, while still landing on OpenTofu as
  this scenario's actual recommendation.
- Surfaces the "internal developer platform" / "platform as a product"
  framing given the prompt explicitly describes a paved-path/self-service
  goal for other teams — not just a bare IaC tool recommendation with no
  mention of the self-service layer on top.
- If state management comes up, names the current S3-native-locking
  approach (`use_lockfile`) rather than only the legacy S3+DynamoDB-table
  pattern.

## Should not show

- Treating this as Backend & API Services, Business Applications, or
  Developer Tooling & Libraries.
- Recommending HashiCorp Vault or HCP Terraform as an unqualified default
  without at least noting the BSL/IBM licensing situation, given the
  prompt's explicit "starting from scratch, nothing to migrate" framing.
- Presenting Kubernetes adoption as a default with no decision rule, or
  citing a specific unverified numeric service-count threshold (e.g. "you
  need 5+ services for Kubernetes") as if it were a settled fact.
