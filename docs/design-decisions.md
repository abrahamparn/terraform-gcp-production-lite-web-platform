# Design Decisions

## Decision 1 - Use private backend vms

The application instances are created without external IP addresses. User traffic enters through the external HTTP load balancer. Outbound internet access is provided by Cloud NAT.

## Decision 2 — Use map-based subnet definitions

Subnets are defined as a map so the network module can create any number of subnets without duplicating Terraform codes.

## Decision 3 — Use map-based firewall rules

Firewall rules are defined as a map to keep traffic policy data-driven and easy to extend.

## Decision 4 — Apply Cloud NAT only to the app subnet

The app subnet needs outbound internet access for package installation and external calls. The reserved database subnet does not receive NAT by default.

## Decision 5 — Use a regional Managed Instance Group

The application instances are managed through a regional MIG so the workload can be managed as a group based on an instance template.

## Decision 6 — Use HTTP only in v1.0

HTTPS is intentionally deferred to v1.1. The v1.0 objective is to prove core platform infrastructure: private backends, NAT, MIG, health checks, and HTTP load balancing.

## Decision 7 — Reserve a DB subnet without provisioning a database

The DB subnet demonstrates tiered network design. A database is intentionally not provisioned in v1.0 because the artifact focuses on web platform infrastructure.

## Decision 8 - Add HTTPS in v1.1

add https because real public web platform should not rely on plain http for user traffic

## Decision 9 - use google managed ssl certificate

I Use google managed ssl certificate because google provisions and renew it themselves.

## Decision 10 - Use the same global ip for http and https

this keeps DNS simple and allow http to https redirect to work cleanly

## Decision 11 — Add Cloud Armor in v1.2

v1.2 introduces Cloud Armor as the first edge security layer for the public load balancer.

## Decision 12 — Use preview mode for WAF rules

SQLi and XSS WAF rules are initially deployed in preview mode. This allows the platform to observe potential matches without blocking legitimate traffic. The goal is to avoid breaking the application with aggressive rules before logs are reviewed.

## Decision 13 — Keep default action as allow

The default Cloud Armor rule remains allow in v1.2. This is intentional because the project is a public web platform and should not become deny-by-default until explicit allowlist

## Decision 14 — Remove broad internal firewall access

v1.2 tightens this posture by keeping only required ingress paths

## Decision 15 — Enable backend logging

Backend service logging is enabled so Cloud Armor decisions and load balancer requests can be reviewed in Cloud Logging.

## Decision 16 — Add Terraform CI/CD in v2.0

v2.0 introduces GitHub Actions for Terraform validation, planning, and controlled apply. The goal is to move infrastructure changes through a repeatable review path instead of relying only on local terminal commands.

## Decision 17 — Run Terraform plan on pull requests

The plan workflow runs `terraform fmt -check -recursive`, `terraform init`, `terraform validate`, and `terraform plan` for pull requests. This makes the infrastructure diff visible before merge and catches formatting or validation errors early.

## Decision 18 — Keep Terraform apply manual

Apply is intentionally not automatic on merge. The apply workflow is manually triggered with `workflow_dispatch`, requires the user to type `APPLY`, and is designed to run behind the `terraform-apply` GitHub environment. This keeps real infrastructure mutation behind explicit human approval.

## Decision 19 — Use Workload Identity Federation instead of service account keys

GitHub Actions authenticates to Google Cloud through Workload Identity Federation. This avoids committing, storing, rotating, or leaking a long-lived service account JSON key.

## Decision 20 — Keep environment values in `environments/dev.tfvars`

v2.0 introduces an environment-specific tfvars file for CI. This keeps the workflow command stable while allowing environment inputs to live in a predictable location. Sensitive values must still stay out of committed tfvars files.
