$gbnaam = "HOEBERGEN\admjordy"
$gbpass = "Admin01!"
$domain = "hoebergen.internal"

$sshUser = "Admin"
$sshsecurePassword = ConvertTo-SecureString "PLACEHOLDER" -AsPlainText -Force

$vmIP = "172.16.2.25"
$vmName = "TestVM"

# Create a secure password object
$sshsecurePassword = ConvertTo-SecureString $gbpass -AsPlainText -Force
$sshcredential = New-Object System.Management.Automation.PSCredential($sshUser, $sshsecurePassword)

# Construct the SSH command to start a session
$sshSession = "ssh -o StrictHostKeyChecking=no $($sshcredential.UserName)@$vmIP"
$sshProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $sshSession -PassThru

Start-Sleep -Seconds 5

#add computer command
$remoteCommand = "Add-Computer -Domain $domain -Credential (New-Object System.Management.Automation.PSCredential('$gbnaam', (ConvertTo-SecureString '$gbpass' -AsPlainText -Force))) -NewName '$vmName' -Restart -Force"

# Execute the command in the SSH session
Invoke-Expression "$sshSession `powershell -Command `"$remoteCommand`""

Stop-Process -Id $sshProcess.Id