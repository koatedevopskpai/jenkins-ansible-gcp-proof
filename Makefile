# Convenience wrapper for GitHub viewers.
# Requires: terraform, gcloud, make. Ansible (on WSL/Linux) for `make ansible`.
#
#   make cheap   <- recommended default: e2-small VM, no GKE, weekday-only schedule
#   make up      <- provision (uses the cheap_mode default in variables.tf)
#   make down    <- destroy everything (~$0/month)
#
# Uses '>' as the recipe prefix so recipe lines need no literal tab.
.RECIPEPREFIX = >

TF_DIR := infra/terraform/environments/dev
ANSIBLE_DIR := ansible

.PHONY: help init up cheap full gke down status inventory ansible fmt validate test

help:
> @echo "Targets:"
> @echo "  make up        - provision (default cheap_mode=true)"
> @echo "  make cheap     - re-apply the cheap profile (e2-small, 20GB, no GKE)"
> @echo "  make full      - standard profile (e2-medium, 40GB)"
> @echo "  make gke       - enable the ephemeral GKE demo target (+~$73/mo)"
> @echo "  make down      - destroy everything (~$0/month)"
> @echo "  make status    - terraform outputs"
> @echo "  make inventory - generate the Ansible inventory"
> @echo "  make ansible   - configure Jenkins with Ansible"
> @echo "  make fmt       - terraform fmt -recursive"
> @echo "  make validate  - terraform validate"
> @echo "  make test      - run the demo app tests"

init:
> terraform -chdir=$(TF_DIR) init -input=false

up: init
> terraform -chdir=$(TF_DIR) apply -auto-approve

cheap: init
> terraform -chdir=$(TF_DIR) apply -auto-approve -var="cheap_mode=true" -var="enable_gke=false"
> @terraform -chdir=$(TF_DIR) output cost_profile

full: init
> terraform -chdir=$(TF_DIR) apply -auto-approve -var="cheap_mode=false"

gke: init
> terraform -chdir=$(TF_DIR) apply -auto-approve -var="enable_gke=true"

down:
> terraform -chdir=$(TF_DIR) destroy -auto-approve

status:
> terraform -chdir=$(TF_DIR) output

inventory:
> pwsh -File scripts/inventory.ps1

ansible:
> cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yml && ansible-playbook site.yml

fmt:
> terraform fmt -recursive

validate: init
> terraform -chdir=$(TF_DIR) validate

test:
> cd app && python -m pytest -q
