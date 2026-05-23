variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
}

variable "lb_name" {
  description = "Base name for the http load balancer"
  type        = string
}

variable "backend_instance_group" {
  description = "Instance group URL used as backend."
  type        = string
}

variable "health_check_self_link" {
  description = "Health check self-link for the backend service."
  type        = string
}

variable "app_port" {
  description = "Application port served by the backend."
  type        = number
}

variable "enable_https" {
  description = "Whether to create HTTPS load balancer resources."
  type        = bool
  default     = false
}

variable "enable_http_redirect" {
  description = "Whether to redirect HTTP requests to HTTPS. Requires enable_https to be true."
  type        = bool
  default     = false
}

variable "managed_ssl_certificate_domains" {
  description = "Domains for the Google-managed SSL certificate."
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


variable "security_policy_self_link" {
  description = "Self-link of the Cloud Armor security policy to attach to the backend service."
  type        = string
  default     = null
}

variable "enable_backend_logging" {
  description = "Whether to enable backend service request logging."
  type        = bool
  default     = true
}

variable "backend_log_sample_rate" {
  description = "Backend service log sampling rate."
  type        = number
  default     = 1.0

  validation {
    condition     = var.backend_log_sample_rate >= 0 && var.backend_log_sample_rate <= 1
    error_message = "backend_log_sample_rate must be between 0 and 1."
  }
}
