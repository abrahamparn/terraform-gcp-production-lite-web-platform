output "load_balancer_ip" {
  description = "The external IP address of the HTTP load balancer."
  value       = google_compute_global_address.this.address
}

output "load_balancer_url" {
  description = "The HTTP URL of the load balancer."
  value       = "http://${google_compute_global_address.this.address}"
}

output "https_url" {
  description = "The HTTPS URL of the primary configured domain."
  value       = var.enable_https && local.primary_domain != null ? "https://${local.primary_domain}" : null
}

output "backend_service_name" {
  description = "The backend service name."
  value       = google_compute_backend_service.this.name
}

output "http_forwarding_rule_name" {
  description = "The HTTP forwarding rule name."
  value       = google_compute_global_forwarding_rule.http.name
}

output "https_forwarding_rule_name" {
  description = "The HTTPS forwarding rule name."
  value       = try(google_compute_global_forwarding_rule.https[0].name, null)
}

output "forwarding_rule_name" {
  description = "The forwarding rule name."
  value       = google_compute_global_forwarding_rule.http.name
}

output "ssl_certificate_name" {
  description = "The Google-managed SSL certificate name."
  value       = try(google_compute_managed_ssl_certificate.this[0].name, null)
}

output "target_https_proxy_name" {
  description = "The target HTTPS proxy name."
  value       = try(google_compute_target_https_proxy.this[0].name, null)
}


output "backend_logging_enabled" {
  description = "Whether backend service request logging is enabled."
  value       = var.enable_backend_logging
}

output "backend_log_sample_rate" {
  description = "Backend service log sampling rate."
  value       = var.backend_log_sample_rate
}

output "attached_security_policy" {
  description = "Cloud Armor security policy attached to the backend service."
  value       = var.security_policy_self_link
}
