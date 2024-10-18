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

## Vcenter connection
$vcServer = "vcenter.netlab.fontysict.nl"

try {
  Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword -ErrorAction Stop
  Write-Debug "Successfully connected to vCenter server $vcServer."
} catch {
  Write-Error "Failed to connect to vCenter server $vcServer. $_"
  exit 1
}

# VM variables
$resourcePool = "I533550"
$folder = "I533550"
$template = "Windows10T"
$datastore = "DataCluster-Students"
$networkName = "2720_I533550_PVlanA"

# Check if the VM already exists, if not create vm
if (-not (Get-VM -Name $vmName -ErrorAction SilentlyContinue)) {
  Write-Debug "Creating a new VM from a template..."
  $vm = New-VM -Name $vmName `
    -Template $template `
    -Datastore $datastore `
    -ResourcePool $resourcePool `
    -Location $folder
}

# Ensure the VM was successfully created before configuring the network
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
    $vm = Get-VM -Name $vmName
    if ($vm) {
        Write-Host "VM already exists, not creating."
    } else {
        Write-Error "Failed to create VM."
        exit 1
    }
}

# Power on the VM
if ((Get-VM -Name $vmName).PowerState -ne 'PoweredOn') {
  Start-VM -VM $vm
}

# Retrieve the IP address of the VM from the vCenter try again every 10 seconds
# Regex from https://www.powershelladmin.com/wiki/PowerShell_regex_to_accurately_match_IPv4_address_(0-255_only).php
$attempts = 1
$maxAttempts = 6
while (-not $vmIP -and $attempts -lt $maxAttempts) {
  $vmIP = (Get-VM -Name $vmName).Guest.IPAddress | Where-Object { $_ -match '^(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$' }
  Start-Sleep -Seconds 10
  Write-Debug "Trying to get the IP address of $vmName... ($attempts/$maxAttempts)"
  $attempts++
}

if (-not $vmIP) {
  Write-Error "Failed to retrieve the IP address of $vmName after $maxAttempts attempts."
  exit 1
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
} else {
    Write-Host "$vmName ($vmIP) is already in the domain $domain."
}

# Ensure the SSH process is terminated
Stop-Process -Id $sshProcess.Id -Force