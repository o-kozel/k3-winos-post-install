#Requires -Version 5.1
# Видалення AppX-застосунків за списком data\appx-remove.psd1 (Етап 3 RP).
# Windows PowerShell 5.1: модуль Appx у pwsh 7 працює лише через шар сумісності.
[CmdletBinding(SupportsShouldProcess)]
param()

$dataFile = Join-Path $PSScriptRoot '..\data\appx-remove.psd1'
$patterns = @((Import-PowerShellDataFile -Path $dataFile).Appx) | Sort-Object -Unique
Write-Step "AppX: $($patterns.Count) шаблонів з data\appx-remove.psd1"

# Get-AppxProvisionedPackage і Get-AppxPackage щоразу перелічують УСІ пакети системи (кілька секунд).
# Тому один виклик на весь список, а далі фільтр у пам'яті: замість хвилин - секунди.
$installed   = @(Get-AppxPackage -AllUsers)
$provisioned = @(Get-AppxProvisionedPackage -Online)

$handled = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$failed  = New-Object System.Collections.Generic.List[string]
$removed = 0

foreach ($pattern in $patterns) {
    # Образ системи ПЕРШИМ: без цього застосунок повернеться для нових користувачів. Якщо спершу зробити
    # Remove-AppxPackage -AllUsers, запис в образі лишається без файлів, і Remove-AppxProvisionedPackage
    # падає з "The system cannot find the path specified" (так було для Xbox/Zune/WebExperience).
    foreach ($package in @($provisioned | Where-Object { $_.DisplayName -like $pattern })) {
        if (-not $handled.Add($package.PackageName)) { continue }
        if (-not $PSCmdlet.ShouldProcess($package.PackageName, 'Remove-AppxProvisionedPackage')) { continue }
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop | Out-Null
            Write-Step "Видалено з образу: $($package.DisplayName)"
            $removed++
        }
        catch {
            $failed.Add($package.DisplayName)
            Write-Step "Не вдалося видалити з образу $($package.DisplayName): $($_.Exception.Message)" -Level Warn
        }
    }

    foreach ($package in @($installed | Where-Object { $_.Name -like $pattern })) {
        if (-not $handled.Add($package.PackageFullName)) { continue }      # вже оброблено іншим шаблоном
        if (-not $PSCmdlet.ShouldProcess($package.PackageFullName, 'Remove-AppxPackage -AllUsers')) { continue }
        try {
            Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
            Write-Step "Видалено: $($package.Name)"
            $removed++
        }
        catch {
            $failed.Add($package.Name)
            Write-Step "Не вдалося видалити $($package.Name): $($_.Exception.Message)" -Level Warn
        }
    }
}

Write-Step "AppX: видалено $removed, збоїв $($failed.Count)"
if ($failed.Count -gt 0) {
    Set-TaskStatus -Status Warn -Message "не вдалося видалити: $(($failed | Sort-Object -Unique) -join ', ')"
}
