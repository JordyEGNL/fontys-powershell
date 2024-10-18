param (
  [string]$vmName,
  [string]$vcPassword,
  [string]$adminUsername,
  [string]$adminPassword,
  [switch]$debug
)

if ($debug) {
  $DebugPreference = "Continue"
}

if (-not $vmName) {
  $vmName = Read-Host "Please provide the name of the VM (ex: TestVM)"
}

if (-not $vcPassword) {
  $vcPassword = Read-Host "Please provide the password of the vCenter"
}

if (-not $adminUsername) {
  $adminUsername = Read-Host "Please provide the username of the domain admin"
}

if (-not $adminPassword) {
  $adminPassword = Read-Host "Please provide the password of the domain admin"
}

## Vcenter connection
$vcServer = "vcenter.netlab.fontysict.nl"
$vcUser = "i533550@fontysict.nl"

Connect-VIServer -Server $vcServer -User $vcUser -Password $vcPassword

# VM variables
$resourcePool = "I533550"
$folder = "I533550"
$template = "Windows10T"
$datastore = "DataCluster-Students"
$networkName = "2721_I533550_PVlanA"

# Check if the VM already exists, if not create vm
if (-not (Get-VM -Name $vmName)) {

$vm = New-VM -Name $vmName `
    -Template $template `
    -Datastore $datastore `
    -ResourcePool $resourcePool `
    -Location $folder
}

# Ensure the VM was successfully created before configuring the network
if ($vm) {
    # Configure the network adapter separately
    Get-NetworkAdapter -VM $vm | Set-NetworkAdapter -NetworkName $networkName -Confirm:$false
} else {
    # If VM already exist
    $vm = Get-VM -Name $vmName
    if ($vm) {
        Write-Host "VM already exists."
    } else {
        Write-Error "Failed to create VM."
    }
}

# Power on the VM
if ((Get-VM -Name $vmName).PowerState -ne 'PoweredOn') {
  Start-VM -VM $vm
}

# Retrieve the IP address of the VM from the vCenter try again every 10 seconds
# Regex from https://www.powershelladmin.com/wiki/PowerShell_regex_to_accurately_match_IPv4_address_(0-255_only).php
while (-not $vmIP) {
    $vmIP = (Get-VM -Name $vmName).Guest.IPAddress | Where-Object { $_ -match '^(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$' }
    Start-Sleep -Seconds 10
}

# Display IP address
Write-Debug "IP of $vmName is $vmIP"

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false


# ---- Add to domain ----

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
$sshProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $sshSession -PassThru

Start-Sleep -Seconds 5

#add computer command
$remoteCommand = "Add-Computer -Domain $domain -Credential (New-Object System.Management.Automation.PSCredential('$adminUsername', (ConvertTo-SecureString '$adminPassword' -AsPlainText -Force))) -NewName '$vmName' -Restart -Force"

# Execute the command in the SSH session
Invoke-Expression "$sshSession `powershell -Command `"$remoteCommand`"" | Out-Null

Stop-Process -Id $sshProcess.Id