output "jenkins_url" {
  description = "Jenkins web UI (reachable via IAP by default)"
  value       = "http://${google_compute_address.jenkins.address}:8080"
}

output "jenkins_vm_name" {
  value = google_compute_instance.jenkins.name
}

output "jenkins_vm_ip" {
  value = google_compute_address.jenkins.address
}

output "ssh_command" {
  description = "SSH via IAP (no public SSH exposure required)"
  value       = "gcloud compute ssh ${google_compute_instance.jenkins.name} --zone ${var.zone} --project ${var.project_id} --tunnel-through-iap"
}

output "iap_tunnel_command" {
  description = "Local tunnel to the Jenkins UI"
  value       = "gcloud compute start-iap-tunnel ${google_compute_instance.jenkins.name} 8080 --local-host-port=localhost:8080 --zone ${var.zone} --project ${var.project_id}"
}

output "artifact_registry" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "jenkins_service_account" {
  value = google_service_account.jenkins.email
}

output "gke_cluster" {
  description = "Optional ephemeral GKE cluster name (empty when enable_gke=false)"
  value       = var.enable_gke ? google_container_cluster.primary[0].name : ""
}
