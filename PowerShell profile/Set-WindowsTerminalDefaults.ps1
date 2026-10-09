#Requires -Version 7.0
# Робить PowerShell 7 профілем за замовчуванням у Windows Terminal і ставить Nerd Font для oh-my-posh.
# Запускається саме під pwsh 7: ConvertFrom-Json у 5.1 не читає коментарі в settings.json.

$pwshGuid     = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'   # динамічний профіль «PowerShell» (Windows.Terminal.PowershellCore)
$fontFace     = 'MesloLGM Nerd Font'
$settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

if (-not (Test-Path (Split-Path (Split-Path $settingsPath)))) {
    Write-Host -ForegroundColor Yellow "Windows Terminal not found - default profile not changed"
    return
}

if (Test-Path $settingsPath) {
    Copy-Item $settingsPath "$settingsPath.bak" -Force
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
}
else {
    # Terminal ще не запускався: мінімальний файл, решту Terminal допише сам при першому старті
    New-Item -ItemType Directory -Path (Split-Path $settingsPath) -Force | Out-Null
    $settings = @{}
}

if (-not $settings.profiles)          { $settings.profiles = @{} }
if (-not $settings.profiles.defaults) { $settings.profiles.defaults = @{} }
if (-not $settings.profiles.defaults.font) { $settings.profiles.defaults.font = @{} }

# Якщо профіль pwsh уже згенеровано — беремо його реальний GUID
$existing = $settings.profiles.list | Where-Object { $_.source -eq 'Windows.Terminal.PowershellCore' } | Select-Object -First 1
if ($existing) { $pwshGuid = $existing.guid }

$settings.defaultProfile = $pwshGuid
$settings.profiles.defaults.font.face = $fontFace

$settings | ConvertTo-Json -Depth 32 | Set-Content -Path $settingsPath -Encoding utf8NoBOM
Write-Host -ForegroundColor DarkMagenta "Windows Terminal: default profile = PowerShell 7, font = $fontFace"
