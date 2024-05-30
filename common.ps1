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
$__ApiAutoComplete = {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
    $PSBoundParameters.Remove('CommandAst') > $null
    $PSBoundParameters.Remove('FakeBoundParameters') > $null
    $PSUServer = Get-PSUAPIToken | Select-Object -First 1
    [string[]] $Response = Invoke-RestMethod -Uri ( '{0}/auto-complete' -f $PSUServer.url ) -Headers @{ authorization = "bearer $($PSUServer.appToken)" } -Body ( ConvertTo-Json -InputObject $PSBoundParameters -Compress ) -ContentType 'application/json'
    return $Response
}
Register-ArgumentCompleter -ParameterName ComputerName -ScriptBlock $__ApiAutoComplete
Register-ArgumentCompleter -ParameterName Server -ScriptBlock $__ApiAutoComplete
Register-ArgumentCompleter -ParameterName Destination -ScriptBlock $__ApiAutoComplete
Register-ArgumentCompleter -ParameterName Identity -ScriptBlock $__ApiAutoComplete
Register-ArgumentCompleter -ParameterName SearchBase -ScriptBlock $__ApiAutoComplete
Register-ArgumentCompleter -ParameterName TargetPath -ScriptBlock $__ApiAutoComplete

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