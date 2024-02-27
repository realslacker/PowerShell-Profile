function Connect-OpenVPNProfile {
    param(
        [Parameter(Mandatory, Position=1)]
        [ArgumentCompleter({
            param($i1,$i2,$WordToComplete)
            Get-ChildItem -Path '~\OpenVPN' -File -Filter '*.ovpn' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like "$($WordToComplete.Trim('''"'))*" } | ForEach-Object { "'$_'" }
        })]
        [string]
        $Profile
    )
    & "${env:ProgramFiles}\OpenVPN\bin\openvpn-gui.exe" --command connect $Profile
}

function Disconnect-OpenVPNProfile {
    param(
        [Parameter(ParameterSetName='Single', Mandatory, Position=1)]
        [ArgumentCompleter({
            param($i1,$i2,$WordToComplete)
            Get-ChildItem -Path '~\OpenVPN' -File -Filter '*.ovpn' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like "$($WordToComplete.Trim('''"'))*" } | ForEach-Object { "'$_'" }
        })]
        [string]
        $Profile,

        [Parameter(ParameterSetName='All', Mandatory)]
        [switch]
        $All
    )
    if ( $All ) {
        & "${env:ProgramFiles}\OpenVPN\bin\openvpn-gui.exe" --command disconnect_all
    } else {
        & "${env:ProgramFiles}\OpenVPN\bin\openvpn-gui.exe" --command disconnect $Profile
    }
}

function Restart-OpenVPNProfile {
    param(
        [Parameter(Mandatory, Position=1)]
        [ArgumentCompleter({
            param($i1,$i2,$WordToComplete)
            Get-ChildItem -Path '~\OpenVPN' -File -Filter '*.ovpn' -Recurse | Select-Object -ExpandProperty Name | Where-Object { $_ -like "$($WordToComplete.Trim('''"'))*" } | ForEach-Object { "'$_'" }
        })]
        [string]
        $Profile
    )
    & "${env:ProgramFiles}\OpenVPN\bin\openvpn-gui.exe" --command reconnect $Profile
}


function Get-PSUAPIToken {
    [CmdletBinding( DefaultParameterSetName='Object' )]
    [OutputType( [object], ParameterSetName='Object' )]
    [OutputType( [securestring], ParameterSetName='Token' )]
    [OutputType( [hashtable], ParameterSetName='AuthHeader' )]
    param(
        
        [Parameter( Position=0 )]
        [SupportsWildcards()]
        [string]
        $Name = '*',

        [Parameter( Mandatory, ParameterSetName='Token' )]
        [switch]
        $Token,

        [Parameter( Mandatory, ParameterSetName='AuthHeader' )]
        [switch]
        $AuthorizationHeader

    )
    if ( Test-Path "$env:APPDATA\code\User\settings.json" ) {

        [object[]] $Tokens = (Get-Content "$env:APPDATA\code\User\settings.json" | ConvertFrom-Json).'powerShellUniversal.connections' | Where-Object Name -like $Name

        if ( $PSCmdlet.ParameterSetName -ne 'Object' -and $Tokens.Count -gt 1 ) {
            Write-Warning ( 'There were {0} tokens returned. Result must contain a single token.' -f $Tokens.Count )
            return
        }

        switch ( $PSCmdlet.ParameterSetName ) {
            'Token' {
                return ConvertTo-SecureString -String $Tokens.appToken -AsPlainText -Force
            }
            'AuthHeader' {
                return @{ authorization = "bearer $($Tokens.appToken)" }
            }
            default {
                return $Tokens
            }
        }
    
    }
}

function Set-ConsoleTitle {
    param( [string] $Title )
    if ( [string]::IsNullOrEmpty($Title) ) {
        Clear-ConsoleTitle
    } else {
        $env:MyConsoleTitle = $Title
    }
}

function Clear-ConsoleTitle {
    Remove-Item Env:\MyConsoleTitle
}

# VMware Argument Completers
Register-ArgumentCompleter -CommandName New-VM, Set-VM -ParameterName GuestId -ScriptBlock { param( $dc, $dc2, $WordToComplete ) [VMware.Vim.VirtualMachineGuestOsIdentifier].GetEnumNames().Where({ $_ -like "$WordToComplete*" }) }

# AD Argument Completer
Register-ArgumentCompleter -ParameterName ComputerName -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
    if ( $CommandName -eq 'Connect-VIServer' ) {
        'ncsa.vcenter.methode.global', 'emea.vcenter.methode.global', 'apac.vcenter.methode.global', 'pcp-vcenter1.procoplast.be' | Where-Object { $_ -match "${WordToComplete}*" }
    } else {
        Invoke-BIDatabaseQuery -Query 'SELECT LOWER(`DNSHostName`) AS `Option` FROM `ad_Objects` WHERE `ObjectClass`="Computer" AND `Deleted`=0 AND `OperatingSystem` LIKE "%Server%" AND `DNSHostName` IS NOT NULL AND `DNSHostName` LIKE CONCAT(TRIM(TRAILING "%" FROM REPLACE(REPLACE(TRIM(''"'' FROM TRIM("''" FROM @WordToComplete)),"?","_"),"*","%")),"%")' -Parameters @{
            WordToComplete = $WordToComplete
        } | Select-Object -Expand Option
    }
}

Register-ArgumentCompleter -ParameterName Server -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
    if ( $CommandName -eq 'Connect-VIServer' ) {
        'ncsa.vcenter.methode.global', 'emea.vcenter.methode.global', 'apac.vcenter.methode.global', 'pcp-vcenter1.procoplast.be' | Where-Object { $_ -match "${WordToComplete}*" }
    } else {
        Invoke-BIDatabaseQuery -Query 'SELECT LOWER(`DNSHostName`) AS `Option` FROM `ad_Objects` WHERE `ObjectClass`="Computer" AND `Deleted`=0 AND `OperatingSystem` LIKE "%Server%" AND `DNSHostName` IS NOT NULL AND `DNSHostName` LIKE CONCAT(TRIM(TRAILING "%" FROM REPLACE(REPLACE(TRIM(''"'' FROM TRIM("''" FROM @WordToComplete)),"?","_"),"*","%")),"%")' -Parameters @{
            WordToComplete = $WordToComplete
        } | Select-Object -Expand Option
    }
}

Register-ArgumentCompleter -ParameterName Identity -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $Parameters )
    $Parameters.CommandName = $CommandName
    $Query = 'SELECT TRIM(TRAILING "$" FROM SAMAccountName) AS SAMAccountName FROM infra.ad_Objects JOIN infra.ad_DomainControllers ON ad_DomainControllers.Domain = ad_Objects.Domain WHERE Deleted = 0 AND SAMAccountName IS NOT NULL AND (((@CommandName LIKE "%ADUser%" OR @CommandName LIKE "%ADAccount%") AND ObjectClass = "User") OR ((@CommandName LIKE "%ADComputer%" OR @CommandName LIKE "%ADAccount%") AND ObjectClass = "Computer") OR (@CommandName LIKE "%ADGroup%" AND ObjectClass = "Group")) AND SAMAccountName LIKE CONCAT(TRIM(TRAILING "%" FROM REPLACE(REPLACE(TRIM(''"'' FROM TRIM("''" FROM @Identity)),"?","_"),"*","%")),"%") AND (@Server IS NULL OR @Server = "" OR HostName = @Server) GROUP BY SAMAccountName'
    [object[]] $Results = Invoke-BIDatabaseQuery -Query $Query -Parameters $Parameters
    $Results.SAMAccountName | ForEach-Object { if ( $_.IndexOf(' ') -ne -1 ) { "'$_'" } else { $_ } }
}

Register-ArgumentCompleter -ParameterName SearchBase -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $Parameters )
    $Parameters.CommandName = $CommandName
    $Query = 'SELECT DistinguishedName FROM infra.ad_Objects JOIN infra.ad_DomainControllers ON ad_DomainControllers.Domain = ad_Objects.Domain WHERE ObjectClass = "OrganizationalUnit" AND Deleted = 0 AND DistinguishedName IS NOT NULL AND DistinguishedName LIKE CONCAT(TRIM(TRAILING "%" FROM REPLACE(REPLACE(TRIM(''"'' FROM TRIM("''" FROM @SearchBase)),"?","_"),"*","%")),"%") AND ( IFNULL(@Server, "") = "" OR HostName = @Server ) GROUP BY DistinguishedName ORDER BY DistinguishedName'
    [object[]] $Results = Invoke-BIDatabaseQuery -Query $Query -Parameters $Parameters
    $Results.DistinguishedName | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object { "'$_'" }
}

Register-ArgumentCompleter -ParameterName TargetPath -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $Parameters )
    $Parameters.CommandName = $CommandName
    $Query = 'SELECT DistinguishedName FROM infra.ad_Objects JOIN infra.ad_DomainControllers ON ad_DomainControllers.Domain = ad_Objects.Domain WHERE ObjectClass = "OrganizationalUnit" AND Deleted = 0 AND DistinguishedName IS NOT NULL AND DistinguishedName LIKE CONCAT(TRIM(TRAILING "%" FROM REPLACE(REPLACE(TRIM(''"'' FROM TRIM("''" FROM @SearchBase)),"?","_"),"*","%")),"%") AND ( IFNULL(@Server, "") = "" OR HostName = @Server ) GROUP BY DistinguishedName ORDER BY DistinguishedName'
    [object[]] $Results = Invoke-BIDatabaseQuery -Query $Query -Parameters $Parameters
    $Results.DistinguishedName | Where-Object { -not [string]::IsNullOrEmpty($_) } | ForEach-Object { "'$_'" }
}

function Wait-Thing {

    [CmdletBinding( DefaultParameterSetName = 'Default' )]
    param(
        
        [Parameter( Position = 1 )]
        [scriptblock]
        $Thing = {$true},

        [Parameter( ParameterSetName = 'Seconds' )]
        [ValidateRange(1,[uint32]::MaxValue)]
        [uint32]
        $RetrySeconds,

        [Parameter( ParameterSetName = 'Milliseconds' )]
        [ValidateRange(1,[uint32]::MaxValue)]
        [uint32]
        $RetryMilliseconds,

        [switch]
        $PlayMusic

    )

    # default is 30 seconds
    $WaitTimespan = [timespan]::FromSeconds(30)

    if ( $RetryMilliseconds ) {
        $WaitTimespan = [timespan]::FromMilliseconds($RetryMilliseconds)
    }

    if ( $RetrySeconds ) { 
        $WaitTimespan = [timespan]::FromSeconds($RetrySeconds)
    }

    Write-Verbose ( 'Waiting {0} milliseconds between thing checks.' -f $WaitTimespan.TotalMilliseconds )

    while ( $( $ThingResult = $Thing.Invoke() -as [bool]; $ThingResult -ne $true ) ) {
        Write-Verbose 'Waiting on thing to finish...'
        Start-Sleep -Milliseconds $WaitTimespan.TotalMilliseconds
    }

    if ( $PlayMusic ) {
        if ( $Sound = Get-Item -Path "$PSScriptRoot\ThingDoneSound.wav" -ErrorAction SilentlyContinue ) {
            [System.Media.SoundPlayer]::new($Sound.FullName).Play()
        } else {
            Write-Warning ( 'Missing Sound! Please create ''{0}''.' -f "$PSScriptRoot\ThingDoneSound.wav" )
        }
    }

}

New-Alias -Name npp -Value 'C:\Program Files\Notepad++\notepad++.exe'

Import-Module BitwardenWrapper -ErrorAction SilentlyContinue