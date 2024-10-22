param (
  [string]$fullname,
  [string]$department,
  [string]$username,
  [string]$password,
  [securestring]$secpassword,
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

if (-not $username) {
  $username = Read-Host "Please provide the username of the user"
}

if ($password) {
  $secpassword = ConvertTo-SecureString $password -AsPlainText -Force
}

if (-not $password -and -not $secpassword) {
  $password = Read-Host "Please provide the password of the user" -AsSecureString
}

# Check if the department group exists
$departmentGroup = "Functiegroep_" + $department
$validDepartments = Get-ADGroup -Filter {GroupCategory -eq "Security"} | Select-Object -ExpandProperty Name | Where-Object { $_ -like "Functiegroep_*" }
if ($validDepartments -notcontains $departmentGroup) {
    Write-Error "Department $departmentGroup not found in local AD."
    Write-Error "Valid validDepartments are: $($validDepartments -join ', ')" -ErrorAction Stop
}

# Check if the department ou exists
$departmentOU = "OU=$department,OU=Gebruikers,DC=hoebergen,DC=internal"
if (-not (Get-ADOrganizationalUnit -Filter {Name -eq $department})) {
    Write-Error "Department $department not found in local AD."
    Write-Error "Please create the OU '$departmentOU' first." -ErrorAction Stop
}

Write-Debug "Full Name: $fullname"
Write-Debug "Department: $department"
Write-Debug "Department Group: $departmentGroup"
Write-Debug "Department OU: $departmentOU"
Write-Debug "Password: $password"
Write-Debug "Secure Password: $secpassword"

# Import the Active Directory module
Import-Module ActiveDirectory

# Stop on error, do not create the user anyway
# https://stackoverflow.com/questions/26274361/powershell-new-aduser-error-handling-password-complexity-activedirectory-module
$ErrorActionPreference = "Stop"

# Split the fullname into first and last name
$names = $fullname -split ' '
$firstname = $names[0]
$lastname = $names[1]

Write-Debug "First Name: $firstname"
Write-Debug "Last Name: $lastname"
Write-Debug "Username: $username"

# Create the new AD user
try {
  New-ADUser `
    -Name $fullname `
    -DisplayName $fullname `
    -Surname $lastname `
    -GivenName $firstname `
    -SamAccountName $username `
    -UserPrincipalName "$username@$domain" `
    -EmailAddress "$username@$domain" `
    -ProfilePath "\\ORC-DC-01\ProfileFolders$\$username" `
    -AccountPassword $secpassword `
    -Company $company `
    -Department $department `
    -Path "OU=$department,OU=Gebruikers,DC=hoebergen,DC=internal" `
    -Enabled $true `
    -ChangePasswordAtLogon $true
} catch {
  Write-Error "Failed to create user: $_" -ErrorAction Stop
}

try {
  Add-ADGroupMember -Identity $departmentGroup -Members $username
} catch {
  Write-Error "Failed to add user to department group: $_" -ErrorAction Stop
}

Write-Output "User $fullname created successfully."

$ErrorActionPreference = $ExistingEAP

exit 0