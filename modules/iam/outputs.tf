output "service_accounts" {
  description = "Service accounts created by this module."

  value = {
    for service_account_key, service_account in google_service_account.this :
    service_account_key => {
      email  = service_account.email
      name   = service_account.name
      member = "serviceAccount:${service_account.email}"
    }
  }
}