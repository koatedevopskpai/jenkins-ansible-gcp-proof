# -----------------------------------------------------------------------------
# Cost guardrail: schedule the Jenkins VM to start/stop on weekdays so it is off
# nights and weekends. This is the single biggest cost lever (~55-65% off the
# VM bill). Cloud Scheduler calls the Compute Engine API directly with an OAuth
# token - no Cloud Function required. Two jobs sit inside the Cloud Scheduler
# free tier (3 jobs/month free).
#
# Note: the VM's static IP is still billed while the VM is stopped (~$3.65/mo),
# but the compute + no per-second charges stop accruing.
# -----------------------------------------------------------------------------

resource "google_service_account" "scheduler" {
  account_id   = "jenkins-scheduler"
  display_name = "Jenkins VM start/stop scheduler (${var.environment})"
  description  = "Cloud Scheduler identity used to start/stop the Jenkins VM"
  depends_on   = [google_project_service.enabled]
}

resource "google_project_iam_member" "scheduler_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_cloud_scheduler_job" "jenkins_start" {
  count     = var.enable_autostop ? 1 : 0
  name      = "${local.name_prefix}-jenkins-start"
  region    = var.region
  schedule  = var.vm_start_schedule
  time_zone = var.autostop_timezone

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${google_compute_instance.jenkins.name}/start"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [google_project_service.enabled]
}

resource "google_cloud_scheduler_job" "jenkins_stop" {
  count     = var.enable_autostop ? 1 : 0
  name      = "${local.name_prefix}-jenkins-stop"
  region    = var.region
  schedule  = var.vm_stop_schedule
  time_zone = var.autostop_timezone

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${google_compute_instance.jenkins.name}/stop"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [google_project_service.enabled]
}
