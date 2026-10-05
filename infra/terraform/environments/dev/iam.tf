# -----------------------------------------------------------------------------
# IAM + APIs. Jenkins runs as a least-privilege service account scoped to what
# the pipeline actually does: push images, deploy to Cloud Run/GKE, write logs
# and metrics, and act as the demo runtime SA when deploying.
# -----------------------------------------------------------------------------

locals {
  apis = [
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudscheduler.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Service accounts ---------------------------------------------------------

resource "google_service_account" "jenkins" {
  account_id   = "jenkins-controller"
  display_name = "Jenkins controller (${var.environment})"
  description  = "Runs the Jenkins controller VM and its CI/CD pipelines"
  depends_on   = [google_project_service.enabled]
}

resource "google_service_account" "demo_runtime" {
  account_id   = "demo-runtime"
  display_name = "Demo app runtime (${var.environment})"
  description  = "Runtime identity for the demo service deployed by Jenkins"
  depends_on   = [google_project_service.enabled]
}

# --- Jenkins controller roles (least privilege) ------------------------------

resource "google_project_iam_member" "jenkins_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "jenkins_metrics" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

# Allow Jenkins to deploy services that RUN AS the demo runtime SA.
resource "google_service_account_iam_member" "jenkins_act_as_demo" {
  service_account_id = google_service_account.demo_runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "demo_runtime_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.demo_runtime.email}"
}
