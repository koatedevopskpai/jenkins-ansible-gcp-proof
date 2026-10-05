<#
.SYNOPSIS
    Provision the GCP infrastructure and configure Jenkins with Ansible.
.DESCRIPTION
    Runs terraform apply, generates the Ansible inventory, then (optionally)
    runs the Ansible playbook. Ansible runs on Linux - this script uses WSL if
    available, otherwise it prints the command to run from WSL or Cloud Shell.
#>
[CmdletBinding()]
param(
    [switch]$SkipApply,
    [switch]$RunAnsible,
    [switch]$EnableGke
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$tfDir = [System.IO.Path]::GetFullPath((Join-Path $here '..\infra\terraform\environments\dev'))
$ansibleDir = [System.IO.Path]::GetFullPath((Join-Path $here '..\ansible'))

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) { throw "terraform not on PATH" }
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) { throw "gcloud not on PATH" }

if (-not $SkipApply) {
    Push-Location $tfDir
    try {
        if (-not (Test-Path (Join-Path $tfDir '.terraform'))) { terraform init -input=false }
        $varFile = Join-Path $tfDir 'terraform.tfvars'
        $args = @("apply", "-auto-approve")
        if (Test-Path $varFile) { $args += "-var-file=$varFile" }
        if ($EnableGke) { $args += "-var=enable_gke=true" }
        terraform @args
        if ($LASTEXITCODE -ne 0) { throw "terraform apply failed" }
    }
    finally { Pop-Location }
}

& (Join-Path $here 'inventory.ps1')

$url = (terraform -chdir=$tfDir output -raw jenkins_url).Trim()
$ssh = (terraform -chdir=$tfDir output -raw ssh_command).Trim()

Write-Host ""
Write-Host "==> INFRASTRUCTURE IS UP"
Write-Host "    Jenkins (via IAP): $url"
Write-Host "    SSH:               $ssh"
Write-Host ""

if ($RunAnsible) {
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        throw "Ansible must run on Linux. Use WSL or Google Cloud Shell, or omit -RunAnsible."
    }
    $secure = Read-Host -AsSecureString "Jenkins admin password"
    $pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    $linuxDir = (wsl wslpath -a $ansibleDir).Trim()
    wsl bash -lc "cd '$linuxDir' && ansible-galaxy collection install -r requirements.yml && ansible-playbook site.yml -e jenkins_admin_password='$pw'"
} else {
    Write-Host "Next: configure Jenkins with Ansible (run from WSL / Cloud Shell):"
    Write-Host "    cd ansible"
    Write-Host "    ansible-galaxy collection install -r requirements.yml"
    Write-Host "    ansible-playbook site.yml -e jenkins_admin_password='<secret>'"
    Write-Host "Then open Jenkins through the IAP tunnel shown on the terraform output."
}
