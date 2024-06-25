#Requires -Version 5.1

if ( -not( Get-Module -Name Fonts -ListAvailable ) ) {
    Install-Module -Name Fonts -Repository PSGallery -Force -Confirm:$false
}

Import-Module -Name Fonts

# download and install font files
$AnonymiceProUri = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/AnonymousPro.zip'
$DownloadPath = "$env:TEMP\AnonymousPro.zip"
$ExpandedPath = "$env:TEMP\AnonymousPro"
Invoke-WebRequest -UseBasicParsing -Uri $AnonymiceProUri -OutFile $DownloadPath
Expand-Archive -Path $DownloadPath -DestinationPath $ExpandedPath -Force
Get-ChildItem -Path $ExpandedPath -Filter *.ttf | Install-Font -Scope CurrentUser -Force

# set default console font
# Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont' -Name '000' -Value 'AnonymicePro Nerd Font Mono'

# set font for Windows Terminal
$WindowsTerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if ( Test-Path -Path $WindowsTerminalSettingsPath ) {
    $ConvertFromJsonSplat = @{}
    $ConvertToJsonSplat = @{}
    if ( $IsCoreCLR ) {
        $ConvertFromJsonSplat.AsHashTable = $true
        $ConvertFromJsonSplat.Depth = 99
        $ConvertToJsonSplat.Depth = 99
    }
    $Settings = Get-Content -Path $WindowsTerminalSettingsPath -Raw | ConvertFrom-Json @ConvertFromJsonSplat
    if ( $Settings['profiles'] -isnot [hashtable] ) { $Settings['profiles'] = @{} }
    if ( $Settings['profiles']['defaults'] -isnot [hashtable] ) { $Settings['profiles']['defaults'] = @{} }
    if ( $Settings['profiles']['defaults']['font'] -isnot [hashtable] ) { $Settings['profiles']['defaults']['font'] = @{} }
    $Settings['profiles']['defaults']['font']['face'] = 'AnonymicePro Nerd Font Mono'
    $Settings['profiles']['defaults']['font']['size'] = 11
    $Settings['profiles']['defaults']['font']['weight'] = 'normal'
    $Settings | ConvertTo-Json @ConvertToJsonSplat | Set-Content -Path $WindowsTerminalSettingsPath -Encoding utf8
}