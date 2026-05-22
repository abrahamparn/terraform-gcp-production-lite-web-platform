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
