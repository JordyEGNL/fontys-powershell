param (
  [string]$vmName,
  [string]$vcPassword
)

if (-not $vmName) {
  $vmName = Read-Host "Please provide the name of the VM"
}

if (-not $vcPassword) {
  $vcPassword = Read-Host "Please provide the password of the vCenter"
}

## Vcenter connection
$vcServer = "vcenter.netlab.fontysict.nl"
$vcUser = "i533550@fontysict.nl"

Connect-VIServer -Server $vcServer -User $vcUser -Password $vcPassword

# VM variables
$resourcePool = "I533550"
$folder = "I533550"
$template = "UbuntuServer"
$datastore = "DataCluster-Students"
$networkName = "2721_I533550_PVlanB"
$vmIP = "172.16.3.55"

# Create a new VM from a template
# Clone the VM from template (without -Cluster parameter)
$vm = New-VM -Name $vmName `
    -Template $template `
    -Datastore $datastore `
    -ResourcePool $resourcePool `
    -Location $folder

# Ensure the VM was successfully created before configuring the network
if ($vm) {
    # Configure the network adapter separately
    Get-NetworkAdapter -VM $vm | Set-NetworkAdapter -NetworkName $networkName -Confirm:$false
} else {
    # If VM already exist
    $vm = Get-VM -Name $vmName
    if ($vm) {
        Write-Host "WARN: VM already exists."
    } else {
        Write-Host "ERROR: Failed to create VM."
    }
}

# Power on the VM
Start-VM -VM $vm

# Display IP address
Write-Host "IP of $vmName is $vmIP"

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false