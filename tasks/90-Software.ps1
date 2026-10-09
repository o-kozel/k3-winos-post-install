#Requires -Version 5.1
# Встановлення програм: бутстрап Chocolatey/winget і пакети з data\packages.psd1.
# Замінює колишній Software_installation.ps1 (Етап 3-4 RP); PowerShell 7 та оболонка - у 95-Shell.ps1,
# автозапуск SuperF4 - у 92-Autostart.ps1.
[CmdletBinding(SupportsShouldProcess)]
param()

function Update-ProcessPath {
    # Поточний процес не бачить змін PATH, зроблених інсталятором. Нові каталоги дописуємо В КІНЕЦЬ:
    # наявний порядок пошуку команд не змінюється
    $env:Path = (@($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) |
        Where-Object { $_ }) -join ';'
}

# --- Chocolatey: ставимо лише якщо його ще немає (повторний прогін не має щоразу качати інсталятор)
if (Get-Command choco -CommandType Application -ErrorAction Ignore) {
    Write-Step 'Chocolatey вже встановлено' -Level Skip
}
elseif ($PSCmdlet.ShouldProcess('Chocolatey', 'Встановити')) {
    Write-Step 'Встановлення Chocolatey'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Update-ProcessPath
}

# --- winget: на свіжій системі App Installer може бути ще не зареєстрований для користувача
if (Get-Command winget -CommandType Application -ErrorAction Ignore) {
    Write-Step 'winget вже доступний' -Level Skip
}
elseif ($PSCmdlet.ShouldProcess('winget (App Installer)', 'Зареєструвати')) {
    Write-Step 'Реєстрація winget (App Installer)'
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    Update-ProcessPath
}

# --- Пакети з data\packages.psd1 (Id, Source, Params). Збій одного пакета не зупиняє решту,
# а наприкінці друкується підсумок "що саме не встановилось".
$packages = @((Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot '..\data\packages.psd1')).Packages)
Write-Step "Пакети: $($packages.Count) записів з data\packages.psd1"

$failedPackages = New-Object System.Collections.Generic.List[string]
foreach ($package in $packages) {
    $source = if ($package.Source) { $package.Source } else { 'choco' }
    Write-Step "Пакет: $($package.Id) [$source]"
    $installError = $null
    # -WhatIf явно: функції модуля не успадковують його надійно; SilentlyContinue + ErrorVariable, щоб рахувати збої самим
    Install-AppPackage @package -WhatIf:$WhatIfPreference -ErrorAction SilentlyContinue -ErrorVariable installError
    if ($installError) {
        $failedPackages.Add($package.Id)
        Write-Step "Не встановлено: $($package.Id)" -Level Warn
    }
}

if ($failedPackages.Count -gt 0) {
    Write-Step "Не встановлено пакетів: $($failedPackages.Count) - $($failedPackages -join ', ')" -Level Warn
    Set-TaskStatus -Status Warn -Message "не встановлено: $($failedPackages -join ', ')"
}
else {
    Write-Step "Усі пакети ($($packages.Count)) оброблено"
}
