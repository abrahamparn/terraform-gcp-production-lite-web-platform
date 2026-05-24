# Workload Identity Federation Setup

## Purpose

This document explains how GitHub Actions authenticates to Google Cloud without a service account JSON key.

## Authentication Flow

```text
GitHub Actions OIDC token
  -> Workload Identity Pool
  -> Workload Identity Provider
  -> Terraform CI/CD service account
  -> Google Cloud APIs
```

## Required Google Cloud Resources

```text
Workload Identity Pool
Workload Identity Provider
Terraform CI/CD service account
IAM binding for roles/iam.workloadIdentityUser
Project IAM roles for Terraform operations
GCS state bucket access
```

## Repository Restriction

The provider uses an attribute condition:

```text
assertion.repository == 'OWNER/REPO'
```

This restricts authentication to the intended GitHub repository.

## Required GitHub Workflow Permission

Each workflow that uses WIF must include:

```yaml
permissions:
  contents: read
  id-token: write
```

The `id-token: write` permission allows GitHub Actions to request an OIDC token.

## Required GitHub Variables

```text
GCP_PROJECT_ID
GCP_PROJECT_NUMBER
GCP_REGION
GCP_WORKLOAD_IDENTITY_PROVIDER
GCP_SERVICE_ACCOUNT
TF_WORKING_DIR
TF_VERSION
```

## No Static Key Policy

This project does not use:

```text
GOOGLE_APPLICATION_CREDENTIALS JSON key
service account key file
base64-encoded credential secret
```

If a workflow requires a service account JSON key, the design is wrong for this v2.0 objective.
