function Set-ServiceStartup {
    <#
    .SYNOPSIS
        Задає тип запуску служби; відсутню службу пропускає, вже встановлений стан не чіпає.
    .DESCRIPTION
        Цільовий стан передається параметром, а не зашивається в цикл: для частини служб
        задум - Disabled, для решти - Manual. Коли тип захардкоджено, виразити це
        неможливо (так з'явився конфлікт щодо DiagTrack).
        Відсутня служба (HP-специфічні, CaptureService_<суфікс> тощо) - це Skip, а не тиха
        помилка: видно, що її не знайдено, а не що її налаштовано.
        Для Disabled запущена служба ще й зупиняється (Stop-Service).
    .EXAMPLE
        Set-ServiceStartup -Name MapsBroker -StartupType Manual
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Name,
        [ValidateSet('Automatic','Manual','Disabled')][string] $StartupType = 'Manual'
    )

    try {
        # Ignore, а не SilentlyContinue: той усе одно кладе помилку в $Error, і відсутня служба виглядала б як збій
        $service = Get-Service -Name $Name -ErrorAction Ignore
        if (-not $service) {
            Write-Step "Служби '$Name' немає в системі" -Level Skip
            return
        }

        foreach ($item in @($service)) {
            if ($item.StartType -eq $StartupType) {
                Write-Step "$($item.Name) вже $StartupType" -Level Skip
            }
            elseif ($PSCmdlet.ShouldProcess($item.Name, "StartupType -> $StartupType")) {
                Set-Service -Name $item.Name -StartupType $StartupType -ErrorAction Stop
                Write-Step "$($item.Name) : $($item.StartType) -> $StartupType"
            }

            # Disabled означає "не має працювати": без зупинки запущена служба (напр. DiagTrack)
            # жила б до перезавантаження. Раніше це робили окремі блоки Stop-Service в Configuration.ps1.
            if ($StartupType -eq 'Disabled' -and $item.Status -eq 'Running') {
                if ($PSCmdlet.ShouldProcess($item.Name, 'Зупинити службу')) {
                    Stop-Service -Name $item.Name -WarningAction SilentlyContinue -ErrorAction Stop
                    Write-Step "$($item.Name) зупинено"
                }
            }
        }
    }
    catch {
        Write-Error -Message "Не вдалося змінити службу ${Name}: $($_.Exception.Message)" -Exception $_.Exception -TargetObject $Name
    }
}
