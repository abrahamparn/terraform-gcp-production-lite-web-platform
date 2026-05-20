locals {
  final_network_main = "${var.environment}-${var.network_name}"
}


resource "google_compute_network" "this" {
  name                    = local.final_network_main
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnets" {
  for_each      = var.subnets
  name          = "${var.environment}-${each.key}-subnet"
  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.this.id
  ip_cidr_range = each.value.cidr_range

  private_ip_google_access = each.value.private_google_access
}


resource "google_compute_firewall" "ingress_rules" {
  for_each = var.firewall_rules

  name          = "${var.environment}-${each.key}"
  network       = google_compute_network.this.name
  description   = each.value.description
  direction     = "INGRESS"
  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags
  dynamic "allow" {
    for_each = each.value.allow

    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}
