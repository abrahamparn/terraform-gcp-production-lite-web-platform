output "router_name" {
  description = "The cloud router name."
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "The Cloud NAT gateway name."
  value       = google_compute_router_nat.this.name
}

output "nat_region" {
  description = "The region of the cloud nat gateway"
  value       = google_compute_router.this.region
}
