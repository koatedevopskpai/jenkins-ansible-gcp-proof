<#
.SYNOPSIS
    Destroy the infrastructure (back to ~GBP0/month).
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$tfDir = [System.IO.Path]::GetFullPath((Join-Path $here '..\infra\terraform\environments\dev'))

Push-Location $tfDir
try {
    $varFile = Join-Path $tfDir 'terraform.tfvars'
    $args = @("destroy", "-auto-approve")
    if (Test-Path $varFile) { $args += "-var-file=$varFile" }
    terraform @args
    if ($LASTEXITCODE -ne 0) { throw "terraform destroy failed" }
}
finally { Pop-Location }
Write-Host "==> Environment destroyed."
