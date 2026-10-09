#Requires -Version 5.1
# Завдання планувальника для автозапуску SuperF4 (Етап 4, дефект 5; RP §6.4).
#
# SuperF4 завершує активну програму по Ctrl+Alt+F4 (Alt+F4 лише просить її закритись), а Win+F4 і клік
# по вікну - примусово завершує вибране. Пакет ставиться з data\packages.psd1.
[CmdletBinding(SupportsShouldProcess)]
param(
    # Лише для тестів; у бойовому прогоні - стандартна тека пакетів Chocolatey
    [string] $ChocolateyLib = $(if ($env:ChocolateyInstall) { Join-Path $env:ChocolateyInstall 'lib' })
)

$taskName = 'SuperF4'

# Повторна реєстрація існуючого завдання - помилка, тому для ідемпотентності перевіряємо наявність
if (Get-ScheduledTask -TaskName $taskName -ErrorAction Ignore) {
    Write-Step "Завдання $taskName вже існує" -Level Skip
    return
}

# Старий шлях "$env:APPDATA\SuperF4\SuperF4.exe" не відповідав місцю, куди пакет кладе файл, а
# Register-ScheduledTask не перевіряє, що виконуваний файл існує: завдання успішно реєструвалось,
# і нічого не запускалось. Тому шукаємо справжній шлях і без нього завдання не створюємо.
$exe = $null
if ($ChocolateyLib) {
    # Не Select-Object -First 1: у Windows PowerShell 5.1 він лишає "фантомну" помилку в $Error
    $found = @(Get-ChildItem -LiteralPath (Join-Path $ChocolateyLib 'superf4') -Filter 'SuperF4.exe' -Recurse -ErrorAction Ignore |
        ForEach-Object { $_.FullName })
    if ($found.Count -gt 0) { $exe = $found[0] }
}
if (-not $exe) {
    $shim = Get-Command 'SuperF4.exe' -CommandType Application -ErrorAction Ignore
    if ($shim) { $exe = @($shim)[0].Source }
}

if (-not $exe) {
    Write-Step 'SuperF4.exe не знайдено - завдання автозапуску не створено' -Level Warn
    Set-TaskStatus -Status Warn -Message 'SuperF4.exe не знайдено, автозапуск не налаштовано'
    return
}

Write-Step "SuperF4: $exe"
if ($PSCmdlet.ShouldProcess($taskName, "Зареєструвати автозапуск ($exe)")) {
    $action    = New-ScheduledTaskAction -Execute $exe
    $trigger   = New-ScheduledTaskTrigger -AtLogOn                                                   # при вході користувача
    $principal = New-ScheduledTaskPrincipal -UserId $env:UserName -LogonType Interactive -RunLevel Highest   # без збереження пароля
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DisallowHardTerminate
    $task      = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Automatically run SuperF4'

    Register-ScheduledTask -TaskName $taskName -InputObject $task -User $env:UserName -RunLevel Highest -ErrorAction Stop | Out-Null
    Write-Step "Завдання '$taskName' створено"
}
