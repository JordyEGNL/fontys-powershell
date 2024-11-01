# Create new VM from template
#
# Usage:
# ./add-employee.ps1 <OPTIONS>
#
# vcUsername and vcPassword are optional for the vCenter connection
# adminUsername and adminPassword are optional for the domain join
# Both can be globally set with ./set-env.ps1 or temp set with the script as arguments

param (
  [string]$username,
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

Write-Debug "-- Debugging disable-employee.ps1 --"

function Show-WelcomeMessage {
  Write-Output "
Usage: ./disable-employee.ps1 <OPTIONS>

Options:
  -username string          The username of the employee
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

if (!$username -or !$vcUsername -or !$vcPassword -or !$adminUsername -or !$adminPassword) {
  Show-WelcomeMessage
  exit 0
}

#
# Retrieve the employeenumber from the username
#
# Split the username to get the first name
$firstName = $username.Split(".")[0]

$employeeNumber = (Get-ADUser -Identity $username -Properties EmployeeNumber).EmployeeNumber
if (!$employeeNumber) {
  Write-Error "The user $username does not exist in Active Directory." -ErrorAction Stop
}

$vmName = "VM-$firstName-$employeeNumber"

Write-Debug "Username: $username"
Write-Debug "Employee Number: $employeeNumber"
Write-Debug "First Name: $firstName"
Write-Debug "vcUsername: $vcUsername"
Write-Debug "vcPassword: $vcPassword"
Write-Debug "adminUsername: $adminUsername"
Write-Debug "adminPassword: $adminPassword"
Write-Debug "VM Name: $vmName"

if ($debug) {
  ./tasks/disable-user.ps1 -username $username -debug
  ./tasks/delete-vm.ps1 -vmName $vmName -vcUsername $vcUsername -vcPassword $vcPassword -debug
} else {
  ./tasks/disable-user.ps1 -username $username
  ./tasks/delete-vm.ps1 -vmName $vmName -vcUsername $vcUsername -vcPassword $vcPassword
}

Write-Output "Employee $username disabled and VM  $vmName deleted successfully."