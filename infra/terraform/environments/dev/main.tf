terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Remote state in GCS. Create the bucket once before `terraform init`:
  #   gcloud storage buckets create gs://jenkins-ansible-gcp-proof-tfstate \
  #     --location=us-central1 --uniform-bucket-level-access
  # (Or switch this to a local backend for a throwaway run.)
  backend "gcs" {
    bucket = "jenkins-ansible-gcp-proof-tfstate"
    prefix = "dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # --- FinOps tagging taxonomy (applied to every labelled resource) ---
  default_labels = {
    project             = var.project_id
    environment         = var.environment
    managed_by          = "terraform"
    cost_center         = var.cost_center
    business_unit       = var.business_unit
    owner               = var.tag_owner
    budget_owner        = var.budget_owner
    workload            = var.workload
    cost_category       = var.cost_category
    data_classification = var.data_classification
    repo                = "jenkins-ansible-gcp-proof"
  }
}

data "google_project" "current" {}

locals {
  name_prefix = "jenkins-ansible-${var.environment}"
}
