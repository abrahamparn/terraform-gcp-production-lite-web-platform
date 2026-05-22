# Changelog

All notable changes to this project will be documented in this file.

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
