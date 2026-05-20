resource "google_compute_router" "this" {
  name    = "${var.environment}-${var.router_name}"
  region  = var.region
  network = var.network_self_link
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.environment}-${var.nat_name}"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = var.nat_subnets

    content {
      name                    = subnetwork.value.self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}