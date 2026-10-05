<#
.SYNOPSIS
    Re-run the Ansible configuration against the Jenkins controller (idempotent).
.DESCRIPTION
    Use after changing the Ansible roles or group_vars. Runs via WSL.
#>
[CmdletBinding()]
param(
    [string]$Tags = "common,docker,gcp_tools,jenkins,monitoring"
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$ansibleDir = [System.IO.Path]::GetFullPath((Join-Path $here '..\ansible'))

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw "Ansible must run on Linux. Use WSL or Google Cloud Shell."
}

$secure = Read-Host -AsSecureString "Jenkins admin password"
$pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$linuxDir = (wsl wslpath -a $ansibleDir).Trim()

wsl bash -lc "cd '$linuxDir' && ansible-playbook site.yml --tags '$Tags' -e jenkins_admin_password='$pw'"
