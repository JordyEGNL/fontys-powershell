# Create new VM from template
#
# Usage:
# ./add-employee.ps1 <OPTIONS>
#
# vcUsername and vcPassword are optional for the vCenter connection
# adminUsername and adminPassword are optional for the domain join
# Both can be globally set with ./set-env.ps1 or temp set with the script as arguments

param (
  [string]$fullName,
  [string]$department,
  [string]$employeeNumber,
  [string]$vcUsername,
  [string]$vcPassword,
  [string]$adminUsername,
  [string]$adminPassword,
  [switch]$debug
)

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-debug?view=powershell-7.4
if ($debug) {
  $DebugPreference = "Continue"
}

Write-Debug "-- Debugging add-employee.ps1 --"

function Show-WelcomeMessage {
  Write-Output "
Usage: ./add-employee.ps1 <OPTIONS>

Options:
  -fullname string          The full name of the employee
  -department string        The department of the employee
  -employeenumber string    The employee number of the employee
  -vcusername string        The username of the vCenter Administrator
  -vcpassword string        The password of the vCenter Administrator
  -adminusername string     The username of the domain admin
  -adminpassword string     The password of the domain admin
  -debug                    Enable debug mode
"
  exit 0
}

if (!$vcUsername) {
  $vcUsername = $env:employeescript_vcAdminUsername
}

if (!$vcPassword) {
  $vcPassword = $env:employeescript_vcAdminPassword
}

if (!$adminUsername) {
  $adminUsername = $env:employeescript_domainAdminUsername
}

if (!$adminPassword) {
  $adminPassword = $env:employeescript_domainAdminPassword
}

if (!$fullName -or !$department -or !$employeeNumber -or !$vcUsername -or !$vcPassword -or !$adminUsername -or !$adminPassword) {
  Show-WelcomeMessage
  exit 0
}

Write-Debug "Full Name: $fullName"
$firstName = $fullName.Split(" ")[0]
Write-Debug "department: $department"
Write-Debug "Employee Number: $employeeNumber"
Write-Debug "vcUsername: $vcUsername"
Write-Debug "vcPassword: $vcPassword"
Write-Debug "adminUsername: $adminUsername"
Write-Debug "adminPassword: $adminPassword"

# Random generate password of 3 words from
# https://github.com/OpenTaal/opentaal-wordlist
$words = Get-Content -Path "opentaal-worldlist\alleen-bijwoorden.txt"
$word1 = $words | Get-Random
$word2 = $words | Get-Random
$word3 = $words | Get-Random
[string]$password = "$word1-$word2-$word3"
Write-Debug "Password: $password"
[securestring]$secpassword = ConvertTo-SecureString "$password" -AsPlainText -Force

# Clear variables
$words = $null
$word1 = $null
$word2 = $null
$word3 = $null

# Split the fullname into first and last name
$names = $fullname -split ' '
$firstname = $names[0]
$lastname = ($names[1..($names.Length - 1)] -join '.').ToLower()
# Create a username from the first and last name
$username = "$firstname.$lastname".ToLower()

if ($debug) {
  ./tasks/add-user.ps1 -fullName $fullName -username $username -department $department -employeenumber $employeeNumber -secpassword $secpassword -debug
  ./tasks/add-vm.ps1 -vmname VM-$firstName-$employeeNumber -vcUsername $vcUsername -vcPassword $vcPassword -adminUsername $adminUsername -adminpassword $adminPassword -debug
} else {
  ./tasks/add-user.ps1 -fullName $fullName -username $username -department $department -employeenumber $employeeNumber -secpassword $secpassword
  ./tasks/add-vm.ps1 -vmname VM-$firstName-$employeeNumber -vcUsername $vcUsername -vcPassword $vcPassword -adminUsername $adminUsername -adminpassword $adminPassword
}

# Send credentials
Write-Host "---------------------"
Write-Host "Username: $username"
Write-Host "Password: $password"
Write-Host "---------------------"