terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.23.0"
    }
  }
}


provider "google" {
  project = local.project_name
  region  = "europe-west6"
}

locals {
  project_name = "db-superset-demo-${terraform.workspace}"
}

data "google_billing_account" "account" {
  billing_account = "billingAccounts/01120A-AED909-357303"
  open            = true
}

resource "google_project" "db-superset-demo" {
  name            = local.project_name
  project_id      = local.project_name
  billing_account = data.google_billing_account.account.id
}

resource "google_storage_bucket" "test-bucket" {
  name                        = "bu-test-bucket-superset-demo-${local.project_name}"
  location                    = "europe-west6"
  uniform_bucket_level_access = true
}

resource "google_artifact_registry_repository" "my-repo" {
  provider = google-beta
  location = "europe-west6"
  repository_id = "my-repo"
  project = local.project_name
  description = "Docker repository for ${local.project_name}"
  format = "DOCKER"
}

resource "google_cloud_run_service" "default" {
  name     = "cr-superset"
  location = "europe-west6"

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}