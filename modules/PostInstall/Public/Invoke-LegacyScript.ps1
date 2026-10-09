function Invoke-LegacyScript {
    <#
    .SYNOPSIS
        Запускає старий лінійний скрипт як задачу оркестратора.
    .DESCRIPTION
        ТИМЧАСОВО, на час між Етапом 1 та Етапами 2-3 плану рефакторингу.

        Старі скрипти покладаються на те, що помилка в середині не зупиняє решту.
        Якщо виконувати їх із $ErrorActionPreference = 'Stop', перша ж відсутня
        гілка реєстру обірве скрипт, і решта твіків не застосується — гірше, ніж
        було. Тому тут помилки не зупиняють скрипт, але підраховуються й
        виводяться: задача отримує статус WARN замість мовчазного «успіху».
        Після переходу на Set-RegValue / Invoke-Native (Етап 2) ця обгортка зникне.

        Нативні команди (bcdedit, powercfg, net ...) ці помилки не породжують і
        тут не враховуються — для них потрібен Invoke-Native.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path,

        # Сухий прогін: скрипт не виконується (він не вміє -WhatIf)
        [switch] $DryRun
    )

    $name = Split-Path -Path $Path -Leaf
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Скрипт не знайдено: $Path"
    }

    if ($DryRun) {
        Write-Step "$name пропущено: старий скрипт не підтримує -WhatIf, нативні команди виконались би насправді" -Level Skip
        Set-TaskStatus -Status WhatIf -Message 'старий скрипт не запускався'
        return
    }

    $ErrorActionPreference = 'Continue'

    # Рахуємо те, що справді потрапило в ПОТІК помилок (2>&1), а не вміст $Error: в $Error
    # потрапляють і помилки, приглушені через -ErrorAction SilentlyContinue, і пійманні винятки
    # (одна невдача = кілька записів), і внутрішні "фантомні" винятки Select-Object -First.
    # stderr нативних програм (choco, winget) у 5.1 теж стає ErrorRecord - його лише показуємо.
    $errors = New-Object System.Collections.Generic.List[object]
    $nativeIds = 'NativeCommandError', 'NativeCommandErrorMessage'

    # Старі скрипти змінюють робочу директорію (Configuration.ps1: cd C:\Support\Scripts)
    Push-Location
    try {
        & $Path 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $isNative = $_.FullyQualifiedErrorId -in $nativeIds
                if (-not $isNative) { $errors.Add($_) }
                $color = if ($isNative) { 'Gray' } else { 'Red' }
                Write-Host (($_ | Out-String).TrimEnd()) -ForegroundColor $color
            }
            else {
                $_
            }
        }
    }
    finally {
        Pop-Location
    }

    if ($errors.Count -gt 0) {
        Write-Step "${name}: $($errors.Count) помилок, що не зупинили скрипт" -Level Warn
        Set-TaskStatus -Status Warn -Message "$($errors.Count) помилок у $name, див. лог"
    }
}
