# Script used to set the variables for the add-employee script
#
# Usage:
# ./set-env.ps1 <OPTIONS>

param (
  [string]$vcAdminUsername,
  [string]$vcAdminPassword,
  [string]$domainAdminUsername,
  [string]$domainAdminPassword,
  [string]$company,
  [string]$domain
)

if (!$vcAdminUsername -and !$vcAdminPassword -and !$domainAdminUsername -or !$domainAdminPassword -and !$company -and !$domain) {
  Write-Host "
Usage: ./set-env.ps1 <OPTIONS>

Options:
  -vcAdminUsername <vcAdminUsername> 
  -vcAdminPassword <vcAdminPassword> 
  -domainAdminUsername <domainAdminUsername> 
  -domainAdminPassword <domainAdminPassword> 
  -company <company> 
  -domain <domain>
"
  exit 0
}

# Loop through the parameters and set the environment variables if they are not empty
if ($vcAdminUsername) { $env:employeescript_vcAdminUsername = $vcAdminUsername }
if ($vcAdminPassword) { $env:employeescript_vcAdminPassword = $vcAdminPassword }
if ($domainAdminUsername) { $env:employeescript_domainAdminUsername = $domainAdminUsername }
if ($domainAdminPassword) { $env:employeescript_domainAdminPassword = $domainAdminPassword }
if ($company) { $env:employeescript_company = $company }
if ($domain) { $env:employeescript_domain = $domain }


Write-Host "Variables set for add-employee.ps1"
Write-Host "vcAdminUsername: $env:employeescript_vcAdminUsername"
Write-Host "vcAdminPassword: $env:employeescript_vcAdminPassword"
Write-Host "domainAdminUsername: $env:employeescript_domainAdminUsername"
Write-Host "domainAdminPassword: $env:employeescript_domainAdminPassword"
Write-Host "company: $env:employeescript_company"
Write-Host "domain: $env:employeescript_domain"