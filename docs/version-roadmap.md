# Version Roadmap

## v1.0 — Production-Lite HTTP Platform

Status: Completed

- VPC
- map-based subnets
- map-based firewall rules
- app subnet
- reserved DB subnet
- Cloud NAT for app subnet
- app service account
- regional MIG
- instance template
- startup script
- HTTP health check
- external HTTP load balancer
- verification docs

## v1.1 — HTTPS and Custom Domain

Status: Completed

- Google-managed SSL certificate
- custom domain
- HTTPS target proxy
- global forwarding rule on 443
- HTTP-to-HTTPS redirect

## v1.2 — Security Hardening

Status: Completed

- Cloud Armor backend security policy
- backend service policy attachment
- load balancer request logging for policy evaluation
- security rollout and verification documentation

## v2.0 — Terraform CI/CD

Status: Completed

- GitHub Actions
- plan on pull request
- manual approval before apply
- Workload Identity Federation
- no service account JSON key
- environment-specific tfvars file
- plan artifact and PR plan visibility

## v2.1 — Drift and Recovery

- manual console change
- drift detection
- terraform state inspection
- terraform import
- recovery explanation

## v3.0 — Database and Secrets

- Cloud SQL private IP
- Secret Manager
- private service access
- app configuration loading
