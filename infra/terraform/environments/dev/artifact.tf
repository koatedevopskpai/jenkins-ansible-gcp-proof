resource "google_artifact_registry_repository" "images" {
  repository_id = "jenkins-demo"
  location      = var.region
  format        = "DOCKER"
  description   = "Container images built by the Jenkins pipeline"
  labels = {
    workload = var.workload
  }
  depends_on = [google_project_service.enabled]
}
