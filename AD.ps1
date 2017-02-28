#Administering Active Directory

#region MasryUK - Installing Active Directory
    #Install AD
    Install-WindowsFeature -ComputerName Server1 -Name AD-Domain-Services
    Enter-PSSession -ComputerName Server1
    Get-Command -Module ADDSDeployment
    Install-ADDSDomainController `
        -Credential (Get-Credential) `
        -InstallDns:$True `
        -DomainName 'masry.uk' `
        -DatabasePath 'C:\Windows\NTDS' `
        -LogPath 'C:\Windows\NTDS' `
        -SysvolPath 'C:\Windows\SYSVOL' `
        -NoGlobalCatalog:$false `
        -SiteName 'Default-First-Site-Name' `
        -NoRebootOnCompletion:$False `
        -Force
    Exit-PSSession

    #Verify DCs in Domain
    Get-DnsServerResourceRecord -ComputerName Server1 -ZoneName masry.uk -RRType Ns
    Get-ADDomainController -Filter * -Server Server1 |
        ft Name,ComputerObjectDN,IsGlobalCatalog
#endregion MasryUK1

#region MasryUK2 - Gathering information in Active Directory
    #View AD Hieararchy
    get-adobject -Filter * |ft name,objectclass

    Get-ADObject -Filter {ObjectClass -eq "OrganizationalUnit"}

    Get-ADObject -SearchBase 'OU=CompanyOU,DC=masry,DC=uk' `
        -Filter {ObjectClass -eq "OrganizationalUnit"}|
        FT Name,DistinguishedName -AutoSize

    #Find Objects
    get-adobject -Filter * | gm

    get-adobject -Filter * -Properties * | gm # -properties * brings extended Properties

    Get-ADObject -Filter {(name -like '*moneim*') -and (ObjectClass -eq 'user')} -Properties *|
        ft Name,DistinguishedName

    #Finding specific user objects
    Get-ADObject `
        -Identity 'CN=Sherif Moneim-Admin,OU=Users,OU=London,OU=CompanyOU,DC=masry,DC=uk' `
        -Properties * | FL

    get-adobject -Filter {SamAccountName -eq 'smadmin'} -Properties * | FL

    #Add OU for Users and Computer under Austin
    New-ADOrganizationalUnit `
        -Name Users `
        -Path 'OU=Austin,OU=CompanyOU,DC=Masry,DC=uk' `
        -Verbose

    New-ADOrganizationalUnit `
        -Name Computers `
        -Path 'OU=Austin,OU=CompanyOU,DC=Masry,DC=uk' `
        -Verbose

    Get-ADObject -SearchBase 'OU=CompanyOU,DC=Masry,DC=uk' `
        -Filter {ObjectClass -eq "OrganizationalUnit"}
#endregion MasryUK2

#region MasryUK3 - users

#Get User Information
get-aduser -Filter * -Properties *| gm

get-ADUser -Filter * -Properties *| fl Name,DistinguishedName,City

Get-ADUser -SearchBase 'OU=CompanyOU,DC=Masry,DC=uk'|
     ft Name,DistinguishedName -AutoSize

Get-ADUser -Filter {Name -like '*moneim*'}  -Properties * |
 ft Name,DistinguishedName -AutoSize

Get-aduser -Identity 'smadmin' -Properties *

#Find all users in London and in IT department; Export to CSV file

get-aduser -Filter {(City -eq 'London') -and (department -eq 'IT')} -Properties *|
    select-object Name,City,Enabled,EmailAddress|
    export-csv -Path C:\masryuk\MasryUK-M5\MadUsers.csv

notepad C:\masryuk\MasryUK-M5\MadUsers.csv

#Create a New user with PowerShell
    $SetPass = read-host -assecurestring
    New-ADUser `
        -Server DC1 `
        -Path 'OU=Users,OU=London,OU=CompanyOU,DC=Masry,DC=uk' `
        -department IT `
        -SamAccountName TimJ `
        -Name Timj `
        -Surname Jones `
        -GivenName Tim `
        -UserPrincipalName Timj@masry.uk `
        -City London `
        -AccountPassword $setpass `
        -ChangePasswordAtLogon $True `
        -Enabled $False -Verbose

    Get-ADUser -Identity 'Timj'

#Modify single user object
Set-ADuser -Identity 'timJ' -Enabled $True -Description 'Tim is a hosty User' -Title 'MasryUK User'
Get-ADUser -Identity 'Timj' -Properties *| FL Name,Description,Title,Enabled

#Modify Existing users without state of Wisconsin
Get-ADUser  `
    -filter { ( State -eq $null) } `
    -SearchBase 'OU=CompanyOU,DC=Masry,DC=uk' -SearchScope Subtree|
    ft Name,SamAccountName,City

Get-ADUser  `
    -filter { -not( State -like '*') } `
    -SearchBase 'OU=CompanyOU,DC=Masry,DC=uk' -SearchScope Subtree -Properties *|
    ft Name,SamAccountName,State

Get-ADUser  `
    -filter { -not( City -like '*') } `
    -SearchBase 'OU=CompanyOU,DC=Masry,DC=uk' -SearchScope Subtree|
    Set-ADUser -State 'WI' -Verbose

get-aduser -Filter {State -eq 'WI'} -Properties *|
        ft name,SamAccountName,State

#Find users that are disabled
    get-aduser -Filter {enabled -eq $false} `
        -SearchBase 'OU=Users,OU=London,OU=CompanyOU,DC=Masry,DC=uk'|
        ft Name,SamAccountName,Enabled -AutoSize

    get-aduser -Filter {enabled -eq $false} `
        -SearchBase 'OU=Users,OU=London,OU=CompanyOU,DC=Masry,DC=uk'|
        Set-ADUser -Enabled $true

    get-aduser -Filter * `
        -SearchBase 'OU=Users,OU=London,OU=CompanyOU,DC=Masry,DC=uk'|
        ft Name,SamAccountName,Enabled -AutoSize

#Determine status of LockedOut Account
    Search-ADAccount -LockedOut | select Name

    Unlock-ADAccount -Identity 'smtest'

#Reset Password
    $newPassword = (Read-Host -Prompt "Provide New Password" -AsSecureString)

    Set-ADAccountPassword -Identity smtest -NewPassword $newPassword -Reset

    Set-ADuser -Identity smtest -ChangePasswordAtLogon $True

#endregion MasryUK3

#region MasryUK4 - Computers

#Find all computers in domain
Get-ADComputer -Filter * -Properties * |ft Name,DNSHostName,OperatingSystem

Get-adcomputer -Filter {OperatingSystem -eq 'Windows 10 Enterprise Evaluation'} -Properties *|
    ft Name,DNSHostName,OperatingSystem

#View information for server1
Get-ADComputer -Identity 'Server1' -Properties *

#Modify Description on Computer
Set-ADComputer -Identity 'Server1' -Description 'This is a Server for App/Dev Testing' -PassThru|
    Get-ADComputer -Properties * | ft Name,DNSHostName,Description

#Move computer to OU
Get-ADComputer -Identity Server1 |
    Move-ADObject -TargetPath 'OU=Computers,OU=Austin,OU=CompanyOU,DC=Masry,DC=uk'

Get-ADComputer -Identity Server1 -Properties * | FT Name,DistinguishedName
#endregion MasryUK4

#region MasryUK5 - Groups
#View all Groups
Get-ADGroup -Filter * -Properties *| FT Name,Description -AutoSize -Wrap

#View Specific Group
get-adgroup -Identity 'Domain Users' -Properties *

#create a new group for IT users
New-ADGroup `
    -Name 'IT Users' `
    -GroupCategory Security `
    -GroupScope Global

Set-ADGroup -Identity 'IT Users' -Description 'This is a group for IT Users'

get-adgroup -Identity 'IT Users' -Properties * | fl Name,Description

#View Group Membership of Group
Get-ADGroupMember -Identity 'Domain Users'|ft Name

#Add Users to Group for IT
Get-ADGroupMember -Identity 'IT Users'

Add-ADGroupMember `
    -Identity 'IT Users' `
    -Members (get-aduser -Filter {department -eq 'IT'})

Get-ADGroupMember -Identity 'IT Users'|ft Name

#Remove IT Users Group
Remove-ADGroup -Identity 'IT Users'

#endregion MasryUK5
