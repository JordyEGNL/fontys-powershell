param (
  [string]$fullname,
  [string]$department,
  [string]$password,
  [switch]$debug
)

if ($debug) {
  $DebugPreference = "Continue"
}

Write-Debug "-- Debugging add-user.ps1 --"

$company = "Hoebergen"
$domain = "hoebergen.internal"

if (-not $fullname) {
  $fullname = Read-Host "Please provide the full name of the user"
}

if (-not $department) {
  $department = Read-Host "Please provide the department of the user"
}

if ($password) {
  $secpassword = ConvertTo-SecureString $password -AsPlainText -Force
}

Write-Debug "Full Name: $fullname"
Write-Debug "Department: $department"
Write-Debug "Password: $password"
Write-Debug "Secure Password: $secpassword"

if (-not $password -and -not $secpassword) {
  $password = Read-Host "Please provide the password of the user" -AsSecureString
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

Write-Debug "First Name: $firstname"
Write-Debug "Last Name: $lastname"
Write-Debug "Username: $username"

# Create the new AD user
New-ADUser `
-Name $fullname `
  -DisplayName $fullname `
  -Surname $lastname `
  -GivenName $firstname `
  -SamAccountName $username `
  -UserPrincipalName "$username@$domain" `
  -AccountPassword $secpassword `
  -Company $company `
  -Department $department `
  -Path "OU=Gebruikers,DC=hoebergen,DC=internal" `
  -Enabled $true `
  -ChangePasswordAtLogon $true

Write-Output "User $fullname created successfully."

$ErrorActionPreference = $ExistingEAP

exit 0