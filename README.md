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

#    ...or, cross-platform (recommended cheap profile):
make cheap

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
| Jenkins GCE VM (e2-small cheap_mode, weekday-only) | ~8 |
| Boot disk (20GB pd-balanced) | ~2 |
| Static external IP (in use) | ~3.65 |
| Cloud Run demo (scale-to-zero) | ~0 |
| Artifact Registry (few images) | <1 |
| Cloud Scheduler (2 jobs) / IAM / Ops Agent | ~0 |
| **Total (cheap_mode, weekday schedule)** | **~14** |
| **Total (destroy between demos)** | **~0** |

GKE is optional (`enable_gke = true`) and excluded - the management fee (~$73/mo)
does not fit the budget.

## Cost guardrails

Three layers keep this project honest on spend:

1. **Hard budget** - `budget_limit_gbp = 8` (approx a **$10 hard cap**) scoped to
   the `workload` label, alerting at 80% and 100%. It fails safe: if the VM is
   left on, the alerts fire within days.
2. **Auto start/stop** - Cloud Scheduler starts the VM at 08:00 and stops it at
   19:00 on weekdays (`enable_autostop = true`, `Europe/London`). The VM is off
   nights and weekends - the biggest single lever (~55-65% off the VM bill).
   Because the budget is intentionally tight, this is what keeps a running
   environment under it.
3. **`cheap_mode` toggle** - `make cheap` switches to an **e2-small** VM + 20GB
   disk (Ansible adds a 2GB swap file so Jenkins still fits). `make full` returns
   to e2-medium; `make down` tears everything down to **~$0/month**.

```bash
make cheap     # recommended: small VM, no GKE, weekday-only
make full      # e2-medium + 40GB when you need headroom
make gke       # spin up the ephemeral GKE demo target (record the screenshots, then make down)
make down      # destroy everything (~$0/month)
```

> Prices are us-central1, USD, on-demand. Check the
> [GCP pricing calculator](https://cloud.google.com/products/calculator) for your region.

## Evidence checklist

- [ ] Green Jenkins pipeline run (screenshot)
- [ ] `trivy` stage output showing HIGH/CRITICAL gate
- [ ] `ansible-playbook site.yml` run showing idempotent `ok`/`changed`
- [ ] Cloud Run service URL serving `/health`
- [ ] Cloud Monitoring dashboard / budget alert
