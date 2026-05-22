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
