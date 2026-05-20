variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
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