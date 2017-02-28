#Windows Server Administration Fundamentals With PowerShell
 
#Setup script for building course hosty environment
#
#Requirements: Physical and Virtual machines define in Intro module
    #Windows Server 2012 R2 evaluation
        #https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2012-r2

    #Windows 10 Enterprise evaluation
        #https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise

    #Setup Files located at c:\shares\MasryUK\Setup
    mkdir c:\shares\masryuk\setup

#Build VMs in VMware Workstation for all computers in hosty environment
    #Default 60GB HD
    #1 Processor
    #2GB RAM (depending on host system)
    #Store VMs in an appropriate location

#Build Windows Server 2012 R2 - DC1
    #Complete OOBE

#region - Name Computer RUN ON DC1
        Rename-Computer -NewName DC1
        Restart-computer
#endregion
#region - Set IP, Timezone, Install AD & DNS RUN ON DC1

    #Set IP Address
        New-netIPAddress -IPAddress 192.168.95.20 `
        -PrefixLength 24 `
        -DefaultGateway 192.168.95.2 `
        -InterfaceAlias Ethernet0
    #Set TimeZone
        Tzutil.exe /s "Central Standard Time"
    #Install AD & DNS
       #Install ADDS Role and Mgt Tools
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
       ##Import ADDSDeployment Module
        Import-Module ADDSDeployment
       ##Install a new AD Forest
        Install-ADDSForest `
	        -CreateDnsDelegation:$false `
	        -DatabasePath "C:\Windows\NTDS" `
	        -DomainMode "Win2012R2" `
	        -DomainName "masry.uk" `
	        -DomainNetbiosName "masry" `
	        -ForestMode "Win2012r2" `
	        -InstallDns:$true `
	        -LogPath "C:\Windows\NTDS" `
	        -NoRebootOnCompletion:$false `
	        -SysvolPath "C:\Windows\SYSVOL" `
	        -Force:$true
#endregion
#region DNS,DHCP, File Shares, and AD Objects
    #Set DNS Forwarder
        Set-DnsServerForwarder -IPAddress 4.2.2.1 -ComputerName DC1
    #Install DHCP
        install-windowsfeature -computerName DC1 -name DHCP -IncludeManagementTools

    #Complete Post Configuration
        #Create DHCP Groups
        netsh dhcp add securitygroups

        #Add Server into Active Directory
        Add-DhcpServerInDC -IPAddress 192.168.95.20 -DnsName dc1.masry.uk

    #Create Initial Scope for 192.168.95.0 subnet
        Add-DhcpServerv4Scope -Name 'Production Scope' `
            -ComputerName DC1.masry.uk `
            -StartRange 192.168.95.100 `
            -EndRange 192.168.95.200 `
            -SubnetMask 255.255.255.0 `
            -LeaseDuration 08:00:00

        set-DhcpServerv4OptionValue `
            -ScopeId 192.168.95.0 `
            -ComputerName DC1.masry.uk `
            -DnsDomain masry.uk `
            -router 192.168.95.2 `
            -DnsServer 192.168.95.20

    #Create \\dc1\masryuk share
    New-SmbShare -Path c:\shares\masryuk -Name MasryUK -FullAccess 'masry\domain users'

    #Add Printers
        Add-PrinterDriver -Name 'Dell 1130 Laser Printer' -ComputerName DC1 -Verbose

        Add-Printer `
            -Name 'EG-MasryUK-1' `
            -PortName 'file:' `
            -Comment 'This is a hosty Printer' `
            -DriverName 'Dell 1130 Laser Printer' `
            -ComputerName DC1 `
            -Shared -ShareName 'EG-MasryUK-1'

        Add-Printer `
            -Name 'EG-MasryUK-2' `
            -PortName 'LPT2:' `
            -Comment 'This is a hosty Printer' `
            -DriverName 'Dell 1130 Laser Printer' `
            -ComputerName DC1 `
            -Shared -ShareName 'EG-MasryUK-2'
    #Add AD Objects
        #Add OUs
        New-ADOrganizationalUnit `
            -Name CompanyOU `
            -path "DC=masry,DC=uk"
        New-ADOrganizationalUnit `
            -Name Austin `
            -Path "OU=CompanyOU,DC=masry,DC=uk"
        New-ADOrganizationalUnit `
            -Name London `
            -path "OU=CompanyOU,DC=masry,DC=uk"
        New-ADOrganizationalUnit `
            -name Computers `
            -path "OU=London,OU=CompanyOU,DC=masry,DC=uk"
        New-ADOrganizationalUnit `
            -Name Users `
            -Path "OU=London,OU=CompanyOU,DC=masry,DC=uk"
        New-ADOrganizationalUnit `
            -Name Member-Servers `
            -path "Ou=Computers,OU=London,OU=CompanyOU,DC=masry,DC=uk"
        #Add Users
        C:\shares\masryuk\setup\Create-Users.ps1
#endregion
#region Verify
    cls

    Get-ADObject -SearchBase "OU=CompanyOU,DC=masry,DC=uk" -Filter *|ft

    get-printer |ft

    get-smbshare -Name MasryUK

    Get-DhcpServerv4Scope | ft
#endregion
#region Build Windows 10 Client - Client1
    #
    Rename-Computer -NewName Client1
    Restart-computer

    Add-computer -DomainName masry.uk -Credential (Get-Credential)
#endregion
#region
##Server 1 - Completed in next module
#endregion
#region Build Server2
    #Set TimeZone
    Tzutil.exe /s "Central Standard Time"

    #Set Network Adapter Names
        get-netadapter -Name Ethernet0 | `
            Rename-NetAdapter -NewName Production

        get-NetAdapter -Name Ethernet1 | `
            Rename-NetAdapter -NewName Management

    #Set IP Address
        New-netIPAddress -IPAddress 192.168.95.60 `
            -PrefixLength 24 `
            -DefaultGateway 192.168.95.2 `
            -InterfaceAlias Production
        New-netIPAddress -IPAddress 192.168.95.70 `
            -PrefixLength 24 `
            -DefaultGateway 192.168.95.2 `
            -InterfaceAlias Management
    #Set DNS Server
        set-DnsClientServerAddress `
            -InterfaceAlias Production `
            -ServerAddresses 192.168.95.20
        Set-DnsClientServerAddress `
            -InterfaceAlias Management `
            -ServerAddresses 192.168.95.20

    #Rename Computer
        Rename-Computer -NewName Server2
        Restart-computer

    #add computer to domain
        Add-computer -DomainName masry.uk -Credential (Get-Credential)
#endregion
#endregion
