#Requires -Version 5.1
# Увімкнення відновлення системи та точка відновлення перед змінами.
# Винесено з Configuration.ps1, щоб -NoCheckpoint / -Skip Checkpoint працювали.
# Enable-ComputerRestore і Checkpoint-Computer існують лише у Windows PowerShell 5.1.
[CmdletBinding(SupportsShouldProcess)]
param(
    # Лише для тестів; у бойовому прогоні - стандартний розділ реєстру
    [string] $RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
)

$valueName = 'SystemRestorePointCreationFrequency'

Write-Step "Вмикаємо відновлення системи на $env:SystemDrive"
if ($PSCmdlet.ShouldProcess($env:SystemDrive, 'Увімкнути відновлення системи')) {
    Enable-ComputerRestore -Drive "$env:SystemDrive"
}

# Без нуля Windows не створює другу точку відновлення протягом 24 годин, а повторні прогони саме цього й
# потребують. Але лишати 0 назавжди не можна: тоді кожен інсталятор створював би точку й з'їдав квоту.
# Тому запам'ятовуємо попереднє значення й повертаємо його у finally (Етап 4, дефект 10).
$previous = (Get-ItemProperty -LiteralPath $RegistryPath -Name $valueName -ErrorAction Ignore).$valueName   # $null - значення не було

try {
    Set-RegValue -Path $RegistryPath -Name $valueName -Value 0 -WhatIf:$WhatIfPreference -ErrorAction Stop

    Write-Step 'Створюємо точку відновлення'
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Створити точку відновлення')) {
        Checkpoint-Computer -Description 'Before the script' -RestorePointType 'MODIFY_SETTINGS'
    }
}
finally {
    if ($null -eq $previous) {
        # Значення не було - повертаємо його відсутність (поведінка Windows за замовчуванням: не частіше разу на 24 год)
        if ($null -ne (Get-ItemProperty -LiteralPath $RegistryPath -Name $valueName -ErrorAction Ignore).$valueName) {
            if ($PSCmdlet.ShouldProcess("$RegistryPath\$valueName", 'Видалити (повернути стандартну поведінку)')) {
                Remove-ItemProperty -LiteralPath $RegistryPath -Name $valueName -ErrorAction Continue
                Write-Step "$valueName повернено до стандартного (значення видалено)"
            }
        }
    }
    else {
        Set-RegValue -Path $RegistryPath -Name $valueName -Value $previous -WhatIf:$WhatIfPreference -ErrorAction Continue
    }
}
