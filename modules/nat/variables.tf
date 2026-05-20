variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
}

variable "region" {
  description = "region for cloud router and cloud nat will be created"
  type        = string
}

variable "network_self_link" {
  description = "self-link of the vpc network we"
  type        = string
}

variable "router_name" {
  description = "Base name of the router for cloud nat"
  type        = string
  default     = "nat-router"
}

variable "nat_name" {
  description = "base name for the cloud nat gateway"
  type        = string
  default     = "nat-gateway"
}

variable "nat_subnets" {
  description = "MAP of subnet objects that should receive cloud nat"
  type = map(object({
    name       = string
    id         = string
    region     = string
    cidr_range = string
    self_link  = string
  }))
}