output "instance_template_self_link" {
  description = "The instance template self-link"
  value       = google_compute_instance_template.this.self_link
}

output "mig_name" {
  description = "The Managed Instance Group name."
  value       = google_compute_region_instance_group_manager.this.name
}

output "mig_instance_group" {
  description = "The instance group URL used by the backend service."
  value       = google_compute_region_instance_group_manager.this.instance_group
}

output "mig_region" {
  description = "The MIG region."
  value       = google_compute_region_instance_group_manager.this.region
}