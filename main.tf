module "network" {
  source = "./modules/network"


  environment    = var.environment
  region         = var.region
  network_name   = var.network_name
  subnets        = var.subnets
  firewall_rules = var.firewall_rules

}

module "iam" {
  source = "./modules/iam"

  project_id       = var.project_id
  environment      = var.environment
  service_accounts = var.service_accounts
}

module "nat" {
  source = "./modules/nat"

  environment = var.environment
  region      = var.region

  network_self_link = module.network.network_self_link

  nat_subnets = {
    for subnet_key in var.nat_subnet_keys :
    subnet_key => module.network.subnets[subnet_key]
  }
}

resource "google_compute_health_check" "http" {
  name = "${local.resource_prefix}-${var.lb_name}-http-health-check"


  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3


  http_health_check {
    port         = var.app_port
    request_path = var.health_check_path
  }
}

resource "time_sleep" "health_check_ready" {
  create_duration = "30s"

  depends_on = [google_compute_health_check.http]
}

module "compute" {

  source = "./modules/compute"

  environment          = var.environment
  mig_name             = var.mig_name
  region               = var.region
  zones                = var.mig_zones
  machine_type         = var.mig_machine_type
  subnetwork_self_link = module.network.subnets[var.mig_subnet_key].self_link
  tags                 = var.mig_tags

  startup_script_path    = "${path.module}/scripts/startup.sh"
  target_size            = var.mig_instance_count
  app_port               = var.app_port
  health_check_self_link = google_compute_health_check.http.self_link
  service_account_email  = module.iam.service_accounts["app"].email

  depends_on = [
    module.nat,
    time_sleep.health_check_ready
  ]
}

module "security" {
  source = "./modules/security"

  enable_cloud_armor  = var.enable_cloud_armor
  environment         = var.environment
  policy_name         = var.cloud_armor_policy_name
  default_rule_action = var.cloud_armor_default_rule_action
  rules               = var.cloud_armor_rules
}


module "load_balancer" {
  source                 = "./modules/load-balancer"
  environment            = var.environment
  lb_name                = var.lb_name
  backend_instance_group = module.compute.mig_instance_group
  health_check_self_link = google_compute_health_check.http.self_link
  app_port               = var.app_port

  enable_https                    = var.enable_https
  enable_http_redirect            = var.enable_http_redirect
  managed_ssl_certificate_domains = var.managed_ssl_certificate_domains

  security_policy_self_link = module.security.security_policy_self_link
  enable_backend_logging    = var.enable_backend_logging
  backend_log_sample_rate   = var.backend_log_sample_rate

  depends_on = [time_sleep.health_check_ready]
}

resource "google_project_iam_member" "iap_tunnel_user" {
  project = var.project_id
  role    = var.iap_tunnel_role
  member  = var.admin_principal
}

resource "google_project_iam_member" "os_admin_login" {
  project = var.project_id
  role    = var.os_admin_login_role
  member  = var.admin_principal
}
