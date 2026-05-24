# Terraform CI/CD — v2.0

## Overview

v2.0 introduces Terraform CI/CD using GitHub Actions.

The goal is controlled infrastructure change:

```text
Pull Request -> terraform fmt -> init -> validate -> plan
Manual approval -> terraform apply
```

## Workflows

This repository uses two workflows:

| Workflow        | Trigger                  | Purpose                               |
| --------------- | ------------------------ | ------------------------------------- |
| Terraform Plan  | Pull request to main     | Review infrastructure changes         |
| Terraform Apply | Manual workflow_dispatch | Apply approved infrastructure changes |

## Authentication

The workflows authenticate to Google Cloud using Workload Identity Federation.

No service account JSON key is used.

Authentication flow:

```text
GitHub Actions OIDC token
  -> Google Workload Identity Provider
  -> Terraform CI/CD service account impersonation
  -> Google Cloud APIs
```

## Manual Approval

The apply workflow uses the GitHub environment:

```text
terraform-apply
```

This environment can require reviewer approval before the job proceeds.

## Terraform State

Terraform state remains stored in the existing GCS backend.

The CI/CD service account is granted access to the remote state bucket.

## Variable Strategy

v2.0 uses:

```text
environments/dev.tfvars
```

This file contains non-sensitive environment configuration.

Sensitive values must not be committed.

## Apply Rules

Normal apply process:

```text
1. Open Pull Request.
2. Review Terraform plan.
3. Merge PR.
4. Manually run Terraform Apply workflow on main.
5. Approve GitHub environment deployment.
6. Review apply logs.
```

## Design Principle

Terraform CI/CD is not just automation.

It is change control for infrastructure.
