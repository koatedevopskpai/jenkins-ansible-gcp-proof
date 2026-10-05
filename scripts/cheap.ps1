<#
.SYNOPSIS
    Apply the cheap cost profile (e2-small VM, 20GB disk, no GKE, weekday schedule).
.DESCRIPTION
    The Makefile equivalent is `make cheap`. Use `make full` / -Cheap:$false to
    switch back to the standard e2-medium profile.
#>
[CmdletBinding()]
param([switch]$Cheap = $true)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$tfDir = [System.IO.Path]::GetFullPath((Join-Path $here '..\infra\terraform\environments\dev'))

if (-not (Test-Path (Join-Path $tfDir '.terraform'))) { terraform -chdir=$tfDir init -input=false }

$args = @("apply", "-auto-approve", "-var=cheap_mode=$($Cheap.IsPresent.ToString().ToLower())")
if ($Cheap) { $args += "-var=enable_gke=false" }
terraform -chdir=$tfDir @args
if ($LASTEXITCODE -ne 0) { throw "terraform apply failed" }

Write-Host ""
Write-Host "==> Active cost profile"
terraform -chdir=$tfDir output cost_profile
