function Get-PSUAPIToken {
    param(
        
        [SupportsWildcards()]
        [string]
        $Name = '*',

        [switch]
        $AuthorizationHeader

    )
    if ( Test-Path "$env:APPDATA\code\User\settings.json" ) {

        $Tokens = (Get-Content "$env:APPDATA\code\User\settings.json" | ConvertFrom-Json).'powerShellUniversal.connections' | Where-Object Name -like $Name

        if ( $AuthorizationHeader ) {
            if ( $Tokens.Count -eq 1 ) {
                @{ authorization = "bearer $($Tokens.appToken)" }
            } else {
                Write-Warning ( 'There were {0} tokens returned. Result must contain a single token.' -f $Tokens.Count )
            }
        } else {
            $Tokens
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

Register-ArgumentCompleter -ParameterName ComputerName -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
    if ( $CommandName -eq 'Connect-VIServer' ) {
        'ncsa.vcenter.methode.global', 'emea.vcenter.methode.global', 'apac.vcenter.methode.global', 'pcp-vcenter1.procoplast.be' | Where-Object { $_ -match "${WordToComplete}*" }
    } else {
        Invoke-BIDatabaseQuery -Query 'SELECT LOWER(`DNSHostName`) AS `Option` FROM `ad_Objects` WHERE `ObjectClass`="Computer" AND `Deleted`=0 AND `OperatingSystem` LIKE "%Server%" AND `DNSHostName` IS NOT NULL AND `DNSHostName` LIKE @WordToComplete' -Parameters @{
            WordToComplete = $WordToComplete.Replace('?', '_').Replace('*', '%').TrimEnd('%') + '%'
        } | Select-Object -Expand Option
    }
}

Register-ArgumentCompleter -ParameterName Server -ScriptBlock {
    param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
    if ( $CommandName -eq 'Connect-VIServer' ) {
        'ncsa.vcenter.methode.global', 'emea.vcenter.methode.global', 'apac.vcenter.methode.global', 'pcp-vcenter1.procoplast.be' | Where-Object { $_ -match "${WordToComplete}*" }
    } else {
        Invoke-BIDatabaseQuery -Query 'SELECT LOWER(`DNSHostName`) AS `Option` FROM `ad_Objects` WHERE `ObjectClass`="Computer" AND `Deleted`=0 AND `OperatingSystem` LIKE "%Server%" AND `DNSHostName` IS NOT NULL AND `DNSHostName` LIKE @WordToComplete' -Parameters @{
            WordToComplete = $WordToComplete.Replace('?', '_').Replace('*', '%').TrimEnd('%') + '%'
        } | Select-Object -Expand Option
    }
}

New-Alias -Name npp -Value 'C:\Program Files\Notepad++\notepad++.exe'

Import-Module BitwardenWrapper -ErrorAction SilentlyContinue