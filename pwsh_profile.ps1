#Requires -Version 7.0

using namespace System.Net
using namespace System.Security.Principal

$InformationPreference = 'Continue'

# remove WindowsPowerShell modules, note that you can create a symlink to a specific module if you want it available
# ie: New-Item -ItemType SymbolicLink -Path '~\Documents\PowerShell\Modules\ActiveDirectory' -Target 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\ActiveDirectory'
$env:PSModulePath = $env:PSModulePath.Split(';') -notlike '*\WindowsPowerShell\Modules' -join ';'

# add script directories to path
$env:Path = $env:Path, "$PSScriptRoot\Scripts", "$env:USERPROFILE\Repos\SharedScripts\Prod", "$env:USERPROFILE\Repos\SharedScripts\Test", "$env:USERPROFILE\Repos\SharedScripts\Dev" -join ';'

# Bump up the max TLS profile 
[ServicePointManager]::SecurityProtocol = [SecurityProtocolType].GetEnumValues().Where({ $_ -ge [SecurityProtocolType]::Tls12 })

$env:IsDemo = [int](Test-Path ~\.demo)
# $env:DemoUser is set in PSDefaultParameterValues

function Switch-DemoMode {
    if (Test-Path ~\.demo) {
        Remove-Item ~\.demo -Force
        $env:IsDemo = 0
    } else {
        if ( -not $env:DemoUser ) {
            $env:DemoUser = Read-Host 'Demo User'
        }
        New-Item ~\.demo > $null
        $env:IsDemo = 1
    }
}

try {
	if ( -not( Get-Command oh-my-posh -ErrorAction SilentlyContinue ) ) {
		Write-Host 'Trying to install Oh-My-Posh...'
		Invoke-WebRequest -Uri 'https://ohmyposh.dev/install.ps1' -OutFile "$env:TEMP\Install-OhMyPosh.ps1"
		Unblock-File "$env:TEMP\Install-OhMyPosh.ps1"
		& "$env:TEMP\Install-OhMyPosh.ps1"
		if ( -not( $env:Path.Split(';') -like '*oh-my-posh*' ) ) {
			$env:PATH += ";$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\bin"
		}
	}
    oh-my-posh init pwsh --config (Join-Path $PSScriptRoot 'slacker.omp.json') | Invoke-Expression
    function Set-PoshEnv {
        $env:BW_STATUS = ('locked', 'unlocked')[$(Test-Path (Join-Path $env:BITWARDENCLI_APPDATA_DIR '.unlocked'))]
        if ( ${Global:DefaultVIServers}?.Name.Count ) {
            $env:ConnectedVIServers = 'true'
            for ( $i = 0; $i -lt 10; $i ++ ) {
                if ( $Global:DefaultVIServers[$i] ) {
                    New-Item -Path "Env:\ConnectedVIServer$i" -Value $Global:DefaultVIServers[$i]?.{Name}?.Split('.',2)?[0]?.ToUpper() -Force > $null
                }
            }
        } else {
            $env:ConnectedVIServers = 'false'
            for ( $i = 0; $i -lt 10; $i ++ ) {
                if ( Test-Path "Env:\ConnectedVIServer$i" ) {
                    Remove-Item -Path "Env:\ConnectedVIServer$i" -ErrorAction SilentlyContinue > $null
                }
            }
        }
    }
    New-Alias -Name Set-PoshContext -Value Set-PoshEnv
} catch {}

Set-PSReadLineOption -Colors @{
    Parameter        = $PSStyle.Foreground.BrightCyan
    Operator         = $PSStyle.Foreground.BrightRed
    InlinePrediction = $PSStyle.Foreground.BrightBlack
} -HistorySaveStyle SaveIncrementally -HistoryNoDuplicates -PredictionSource HistoryAndPlugin -BellStyle Visual

Import-Module CompletionPredictor -ErrorAction SilentlyContinue
Import-Module DirectoryPredictor -ErrorAction SilentlyContinue

$PSStyle.Formatting.Warning = $PSStyle.Blink + $PSStyle.Foreground.BrightYellow
$PSStyle.Formatting.Verbose = $PSStyle.Foreground.Cyan
$PSStyle.Formatting.Debug   = $PSStyle.Background.Magenta
