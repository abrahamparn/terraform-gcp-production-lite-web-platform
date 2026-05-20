terraform {
  backend "gcs" {
    bucket = "terraform-gcp-production-lite-tfstate"
    prefix = "production-lite-web-platform"
  }
}