# Create new VM from template
#
# Usage:
# ./add-vm.ps1 <OPTIONS>
#
# vcUsername and vcPassword are optional for the vCenter connection
# adminUsername and adminPassword are optional for the domain join
# Both can be globally set with ../set-env.ps1 or temp set with the script as arguments

param (
  [string]$vmName,
  [string]$vcUsername,
  [string]$vcPassword,
  [string]$adminUsername,
  [string]$adminPassword,
  [switch]$debug
)

if ($debug) {
  $DebugPreference = "Continue"
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

if (-not $vmName) {
  $vmName = Read-Host "Please provide the name of the VM (ex: TestVM)"
}

if (-not $vcUsername) {
  $vcUsername = Read-Host "Please provide the username of the vCenter Administrator"
}

if (-not $vcPassword) {
  $vcPassword = Read-Host "Please provide the password of the vCenter Administrator"
}

if (-not $adminUsername) {
  $adminUsername = Read-Host "Please provide the username of the domain admin"
}

if (-not $adminPassword) {
  $adminPassword = Read-Host "Please provide the password of the domain admin"
}

Write-Debug "-- Debugging add-vm.ps1 --"
Write-Debug "VM Name: $vmName"
Write-Debug "vCenter Username: $vcUsername"
Write-Debug "vCenter Password: $vcPassword"
Write-Debug "Admin Username: $adminUsername"
Write-Debug "Admin Password: $adminPassword"

# 
# Connect to the vcenter server
#
$vcServer = "vcenter.netlab.fontysict.nl"

try {
  Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword -ErrorAction Stop
  Write-Debug "Successfully connected to vCenter server $vcServer."
} catch {
  Write-Error "Failed to connect to vCenter server $vcServer. $_"
  exit 1
}

# Set the default variables for the vm
$resourcePool = "I533550"
$folder = "I533550"
$template = "Windows10T"
$datastore = "DataCluster-Students"
$networkName = "2720_I533550_PVlanA"
$isVM = $false

#
# Check if the VM already exists via name check
#
if ($vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
  Write-Debug "VM $vmName already exists."
  $isVM = $true
}

# Create the VM if it does not exist
if (-not $isVM) {
  Write-Debug "Creating a new VM from a template..."
  $vm = New-VM -Name $vmName `
    -Template $template `
    -Datastore $datastore `
    -ResourcePool $resourcePool `
    -Location $folder
}

# Delay to finish the VM creation (if the vm is created but not ready it is fine)
Start-Sleep -Seconds 10

# 
# When vm is created, set the network adapter
# If the vm already exists, dont do this
# $vm is set when the vm is created
#
if ($vm) {
    Write-Debug "Checking if network adapter is already set..."
    $networkAdapter = Get-NetworkAdapter -VM $vm
    Write-Debug "Network adapter thats currently set: $($networkAdapter.NetworkName)"
    if ($networkAdapter.NetworkName -ne $networkName) {
      Write-Debug "Changing network adapter..."
      # Configure the network adapter separately
      $networkAdapter | Set-NetworkAdapter -NetworkName $networkName -Confirm:$false
    } else {
      Write-Debug "Network adapter is already set to $networkName."
    }
} else {
    # If VM already exists
    Write-Debug "VM already exists, not creating."
    $vm = Get-VM -Name $vmName
    if ($vm) {
        Write-Debug "Starting VM $vmName..."
        # Power on the VM
        if ($vm.PowerState -ne 'PoweredOn') {
          Start-VM -VM $vm
          Write-Debug "VM $vmName powered on."
        }
    } else {
        Write-Error "Failed to create VM."
        exit 1
    }
}

#
# Start the VM
#
if ($vm.PowerState -ne 'PoweredOn') {
  Write-Debug "Starting VM $vmName..."
  Start-VM -VM $vm
  Write-Debug "VM $vmName powered on."
}

# Retrieve the IP address of the VM from the vCenter try again every 10 seconds
# Regex from https://www.powershelladmin.com/wiki/PowerShell_regex_to_accurately_match_IPv4_address_(0-255_only).php
$attempts = 1
$maxAttempts = 10
while (-not $vmIP -and $attempts -lt $maxAttempts) {
  $vmIP = (Get-VM -Name $vmName).Guest.IPAddress | Where-Object { $_ -match '^(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$' }
  Start-Sleep -Seconds 20
  Write-Debug "Trying to get the IP address of $vmName... ($attempts/$maxAttempts)"
  $attempts++
}

if (-not $vmIP) {
  Write-Error "Failed to retrieve the IP address of $vmName after $maxAttempts attempts."
  exit 1
}

# Display IP address
Write-Debug "IP of $vmName is $vmIP"

#
# vcenter cleanup
#
Disconnect-VIServer -Server $vcServer -Confirm:$false


#
# Domain join
#

# Domain information
$adminUsername = "HOEBERGEN\" + $adminUsername
$domain = "hoebergen.internal"

Write-Debug "Admin Username: $adminUsername"

$sshUser = "Admin"
$sshsecurePassword = ConvertTo-SecureString "PLACEHOLDER" -AsPlainText -Force

# Create a secure password object
$sshsecurePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$sshcredential = New-Object System.Management.Automation.PSCredential($sshUser, $sshsecurePassword)

# Construct the SSH command to start a session
$sshSession = "ssh -o StrictHostKeyChecking=no $($sshcredential.UserName)@$vmIP"
$sshProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $sshSession -WindowStyle Hidden -PassThru

Start-Sleep -Seconds 5

# Check if the computer is already in the domain
# https://www.alexandrumarin.com/check-if-a-system-is-joined-to-domain-using-powershell/
$domainCheckCommand = "if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) { Write-Host 'Already in domain' } else { Write-Host 'Not in domain' }"
$domainCheckResult = Invoke-Expression "$sshSession `powershell -Command `"$domainCheckCommand`"" | Out-String

# If the computer is not in the domain, add it
# Made with Karsten S
if ($domainCheckResult -match 'Not in domain') {
    # Add computer command
    $remoteCommand = "Add-Computer -Domain $domain -Credential (New-Object System.Management.Automation.PSCredential('$adminUsername', (ConvertTo-SecureString '$adminPassword' -AsPlainText -Force))) -NewName '$vmName' -Restart -Force"
    # Execute the command in the SSH session
    Invoke-Expression "$sshSession `powershell -Command `"$remoteCommand`"" | Out-Null
    Write-Host "$vmName ($vmIP) has been added to the domain $domain."
  } else {
    if ($domainCheckResult -match 'Already in domain') {
        Write-Host "$vmName ($vmIP) is already in the domain $domain."
    } else {
      # On connection error, for example ssh timeout
      Write-Error "Failed to check if $vmName is in the domain." -ErrorAction Stop
    }
}

#
# domain join cleanup
#
Stop-Process -Id $sshProcess.Id -Force

exit 0