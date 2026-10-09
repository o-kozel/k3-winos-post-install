#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Єдина точка входу post-install конфігурації Windows.
.DESCRIPTION
    Запускає задачі з tasks\ у порядку числових префіксів (00-, 10-, ...).
    Падіння однієї задачі не зупиняє решту, але фіксується в підсумковій таблиці.
    Увесь прогін пишеться у транскрипт у -LogDirectory.
.EXAMPLE
    .\Invoke-PostInstall.ps1 -WhatIf
.EXAMPLE
    .\Invoke-PostInstall.ps1 -Only Configuration
.EXAMPLE
    .\Invoke-PostInstall.ps1 -Skip Software -NoCheckpoint
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # Виконати лише вказані задачі (ім'я файлу без номера й розширення)
    [string[]] $Only,

    # Пропустити вказані задачі
    [string[]] $Skip,

    # Не створювати точку відновлення (для повторних прогонів)
    [switch] $NoCheckpoint,

    [string] $LogDirectory = 'C:\Support\Logs'
)

# Задачі користуються Checkpoint-Computer / Enable-ComputerRestore: цих командлетів
# немає в PowerShell 7. Тому під pwsh перезапускаємо себе у Windows PowerShell 5.1
# з тими самими параметрами.
if ($PSVersionTable.PSEdition -eq 'Core') {
    $self = $PSCommandPath -replace "'", "''"
    $tokens = foreach ($entry in $PSBoundParameters.GetEnumerator()) {
        $value = $entry.Value
        if ($value -is [System.Management.Automation.SwitchParameter]) {
            if ($value.IsPresent) { "-$($entry.Key)" } else { "-$($entry.Key):`$false" }
        }
        elseif ($value -is [array]) {
            "-$($entry.Key) " + (($value | ForEach-Object { "'" + ("$_" -replace "'", "''") + "'" }) -join ',')
        }
        else {
            "-$($entry.Key) '" + ("$value" -replace "'", "''") + "'"
        }
    }
    Write-Host '  ! Запущено під PowerShell 7 - перезапуск у Windows PowerShell 5.1' -ForegroundColor Yellow
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '$self' $($tokens -join ' '); exit `$LASTEXITCODE"
    exit $LASTEXITCODE
}

# Без 'Stop' не-термінальні помилки командлетів не потрапляють у catch нижче
$ErrorActionPreference = 'Stop'

# Лог - не зміна системи, тому -WhatIf:$false: у сухому прогоні він теж потрібен
if (-not (Test-Path -LiteralPath $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force -WhatIf:$false | Out-Null
}
$logFile = Join-Path $LogDirectory "postinstall_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
Start-Transcript -Path $logFile -IncludeInvocationHeader -WhatIf:$false | Out-Null

$results = [System.Collections.Generic.List[object]]::new()
$fatal = $false

try {
    Import-Module (Join-Path $PSScriptRoot 'modules\PostInstall\PostInstall.psd1') -Force -DisableNameChecking

    Write-Step "Post install: лог $logFile" -Level Header
    if ($WhatIfPreference) { Write-Step 'Сухий прогін (-WhatIf): систему не буде змінено' -Level Warn }
    Test-Prerequisites

    $tasks = @(
        Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'tasks') -Filter '*.ps1' -File |
            Where-Object { $_.Name -match '^\d{2}-' } |
            Sort-Object -Property Name |
            ForEach-Object { [pscustomobject]@{ Name = $_.BaseName -replace '^\d{2}-', ''; Path = $_.FullName } }
    )

    if ($NoCheckpoint) { $Skip = @($Skip | Where-Object { $_ }) + 'Checkpoint' }

    # Помилка в назві задачі не повинна мовчки перетворитись на «нічого не виконано»
    $unknown = @(@($Only) + @($Skip) | Where-Object { $_ -and $_ -notin $tasks.Name })
    if ($unknown.Count -gt 0) {
        throw "Невідомі задачі: $($unknown -join ', '). Доступні: $($tasks.Name -join ', ')"
    }

    foreach ($task in $tasks) {
        if (($Only -and $task.Name -notin $Only) -or ($Skip -and $task.Name -in $Skip)) {
            $results.Add([pscustomobject]@{ Task = $task.Name; Status = 'SKIPPED'; Seconds = $null; Note = '' })
            continue
        }

        Write-Step "Задача: $($task.Name)" -Level Header
        $null = Get-TaskStatus -Reset
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            & $task.Path -ErrorAction Stop | Out-Host

            $status = if ($WhatIfPreference) { 'WHATIF' } else { 'OK' }
            $note = ''
            $reported = Get-TaskStatus -Reset
            if ($reported) {
                $status = $reported.Status.ToUpper()
                $note = $reported.Message
            }
            $results.Add([pscustomobject]@{
                Task = $task.Name; Status = $status; Seconds = [math]::Round($timer.Elapsed.TotalSeconds, 1); Note = $note
            })
        }
        catch {
            Write-Step "ПОМИЛКА у $($task.Name): $($_.Exception.Message)" -Level Error
            Write-Step "$($_.ScriptStackTrace)" -Level Skip
            $results.Add([pscustomobject]@{
                Task = $task.Name; Status = 'FAILED'; Seconds = [math]::Round($timer.Elapsed.TotalSeconds, 1); Note = $_.Exception.Message
            })
        }
    }
}
catch {
    # Write-Host, а не Write-Step: модуль міг не завантажитись
    Write-Host " !! КРИТИЧНА ПОМИЛКА: $($_.Exception.Message)" -ForegroundColor Red
    $fatal = $true
}
finally {
    if ($results.Count -gt 0) {
        # Підсумкова таблиця - головний артефакт прогону; Out-Host, щоб потрапила в транскрипт
        $results | Format-Table -Property Task, Status, Seconds, Note -AutoSize -Wrap | Out-Host
    }
    Stop-Transcript | Out-Null
}

if ($fatal -or @($results | Where-Object { $_.Status -eq 'FAILED' }).Count -gt 0) { exit 1 }
exit 0
