variable "enable_cloud_armor" {
  description = "Whether to create a Cloud Armor security policy."
  type        = bool
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "policy_name" {
  description = "Base name for the Cloud Armor security policy."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.policy_name))
    error_message = "policy_name must use lowercase letters, numbers, and hyphens."
  }
}

variable "default_rule_action" {
  description = "Default action for traffic that does not match a custom rule."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "deny(403)", "deny(404)", "deny(502)"], var.default_rule_action)
    error_message = "default_rule_action must be one of: allow, deny(403), deny(404), deny(502)."
  }
}

variable "rules" {
  description = "Map of Cloud Armor security policy rules."
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
      for rule in values(var.rules) :
      rule.priority > 0 && rule.priority < 2147483647
    ])
    error_message = "Each Cloud Armor rule priority must be greater than 0 and less than 2147483647."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      contains(["allow", "deny(403)", "deny(404)", "deny(502)"], rule.action)
    ])
    error_message = "Each Cloud Armor rule action must be one of: allow, deny(403), deny(404), deny(502)."
  }

  validation {
    condition = length(distinct([
      for rule in values(var.rules) : rule.priority
    ])) == length(var.rules)
    error_message = "Each Cloud Armor rule priority must be unique."
  }

  validation {
    condition = alltrue([
      for rule in values(var.rules) :
      (
        try(length(trimspace(rule.match.expression)) > 0, false) && rule.match.src_ip_ranges == null
        ) || (
        rule.match.expression == null && try(length(rule.match.src_ip_ranges) > 0 && length(rule.match.src_ip_ranges) <= 10, false)
      )
    ])
    error_message = "Each Cloud Armor rule must use exactly one non-empty match type: expression or 1 to 10 src_ip_ranges."
  }
}
