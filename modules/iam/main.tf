locals {
  service_account_roles = flatten([
    for service_account_key, service_account in var.service_accounts : [
      for role in service_account.project_roles : {
        key                 = "${service_account_key}-${role}"
        service_account_key = service_account_key
        role                = role
      }
    ]
  ])

}

resource "google_service_account" "this" {
  for_each = var.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for item in local.service_account_roles :
    item.key => item
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.this[each.value.service_account_key].email}"

}
