# Verification Guide — Terraform GCP Production-Lite Web Platform

## 1. Purpose

This document provides verification steps for the Production-Lite GCP Web Platform after Terraform deployment.

Use this guide to confirm that the infrastructure is working correctly.

The verification checks cover:

```text
Terraform outputs
load balancer response
DNS records
Google-managed SSL certificate
HTTPS response
HTTP-to-HTTPS redirect
Cloud Armor security policy
backend request logging
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
[ ] Domain resolves to the load balancer IP
[ ] HTTPS certificate is active when HTTPS is enabled
[ ] HTTPS endpoint works when HTTPS is enabled
[ ] HTTP redirects to HTTPS when redirect is enabled
[ ] Cloud Armor policy is attached when Cloud Armor is enabled
[ ] Backend request logging is enabled during Cloud Armor verification
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
health_check_path
mig_name
mig_instance_group
load_balancer_ip
load_balancer_url
curl_test_command
curl_health_check_command
https_enabled
http_redirect_enabled
managed_ssl_certificate_domains
https_url
ssl_certificate_name
https_forwarding_rule_name
backend_service_name
cloud_armor_enabled
cloud_armor_policy_name
cloud_armor_policy_self_link
backend_logging_enabled
backend_log_sample_rate
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

## 5. Verify DNS for Custom Domain

Use this section when `managed_ssl_certificate_domains` contains one or more domains.

Get the load balancer IP:

```bash
terraform output -raw load_balancer_ip
```

Check DNS:

```bash
dig +short mydomain.tld A
dig +short www.mydomain.tld A
```

Expected:

```text
Both records return the load balancer IP.
```

Example:

```text
mydomain.tld      -> 8.233.201.124
www.mydomain.tld  -> 8.233.201.124
```

If DNS does not match the load balancer IP:

```text
check the registrar DNS records
remove conflicting parking or redirect records
wait for DNS propagation
do not enable HTTP-to-HTTPS redirect yet
```

---

## 6. Verify Google-Managed SSL Certificate

Use this section when `enable_https = true`.

Get the certificate name:

```bash
terraform output -raw ssl_certificate_name
```

Describe the certificate:

```bash
gcloud compute ssl-certificates describe CERTIFICATE_NAME \
  --global
```

The `gcloud` resource name is `ssl-certificates` plural.

Example:

```bash
gcloud compute ssl-certificates describe dev-web-lb-managed-cert \
  --global
```

Check:

```text
type: MANAGED
managed.status: ACTIVE
managed.domainStatus.<domain>: ACTIVE
```

If the status is `PROVISIONING`, wait and check again:

```bash
gcloud compute ssl-certificates describe CERTIFICATE_NAME \
  --global \
  --format="yaml(name,type,managed)"
```

Common reasons for a certificate staying in `PROVISIONING`:

```text
domain does not resolve to the load balancer IP
DNS was recently changed and has not propagated
forwarding rule on port 443 is not created yet
certificate domain list does not match the public DNS names
```

---

## 7. Verify HTTPS Endpoint

Use this section when `enable_https = true`.

Run:

```bash
curl -I https://mydomain.tld
```

Expected response:

```text
HTTP/2 200
```

or:

```text
HTTP/1.1 200 OK
```

Then verify the body:

```bash
curl -i https://mydomain.tld
```

Expected body:

```text
Hi from Terraform GCP Production-Lite Platform
```

Verify the health endpoint through HTTPS:

```bash
curl -i https://mydomain.tld/healthz
```

Expected:

```text
HTTP response is 200
body is ok
```

---

## 8. Verify HTTP-to-HTTPS Redirect

Use this section when `enable_http_redirect = true`.

Run:

```bash
curl -I http://mydomain.tld
```

Expected response:

```text
HTTP/1.1 301 Moved Permanently
location: https://mydomain.tld/
```

The exact header casing may differ. `Location` and `location` are equivalent.

Also check the `www` hostname if it is in `managed_ssl_certificate_domains`:

```bash
curl -I http://www.mydomain.tld
```

Expected response:

```text
HTTP/1.1 301 Moved Permanently
location: https://www.mydomain.tld/
```

Follow redirects end to end:

```bash
curl -IL http://mydomain.tld
```

Expected sequence:

```text
HTTP 301 from http://mydomain.tld
HTTP 200 from https://mydomain.tld
```

Do not enable redirect until HTTPS works. Redirecting before the managed certificate is active can make the domain appear broken to users.

---

## 9. Verify Health Endpoint

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

## 10. Verify Metadata Endpoint

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

## 11. Verify VPC

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

## 12. Verify Subnets

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

## 13. Verify Firewall Rules

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

## 14. Verify Cloud Router

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

## 15. Verify Cloud NAT

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

If an older deployment still uses all subnet NAT, document it and improve later.

Preferred target design:

```text
Only app subnet receives NAT.
DB subnet does not receive NAT by default.
```

---

## 16. Verify Service Account

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

## 17. Verify Instance Template

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

## 18. Verify Managed Instance Group

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

## 19. Verify Backend Service

List backend services:

```bash
gcloud compute backend-services list --global
```

Describe backend service:

```bash
terraform output -raw backend_service_name
gcloud compute backend-services describe BACKEND_SERVICE_NAME \
  --global \
  --format="yaml(name,protocol,loadBalancingScheme,portName,healthChecks,backends,securityPolicy,logConfig)"
```

Check:

```text
protocol: HTTP
load balancing scheme: EXTERNAL_MANAGED
port name: http
health check attached
backend group points to MIG instance group
securityPolicy points to the Cloud Armor policy when enabled
logConfig.enable is true during Cloud Armor policy verification
logConfig.sampleRate is 1.0 during the initial observation window
```

---

## 20. Verify Cloud Armor And Request Logging

Use this section when `enable_cloud_armor = true`.

Get the managed policy name:

```bash
terraform output -raw cloud_armor_policy_name
```

Describe the policy:

```bash
gcloud compute security-policies describe POLICY_NAME
```

Check:

```text
custom rules have distinct priorities
new WAF rules show preview: true during observation
default rule has priority 2147483647 and action: allow
```

Review request logs after sending normal application requests and selected test requests:

```bash
gcloud logging read \
  'resource.type="http_load_balancer" AND (jsonPayload.enforcedSecurityPolicy.name="POLICY_NAME" OR jsonPayload.previewSecurityPolicy.name="POLICY_NAME")' \
  --limit=20 \
  --format=json
```

Check:

```text
jsonPayload.enforcedSecurityPolicy reports enforced matches
jsonPayload.previewSecurityPolicy reports preview matches
normal HTTPS requests are not unexpectedly denied
```

Keep new WAF rules in preview mode until log review establishes that expected traffic is not matched incorrectly.

---

## 21. Verify Backend Health

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

## 22. Verify Global Forwarding Rules

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
port range is 80 for HTTP forwarding rule
port range is 443 for HTTPS forwarding rule when HTTPS is enabled
HTTP target points to target HTTP proxy
HTTPS target points to target HTTPS proxy when HTTPS is enabled
load balancing scheme is EXTERNAL_MANAGED
```

---

## 23. Verify Target Proxies

Verify the HTTP proxy:

```bash
gcloud compute target-http-proxies describe TARGET_HTTP_PROXY_NAME \
  --global
```

Expected:

```text
proxy points to the application URL map
```

When HTTPS is enabled, verify the HTTPS proxy:

```bash
gcloud compute target-https-proxies describe TARGET_HTTPS_PROXY_NAME \
  --global
```

Expected:

```text
proxy points to the same application URL map
proxy has the Google-managed SSL certificate attached
```

If HTTP-to-HTTPS redirect is enabled, verify the redirect HTTP proxy points to the redirect URL map, not the application URL map.

---

## 24. Verify Backend VMs Have No External IP

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

## 25. Verify IAP SSH

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

## 26. Verify Application Service

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

## 27. Verify Outbound Internet from Private VM

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

## 28. Verification Evidence for Portfolio

Capture screenshots or terminal output for:

```text
terraform apply complete
terraform output
curl root endpoint
curl /healthz
curl /metadata
DNS records for custom domain
managed SSL certificate status
curl HTTPS endpoint
curl HTTP-to-HTTPS redirect
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
06-dns-records.png
07-managed-ssl-certificate.png
08-https-endpoint.png
09-http-redirect.png
10-backend-health.png
11-private-vm-no-external-ip.png
12-cloud-nat.png
13-mig.png
```

---

## 29. Final Verification Statement

The platform is verified when this statement is true:

```text
A user can reach the application through the external HTTP(S) Load Balancer, HTTPS works with a Google-managed SSL certificate, optional HTTP-to-HTTPS redirect works when enabled, Cloud Armor policy behavior is observable through backend request logging when enabled, and the backend VM instances remain private, healthy, managed by a regional MIG, and able to reach outbound internet only through Cloud NAT.
```
