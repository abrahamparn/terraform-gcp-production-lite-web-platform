variable "project_id" {
  description = "Google cloud project ID where resrouces will be created"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project id must not be empty"
  }
}

variable "region" {
  description = "The region that we use for this project"
  type        = string
  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "Must be either asia-southeast2 or asia-southeast1 or us-central1"
  }
}

variable "environment" {
  description = "This production environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be either dev or staging or prod"
  }
}

variable "name_prefix" {
  description = "base prefix used for resrouce names"
  type        = string
  default     = "prod-lite"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be use lowercase letters, numbers and hypens. it must startwith a letter and end with a leter or number."
  }
}

variable "network_name" {
  description = "Base name of the VPC network"
  type        = string
  default     = "web-platform-vpc"

  validation {

    condition = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))

    error_message = "network name must use lowercase letters, numbers, and hyphens"
  }
}

variable "subnets" {
  description = "Map of subnets to create inside the VPC."

  type = map(object({
    cidr_range            = string
    region                = optional(string)
    private_google_access = optional(bool, true)
    purpose               = optional(string)
    role                  = optional(string)
  }))

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key))
    ])

    error_message = "Each subnet key must be a valid lowercase name."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(cidrhost(subnet.cidr_range, 0))

    ])
    error_message = "each cidr_range must be a valid IPV4 CIDR block."

  }
}

variable "firewall_rules" {
  description = "Map of ingress firewall rules to create"

  type = map(object({
    description   = optional(string)
    source_ranges = list(string)
    target_tags   = optional(list(string), [])
    allow = list(object({
      protocol = string
      ports    = optional(list(string))
    }))
  }))

  default = {}
}

variable "nat_subnet_keys" {
  description = "Subnet keys that should receive outbound internet access through Cloud NAT."
  type        = list(string)
  default     = ["app"]
}

variable "mig_name" {
  description = "Base name for the managed instance group."
  type        = string
  default     = "web-mig"
}

variable "mig_instance_count" {
  description = "Number of instances in the Managed Instance Group."
  type        = number
  default     = 1

  validation {
    condition     = var.mig_instance_count >= 1 && var.mig_instance_count <= 3
    error_message = "For this portfolio artifact, mig_instance_count must be between 1 and 3"
  }
}

variable "mig_machine_type" {
  description = "Machine type for MIG instance"
  type        = string
  default     = "e2-micro"
}

variable "mig_zones" {
  description = "Zones used by the regional MIG distribution policy"
  type        = list(string)
  default     = ["asia-southeast2-a"]
}

variable "mig_tags" {
  description = "Network tags attached to MIG instances."
  type        = list(string)
  default     = ["web-backend"]
}

variable "mig_subnet_key" {
  description = "Subnet key from the network module where MIG instances will be attached."
  type        = string
  default     = "app"
}

variable "lb_name" {
  description = "Base name for the HTTP load balancer."
  type        = string
  default     = "web-lb"
}

variable "app_port" {
  description = "Application port serverd by backend instances."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path used by the http health check."
  type        = string
  default     = "/healthz"
}

variable "service_accounts" {
  description = "Map of service accounts to create."
  type = map(object({
    account_id    = string
    display_name  = string
    description   = optional(string)
    project_roles = optional(list(string), [])
  }))
}

variable "admin_principal" {
  description = "IAM principal allowed to access private"
  type        = string

  validation {
    condition     = can(regex("^(user|group|serviceAccount):.+", var.admin_principal))
    error_message = "admin_principal must start with users:, group:, ro serviceAccount:."
  }
}

variable "iap_tunnel_role" {
  description = "Role required to access VMs through IAP TCP forwarding."
  type        = string
  default     = "roles/iap.tunnelResourceAccessor"
}

variable "os_admin_login_role" {
  description = "Role required for OS Login administrator access."
  type        = string
  default     = "roles/compute.osAdminLogin"
}

variable "enable_https" {
  description = "Whether to enable HTTPS resources for the external load balancer."
  type        = bool
  default     = false
}

variable "enable_http_redirect" {
  description = "Whether to redirect HTTP traffic to HTTPS. Requires enable_https to be true."
  type        = bool
  default     = false
}

variable "managed_ssl_certificate_domains" {
  description = "Domains to include in the Google-managed SSL certificate. Example: [\"app.example.com\"]"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for domain in var.managed_ssl_certificate_domains :
      length(trimspace(domain)) > 0
    ])

    error_message = "Each managed SSL certificate domain must be a non-empty string."
  }
}


variable "enable_cloud_armor" {
  description = "Whether to create and attach a Cloud Armor security policy."
  type        = bool
  default     = false
}

variable "cloud_armor_policy_name" {
  description = "Base name for the Cloud Armor security policy."
  type        = string
  default     = "web-security-policy"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.cloud_armor_policy_name))
    error_message = "cloud_armor_policy_name must use lowercase letters, numbers, and hyphens."
  }
}

variable "cloud_armor_default_rule_action" {
  description = "Default Cloud Armor action for requests that match no custom rule."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "deny(403)", "deny(404)", "deny(502)"], var.cloud_armor_default_rule_action)
    error_message = "cloud_armor_default_rule_action must be one of: allow, deny(403), deny(404), deny(502)."
  }
}

variable "cloud_armor_rules" {
  description = "Map of Cloud Armor security policy rules. Use preview = true for new WAF rules before enforcement."

  type = map(object({
    priority    = number
    action      = string
    description = optional(string)
    preview     = optional(bool, false)

    match = object({
      expression    = optional(string)
      src_ip_ranges = optional(list(string))
    })
  }))

  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.cloud_armor_rules) :
      rule.priority > 0 && rule.priority < 2147483647
    ])
    error_message = "Each Cloud Armor rule priority must be greater than 0 and less than 2147483647."
  }

  validation {
    condition = alltrue([
      for rule in values(var.cloud_armor_rules) :
      contains(["allow", "deny(403)", "deny(404)", "deny(502)"], rule.action)
    ])
    error_message = "Each Cloud Armor rule action must be one of: allow, deny(403), deny(404), deny(502)."
  }

  validation {
    condition = length(distinct([
      for rule in values(var.cloud_armor_rules) : rule.priority
    ])) == length(var.cloud_armor_rules)
    error_message = "Each Cloud Armor rule priority must be unique."
  }

  validation {
    condition = alltrue([
      for rule in values(var.cloud_armor_rules) :
      (
        try(length(trimspace(rule.match.expression)) > 0, false) && rule.match.src_ip_ranges == null
        ) || (
        rule.match.expression == null && try(length(rule.match.src_ip_ranges) > 0 && length(rule.match.src_ip_ranges) <= 10, false)
      )
    ])
    error_message = "Each Cloud Armor rule must use exactly one non-empty match type: expression or 1 to 10 src_ip_ranges."
  }
}

variable "enable_backend_logging" {
  description = "Whether to enable backend service request logging. Cloud Armor logs are part of load balancer logs."
  type        = bool
  default     = true
}

variable "backend_log_sample_rate" {
  description = "Backend service log sampling rate. Use 1.0 for learning and verification, lower values for cost control."
  type        = number
  default     = 1.0

  validation {
    condition     = var.backend_log_sample_rate >= 0 && var.backend_log_sample_rate <= 1
    error_message = "backend_log_sample_rate must be between 0 and 1."
  }
}
