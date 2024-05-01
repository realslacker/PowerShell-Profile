using namespace System.Net
using namespace System.Security.Principal

$InformationPreference = 'Continue'

# add script directories to path
$env:Path = $env:Path, "$PSScriptRoot\Scripts", "$env:USERPROFILE\Repos\SharedScripts\Prod", "$env:USERPROFILE\Repos\SharedScripts\Test", "$env:USERPROFILE\Repos\SharedScripts\Dev" -join ';'

# Bump up the max TLS profile 
[ServicePointManager]::SecurityProtocol = [SecurityProtocolType].GetEnumValues().Where({ $_ -ge [SecurityProtocolType]::Tls12 })

# ignore invalid certs for now to allow any SMTP server
Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


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
    oh-my-posh init powershell --config "$PSScriptRoot\slacker.omp.json" | Invoke-Expression
    function Set-PoshEnv {
        $env:BW_STATUS = ('locked', 'unlocked')[$(Test-Path (Join-Path $env:BITWARDENCLI_APPDATA_DIR '.unlocked'))]
    }
    New-Alias -Name Set-PoshContext -Value Set-PoshEnv
} catch {}
