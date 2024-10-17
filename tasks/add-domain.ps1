param (
  [string]$vmName,
  [string]$vmIP,
  [string]$adminUsername,
  [string]$adminPassword
)

if (-not $vmName) {
  $vmName = Read-Host "Please provide the name of the VM"
}

if (-not $vmIP) {
  $vmIP = Read-Host "Please provide the IP of the VM"
}

if (-not $adminUsername) {
  $adminUsername = Read-Host "Please provide the username of the domain admin"
}

if (-not $adminPassword) {
  $adminPassword = Read-Host "Please provide the password of the domain admin"
}

# Domain information
#$adminUsername = "HOEBERGEN\admjordy"
#$adminPassword = "Admin01!"
$domain = "hoebergen.internal"

$sshUser = "Admin"
$sshsecurePassword = ConvertTo-SecureString "PLACEHOLDER" -AsPlainText -Force

#$vmIP = "172.16.2.25"
#$vmName = "TestVM"

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
Invoke-Expression "$sshSession `powershell -Command `"$remoteCommand`""

Stop-Process -Id $sshProcess.Id