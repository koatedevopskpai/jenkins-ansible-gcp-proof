variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "environment" {
  type    = string
  default = "dev"
}

# --- Compute ---
variable "jenkins_machine_type" {
  description = "Jenkins controller VM type (e2-medium = 4GB; Jenkins + plugins need headroom)"
  type        = string
  default     = "e2-medium"
}

variable "root_volume_size" {
  type    = number
  default = 40
}

variable "jenkins_image" {
  description = "Boot image for the Jenkins controller"
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

# --- Networking ---
variable "vpc_cidr" {
  description = "CIDR for the platform subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "ssh_cidr" {
  description = "CIDRs allowed to reach SSH/Jenkins web. Default is the IAP TCP-forwarding range (recommended); add your own IP for direct access."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

# --- Jenkins ---
variable "jenkins_admin_user" {
  description = "Initial Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_url_prefix" {
  type    = string
  default = ""
}

variable "jenkins_plugins" {
  description = "Plugins installed by the Ansible jenkins role (jenkins-plugin-cli)"
  type        = list(string)
  default = [
    "configuration-as-code",
    "git",
    "workflow-aggregator",
    "workflow-cps-global-lib",
    "github",
    "docker-workflow",
    "pipeline-utility-steps",
    "credentials-binding",
    "google-oauth-plugin",
    "google-kubernetes-engine",
    "ws-cleanup",
    "timestamper",
    "ansicolor",
  ]
}

# --- Deployment target (optional ephemeral GKE; otherwise deploy to Cloud Run) ---
variable "enable_gke" {
  description = "Provision the optional ephemeral GKE cluster (management fee ~$73/mo). Disabled by default to stay cheap."
  type        = bool
  default     = false
}

# --- FinOps tagging taxonomy ---
variable "cost_center" {
  type    = string
  default = "cc-platform-engineering"
}

variable "business_unit" {
  type    = string
  default = "platform"
}

variable "tag_owner" {
  type    = string
  default = "koatekpai"
}

variable "budget_owner" {
  type    = string
  default = "platform-leads"
}

variable "workload" {
  type    = string
  default = "jenkins-ansible-gcp-proof"
}

variable "cost_category" {
  type    = string
  default = "engineering-rnd"
}

variable "data_classification" {
  type    = string
  default = "public-reference"
}

# --- Budget & cost guardrails ---
variable "billing_account_id" {
  description = "GCP billing account id (e.g. 01FBBE-ACD618-CFA5D6)"
  type        = string
}

variable "budget_limit_gbp" {
  description = "Hard monthly budget cap in GBP (billing account currency)"
  type        = number
  default     = 10
}

variable "budget_alerts_email" {
  type    = string
  default = "koatekpai@outlook.com"
}
