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
