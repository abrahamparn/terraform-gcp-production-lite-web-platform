# Verification Guide — Terraform GCP Production-Lite Web Platform

## 1. Purpose

This document provides verification steps for the Production-Lite GCP Web Platform after Terraform deployment.

Use this guide to confirm that the infrastructure is working correctly.

The verification checks cover:

```text
Terraform outputs
load balancer response
application endpoints
VPC and subnet creation
firewall rules
Cloud NAT
Managed Instance Group
backend health
private VM posture
IAP SSH
application service
```

---

## 2. Verification Checklist

The platform is considered successfully deployed when:

```text
[ ] Terraform output is available
[ ] Load balancer IP exists
[ ] Root endpoint works
[ ] /healthz returns 200
[ ] /metadata returns JSON
[ ] VPC exists
[ ] App subnet exists
[ ] DB subnet exists
[ ] Firewall rules exist
[ ] Cloud Router exists
[ ] Cloud NAT exists
[ ] MIG exists
[ ] Backend service is healthy
[ ] Backend VMs have no external IP
[ ] IAP SSH works
[ ] Application service is running
```

---

## 3. Verify Terraform Output

Run:

```bash
terraform output
```

Expected outputs:

```text
network_name
subnets
firewall_rules
cloud_nat_name
cloud_router_name
health_check_name
mig_name
mig_instance_group
load_balancer_ip
load_balancer_url
curl_test_command
curl_health_check_command
platform_summary
```

Example:

```text
load_balancer_url = "http://34.xxx.xxx.xxx"
```

---

## 4. Verify Root Endpoint

Run:

```bash
curl -i http://LOAD_BALANCER_IP
```

Expected response:

```text
HTTP/1.1 200 OK
```

Expected body:

```text
Hi from Terraform GCP Production-Lite Platform
```

If this fails, wait a few minutes and try again.

The load balancer may take time to mark the backend healthy.

---

## 5. Verify Health Endpoint

Run:

```bash
curl -i http://LOAD_BALANCER_IP/healthz
```

Expected response:

```text
HTTP/1.1 200 OK

ok
```

This endpoint is used to confirm that the application is alive.

---

## 6. Verify Metadata Endpoint

Run:

```bash
curl -i http://LOAD_BALANCER_IP/metadata
```

Expected response:

```json
{
  "service": "terraform-gcp-production-lite-web-platform",
  "environment": "dev",
  "version": "1.0.0",
  "hostname": "dev-web-mig-xxxx"
}
```

The `hostname` value should come from the backend VM instance.

---

## 7. Verify VPC

Run:

```bash
gcloud compute networks list
```

Or filter:

```bash
gcloud compute networks list \
  --filter="name~web-platform"
```

Expected:

```text
VPC network exists
auto subnet mode is disabled
```

To describe:

```bash
gcloud compute networks describe NETWORK_NAME
```

Check:

```text
autoCreateSubnetworks: false
routingConfig.routingMode: REGIONAL
```

---

## 8. Verify Subnets

Run:

```bash
gcloud compute networks subnets list \
  --regions=asia-southeast2
```

Expected subnets:

```text
dev-app-subnet
dev-db-subnet
```

Names may differ depending on your environment and naming variables.

Describe app subnet:

```bash
gcloud compute networks subnets describe APP_SUBNET_NAME \
  --region=asia-southeast2
```

Describe DB subnet:

```bash
gcloud compute networks subnets describe DB_SUBNET_NAME \
  --region=asia-southeast2
```

Check:

```text
CIDR ranges match terraform.tfvars
privateIpGoogleAccess is enabled if configured
```

---

## 9. Verify Firewall Rules

List firewall rules:

```bash
gcloud compute firewall-rules list
```

Filter platform rules:

```bash
gcloud compute firewall-rules list \
  --filter="name~dev-"
```

Expected firewall rules:

```text
allow-lb-health-check
allow-iap-ssh
allow-internal
```

### Verify Load Balancer / Health Check Rule

```bash
gcloud compute firewall-rules describe FIREWALL_RULE_NAME
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

Expected allowed port:

```text
tcp:80
```

### Verify IAP SSH Rule

Expected source range:

```text
35.235.240.0/20
```

Expected allowed port:

```text
tcp:22
```

### Verify No Public SSH Rule

Check that there is no rule allowing:

```text
0.0.0.0/0 -> tcp:22
```

This should not exist.

---

## 10. Verify Cloud Router

Run:

```bash
gcloud compute routers list \
  --regions=asia-southeast2
```

Expected:

```text
Cloud Router exists
region is correct
network is correct
```

Describe:

```bash
gcloud compute routers describe ROUTER_NAME \
  --region=asia-southeast2
```

---

## 11. Verify Cloud NAT

Run:

```bash
gcloud compute routers nats list \
  --router=ROUTER_NAME \
  --region=asia-southeast2
```

Expected:

```text
Cloud NAT exists
NAT region matches app subnet region
```

Describe:

```bash
gcloud compute routers nats describe NAT_NAME \
  --router=ROUTER_NAME \
  --region=asia-southeast2
```

Check:

```text
natIpAllocateOption: AUTO_ONLY
sourceSubnetworkIpRangesToNat: LIST_OF_SUBNETWORKS
```

If your v1.0 still uses all subnet NAT, document it and improve later.

Preferred target design:

```text
Only app subnet receives NAT.
DB subnet does not receive NAT by default.
```

---

## 12. Verify Service Account

List service accounts:

```bash
gcloud iam service-accounts list \
  --filter="email~prod-lite"
```

Expected:

```text
application service account exists
```

Check IAM bindings:

```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:SERVICE_ACCOUNT_EMAIL"
```

Expected roles may include:

```text
roles/logging.logWriter
roles/monitoring.metricWriter
```

The service account should not have:

```text
roles/editor
roles/owner
```

---

## 13. Verify Instance Template

List instance templates:

```bash
gcloud compute instance-templates list
```

Describe template:

```bash
gcloud compute instance-templates describe INSTANCE_TEMPLATE_NAME
```

Check:

```text
machine type
disk image
network tags
service account
startup script metadata
no external access config
```

---

## 14. Verify Managed Instance Group

List MIGs:

```bash
gcloud compute instance-groups managed list
```

Describe MIG:

```bash
gcloud compute instance-groups managed describe MIG_NAME \
  --region=asia-southeast2
```

Check:

```text
target size
instance template
named port
autohealing policy
distribution zones
```

List instances:

```bash
gcloud compute instance-groups managed list-instances MIG_NAME \
  --region=asia-southeast2
```

Expected:

```text
instances are running
instances are part of the MIG
```

---

## 15. Verify Backend Service

List backend services:

```bash
gcloud compute backend-services list --global
```

Describe backend service:

```bash
gcloud compute backend-services describe BACKEND_SERVICE_NAME \
  --global
```

Check:

```text
protocol: HTTP
load balancing scheme: EXTERNAL_MANAGED
port name: http
health check attached
backend group points to MIG instance group
```

---

## 16. Verify Backend Health

Run:

```bash
gcloud compute backend-services get-health BACKEND_SERVICE_NAME \
  --global
```

Expected:

```text
backend instances are healthy
```

If unhealthy:

```text
wait a few minutes
check firewall rules
check health check path
check app service
check startup logs
```

---

## 17. Verify Global Forwarding Rule

List:

```bash
gcloud compute forwarding-rules list --global
```

Describe:

```bash
gcloud compute forwarding-rules describe FORWARDING_RULE_NAME \
  --global
```

Expected:

```text
IP address matches Terraform output
port range is 80
target points to target HTTP proxy
load balancing scheme is EXTERNAL_MANAGED
```

---

## 18. Verify Backend VMs Have No External IP

List instances:

```bash
gcloud compute instances list
```

Or use table output:

```bash
gcloud compute instances list \
  --format="table(name,zone,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP)"
```

Expected:

```text
internal IP exists
external IP is empty
```

This confirms that backend instances are private.

---

## 19. Verify IAP SSH

SSH into a backend instance:

```bash
gcloud compute ssh INSTANCE_NAME \
  --zone=asia-southeast2-a \
  --tunnel-through-iap
```

Expected:

```text
SSH session opens successfully
```

Inside the VM:

```bash
hostname
curl -i http://localhost/
curl -i http://localhost/healthz
curl -i http://localhost/metadata
```

Exit:

```bash
exit
```

---

## 20. Verify Application Service

Inside the VM:

```bash
sudo systemctl status prod-lite-app
```

Expected:

```text
active (running)
```

Check logs:

```bash
sudo journalctl -u prod-lite-app --no-pager -n 50
```

Check startup script logs:

```bash
sudo journalctl -u google-startup-scripts.service --no-pager -n 100
```

---

## 21. Verify Outbound Internet from Private VM

Inside the VM:

```bash
curl -I https://example.com
```

Expected:

```text
HTTP response from example.com
```

This confirms that Cloud NAT works.

If it fails:

```text
check Cloud NAT
check subnet selection
check router region
check VM subnet
```

---

## 22. Verification Evidence for Portfolio

Capture screenshots or terminal output for:

```text
terraform apply complete
terraform output
curl root endpoint
curl /healthz
curl /metadata
backend service health
VM list showing no external IP
Cloud NAT configuration
MIG list
```

Suggested folder:

```text
docs/images/
```

Suggested filenames:

```text
01-terraform-apply.png
02-terraform-output.png
03-root-endpoint.png
04-healthz.png
05-metadata.png
06-backend-health.png
07-private-vm-no-external-ip.png
08-cloud-nat.png
09-mig.png
```

---

## 23. Final Verification Statement

The platform is verified when this statement is true:

```text
A user can reach the application through the external HTTP Load Balancer, while the backend VM instances remain private, healthy, managed by a regional MIG, and able to reach outbound internet only through Cloud NAT.
```
