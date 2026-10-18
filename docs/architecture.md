# Architecture

## Intent

Demonstrate two enterprise-standard tools on a GCP foundation:

- **Ansible** for configuration management of the Jenkins controller (host-side).
- **Jenkins** (declarative + Groovy shared library) for CI/CD.

Terraform provisions infrastructure; Ansible configures the host; Jenkins owns the
delivery pipeline. Keeping those responsibilities separate is the point - it is
exactly what interviewers probe.

## Provisioning split

| Layer | Tool | Responsibility |
|---|---|---|
| Infrastructure | Terraform | VPC, subnet, firewall, IAM, Artifact Registry, budget, VM, optional GKE |
| Configuration | Ansible | Packages, Docker, gcloud/kubectl/helm/trivy, Jenkins + plugins + JCasC, Ops Agent |
| Delivery | Jenkins | Build → test → scan → push → deploy |

The VM startup script (`startup.sh.tftpl`) only prepares the host for Ansible
(`python3`, `python3-apt`, `git`, `curl`, `gnupg`). Everything else is Ansible.

## Networking & access

- Custom VPC + subnet with `private_ip_google_access` and GKE secondary ranges.
- **No public SSH/web exposure by default**: SSH (22) and Jenkins (8080) are
  restricted to the IAP TCP-forwarding range `35.235.240.0/20`; inbound agents
  (50000) are VPC-internal only.
- Access via `gcloud compute start-iap-tunnel` (see `terraform output
  iap_tunnel_command`). Direct access is opt-in by adding your IP to `ssh_cidr`.

## Identity

- `jenkins-controller` SA: Artifact Registry writer, Cloud Run developer,
  GKE container developer, log/metric writer, and `serviceAccountUser` **on the
  demo runtime SA only** (not project-wide).
- `demo-runtime` SA: the identity the deployed Cloud Run service runs as.
- No long-lived keys: the pipeline authenticates to Artifact Registry via the VM's
  attached service account (metadata server).

## Ansible roles

| Role | Does |
|---|---|
| `common` | apt cache, base packages, timezone, optional UFW |
| `docker` | Docker apt repo, engine + compose/buildx plugins, service |
| `gcp_tools` | gcloud CLI, GKE auth plugin, kubectl, Helm, Trivy |
| `jenkins` | Java 17, Jenkins apt repo, plugins (jenkins-plugin-cli), JCasC config, docker-group membership |
| `monitoring` | Google Cloud Ops Agent (logs + metrics) |

`site.yml` applies them in order to the `jenkins` inventory group. All roles are
idempotent and announce changes via handlers (`Restart jenkins`, `Restart docker`).

## Jenkins configuration as code

`ansible/roles/jenkins/templates/jenkins.yaml.j2` (JCasC) sets:

- No sign-up; a local `admin` user whose password comes from
  `JENKINS_ADMIN_PASSWORD` (written to `/etc/default/jenkins`, read by the systemd
  unit's `EnvironmentFile`).
- Anonymous read disabled.
- The `platform-lib` **global shared library** wired directly from this repo's
  `jenkins/shared-library` directory.

## Pipeline

`Jenkinsfile` (declarative) consumes the shared library:

1. `runTests` builds the Dockerfile `test` stage - a failing `pytest` fails the build.
2. `buildImage` builds the `runtime` stage.
3. `scanImage` runs Trivy and fails on HIGH/CRITICAL.
4. `pushImage` authenticates Docker to Artifact Registry and pushes.
5. `deployToRun` deploys to Cloud Run as `demo-runtime`.

## Cost & FinOps

- Every resource carries the shared label taxonomy (`workload`, `cost_center`, ...).
- A monthly budget alert amount, configured by `budget_limit_gbp` (default 8 GBP),
  is scoped to this project and the `workload` label, with alerts at 80% and 100%.
  The budget sends notifications; it does not stop resources or cap spending.
- **Cloud Scheduler** starts/stops the Jenkins VM at 08:00/19:00 weekdays, so the
  VM is off nights and weekends (the biggest cost lever). The scheduler calls the
  Compute Engine API directly with an OAuth token - no Cloud Function needed.
- **`cheap_mode`** (default true) selects an e2-small VM + 20GB disk; the Ansible
  `common` role adds a 2GB swap file so Jenkins is still usable in 2GB RAM.
- GKE is optional and off by default; tear down with `scripts/down.ps1` or
  `make down` when idle (back to ~$0/month).
