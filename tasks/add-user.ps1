param (
  [string]$fullname,
  [string]$department
)

$company = "Hoebergen"

if (-not $fullname) {
  $fullname = Read-Host "Please provide the full name of the user"
}

if (-not $department) {
  $department = Read-Host "Please provide the department of the user"
}

if (-not $password) {
  $password = Read-Host "Please provide the password of the user" -AsSecureString
}

if (-not $company) {
  $company = Read-Host "Please provide the company of the user"
}

# Import the Active Directory module
Import-Module ActiveDirectory

# Stop on error, do not create the user anyway
# https://stackoverflow.com/questions/26274361/powershell-new-aduser-error-handling-password-complexity-activedirectory-module
$ErrorActionPreference = "Stop"

# Split the fullname into first and last name
$names = $fullname -split ' '
$firstname = $names[0]
$lastname = $names[1]

# Create a username from the first and last name
$username = "$firstname.$lastname".ToLower()

# Create the new AD user
New-ADUser `
-Name $fullname `
  -DisplayName $fullname `
  -Surname $lastname `
  -GivenName $firstname `
  -SamAccountName $username `
  -UserPrincipalName "$username@hoebergen.internal" `
  -AccountPassword $password `
  -Company $company `
  -Department $department `
  -Path "OU=Gebruikers,DC=hoebergen,DC=internal" `
  -Enabled $true `
  -ChangePasswordAtLogon $true

Write-Output "User $fullname created successfully."

$ErrorActionPreference = $ExistingEAP