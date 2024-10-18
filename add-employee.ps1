param (
    [string]$fullName,
    [string]$department,
    [string]$vmIP,
    [string]$vcPassword,
    [switch]$debug
)

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-debug?view=powershell-7.4
if ($debug) {
    $DebugPreference = "Continue"
}

Write-Debug "-- Debugging add-employee.ps1 --"

function Show-WelcomeMessage {
    Write-Output ""
    Write-Output "Usage: ./add-employee.ps1 <OPTIONS>"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "-fullname string      The full name of the employee"
    Write-Output "-department string    The department of the employee"
    Write-Output "-vmip string          The IP address of the virtual machine"
    Write-Output "-vcpassword string    The password of the vCenter Administrator"
    Write-Output "-debug                Enable debug mode"
    Write-Output ""
}

if (!$fullName -or !$department -or !$vmIP) {
    Show-WelcomeMessage
    exit 0
}

Write-Debug "Full Name: $fullName"
$firstName = $fullName.Split(" ")[0]
$randomVMID= Get-Random -Minimum 10 -Maximum 99
Write-Debug "department: $department"
Write-Debug "Virtual Machine IP: $vmIP"

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
$password = $null
$words = $null
$word1 = $null
$word2 = $null
$word3 = $null

if ($debug) {
    ./tasks/add-user.ps1 -fullName $fullName -department $department -secpassword $secpassword -debug
} else {
    ./tasks/add-user.ps1 -fullName $fullName -department $department -secpassword $secpassword
}

if ($debug) {
    ./tasks/add-vm.ps1 -vmName VM-$firstName-$randomVMID -vcPassword $vcPassword -debug
}