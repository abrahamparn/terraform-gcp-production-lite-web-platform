# Architecture — Terraform GCP Production-Lite Web Platform

## 1. Overview

This document explains the architecture of the **Terraform GCP Production-Lite Web Platform**.

The project provisions a small but production-shaped web platform on Google Cloud using Terraform.

The main architectural goal is to demonstrate how an application workload can run behind a load balancer while keeping backend VM instances private.

The architecture includes:

```text
Custom VPC
App subnet
Reserved DB subnet
Map-based firewall rules
Cloud Router
Cloud NAT
Application service account
Regional Managed Instance Group
Instance template
Startup script
HTTP health check
Backend service
External HTTP Load Balancer
Remote Terraform state
```

This is not a full enterprise landing zone. It is a focused infrastructure artifact designed to prove the core pattern:

```text
private backend instances
+ Managed Instance Group
+ Cloud NAT
+ health checks
+ external HTTP Load Balancer
+ modular Terraform
```

---

## 2. High-Level Architecture

```text
User
  |
  v
External HTTP Load Balancer
  |
  v
Backend Service
  |
  v
Regional Managed Instance Group
  |
  v
Private Application VM(s)
  |
  v
Outbound Internet through Cloud NAT
```

The backend VM instances do not have external IP addresses.

Inbound user traffic enters through the external HTTP Load Balancer. Outbound internet access from the private VM instances is handled through Cloud NAT.

---

## 3. Architecture Diagram

```mermaid
flowchart TD
    User[User / Browser] --> LB[External HTTP Load Balancer]

    LB --> FR[Global Forwarding Rule]
    FR --> Proxy[Target HTTP Proxy]
    Proxy --> URLMap[URL Map]
    URLMap --> Backend[Backend Service]
    Backend --> MIG[Regional Managed Instance Group]

    MIG --> VM1[Private App VM 1]
    MIG --> VM2[Private App VM 2]

    VM1 --> App1[Application Endpoint]
    VM2 --> App2[Application Endpoint]

    VM1 --> NAT[Cloud NAT]
    VM2 --> NAT
    NAT --> Internet[Outbound Internet]

    Router[Cloud Router] --> NAT

    VPC[VPC Network] --> AppSubnet[App Subnet]
    VPC --> DBSubnet[Reserved DB Subnet]

    AppSubnet --> MIG
    DBSubnet --> FutureDB[Future Database Tier]

    HC[Google Health Check Probes] --> FWLB[Firewall: Allow LB / Health Check]
    FWLB --> VM1
    FWLB --> VM2

    IAP[IAP TCP Forwarding] --> FWIAP[Firewall: Allow IAP SSH]
    FWIAP --> VM1
    FWIAP --> VM2
```

---

## 4. Main Components

| Component              | Purpose                                                 |
| ---------------------- | ------------------------------------------------------- |
| VPC                    | Provides the isolated network boundary for the platform |
| App subnet             | Hosts the application VM instances                      |
| DB subnet              | Reserved for future database tier                       |
| Firewall rules         | Controls ingress access to backend instances            |
| Cloud Router           | Required dependency for Cloud NAT                       |
| Cloud NAT              | Provides outbound internet access for private VMs       |
| Service account        | Runtime identity for application VMs                    |
| Instance template      | Defines how application VMs are created                 |
| Regional MIG           | Manages the application VM instances                    |
| HTTP health check      | Determines whether backend instances are healthy        |
| Backend service        | Connects load balancer to the MIG                       |
| URL map                | Routes HTTP traffic to backend service                  |
| Target HTTP proxy      | Receives HTTP traffic from forwarding rule              |
| Global forwarding rule | Public HTTP listener                                    |
| Global IP address      | External entry point for users                          |
| GCS backend            | Stores Terraform remote state                           |

---

## 5. Network Design

The network layer is defined using a custom VPC.

The project uses map-based subnet creation instead of hardcoding subnet resources one by one.

Example subnet structure:

```hcl
subnets = {
  app = {
    cidr_range            = "10.80.1.0/24"
    private_google_access = true
    role                  = "application"
  }

  db = {
    cidr_range            = "10.80.2.0/24"
    private_google_access = true
    role                  = "database-reserved"
  }
}
```

This gives the network module a reusable pattern.

The module does not need to know in advance how many subnets exist. It only needs to receive a structured map and create subnets using `for_each`.

---

## 6. Subnet Roles

### App Subnet

The app subnet is used by the Managed Instance Group.

Application VM instances are deployed into this subnet.

The app subnet receives outbound internet access through Cloud NAT.

### DB Subnet

The DB subnet is created as a reserved private tier.

This version does not provision a database. The DB subnet exists to show tiered network design and prepare the architecture for future database expansion.

In v1.0:

```text
DB subnet exists.
No database is provisioned.
Cloud NAT is not required for the DB subnet by default.
```

---

## 7. Firewall Design

Firewall rules are defined using a map.

This keeps ingress policy data-driven and modular.

Core firewall rules:

```text
allow-lb-health-check
allow-iap-ssh
allow-internal
```

### allow-lb-health-check

Allows Google Cloud load balancer health check and proxy traffic to reach the backend instances.

Typical source ranges:

```text
35.191.0.0/16
130.211.0.0/22
```

Target:

```text
web-backend network tag
```

Port:

```text
80
```

### allow-iap-ssh

Allows SSH access through Identity-Aware Proxy.

Typical source range:

```text
35.235.240.0/20
```

Target:

```text
web-backend network tag
```

Port:

```text
22
```

This avoids opening SSH directly to the internet.

### allow-internal

Allows internal communication inside the platform CIDR range.

Example source range:

```text
10.80.0.0/16
```

This is useful for future internal communication between app, database, cache, or internal services.

---

## 8. Private Backend Design

The application VMs do not have external IP addresses.

In the instance template, the network interface does not include an `access_config` block.

Example:

```hcl
network_interface {
  subnetwork = var.subnetwork_self_link

  # No access_config block.
  # This intentionally creates VMs without external IP addresses.
}
```

This means the backend VMs only receive internal IP addresses.

They cannot be reached directly from the public internet.

User traffic must enter through the external HTTP Load Balancer.

---

## 9. Cloud NAT Design

Private backend VMs still need outbound internet access for operational tasks such as:

```text
apt-get update
package installation
dependency download
external API calls
system patching
```

Because the VMs do not have external IP addresses, outbound internet access is provided through Cloud NAT.

The intended v1.0 design is:

```text
Cloud NAT applies to selected subnets only.
The app subnet receives NAT.
The reserved DB subnet does not receive NAT by default.
```

This is better than giving NAT access to all subnets because it keeps subnet behavior intentional.

---

## 10. Compute Design

The compute layer uses a regional Managed Instance Group.

The MIG is based on an instance template.

The instance template defines:

```text
machine type
boot disk image
network interface
startup script
network tags
service account
```

The MIG defines:

```text
target size
regional placement
named port
autohealing policy
instance template version
```

A MIG is more production-shaped than a standalone VM because it manages a group of instances consistently.

---

## 11. Health Check Design

The application exposes a dedicated health endpoint:

```text
GET /healthz
```

Expected response:

```text
200 OK
ok
```

The health check path is intentionally separate from the root endpoint.

The root endpoint is user-facing:

```text
GET /
```

The health endpoint is operational:

```text
GET /healthz
```

This separation makes backend health easier to reason about.

---

## 12. Load Balancer Design

The external HTTP Load Balancer provides the public entry point.

The load balancer stack includes:

```text
global external IP address
global forwarding rule
target HTTP proxy
URL map
backend service
health check
MIG backend
```

The public listener is HTTP on port 80.

In v1.0, HTTPS is intentionally not included.

HTTPS will be added in v1.1.

---

## 13. Runtime Application

The application is intentionally simple.

It exposes:

| Endpoint    | Purpose               |
| ----------- | --------------------- |
| `/`         | Root response         |
| `/healthz`  | Health check response |
| `/metadata` | Runtime information   |

Example root response:

```text
Hi from Terraform GCP Production-Lite Platform
```

Example health response:

```text
ok
```

Example metadata response:

```json
{
  "service": "terraform-gcp-production-lite-web-platform",
  "environment": "dev",
  "version": "1.0.0",
  "hostname": "dev-web-mig-xxxx"
}
```

The application is not the main focus. The infrastructure pattern is the focus.

---

## 14. IAM Design

The application VM instances use a dedicated service account.

The service account should follow least privilege.

Recommended roles for v1.0:

```text
roles/logging.logWriter
roles/monitoring.metricWriter
```

Avoid broad roles such as:

```text
roles/editor
roles/owner
```

The admin principal may also need these roles for IAP and OS Login workflows:

```text
roles/iap.tunnelResourceAccessor
roles/compute.osAdminLogin
roles/iam.serviceAccountUser
```

---

## 15. Remote State Design

Terraform state is stored in Google Cloud Storage.

The backend should use a separate prefix for this artifact.

Example:

```hcl
terraform {
  backend "gcs" {
    bucket = "YOUR_TERRAFORM_STATE_BUCKET"
    prefix = "terraform-gcp-production-lite-web-platform/v1"
  }
}
```

The state bucket should already exist before this project is initialized.

The backend file is usually created locally from:

```bash
cp backend.tf.example backend.tf
```

---

## 16. Current Scope

v1.0 includes:

```text
HTTP only
private backend VMs
MIG
Cloud NAT
health checks
load balancer
firewall rules
remote state
modular Terraform
```

v1.0 does not include:

```text
HTTPS
custom domain
Cloud Armor
Cloud SQL
Secret Manager
CI/CD
Kubernetes
multi-region production deployment
```

Those features are deferred to later versions.

---

## 17. Future Architecture Roadmap

### v1.1 — HTTPS and Custom Domain

Planned additions:

```text
Google-managed SSL certificate
custom domain
HTTPS target proxy
global forwarding rule on port 443
HTTP-to-HTTPS redirect
```

### v1.2 — Security Hardening

Planned additions:

```text
Cloud Armor
stronger firewall posture
edge security policy documentation
```

### v2.0 — Terraform CI/CD

Planned additions:

```text
GitHub Actions
plan on pull request
manual apply approval
Workload Identity Federation
no service account key
```

### v3.0 — Database and Secrets

Planned additions:

```text
Cloud SQL private IP
Secret Manager
private service access
application configuration loading
```

---

## 18. Architecture Summary

This platform demonstrates the following design principle:

```text
Application backends should not be directly exposed to the internet.
Traffic should enter through a controlled entry point.
Private workloads should use NAT for outbound access.
Infrastructure should be reproducible through Terraform.
```

The key pattern is:

```text
External HTTP Load Balancer
-> Backend Service
-> Regional MIG
-> Private App VMs
-> Cloud NAT for outbound access
```

This is the core production-lite web platform pattern for v1.0.
