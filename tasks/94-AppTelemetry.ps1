#Requires -Version 5.1
# Телеметрія програм, яка вимикається у файлах налаштувань користувача: VS Code, Claude Code, Codex CLI.
# Решту (перемикачі в інтерфейсах програм і налаштування акаунтів) скрипт зробити не може - вони в
# data\manual-steps.psd1 і друкуються наприкінці прогону.
#
# Файли належать користувачеві, від імені якого запущено скрипт (%USERPROFILE%, %APPDATA%). Якщо прогін іде
# під ІНШИМ обліковим записом адміністратора, налаштування потраплять у його профіль, а не у ваш.
#
# Наявні налаштування не перезаписуються: змінюються лише потрібні ключі, решта лишається як була. Перед першою
# зміною файл копіюється в <ім'я>.postinstall.bak (лише раз - оригінал не губиться з другого прогону).
# Повторний прогін нічого не змінює (Skip).
[CmdletBinding(SupportsShouldProcess)]
param(
    # Параметри нижче - лише для тестів; у бойовому прогоні стандартні значення
    [string] $UserHome = $HOME,
    [string] $AppData = $env:APPDATA
)

$failed = New-Object System.Collections.Generic.List[string]
$utf8NoBom = New-Object System.Text.UTF8Encoding $false   # JSON із BOM не читає частина парсерів (Node.js)

function Invoke-AppStep {
    param([string] $Title, [scriptblock] $Body)
    try { & $Body }
    catch {
        $failed.Add($Title)
        Write-Step "$Title : $($_.Exception.Message)" -Level Warn
    }
}

function Read-TextFile {
    param([string] $Path)
    if (Test-Path -LiteralPath $Path) { [IO.File]::ReadAllText($Path) } else { $null }
}

function Save-TextFile {
    # Пише файл лише якщо вміст змінився; перед першою зміною робить резервну копію.
    # $PSCmdlet - задачі (знаходиться за областю видимості), тож -WhatIf задачі діє і тут
    # (попередження аналізатора PSShouldProcess на цю функцію очікуване)
    # $Original без [string]: типізований параметр перетворив би $null ("файлу немає") на порожній рядок
    param([string] $Path, $Original, [string] $Content, [string] $What)
    if ($null -ne $Original -and $Original -ceq $Content) {
        Write-Step "$What - уже налаштовано" -Level Skip
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Path, $What)) { return }
    New-Item -ItemType Directory -Path (Split-Path -Path $Path -Parent) -Force | Out-Null
    $backup = "$Path.postinstall.bak"
    if ($null -ne $Original -and -not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $Path -Destination $backup -ErrorAction Stop
    }
    [IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
    Write-Step "$What - $Path"
}

function Set-TomlValue {
    <#
        Ставить "Key = Value" у таблицю [Table] простого TOML-файлу (рядками, щоб не губити коментарі).
        Value - вже у форматі TOML (false, "none"). Підтримує і форму "Table.Key = ..." на верхньому рівні.
    #>
    # Список, а не "масив + рядок": у 5.1 порожній масив + $null + рядок дає склеєний РЯДОК, а не масив
    param($Lines, [string] $Table, [string] $Key, [string] $Value)
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($line in @($Lines)) { if ($null -ne $line) { $list.Add($line) } }
    $wanted = "$Key = $Value"
    $headerRe = '^\s*\['
    $tableRe = '^\s*\[\s*' + [regex]::Escape($Table) + '\s*\]\s*(#.*)?$'
    $keyRe = '^\s*' + [regex]::Escape($Key) + '\s*='

    $header = -1
    for ($i = 0; $i -lt $list.Count; $i++) { if ($list[$i] -match $tableRe) { $header = $i; break } }

    if ($header -ge 0) {
        for ($i = $header + 1; $i -lt $list.Count -and $list[$i] -notmatch $headerRe; $i++) {
            if ($list[$i] -match $keyRe) { $list[$i] = $wanted; return $list.ToArray() }
        }
        # Ключа в таблиці немає - вставляємо одразу після заголовка
        $list.Insert($header + 1, $wanted)
        return $list.ToArray()
    }

    # Форма з крапкою до першої таблиці: analytics.enabled = true
    $dottedRe = '^\s*' + [regex]::Escape("$Table.$Key") + '\s*='
    for ($i = 0; $i -lt $list.Count -and $list[$i] -notmatch $headerRe; $i++) {
        if ($list[$i] -match $dottedRe) { $list[$i] = "$Table.$wanted"; return $list.ToArray() }
    }

    if ($list.Count -gt 0 -and $list[$list.Count - 1].Trim()) { $list.Add('') }
    $list.Add("[$Table]")
    $list.Add($wanted)
    return $list.ToArray()
}

# ---------------------------------------------------------------- VS Code (WCS F5)
Invoke-AppStep 'VS Code' {
    # settings.json у VS Code - JSONC (коментарі, коми в кінці), ConvertFrom-Json у 5.1 його не прочитає.
    # Тому правка текстом: замінити значення ключа або дописати ключ першим у об'єкт.
    $path = Join-Path $AppData 'Code\User\settings.json'
    $original = Read-TextFile $path
    $pair = '"telemetry.telemetryLevel": "off"'
    $keyRe = '"telemetry\.telemetryLevel"\s*:\s*"[^"]*"'
    if ($null -eq $original -or $original -match '^\s*(\{\s*\})?\s*$') {
        $content = "{`r`n    $pair`r`n}`r`n"
    }
    elseif ($original -match $keyRe) {
        $content = [regex]::Replace($original, $keyRe, $pair)
    }
    elseif ($original -match '\{') {
        $content = ([regex]'\{').Replace($original, "{`r`n    $pair,", 1)
    }
    else { throw "не схоже на JSON: $path" }
    Save-TextFile -Path $path -Original $original -Content $content -What 'VS Code: telemetry.telemetryLevel = off'
}

# ---------------------------------------------------------------- Claude Code
Invoke-AppStep 'Claude Code' {
    # Звичайний JSON. Лише DISABLE_TELEMETRY і DISABLE_ERROR_REPORTING: загальний
    # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC вимкнув би ще й автооновлення.
    $path = Join-Path $UserHome '.claude\settings.json'
    $original = Read-TextFile $path
    $settings = if ($original -and $original.Trim()) { $original | ConvertFrom-Json -ErrorAction Stop } else { New-Object psobject }
    if (-not $settings.PSObject.Properties['env']) { $settings | Add-Member -NotePropertyName env -NotePropertyValue (New-Object psobject) }
    $changed = $false
    foreach ($name in 'DISABLE_TELEMETRY', 'DISABLE_ERROR_REPORTING') {
        if ($settings.env.PSObject.Properties[$name]) {
            if ($settings.env.$name -cne '1') { $settings.env.$name = '1'; $changed = $true }
        }
        else { $settings.env | Add-Member -NotePropertyName $name -NotePropertyValue '1'; $changed = $true }
    }
    # Без змін - не переписуємо файл (ConvertTo-Json переформатував би його)
    $content = if ($changed) { ($settings | ConvertTo-Json -Depth 32) + "`r`n" } else { $original }
    Save-TextFile -Path $path -Original $original -Content $content -What 'Claude Code: DISABLE_TELEMETRY, DISABLE_ERROR_REPORTING'
}

# ---------------------------------------------------------------- Codex CLI
Invoke-AppStep 'Codex CLI' {
    # Ключі з офіційного довідника конфігурації Codex: analytics.enabled; otel.metrics_exporter за замовчуванням
    # "statsig" (метрики відправляються в OpenAI) - ставимо "none". Лише користувацький config.toml: проєктні
    # .codex\config.toml телеметричні ключі ігнорують.
    $path = Join-Path $UserHome '.codex\config.toml'
    $original = Read-TextFile $path
    $lines = @(if ($original) { $original.TrimEnd("`r", "`n") -split '\r?\n' })
    $lines = @(Set-TomlValue -Lines $lines -Table 'analytics' -Key 'enabled' -Value 'false')
    $lines = @(Set-TomlValue -Lines $lines -Table 'otel' -Key 'metrics_exporter' -Value '"none"')
    $content = ($lines -join "`r`n") + "`r`n"
    # Відрізняється лише кінцями рядків - не переписуємо
    if ($original -and ($original -replace '\r?\n', "`r`n").TrimEnd() -ceq $content.TrimEnd()) { $content = $original }
    Save-TextFile -Path $path -Original $original -Content $content -What 'Codex CLI: analytics.enabled = false, otel.metrics_exporter = none'
}

if ($failed.Count -gt 0) {
    Set-TaskStatus -Status Warn -Message "не вдалося: $($failed -join '; ')"
}
