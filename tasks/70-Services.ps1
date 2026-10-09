#Requires -Version 5.1
# Тип запуску служб за списком data\services.psd1 (Етап 3 RP).
# Раніше це був масив $services і цикл усередині Configuration.ps1.
[CmdletBinding(SupportsShouldProcess)]
param()

$dataFile = Join-Path $PSScriptRoot '..\data\services.psd1'
$services = @((Import-PowerShellDataFile -Path $dataFile).Services)
Write-Step "Служби: $($services.Count) записів з data\services.psd1"

$failed = New-Object System.Collections.Generic.List[string]
foreach ($service in $services) {
    # Збій однієї служби (захищена, відмовлено в доступі) не повинен зупиняти решту.
    # -WhatIf передається явно: функції модуля не успадковують його надійно від скрипта.
    try {
        Set-ServiceStartup -Name $service.Name -StartupType $service.Startup -WhatIf:$WhatIfPreference -ErrorAction Stop
    }
    catch {
        $failed.Add($service.Name)
        Write-Step "Не вдалося змінити $($service.Name): $($_.Exception.Message)" -Level Warn
    }
}

if ($failed.Count -gt 0) {
    Set-TaskStatus -Status Warn -Message "не вдалося змінити служби: $($failed -join ', ')"
}
