# Security Hardening — v1.2

## Overview

v1.2 adds the first security hardening layer to the Production-Lite GCP Web Platform.

This release adds:

- Cloud Armor security policy
- active deny rule for obvious scanner User-Agent traffic
- preview WAF rules for SQLi and XSS
- backend service request logging
- stricter firewall posture
- Cloud Armor verification steps
- security design decisions

## Security Model

The platform follows a layered security model:

```text
Public internet
  -> HTTPS Load Balancer
  -> Cloud Armor security policy
  -> Backend Service
  -> Regional MIG
  -> Private App VMs
```

Backend VMs remain private and do not have external IP addresses.

## Cloud Armor Rules

v1.2 starts with a conservative policy:

| Rule                   | Mode     | Purpose                              |
| ---------------------- | -------- | ------------------------------------ |
| deny-sqlmap-user-agent | Enforced | Blocks obvious scanner traffic       |
| waf-sqli-preview       | Preview  | Observes SQL injection-like requests |
| waf-xss-preview        | Preview  | Observes XSS-like requests           |
| default allow          | Enforced | Allows normal traffic                |

## Why WAF Rules Start in Preview

Preconfigured WAF rules can create false positives.

For that reason, SQLi and XSS rules start in preview mode.

Preview mode allows us to observe matching traffic in logs before blocking it.

## Firewall Hardening

v1.2 removes broad internal firewall access unless needed.

The preferred rules are:

```text
allow-lb-health-check
allow-iap-ssh
```

Optional diagnostic rule:

```text
allow-internal-diagnostics
```

The platform should not expose:

```text
0.0.0.0/0 -> tcp:22
10.80.0.0/16 -> all tcp/udp ports
```

## Logging

Cloud Armor logs are part of Cloud Load Balancing logs.

For v1.2 verification, backend service logging should be enabled with:

```hcl
backend_log_sample_rate = 1.0
```

After validation, the sample rate can be reduced for cost control.

## Verification

Test normal traffic:

```bash
curl -I https://YOUR_DOMAIN
```

Test active deny rule:

```bash
curl -I -A "sqlmap" https://YOUR_DOMAIN
```

Expected:

```text
403 Forbidden
```

Test WAF preview:

```bash
curl -I "https://YOUR_DOMAIN/?id=1%20OR%201=1"
```

Expected:

```text
200 OK, with preview logs if matched
```

## Operating Principle

Do not enforce WAF rules blindly.

Recommended rollout:

```text
1. Create policy.
2. Enable logging.
3. Add WAF rule in preview mode.
4. Generate test requests.
5. Review logs.
6. Tune rules if needed.
```
