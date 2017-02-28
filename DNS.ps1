  ##Configuring DNS with PowerShell

  #region MasryUK1-Querying

    #Test Network Connectivity and Name Resolution in one step
        Test-NetConnection -ComputerName pluralsight.com

    #querying DNS
        Resolve-DnsName -Type ALL -Name pluralsight.com -Server 4.2.2.1

        Resolve-DnsName -Name masry.uk -Type A -Server DC1.masry.uk

        Resolve-DnsName -Name masry.uk -Type A -Server Server1.masry.uk

        Resolve-DnsName -Name pluralsight.com -Type MX -Server DC1.masry.uk

    #DNS Client Stuff
        Get-DnsClientCache
	    gcm *DNSClient*
	    Clear-DNSClientCache
	    Get-DnsClientCache
        Get-DnsClientServerAddress -CimSession (New-CimSession -ComputerName DC1)



    #configure DNS Server Settings
        Get-DnsServer -ComputerName DC1 |gm

        get-dnsserver -ComputerName DC1

        Get-DnsServerSetting -All -ComputerName DC1

        Get-DNSServerSetting -ComputerName DC1 -all | select RoundRobin

        Get-DnsServerSetting -computername DC1 -all | Export-Clixml  C:\MasryUK\testdns.xml

        notepad c:\masryuk\testdns.xml

        Import-Clixml C:\masryuk\testdns-u.xml | Set-DnsServerSetting -ComputerName DC1

        Get-DNSServerSetting -ComputerName DC1 -all | select RoundRobin

    #Configure with WMI
        $Server = Get-WMIObject MicrosoftDNS_Server `
                    -Namespace "root\MicrosoftDNS" `
                    -Computer DC1
        $Server

        $Server | Get-Member

        # Setting RoundRobin
        $Server.RoundRobin = 'false'

        $Server.Put()

        # Start Scavenging
        $Server.RoundRobin

  #endregion hosty1-querying

  #region MasryUK2:forwaders
      #configure Forwarders
          Get-DnsServerForwarder -ComputerName DC1
          Get-DnsServerForwarder -ComputerName Server1

      #Standard Forwarders
          Resolve-DnsName -Name dc1.masry.uk -Server Server1.masry.uk
          Add-DnsServerForwarder -IPAddress 192.168.95.20 -ComputerName server1.masry.uk
          Invoke-command -ComputerName Server1 -ScriptBlock { restart-service -Name DNS -force}
          Resolve-DnsName -Name dc1.masry.uk -Server server1.masry.uk

      #conditional Forwarders

          help Add-DnsServerConditionalForwarderZone -Full
          help Add-DnsServerConditionalForwarderZone -Examples
          Get-DnsServerZone -ComputerName DC1 | where 'ZoneType' -eq 'forwarder'

          #Add non-AD integrated conditional forwarder
            Add-DnsServerConditionalForwarderZone `
            -Name "appdevwb1.uk"`
            -MasterServers 192.168.95.40 `
            -ComputerName DC1

          #Add AD integrated conditional forwarder
            Add-DnsServerConditionalForwarderZone `
            -Name "appdevwb2.uk" -ReplicationScope "Forest" `
            -MasterServers 192.168.95.40 `
            -ComputerName DC1

  #endregion MasryUK2:forwaders

  #region MasryUK3:DNS Zones

    #Query DNS Zones
        Get-DnsServerZone -ComputerName dc1

        Get-DnsServerZone `
            -Name masry.uk `
            -ComputerName DC1.masry.uk | fl

    #Create Reverse Lookup for 192.168.95.0
        Add-DnsServerPrimaryZone `
            -ComputerName DC1 `
            -NetworkID "192.168.95.0/24" `
            -ReplicationScope "Forest" -Verbose

    #Create File-Based Zone on Server1 for appdevwb.uk
        Add-DnsServerPrimaryZone `
            -ComputerName Server1.masry.uk `
            -ZoneName appdevwb.uk `
            -ZoneFile 'appdevwb.uk.dns' -Verbose

        get-childitem -Path \\server1\c$\windows\system32\dns #CheckPath to verify file

        Get-DnsServerZone -ComputerName server1
    #Create Secondary for appdevwb.uk on DC1
        Set-DnsServerPrimaryZone `
            -Name appdevwb.uk `
            -ComputerName Server1.masry.uk `
            -SecondaryServers 192.168.95.20 `
            -SecureSecondaries TransferToSecureServers

        Add-DnsServerSecondaryZone `
            -Name appdevwb.uk `
            -ComputerName DC1.masry.uk `
            -MasterServers 192.168.95.40 `
            -ZoneFile 'appdevwb.uk.dns'

        Start-DnsServerZoneTransfer `
            -ComputerName DC1.masry.uk `
            -ZoneName appdevwb.uk `
            -FullTransfer

		Get-DnsServerZone -Name appdevwb.uk -ComputerName DC1.masry.uk

    #Convert Zone to AD-Integrated
        Add-DnsServerPrimaryZone `
            -ComputerName DC1.masry.uk `
            -ZoneName moarcoffee.uk `
            -ZoneFile 'moarcoffee.uk.dns'

        ConvertTo-DnsServerPrimaryZone `
            -ComputerName DC1 `
            -Name moarcoffee.uk `
            -ReplicationScope Domain `
            -PassThru `
            -Verbose `
            -Force
    #Remove Moarcoffee.uk zone
        Remove-DnsServerZone `
            -Name 'moarcoffee.uk' `
            -ComputerName DC1 -Verbose

        Get-DnsServerZone -ComputerName DC1
  #endregion MasryUK3:DNS Zones

  #region MasryUK4:Records

      #Viewing Records
        #All
        Get-DnsServerResourceRecord `
            -ZoneName masry.uk `
            -ComputerName DC1

        #By Type
        Get-DnsServerResourceRecord `
            -ZoneName masry.uk `
            -Name DC1 `
            -RRType A `
            -ComputerName DC1 | fl

      #Create Records
        #A
        Add-DnsServerResourceRecordA `
            -ZoneName masry.uk `
            -Name Server5 `
            -IPv4Address 192.168.95.60 `
            -CreatePtr `
            -ComputerName DC1 `
            -Verbose
        #Cname
        Add-DnsServerResourceRecordCName `
            -ZoneName masry.uk `
            -HostNameAlias server5.masry.uk `
            -Name Mail `
            -ComputerName dc1 `
            -Verbose

        Resolve-DnsName -Name mail.masry.uk -Server DC1

        #MX
        Add-DnsServerResourceRecordMX `
            -Zonename masry.uk `
            -Name . `
            -MailExchange mail.masry.uk `
            -Preference 5 `
            -ComputerName DC1 `
            -Verbose

        Get-DnsServerResourceRecord -ZoneName masry.uk -ComputerName DC1

  #endregion MasryUK4:Records
