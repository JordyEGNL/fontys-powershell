# Automating the onboarding process with Powershell

## Introduction
This repository consists of PowerShell scripts used to automate te onboarding process of a fictive company. In the future VM deployment will also be automated on VMware ESXI.

## Prerequisites
- **Windows PowerShell**
- **Active Directory Module**: Installed via RSAT (Remote Server Administration Tools).

## Installation Steps

### Installing RSAT
1. Open **Settings**.
2. Go to **Apps** > **Optional Features**.
3. Click on **Add a feature**.
4. Search for **RSAT: Active Directory Domain Services and Lightweight Directory Tools**.
5. Install the feature.

### Import the Active Directory Module
```powershell
Import-Module ActiveDirectory -Scope CurrentUser
```

### Import the PowerCLI Module
```powershell
Install-Module VMware.PowerCLI -Scope CurrentUser
```

## Troubleshooting

### Execution policy
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage Example
```powershell
# Get all users in the domain
Get-ADUser -Filter *
```

## Additional Resources
- [Microsoft Docs: Active Directory Module for Windows PowerShell](https://docs.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2022-ps)