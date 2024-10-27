# Disable user from Active Directory
#
# Usage:
# ./disable-user.ps1 <OPTIONS>

param (
  [string]$username,
  [switch]$debug
)

if ($debug) {
  $DebugPreference = "Continue"
}

Write-Debug "-- Debugging disable-user.ps1 --"

if (!$domain) {
  $domain = $env:employeescript_domain
}

if (!$company) {
  $company = $env:employeescript_company
}

if (!$domain -or !$company) {
  Write-Error "Domain and/or company not set. Please run set-env.ps1 first." -ErrorAction Stop
}

if (-not $username) {
  $username = Read-Host "Please provide the username of the user"
}

# Import the Active Directory module
Import-Module ActiveDirectory

# Stop on error, do not disable the user anyway
# https://stackoverflow.com/questions/26274361/powershell-new-aduser-error-handling-password-complexity-activedirectory-module
$ErrorActionPreference = "Stop"

# Disable the AD user
try {
    Disable-ADAccount -Identity $username -Confirm:$false
} catch {
    Write-Error "Failed to disable user: $_" -ErrorAction Stop
}

Write-Output "User $username disabled successfully."

$ErrorActionPreference = $ExistingEAP

exit 0