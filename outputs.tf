output "network_name" {
  description = "The VPC network name."
  value       = module.network.network_name
}


output "network_self_link" {
  description = "the self link of the network"
  value       = module.network.network_self_link
}

output "subnets" {
  description = "Subnets created by the network module."
  value       = module.network.subnets
}

output "firewall_rules" {
  description = "Firewall rules created by the network module."
  value       = module.network.firewall_rules
}

output "cloud_nat_name" {
  description = "Cloud NAT gateway name."
  value       = module.nat.nat_name
}

output "cloud_router_name" {
  description = "Cloud Router Name."
  value       = module.nat.router_name
}

output "health_check_path" {
  description = "HTTP name of health check that was created"
  value       = google_compute_health_check.http.name
}

output "mig_name" {
  description = "Managed Instance Group Name"
  value       = module.compute.mig_name
}

output "mig_instance_group" {
  description = "Managed Instance Group Backend URL."
  value       = module.compute.mig_instance_group
}

output "load_balancer_ip" {
  description = "Manages Instance Group URL."
  value       = module.load_balancer.load_balancer_ip
}

output "load_balancer_url" {
  description = "External HTTP load balancer IP"
  value       = module.load_balancer.load_balancer_url
}

output "curl_test_command" {
  description = "Command to test the load balancer root endpoint."
  value       = "curl -i ${module.load_balancer.load_balancer_url}"
}

output "curl_health_check_command" {
  description = "Command to test the health endpoint"
  value       = "curl -i ${module.load_balancer.load_balancer_url}${var.health_check_path}"
}

output "platform_summary" {
  description = "Summary of the production lite platform."

  value = {
    project           = var.project_id
    environment       = var.environment
    region            = var.region
    network_name      = module.network.network_name
    mig_name          = module.compute.mig_name
    mig_size          = var.mig_instance_count
    app_port          = var.app_port
    health_check_path = var.health_check_path
    cloud_nat         = module.nat.nat_name
    health_check      = google_compute_health_check.http.name
    load_balancer_ip  = module.load_balancer.load_balancer_ip
    load_balancer_url = module.load_balancer.load_balancer_url
  }

}
