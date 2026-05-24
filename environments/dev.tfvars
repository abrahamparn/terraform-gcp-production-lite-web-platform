project_id      = "terraform-gcp-foundation-lite"
region          = "asia-southeast2"
environment     = "dev"
name_prefix     = "prod-lite"
admin_principal = "user:abram.domu@gmail.com"

network_name = "web-platform-vpc"

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

firewall_rules = {
  allow-lb-health-check = {
    description   = "Allow Google Cloud load balancer health checks and proxy traffic to backend instances."
    source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
    target_tags   = ["web-backend"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["80"]
      }
    ]
  }

  allow-iap-ssh = {
    description   = "Allow SSH to private backend instances through Identity-Aware Proxy."
    source_ranges = ["35.235.240.0/20"]
    target_tags   = ["web-backend"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["22"]
      }
    ]
  }

  # We remove this to make the system even tighter
  # allow-internal = {
  #   description   = "Allow internal traffic between platform subnets."
  #   source_ranges = ["10.80.0.0/16"]

  #   allow = [
  #     {
  #       protocol = "tcp"
  #       ports    = ["0-65535"]
  #     },
  #     {
  #       protocol = "udp"
  #       ports    = ["0-65535"]
  #     },
  #     {
  #       protocol = "icmp"
  #     }
  #   ]
  # }
}

nat_subnet_keys = ["app"]

service_accounts = {
  app = {
    account_id   = "dev-prod-lite-app-sa"
    display_name = "Production Lite App Service Account"
    description  = "Service account used by private application VM instances."
    project_roles = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter"
    ]
  }
}

mig_name           = "web-mig"
mig_instance_count = 1
mig_machine_type   = "e2-micro"
mig_zones          = ["asia-southeast2-a"]
mig_subnet_key     = "app"
mig_tags           = ["web-backend"]

lb_name           = "web-lb"
app_port          = 80
health_check_path = "/healthz"

# For v1.1
enable_https                    = true
enable_http_redirect            = true
managed_ssl_certificate_domains = ["abrahampn.xyz", "www.abrahampn.xyz"]


enable_cloud_armor              = false
cloud_armor_policy_name         = "web-security-policy"
cloud_armor_default_rule_action = "allow"

enable_backend_logging  = true
backend_log_sample_rate = 1.0

cloud_armor_rules = {
  deny-sqlmap-user-agent = {
    priority    = 1000
    action      = "deny(403)"
    description = "Deny obvious sqlmap scanner traffic by User-Agent."
    preview     = false

    match = {
      expression = "has(request.headers['user-agent']) && request.headers['user-agent'].contains('sqlmap')"
    }
  }

  waf-sqli-preview = {
    priority    = 1100
    action      = "deny(403)"
    description = "Preview SQL injection WAF rule before enforcement."
    preview     = true

    match = {
      expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
    }
  }

  waf-xss-preview = {
    priority    = 1200
    action      = "deny(403)"
    description = "Preview XSS WAF rule before enforcement."
    preview     = true

    match = {
      expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1})"
    }
  }
}