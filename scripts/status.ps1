<#
.SYNOPSIS
    Show the current infrastructure state.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$tfDir = [System.IO.Path]::GetFullPath((Join-Path $here '..\infra\terraform\environments\dev'))

Write-Host "==> Terraform outputs"
terraform -chdir=$tfDir output
Write-Host ""
Write-Host "==> Jenkins VM"
gcloud compute instances list --filter="name~jenkins-ansible" --format="table(name,zone,status,networkInterfaces[0].accessConfigs[0].natIP)"
