locals {
  ssl_certificate_domains = [
    for domain in var.managed_ssl_certificate_domains : trimspace(domain)
  ]
  primary_domain        = try(local.ssl_certificate_domains[0], null)
  http_redirect_enabled = var.enable_https && var.enable_http_redirect
}

resource "google_compute_global_address" "this" {
  name = "${var.environment}-${var.lb_name}-ip"
}

resource "google_compute_backend_service" "this" {
  name                  = "${var.environment}-${var.lb_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  security_policy = var.security_policy_self_link

  health_checks = [
    var.health_check_self_link
  ]

  backend {
    group           = var.backend_instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = var.enable_backend_logging
    sample_rate = var.backend_log_sample_rate
  }
}

resource "google_compute_url_map" "this" {
  name            = "${var.environment}-${var.lb_name}-url-map"
  default_service = google_compute_backend_service.this.self_link
}

resource "google_compute_target_http_proxy" "this" {
  name    = "${var.environment}-${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.this.self_link
}

resource "google_compute_url_map" "http_redirect" {
  count = local.http_redirect_enabled ? 1 : 0
  name  = "${var.environment}-${var.lb_name}-http-redirect-url-map"

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  count   = local.http_redirect_enabled ? 1 : 0
  name    = "${var.environment}-${var.lb_name}-http-redirect-proxy"
  url_map = google_compute_url_map.http_redirect[0].self_link
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.environment}-${var.lb_name}-http-forwarding-rule"
  ip_address            = google_compute_global_address.this.address
  ip_protocol           = "TCP"
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = local.http_redirect_enabled ? google_compute_target_http_proxy.http_redirect[0].self_link : google_compute_target_http_proxy.this.self_link

  lifecycle {
    precondition {
      condition     = !var.enable_http_redirect || var.enable_https
      error_message = "enable_http_redirect requires enable_https to be true."
    }
  }
}

resource "google_compute_managed_ssl_certificate" "this" {
  count = var.enable_https ? 1 : 0

  name = "${var.environment}-${var.lb_name}-managed-cert"

  managed {
    domains = local.ssl_certificate_domains
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = length(local.ssl_certificate_domains) > 0
      error_message = "managed_ssl_certificate_domains must contain at least one domain when enable_https is true."
    }
  }
}

resource "google_compute_target_https_proxy" "this" {
  count = var.enable_https ? 1 : 0

  name = "${var.environment}-${var.lb_name}-https-proxy"

  url_map = google_compute_url_map.this.self_link

  ssl_certificates = [
    google_compute_managed_ssl_certificate.this[0].self_link
  ]
}

resource "google_compute_global_forwarding_rule" "https" {
  count = var.enable_https ? 1 : 0

  name = "${var.environment}-${var.lb_name}-https-forwarding-rule"

  ip_address            = google_compute_global_address.this.address
  ip_protocol           = "TCP"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_https_proxy.this[0].self_link
}
