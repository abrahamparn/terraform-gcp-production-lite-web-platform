variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
}

variable "mig_name" {
  description = "Base name for the Managed Instace Group"
  type        = string
}

variable "region" {
  description = "Regoin for the regional MIG."
  type        = string
}


variable "machine_type" {
  description = "Machine type for instances"
  type        = string
}
variable "zones" {
  description = "Zones used in the regional MIG distribution policy"
  type        = list(string)
}


variable "subnetwork_self_link" {
  description = "Self-link of the subnet where the vm network interfaces will be attached"
  type        = string
}

variable "tags" {
  description = "Network tags attached to the instances"
  type        = list(string)
}

variable "startup_script_path" {
  description = "Path to the startup scripts"
  type        = string
}

variable "target_size" {
  description = "Number of instances in the MIG"
  type        = number
}

variable "app_port" {
  description = "Application port served by backend instances"
  type        = number
}

variable "health_check_self_link" {
  description = "Self-link of the health check used for authealing"
  type        = string
}

variable "service_account_email" {
  description = "Service acccount email attached to the MIG instances"
  type        = string
}
