# jenkins-ansible-gcp-proof

**Jenkins CI/CD + Ansible configuration management on Google Cloud** - a public,
NDA-proof reference implementation showing how to provision a GCP host with
Terraform, configure it end to end with Ansible, and drive a Jenkins (Groovy)
pipeline that builds, tests, scans and deploys a container to Cloud Run.

> Companion to `gcp-proof-platform` (Terraform/GKE/Cloud Build/FinOps) and
> `ai-platform-proof` (AWS/EKS). This project deliberately uses **Jenkins** and
> **Ansible** - the two tools that appear most often in enterprise GCP/DevOps
> adverts - on a GCP foundation.

## Architecture

```
                        Terraform (infra/)
   VPC + subnet (+GKE ranges) ─ IAM ─ Artifact Registry ─ Budget ─ optional GKE
                              │
                              ▼
                    GCE VM: Jenkins controller
                              │
        Ansible (ansible/) configures it, host-side:
         ┌──────────────────────────────────────────────┐
         │ common     base pkgs, timezone, (optional UFW)│
         │ docker     docker-ce + compose plugin         │
         │ gcp_tools  gcloud, kubectl, helm, trivy       │
         │ jenkins    java, Jenkins, plugins, JCasC      │
         │ monitoring Cloud Ops Agent (logs/metrics)     │
         └──────────────────────────────────────────────┘
                              │
                    Jenkins pipeline (Jenkinsfile)
        checkout → test (docker --target test) → build image →
        trivy scan → push to Artifact Registry → deploy Cloud Run
```

## What it demonstrates

| Requirement | Where |
|---|---|
| **Jenkins CI/CD** | `Jenkinsfile` + Groovy shared library (`jenkins/shared-library/vars/*.groovy`) |
| **Groovy pipelines** | `vars/buildImage.groovy`, `runTests.groovy`, `scanImage.groovy`, `pushImage.groovy`, `deployToRun.groovy` |
| **Jenkins as code** | Configuration-as-Code template in `ansible/roles/jenkins/templates/jenkins.yaml.j2` |
| **Ansible configuration management** | Five roles under `ansible/roles/` + `site.yml` |
| **Idempotent playbooks** | Roles use `apt`, `service`, `template`, `blockinfile`, handlers |
| **Terraform** | Full GCP footprint in `infra/terraform/environments/dev` |
| **GKE (optional)** | `gke.tf`, ephemeral, disabled by default for cost |
| **Container security** | Trivy image scan stage that fails the build on HIGH/CRITICAL |
| **Artifact Registry** | `artifact.tf` + `pushImage` stage |
| **Cloud Run deploy** | `deployToRun` shared-library step |
| **FinOps** | Label taxonomy + hard monthly budget with 80%/100% alerts |
| **Observability** | Cloud Ops Agent + Cloud Logging/Monitoring |

## Repository map

```
├── infra/terraform/environments/dev/   # VPC, IAM, AR, Jenkins VM, budget, GKE(opt)
├── ansible/
│   ├── site.yml
│   ├── group_vars/all.yml
│   └── roles/{common,docker,gcp_tools,jenkins,monitoring}
├── jenkins/shared-library/vars/        # Groovy pipeline steps
├── Jenkinsfile                         # declarative pipeline
├── app/                                # demo Flask service + tests + Dockerfile
├── scripts/                            # up / down / status / inventory / deploy
└── docs/architecture.md
```

## Quick start

```powershell
# 0. One-time: create the state bucket
gcloud storage buckets create gs://jenkins-ansible-gcp-proof-tfstate `
  --location=us-central1 --uniform-bucket-level-access

# 1. Configure variables
Copy-Item infra\terraform\environments\dev\terraform.tfvars.example `
          infra\terraform\environments\dev\terraform.tfvars
#    edit project_id + billing_account_id

# 2. Provision + write the Ansible inventory
scripts\up.ps1

# 3. Configure Jenkins with Ansible (from WSL or Cloud Shell)
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml -e jenkins_admin_password='<secret>'

# 4. Open Jenkins through the IAP tunnel, add a pipeline job for this repo,
#    and click Build - the pipeline builds, tests, scans and deploys.

# 5. Tear down (back to ~GBP0/month)
scripts\down.ps1
```

## Jenkins pipeline stages

1. **Checkout** - `checkout scm`
2. **Test** - `docker build --target test` runs `pytest`; a failure fails the pipeline
3. **Build image** - `docker build --target runtime`
4. **Scan image** - `trivy image --severity HIGH,CRITICAL --exit-code 1`
5. **Push image** - `gcloud auth configure-docker` + `docker push` (VM service account, no stored key)
6. **Deploy** - `gcloud run deploy` as the least-privilege `demo-runtime` service account

## Cost

| Component | ~$/mo |
|---|---|
| Jenkins GCE VM (e2-medium, always-on) | ~25 |
| Boot disk (40GB pd-balanced) | ~4 |
| Cloud Run demo (scale-to-zero) | ~0 |
| Artifact Registry (few images) | <1 |
| Networking / IAM / Ops Agent | ~0 |
| **Total** | **~30** - under a **GBP10** guardrail once idle; tear down when not demoing |

GKE is optional (`enable_gke = true`) and excluded - the management fee (~$73/mo)
does not fit the budget.

## Evidence checklist

- [ ] Green Jenkins pipeline run (screenshot)
- [ ] `trivy` stage output showing HIGH/CRITICAL gate
- [ ] `ansible-playbook site.yml` run showing idempotent `ok`/`changed`
- [ ] Cloud Run service URL serving `/health`
- [ ] Cloud Monitoring dashboard / budget alert
