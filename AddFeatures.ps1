#Review Installed Roles and Features
Get-WindowsFeature -ComputerName Server1.masry.uk

Get-WindowsFeature -ComputerName Server1.masry.uk |
     where 'Installed' -eq $true

#Add Roles
Add-WindowsFeature -Name DNS -IncludeManagementTools

Add-WindowsFeature -name Web-Server -IncludeSubFeatures
