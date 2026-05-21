# Operations Runbook — Terraform GCP Production-Lite Web Platform

## 1. Purpose

This runbook explains how to operate and troubleshoot the Production-Lite GCP Web Platform after deployment.

The platform includes:

```text
External HTTP Load Balancer
Backend Service
Regional Managed Instance Group
Private application VMs
Cloud NAT
Firewall rules
IAP SSH access
```

Use this runbook when checking health, debugging failed deployments, inspecting application logs, or validating platform behavior.

---

## 2. Operational Model

The platform follows this model:

```text
Users do not access backend VMs directly.
Users access the external HTTP Load Balancer.
The load balancer sends traffic to the backend service.
The backend service sends traffic to the regional MIG.
The MIG manages private application VMs.
Private VMs use Cloud NAT for outbound internet.
Admin access uses IAP SSH.
```

---

## 3. Common Operational Commands

### Show Terraform outputs

```bash
terraform output
```

### Show platform summary

```bash
terraform output platform_summary
```

### Test root endpoint

```bash
curl -i http://LOAD_BALANCER_IP
```

### Test health endpoint

```bash
curl -i http://LOAD_BALANCER_IP/healthz
```

### Test metadata endpoint

```bash
curl -i http://LOAD_BALANCER_IP/metadata
```

---

## 4. Load Balancer Operations

### List global forwarding rules

```bash
gcloud compute forwarding-rules list --global
```

### Describe HTTP forwarding rule

```bash
gcloud compute forwarding-rules describe FORWARDING_RULE_NAME \
  --global
```

### List target HTTP proxies

```bash
gcloud compute target-http-proxies list
```

### List URL maps

```bash
gcloud compute url-maps list
```

### List backend services

```bash
gcloud compute backend-services list --global
```

### Describe backend service

```bash
gcloud compute backend-services describe BACKEND_SERVICE_NAME \
  --global
```

### Check backend health

```bash
gcloud compute backend-services get-health BACKEND_SERVICE_NAME \
  --global
```

Expected healthy output should indicate that backend instances are serving.

If backend health is unhealthy, check:

```text
firewall rule
health check path
application service
MIG instance status
startup script logs
network tag
named port
```

---

## 5. Managed Instance Group Operations

### List MIGs

```bash
gcloud compute instance-groups managed list
```

### Describe MIG

```bash
gcloud compute instance-groups managed describe MIG_NAME \
  --region=asia-southeast2
```

### List MIG instances

```bash
gcloud compute instance-groups managed list-instances MIG_NAME \
  --region=asia-southeast2
```

### Check MIG target size

```bash
gcloud compute instance-groups managed describe MIG_NAME \
  --region=asia-southeast2 \
  --format="value(targetSize)"
```

### Resize MIG manually

Manual resize is not recommended because Terraform owns the desired state.

If you need to change size, update:

```hcl
mig_instance_count = 2
```

Then run:

```bash
terraform plan
terraform apply
```

If you manually resize through the console or CLI, Terraform may detect drift later.

---

## 6. VM Operations

### List instances

```bash
gcloud compute instances list
```

### Confirm VM has no external IP

```bash
gcloud compute instances list \
  --format="table(name,zone,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP)"
```

The external IP column should be empty for backend instances.

### SSH through IAP

```bash
gcloud compute ssh INSTANCE_NAME \
  --zone=asia-southeast2-a \
  --tunnel-through-iap
```

### Check application service

Inside the VM:

```bash
sudo systemctl status prod-lite-app
```

### Restart application service

```bash
sudo systemctl restart prod-lite-app
```

### Stop application service

```bash
sudo systemctl stop prod-lite-app
```

### Start application service

```bash
sudo systemctl start prod-lite-app
```

### Check application logs

```bash
sudo journalctl -u prod-lite-app --no-pager -n 100
```

### Follow application logs

```bash
sudo journalctl -u prod-lite-app -f
```

### Check startup script logs

```bash
sudo journalctl -u google-startup-scripts.service --no-pager -n 100
```

### Test app locally

```bash
curl -i http://localhost/
curl -i http://localhost/healthz
curl -i http://localhost/metadata
```

Expected:

```text
/        returns application message
/healthz returns ok
/metadata returns JSON
```

---

## 7. Cloud NAT Operations

### List Cloud Routers

```bash
gcloud compute routers list \
  --regions=asia-southeast2
```

### Describe Cloud Router

```bash
gcloud compute routers describe ROUTER_NAME \
  --region=asia-southeast2
```

### List NAT gateways

```bash
gcloud compute routers nats list \
  --router=ROUTER_NAME \
  --region=asia-southeast2
```

### Describe NAT gateway

```bash
gcloud compute routers nats describe NAT_NAME \
  --router=ROUTER_NAME \
  --region=asia-southeast2
```

### Test outbound internet from private VM

SSH into the VM through IAP:

```bash
gcloud compute ssh INSTANCE_NAME \
  --zone=asia-southeast2-a \
  --tunnel-through-iap
```

Then test:

```bash
curl -I https://example.com
```

Expected:

```text
HTTP response is returned.
```

If this fails, investigate Cloud NAT configuration.

---

## 8. Firewall Operations

### List firewall rules

```bash
gcloud compute firewall-rules list
```

### Filter platform firewall rules

```bash
gcloud compute firewall-rules list \
  --filter="name~dev-"
```

### Check load balancer health check firewall rule

```bash
gcloud compute firewall-rules list \
  --filter="name~allow-lb"
```

Expected source ranges:

```text
35.191.0.0/16
130.211.0.0/22
```

Expected target tag:

```text
web-backend
```

Expected port:

```text
80
```

### Check IAP SSH firewall rule

```bash
gcloud compute firewall-rules list \
  --filter="name~iap"
```

Expected source range:

```text
35.235.240.0/20
```

Expected port:

```text
22
```

---

## 9. IAM Operations

### Check IAM policy for admin principal

```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL@example.com"
```

Expected roles for IAP SSH workflow may include:

```text
roles/iap.tunnelResourceAccessor
roles/compute.osAdminLogin
```

### Check service account

```bash
gcloud iam service-accounts list \
  --filter="email~prod-lite"
```

### Check service account IAM policy

```bash
gcloud iam service-accounts get-iam-policy SERVICE_ACCOUNT_EMAIL
```

---

## 10. Health Check Operations

### List health checks

```bash
gcloud compute health-checks list
```

### Describe health check

```bash
gcloud compute health-checks describe HEALTH_CHECK_NAME
```

Expected configuration:

```text
protocol: HTTP
port: 80
request path: /healthz
```

### Test health endpoint externally

```bash
curl -i http://LOAD_BALANCER_IP/healthz
```

### Test health endpoint locally on VM

```bash
curl -i http://localhost/healthz
```

---

## 11. Troubleshooting Scenarios

## Scenario 1 — Load Balancer Returns 502

Symptoms:

```text
curl to load balancer returns 502
backend service unhealthy
root endpoint unavailable
```

Possible causes:

```text
application service is not running
startup script failed
health check path is wrong
firewall rule does not allow health check probes
target tag mismatch
backend service points to wrong MIG
named port mismatch
```

Investigation steps:

```bash
gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global
```

SSH into VM:

```bash
gcloud compute ssh INSTANCE_NAME \
  --zone=asia-southeast2-a \
  --tunnel-through-iap
```

Check service:

```bash
sudo systemctl status prod-lite-app
sudo journalctl -u prod-lite-app --no-pager -n 100
sudo journalctl -u google-startup-scripts.service --no-pager -n 100
```

Test locally:

```bash
curl -i http://localhost/healthz
```

Fix based on the failure:

```text
restart service
fix startup script
fix firewall rule
fix health check path
fix named port
rerun terraform apply
```

---

## Scenario 2 — Backend Service Is Unhealthy

Symptoms:

```text
backend service reports unhealthy
load balancer does not serve traffic
```

Check health:

```bash
gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global
```

Check health check config:

```bash
gcloud compute health-checks describe HEALTH_CHECK_NAME
```

Check firewall:

```bash
gcloud compute firewall-rules list \
  --filter="name~allow-lb"
```

Check VM tag:

```bash
gcloud compute instances describe INSTANCE_NAME \
  --zone=asia-southeast2-a \
  --format="value(tags.items)"
```

The firewall rule target tag must match the VM network tag.

---

## Scenario 3 — IAP SSH Fails

Symptoms:

```text
cannot SSH into private VM
IAP tunnel error
permission denied
connection timeout
```

Possible causes:

```text
missing IAP role
missing OS Login role
missing serviceAccountUser role
missing allow-iap-ssh firewall rule
VM does not have expected network tag
OS Login issue
```

Check firewall:

```bash
gcloud compute firewall-rules list \
  --filter="name~iap"
```

Check IAM:

```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL@example.com"
```

Retry:

```bash
gcloud compute ssh INSTANCE_NAME \
  --zone=asia-southeast2-a \
  --tunnel-through-iap
```

---

## Scenario 4 — VM Cannot Access Internet

Symptoms:

```text
startup script fails during apt-get update
npm install fails
curl external site fails
```

Possible cause:

```text
Cloud NAT is missing or not applied to the app subnet.
```

Check NAT:

```bash
gcloud compute routers nats list \
  --router=ROUTER_NAME \
  --region=asia-southeast2
```

Describe NAT:

```bash
gcloud compute routers nats describe NAT_NAME \
  --router=ROUTER_NAME \
  --region=asia-southeast2
```

From VM:

```bash
curl -I https://example.com
```

If outbound access fails, check:

```text
NAT subnet configuration
Cloud Router region
VM subnet
routing
organization policy
```

---

## Scenario 5 — Terraform Plan Shows Unexpected Replacement

Symptoms:

```text
terraform plan wants to replace instance template
terraform plan wants to update MIG
```

Explanation:

```text
Instance templates are immutable.
Changes to startup script, image, metadata, machine type, disk, tags, or service account often create a new instance template.
```

This is usually expected.

Review whether the replacement is safe.

Then apply:

```bash
terraform apply
```

---

## Scenario 6 — Terraform Detects Drift

Symptoms:

```text
terraform plan shows changes that you did not make in code
```

Possible causes:

```text
someone changed infrastructure manually in console
MIG was resized manually
firewall rule was edited manually
load balancer setting was changed manually
```

Recommended response:

```text
Do not immediately apply.
Read the plan.
Identify the source of drift.
Decide whether to keep the manual change by updating Terraform code or revert it by applying Terraform.
```

This is one reason infrastructure should be managed through code.

---

## 12. Operational Checklist

Use this checklist after every deployment:

```text
[ ] terraform apply completed
[ ] terraform output shows load_balancer_url
[ ] root endpoint returns expected response
[ ] /healthz returns 200 OK
[ ] /metadata returns JSON
[ ] backend service is healthy
[ ] MIG target size is correct
[ ] backend VMs have no external IP
[ ] Cloud NAT exists
[ ] IAP SSH works
[ ] startup script logs show success
```

---

## 13. Escalation Notes

For this portfolio project, escalation means deeper debugging.

Recommended order:

```text
1. Check Terraform output.
2. Check load balancer response.
3. Check backend service health.
4. Check MIG instances.
5. SSH through IAP.
6. Check application service.
7. Check startup script logs.
8. Check firewall rules.
9. Check Cloud NAT.
10. Review terraform plan for drift.
```

---

## 14. Operating Principle

The main operating principle for this project:

```text
Do not fix infrastructure manually unless it is temporary debugging.
Any permanent fix should be reflected in Terraform code.
```

Manual fixes create drift.

Terraform should remain the source of truth.
