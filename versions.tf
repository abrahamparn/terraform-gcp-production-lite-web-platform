terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # pessimistic
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }
}
