# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - v1.2 Security Hardening

### Added

- optional Cloud Armor backend security policy attached to the existing backend service
- backend request logging configuration for Cloud Armor preview and enforcement verification
- Cloud Armor configuration variables, outputs, and operational verification documentation

### Changed

- validated Cloud Armor actions, unique rule priorities, and exclusive match configuration
- retained the existing HTTPS URL map and backend path while adding security policy attachment

## [v1.1.0] - 22 May 2026

### Added

- google managed ssl certificate support
- custom domain support for the external application load balancer
- https target proxy
- https global forwarding rule on port 443.
- optional http to https redirect
- https related terraform variables
- https related terraform outputs
- https verification documentation

### Changed

- updated load balancer module
- updated readme to describe v1.1
- updated architecture documentation
- updated verification documentation

### Notes

- HTTPS must be enabled only after the user owns a domain and can point DNS to the load balancer IP.
- Google-managed certificate provisioning may take time depending on DNS
  visibility and propagation.
- Activating a domain also takes time (if you just bought a new one)
