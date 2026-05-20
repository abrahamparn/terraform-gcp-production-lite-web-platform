locals {
  resource_prefix = "${var.environment}-${var.name_prefix}"

  common_labels = {
    environment = var.environment
    project     = var.name_prefix
    managed_by  = "terraform"
    artifact    = "production-lite-web-platform"
  }

  app_subnet_self_link = module.network.subnets[var.mig_subnet_key].self_link
}
