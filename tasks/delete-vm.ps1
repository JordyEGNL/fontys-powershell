# Delete the VM from the vCenter server
#
# Usage:
# ./disable-vm.ps1 <OPTIONS>
#
# vcUsername and vcPassword are optional for the vCenter connection
# Both can be globally set with ../set-env.ps1 or temp set with the script as arguments

param (
  [string]$vmName,
  [string]$vcUsername,
  [string]$vcPassword,
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

if (-not $vmName) {
  $vmName = Read-Host "Please provide the name of the VM (ex: TestVM)"
}

if (-not $vcUsername) {
  $vcUsername = Read-Host "Please provide the username of the vCenter Administrator"
}

if (-not $vcPassword) {
  $vcPassword = Read-Host "Please provide the password of the vCenter Administrator"
}

Write-Debug "-- Debugging add-vm.ps1 --"
Write-Debug "VM Name: $vmName"
Write-Debug "vCenter Username: $vcUsername"
Write-Debug "vCenter Password: $vcPassword"

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
$isVM = $true

#
# Check if the VM already exists via name check
#
if (-not ($vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue)) {
  Write-Debug "VM $vmName does not exist."
  $isVM = $false
}

# When the VM exists, stop and remove it
if ( $isVM) {
    # Stop the VM
    Write-Debug "Stopping the VM $vmName..."
    Stop-VM -VM $vm -Confirm:$false

    # Remove the VM
    Write-Debug "Removing the VM $vmName..."
    Remove-VM -VM $vm -DeleteFromDisk -Confirm:$false
}

#
# vcenter cleanup
#
Disconnect-VIServer -Server $vcServer -Confirm:$false

exit 0