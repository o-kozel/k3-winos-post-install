#Requires -Version 5.1
# Курсори macOS: автоматизація колишньої ручної установки (через Install.inf з архіву).
#
# Чому не "правий клік -> Встановити" (InfDefaultInstall / setupapi):
#   * його Install.inf пише в HKLM\...\Runonce команду відкрити "Властивості миші" при наступному вході -
#     вікно, яке треба закрити вручну; ми цього запису свідомо НЕ робимо;
#   * розбір INF самим скриптом дає тестований результат (копіювання, схема, поточні курсори).
#
# Що робить, як і Install.inf обраного варіанта (data\cursors.psd1): копіює файли курсорів у
# <Windows>\Cursors\<тека варіанта>, реєструє схему в HKCU\Control Panel\Cursors\Schemes, робить її
# поточною і застосовує без перезавантаження (SystemParametersInfo SPI_SETCURSORS).
# Налаштування діють для користувача, під яким запущено скрипт (HKCU).
[CmdletBinding(SupportsShouldProcess)]
param(
    # Параметри нижче - лише для тестів; у бойовому прогоні стандартні значення
    [string] $WindowsDir = $env:SystemRoot,
    [string] $RegistryBase = 'HKCU:\',
    [switch] $SkipApply
)

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$choice = Import-PowerShellDataFile -Path (Join-Path $projectRoot 'data\cursors.psd1')
$archive = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets\cursors') -Filter '*.zip' -File -ErrorAction Ignore)
if ($archive.Count -eq 0) {
    # Архів не входить до репозиторію (чужі курсори, похідні від Apple), тож його відсутність - звичайний стан
    Write-Step 'Архів курсорів не знайдено в assets\cursors\*.zip - задачу пропущено (див. README, розділ «Курсори»)' -Level Skip
    Set-TaskStatus -Status Skipped -Message 'немає assets\cursors\*.zip'
    return
}

function Read-InfSections([string] $Path) {
    $sections = @{}; $current = $null
    foreach ($raw in [IO.File]::ReadAllLines($Path)) {
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith(';')) { continue }
        if ($line -match '^\[(.+)\]$') { $current = $Matches[1]; $sections[$current] = New-Object System.Collections.Generic.List[string]; continue }
        if ($current) { $sections[$current].Add($line) }
    }
    $sections
}

function Split-InfFields([string] $Line) {
    # Поля через кому; кома всередині лапок - частина значення
    $fields = New-Object System.Collections.Generic.List[string]; $sb = New-Object System.Text.StringBuilder; $quoted = $false
    foreach ($ch in $Line.ToCharArray()) {
        if ($ch -eq '"') { $quoted = -not $quoted; continue }
        if ($ch -eq ',' -and -not $quoted) { $fields.Add($sb.ToString().Trim()); [void]$sb.Clear(); continue }
        [void]$sb.Append($ch)
    }
    $fields.Add($sb.ToString().Trim())
    , $fields.ToArray()
}

# ---------------------------------------------------------------- 1. знайти варіант в архіві й розпакувати
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($archive[0].FullName)
$work = Join-Path ([IO.Path]::GetTempPath()) ('postinstall-cursors-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    $strip = { param($s) $s -replace '^\d+\.\s*', '' }
    $variants = @($zip.Entries | Where-Object { $_.Name -eq 'Install.inf' })
    $hit = @($variants | Where-Object {
        $c = $_.FullName -split '/'
        $c.Count -ge 5 -and (& $strip $c[1]) -eq $choice.Generation -and (& $strip $c[2]) -eq $choice.Shadow -and (& $strip $c[3]) -eq $choice.Size })
    if ($hit.Count -ne 1) {
        $available = $variants | ForEach-Object { $c = $_.FullName -split '/'; "$(& $strip $c[1]) / $(& $strip $c[2]) / $(& $strip $c[3])" }
        throw "Варіант '$($choice.Generation) / $($choice.Shadow) / $($choice.Size)' не знайдено в архіві. Доступні: $($available -join '; ')"
    }
    $prefix = $hit[0].FullName.Substring(0, $hit[0].FullName.Length - 'Install.inf'.Length)
    # -WhatIf:$false: тимчасова робота (розпакування) - не зміна системи, а без неї сухий прогін падав би
    New-Item -ItemType Directory -Path $work -Force -WhatIf:$false | Out-Null
    foreach ($entry in @($zip.Entries | Where-Object { $_.FullName.StartsWith($prefix) -and $_.Name })) {
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $work $entry.Name), $true)
    }
    Write-Step "Курсори: $($choice.Generation) / $($choice.Shadow) / $($choice.Size)"

    # ------------------------------------------------------------ 2. розібрати Install.inf
    $inf = Read-InfSections (Join-Path $work 'Install.inf')
    $strings = @{}
    foreach ($l in $inf['Strings']) { if ($l -match '^([^=]+?)\s*=\s*"?(.*?)"?\s*$') { $strings[$Matches[1].Trim().ToLower()] = $Matches[2] } }
    function Expand-Inf([string] $Text) {
        for ($pass = 0; $pass -lt 6; $pass++) {
            $new = [regex]::Replace($Text, '%([^%]+)%', {
                param($m) $k = $m.Groups[1].Value
                if ($k -eq '10') { $WindowsDir } elseif ($strings.ContainsKey($k.ToLower())) { $strings[$k.ToLower()] } else { $m.Value } })
            if ($new -eq $Text) { break }
            $Text = $new
        }
        $Text
    }

    $destLine = @($inf['DestinationDirs'] | Where-Object { $_ -match '^Scheme\.Cur\s*=' })[0]
    $destParts = Split-InfFields ($destLine -replace '^[^=]+=\s*', '')
    if ($destParts[0] -ne '10') { throw "Непідтримуваний DIRID '$($destParts[0])' в Install.inf (очікувався 10 - каталог Windows)" }
    $destDir = Join-Path $WindowsDir (Expand-Inf $destParts[1])
    $files = @($inf['Scheme.Cur'])

    # ------------------------------------------------------------ 3. копіювання файлів
    Write-Step "Файли курсорів ($($files.Count)) -> $destDir"
    if ($PSCmdlet.ShouldProcess($destDir, "Скопіювати $($files.Count) файлів курсорів")) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $copied = 0
        foreach ($f in $files) {
            $src = Join-Path $work $f; $dst = Join-Path $destDir $f
            if (-not (Test-Path -LiteralPath $src)) { throw "У архіві немає файлу з Install.inf: $f" }
            if ((Test-Path -LiteralPath $dst) -and (Get-Item -LiteralPath $dst).Length -eq (Get-Item -LiteralPath $src).Length) { continue }
            Copy-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop
            $copied++
        }
        Write-Step "Скопійовано: $copied, уже були: $($files.Count - $copied)" $(if ($copied) { 'Info' } else { 'Skip' })
    }

    # ------------------------------------------------------------ 4. реєстр (лише HKCU)
    $kinds = @{ 0 = 'String'; 0x20000 = 'ExpandString'; 0x10000 = 'MultiString'; 0x10001 = 'DWord' }
    $addReg = @((@($inf['DefaultInstall'] | Where-Object { $_ -match '^AddReg\s*=' })[0] -replace '^[^=]+=\s*', '') -split '\s*,\s*')
    foreach ($section in $addReg) {
        foreach ($l in $inf[$section]) {
            $f = Split-InfFields $l
            if ($f[0] -ne 'HKCU') { Write-Step "Пропущено запис $($f[0])\$($f[1]): це не HKCU (Install.inf так відкриває вікно миші при наступному вході)" -Level Skip; continue }
            $key = Join-Path $RegistryBase (Expand-Inf $f[1])
            $name = Expand-Inf $f[2]
            $flags = if ($f[3]) { [Convert]::ToInt32($f[3].Substring(2), 16) } else { 0 }
            if (-not $kinds.ContainsKey($flags)) { Write-Step "Пропущено $key\${name}: непідтримувані прапорці 0x$('{0:X}' -f $flags)" -Level Warn; continue }
            $value = Expand-Inf $f[4]
            if ($name -eq '') {
                # Значення "за замовчуванням" ключа (поточна схема); Set-RegValue його не розпізнає
                if (-not (Test-Path -LiteralPath $key)) { if ($PSCmdlet.ShouldProcess($key, 'Створити ключ')) { New-Item -Path $key -Force | Out-Null } }
                $current = if (Test-Path -LiteralPath $key) { (Get-Item -LiteralPath $key).GetValue('') } else { $null }
                if ($current -ceq $value) { Write-Step "$key\(за замовчуванням) вже = $value" -Level Skip }
                elseif ($PSCmdlet.ShouldProcess("$key\(за замовчуванням)", "Встановити $value")) {
                    Set-ItemProperty -LiteralPath $key -Name '(default)' -Value $value -Type String -ErrorAction Stop
                    Write-Step "$key\(за замовчуванням) = $value"
                }
            }
            else {
                Set-RegValue -Path $key -Name $name -Value $value -Type $kinds[$flags] -WhatIf:$WhatIfPreference -ErrorAction Stop
            }
        }
    }

    # ------------------------------------------------------------ 5. застосувати без перезавантаження
    if ($SkipApply) { Write-Step 'Застосування (SPI_SETCURSORS) пропущено' -Level Skip }
    elseif ($PSCmdlet.ShouldProcess('сеанс користувача', 'Застосувати курсори (SPI_SETCURSORS)')) {
        if (-not ('PostInstall.NativeCursor' -as [type])) {
            Add-Type -Namespace PostInstall -Name NativeCursor -MemberDefinition '[DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);'
        }
        # 0x57 = SPI_SETCURSORS; 3 = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
        # Реєстр уже записано, тож збій тут не критичний: курсори застосуються при наступному вході в систему
        if ([PostInstall.NativeCursor]::SystemParametersInfo(0x57, 0, [IntPtr]::Zero, 3)) {
            Write-Step 'Курсори застосовано без перезавантаження'
        }
        else {
            $win32 = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Step "SystemParametersInfo не застосував курсори одразу (Win32 $win32); вони з'являться після повторного входу в систему" -Level Warn
            Set-TaskStatus -Status Warn -Message 'курсори записано в реєстр; застосуються після повторного входу'
        }
    }
}
finally {
    $zip.Dispose()
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -WhatIf:$false -ErrorAction SilentlyContinue }
}
