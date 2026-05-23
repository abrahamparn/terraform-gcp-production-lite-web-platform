resource "google_compute_security_policy" "this" {
  count = var.enable_cloud_armor ? 1 : 0

  name        = "${var.environment}-${var.policy_name}"
  description = "Cloud Armor security policy for the production-lite web platform."
  type        = "CLOUD_ARMOR"

  dynamic "rule" {
    for_each = var.rules

    content {
      priority    = rule.value.priority
      action      = rule.value.action
      description = rule.value.description
      preview     = rule.value.preview

      match {
        versioned_expr = rule.value.match.src_ip_ranges != null ? "SRC_IPS_V1" : null

        dynamic "config" {
          for_each = rule.value.match.src_ip_ranges != null ? [rule.value.match.src_ip_ranges] : []

          content {
            src_ip_ranges = config.value
          }
        }

        dynamic "expr" {
          for_each = rule.value.match.expression != null ? [rule.value.match.expression] : []

          content {
            expression = expr.value
          }
        }
      }
    }
  }

  rule {
    priority    = 2147483647
    action      = var.default_rule_action
    description = "Default rule for requests that do not match a custom rule."

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
