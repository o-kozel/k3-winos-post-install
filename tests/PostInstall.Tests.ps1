# Статичні тести проєкту (RP, Етап 7.4) + кілька функціональних перевірок хелперів.
#
# Запуск (з кореня проєкту):
#     Invoke-Pester .\tests
# Достатньо Pester 3.4, який є у Windows PowerShell 5.1; тести написано так, щоб працювали й у Pester 5
# (у ньому дані й функції треба готувати в BeforeAll - так тут і зроблено).
#
# Ідея з RP: перевірити справжній результат налаштування ПК можна лише на чистій системі, тож цінність мають
# статичні тести, які ловлять уже знайдені дефекти: дублікати в списках, синтаксичні помилки, кирилицю без BOM.

Describe 'Дані' {
    BeforeAll {
        . "$PSScriptRoot\TestHelpers.ps1"
        $script:services = @((Import-PowerShellDataFile -Path "$script:ProjectRoot\data\services.psd1").Services)
        $script:appx = @((Import-PowerShellDataFile -Path "$script:ProjectRoot\data\appx-remove.psd1").Appx)
        $script:packages = @((Import-PowerShellDataFile -Path "$script:ProjectRoot\data\packages.psd1").Packages)
        $script:cursors = Import-PowerShellDataFile -Path "$script:ProjectRoot\data\cursors.psd1"
    }

    It 'services.psd1: не порожній і кожен запис має Name та коректний Startup' {
        Assert-True ($script:services.Count -gt 0) 'у services.psd1 немає жодної служби'
        Assert-None ($script:services | Where-Object { -not $_.Name }) 'запис без Name'
        Assert-None ($script:services | Where-Object { $_.Startup -notin 'Automatic', 'Manual', 'Disabled' } | ForEach-Object { "$($_.Name)=$($_.Startup)" }) 'неприпустимий Startup'
    }

    It 'services.psd1: немає дублікатів служб (так виник конфлікт DiagTrack)' {
        $dups = $script:services | Group-Object { $_.Name.ToLower() } | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
        Assert-None $dups 'служба згадана кілька разів'
    }

    It 'services.psd1: DiagTrack заданий рівно один раз і Disabled' {
        $diag = @($script:services | Where-Object { $_.Name -eq 'DiagTrack' })
        Assert-True ($diag.Count -eq 1) "DiagTrack зустрічається $($diag.Count) разів"
        Assert-True ($diag[0].Startup -eq 'Disabled') "DiagTrack = $($diag[0].Startup), очікувалось Disabled"
    }

    It 'appx-remove.psd1: список рядків без дублікатів (без урахування регістру)' {
        Assert-True ($script:appx.Count -gt 50) "підозріло мало записів: $($script:appx.Count)"
        Assert-None ($script:appx | Where-Object { $_ -isnot [string] }) 'елемент не є рядком'
        $dups = $script:appx | Group-Object { $_.ToLower() } | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
        Assert-None $dups 'дублікати AppX-шаблонів'
    }

    It 'appx-remove.psd1: жоден шаблон не зачіпає пакети, потрібні іграм (Game Pass) і системі' {
        $protected = 'Microsoft.GamingServices', 'Microsoft.GamingApp', 'Microsoft.XboxApp', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGameCallableUI', 'Microsoft.XboxIdentityProvider',
            # winget, Store, Ножиці (Win+Shift+S - WCS B2), засоби усунення неполадок
            'Microsoft.DesktopAppInstaller', 'Microsoft.WindowsStore', 'Microsoft.ScreenSketch', 'Microsoft.GetHelp'
        $hits = foreach ($pattern in $script:appx) { foreach ($name in $protected) { if ($name -like $pattern) { "$pattern зачіпає $name" } } }
        Assert-None $hits 'шаблон видалить захищений пакет'
    }

    It 'packages.psd1: кожен запис має Id; Source - choco або winget' {
        Assert-True ($script:packages.Count -gt 0) 'у packages.psd1 немає пакетів'
        Assert-None ($script:packages | Where-Object { -not $_.Id }) 'запис без Id'
        Assert-None ($script:packages | Where-Object { $_.Source -and $_.Source -notin 'choco', 'winget' } | ForEach-Object { "$($_.Id)=$($_.Source)" }) 'невідомий Source'
    }

    It 'packages.psd1: немає дублікатів Source+Id' {
        $dups = $script:packages | Group-Object { "$(if ($_.Source) { $_.Source } else { 'choco' })|$($_.Id)".ToLower() } | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
        Assert-None $dups 'пакет вказано кілька разів'
    }

    It 'packages.psd1: winget-пакети мають повний Id (Видавець.Пакет) - для --exact --id' {
        Assert-None ($script:packages | Where-Object { $_.Source -eq 'winget' -and $_.Id -notmatch '^[^.\s]+\.[^\s]+$' } | ForEach-Object { $_.Id }) 'неповний winget Id'
    }

    It 'packages.psd1: Params є лише у choco-пакетів' {
        Assert-None ($script:packages | Where-Object { $_.Params -and $_.Source -eq 'winget' } | ForEach-Object { $_.Id }) 'Params у winget-пакета ігнорується'
    }

    It 'packages.psd1: git і git.install не стоять разом (git залежить від git.install і ховає його --params)' {
        $ids = @($script:packages | ForEach-Object { $_.Id })
        Assert-True (-not ($ids -contains 'git' -and $ids -contains 'git.install')) 'git і git.install разом'
    }

    It 'manual-steps.psd1: кожен крок має Group, Title і How; Task - ім''я наявної задачі' {
        $steps = @((Import-PowerShellDataFile -Path "$script:ProjectRoot\data\manual-steps.psd1").Steps)
        $taskNames = @(Get-ChildItem -LiteralPath "$script:ProjectRoot\tasks" -Filter '*.ps1' -File | ForEach-Object { $_.BaseName -replace '^\d{2}-', '' })
        Assert-True ($steps.Count -gt 0) 'у manual-steps.psd1 немає кроків'
        Assert-None ($steps | Where-Object { -not $_.Group -or -not $_.Title -or @($_.How).Count -eq 0 } | ForEach-Object { "$($_.Title)" }) 'крок без Group/Title/How'
        Assert-None ($steps | Where-Object { $_.Task -and $_.Task -notin $taskNames } | ForEach-Object { "$($_.Title): $($_.Task)" }) 'Task, якої немає в tasks\ (крок ніколи не показався б)'
    }

    It 'cursors.psd1: варіант курсорів має допустимі значення' {
        Assert-True ($script:cursors.Generation -in 'Sierra and newer', 'El Capitan and before') "Generation: $($script:cursors.Generation)"
        Assert-True ($script:cursors.Shadow -in 'No Shadow', 'With Shadow') "Shadow: $($script:cursors.Shadow)"
        Assert-True ($script:cursors.Size -in 'Normal', 'Large', 'XtraLarge') "Size: $($script:cursors.Size)"
    }

    It 'конфіг O&O ShutUp10 в Configuration.ps1: кожен запис має вигляд "ID<TAB>+/-<TAB># опис"' {
        # Табуляція тут - роздільник формату; заміна її на пробіли зламала б утиліту
        $lines = [IO.File]::ReadAllLines("$script:ProjectRoot\Configuration.ps1")
        $start = (0..($lines.Count - 1) | Where-Object { $lines[$_] -match '^\$configText = @"' })[0]
        $end = (($start + 1)..($lines.Count - 1) | Where-Object { $lines[$_] -eq '"@' })[0]
        Assert-True ($null -ne $start -and $null -ne $end) 'не знайдено here-string $configText'
        $bad = $lines[($start + 1)..($end - 1)] | Where-Object { $_ -notmatch '^[A-Z]\d{3}\t[+-]\t# .+$' }
        Assert-None $bad 'рядки конфігу O&O у неправильному форматі'
    }
}

Describe 'Задачі' {
    BeforeAll {
        . "$PSScriptRoot\TestHelpers.ps1"
        $script:taskFiles = @(Get-ChildItem -LiteralPath "$script:ProjectRoot\tasks" -Filter '*.ps1' -File)
    }

    It 'усі файли в tasks\ названо NN-Назва.ps1' {
        Assert-True ($script:taskFiles.Count -gt 0) 'у tasks\ немає задач'
        Assert-None ($script:taskFiles | Where-Object { $_.Name -notmatch '^\d{2}-[A-Za-z][A-Za-z0-9]*\.ps1$' } | ForEach-Object { $_.Name }) 'некоректна назва задачі'
    }

    It 'числові префікси задач унікальні (порядок виконання однозначний)' {
        $dups = $script:taskFiles | Group-Object { $_.Name.Substring(0, 2) } | Where-Object { $_.Count -gt 1 } | ForEach-Object { "$($_.Name): $(($_.Group | ForEach-Object { $_.Name }) -join ', ')" }
        Assert-None $dups 'однаковий префікс'
    }

    It 'імена задач (для -Only / -Skip) унікальні' {
        $dups = $script:taskFiles | Group-Object { ($_.BaseName -replace '^\d{2}-', '').ToLower() } | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
        Assert-None $dups 'однакове ім''я задачі'
    }

    It 'кожна задача розбирається без синтаксичних помилок' {
        $bad = foreach ($f in $script:taskFiles) { $p = Get-ParsedFile $f.FullName; foreach ($e in $p.Errors) { "$($f.Name):$($e.Extent.StartLineNumber): $($e.Message)" } }
        Assert-None $bad 'синтаксичні помилки'
    }

    It 'кожна задача має [CmdletBinding()] (інакше оркестратор не передасть їй -ErrorAction)' {
        $bad = foreach ($f in $script:taskFiles) {
            $attr = $null
            $p = Get-ParsedFile $f.FullName
            if ($p.Ast.ParamBlock) { $attr = @($p.Ast.ParamBlock.Attributes | Where-Object { $_.TypeName.Name -eq 'CmdletBinding' }) }
            if (-not $attr) { $f.Name }
        }
        Assert-None $bad 'немає [CmdletBinding()]'
    }

    It 'вимкнені файли (з позначкою ВИМКНЕНО) не лежать у tasks\ - оркестратор би їх виконав' {
        $inRoot = $script:taskFiles | Where-Object { (Get-Content -LiteralPath $_.FullName -TotalCount 3) -match 'ВИМКНЕНО' } | ForEach-Object { $_.Name }
        Assert-None $inRoot 'вимкнені файли лежать у tasks\ і будуть виконані'
    }
}

Describe 'Модуль PostInstall' {
    BeforeAll {
        . "$PSScriptRoot\TestHelpers.ps1"
        $script:moduleDir = "$script:ProjectRoot\modules\PostInstall"
        $script:publicFiles = @(Get-ChildItem -LiteralPath "$script:moduleDir\Public" -Filter '*.ps1' -File)
    }

    It 'маніфест коректний (Test-ModuleManifest)' {
        $m = Test-ModuleManifest -Path "$script:moduleDir\PostInstall.psd1" -ErrorAction Stop
        Assert-True ($m.Name -eq 'PostInstall') 'неочікуване ім''я модуля'
    }

    It 'FunctionsToExport збігається з файлами в Public\ (нічого не забуто і нічого зайвого)' {
        $manifest = Import-PowerShellDataFile -Path "$script:moduleDir\PostInstall.psd1"
        $diff = Compare-Object @($manifest.FunctionsToExport | Sort-Object) @($script:publicFiles | ForEach-Object { $_.BaseName } | Sort-Object)
        Assert-None ($diff | ForEach-Object { "$($_.InputObject) ($($_.SideIndicator))" }) 'розбіжність маніфесту та Public\ (=> лише у файлах, <= лише в маніфесті)'
    }

    It 'кожен файл Public\ оголошує функцію з тим самим іменем' {
        $bad = foreach ($f in $script:publicFiles) {
            $names = @((Get-ParsedFile $f.FullName).Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object { $_.Name })
            if ($names -notcontains $f.BaseName) { $f.Name }
        }
        Assert-None $bad 'файл не містить функції зі своєю назвою'
    }

    It 'жодна функція модуля не називається Install-Package (перекрила б вбудовану з PackageManagement)' {
        Assert-True (@($script:publicFiles | Where-Object { $_.BaseName -eq 'Install-Package' }).Count -eq 0) 'є функція Install-Package; назва має бути Install-AppPackage'
    }
}

Describe 'Кодування та пастки PowerShell' {
    BeforeAll {
        . "$PSScriptRoot\TestHelpers.ps1"
        $script:files = @(Get-ScriptFiles)
    }

    It 'кожен скрипт з кирилицею збережено як UTF-8 З BOM (Windows PowerShell 5.1 читає інакше як ANSI)' {
        $bad = $script:files | Where-Object { (Test-HasNonAscii $_.FullName) -and -not (Test-HasUtf8Bom $_.FullName) } | ForEach-Object { Get-RelativePath $_.FullName }
        Assert-None $bad 'немає BOM'
    }

    It 'усі скрипти розбираються без синтаксичних помилок' {
        $bad = foreach ($f in $script:files) { $p = Get-ParsedFile $f.FullName; foreach ($e in $p.Errors) { "$(Get-RelativePath $f.FullName):$($e.Extent.StartLineNumber): $($e.Message)" } }
        Assert-None $bad 'синтаксичні помилки'
    }

    It 'у модулі й задачах немає Select-Object -First (у 5.1 лишає фантомну помилку в $Error)' {
        $targets = @($script:files | Where-Object { $_.FullName -match '\\(modules|tasks)\\' -and $_.FullName -notmatch '\\_disabled\\' })
        $bad = foreach ($f in $targets) {
            foreach ($call in (Get-CommandCalls $f.FullName 'Select-Object')) {
                if (@($call.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'First' }).Count -gt 0) {
                    "$(Get-RelativePath $f.FullName):$($call.Extent.StartLineNumber)"
                }
            }
        }
        Assert-None $bad 'Select-Object -First; використовуйте @(...)[0]'
    }

    It 'Configuration.ps1: немає прямих Set-ItemProperty (усе через Set-RegValue)' {
        $calls = Get-CommandCalls "$script:ProjectRoot\Configuration.ps1" 'Set-ItemProperty'
        Assert-None ($calls | ForEach-Object { "рядок $($_.Extent.StartLineNumber)" }) 'прямий Set-ItemProperty'
    }

    It 'Configuration.ps1: немає нативних команд без Invoke-Native (код виходу не перевірявся б)' {
        $calls = Get-CommandCalls "$script:ProjectRoot\Configuration.ps1" 'bcdedit', 'vssadmin', 'powercfg', 'powercfg.exe', 'net', 'icacls', 'reg', 'choco', 'winget'
        Assert-None ($calls | ForEach-Object { "$($_.GetCommandName()) (рядок $($_.Extent.StartLineNumber))" }) 'нативний виклик без Invoke-Native'
    }

    It 'Configuration.ps1: поза here-string O&O немає провідних табуляцій (лише 4 пробіли)' {
        $lines = [IO.File]::ReadAllLines("$script:ProjectRoot\Configuration.ps1")
        $start = (0..($lines.Count - 1) | Where-Object { $lines[$_] -match '^\$configText = @"' })[0]
        $end = (($start + 1)..($lines.Count - 1) | Where-Object { $lines[$_] -eq '"@' })[0]
        $bad = 0..($lines.Count - 1) | Where-Object { ($_ -le $start -or $_ -ge $end) -and $lines[$_] -match '^ *\t' } | ForEach-Object { $_ + 1 }
        Assert-None $bad 'рядки з провідною табуляцією'
    }
}

Describe 'Документація' {
    BeforeAll {
        . "$PSScriptRoot\TestHelpers.ps1"
    }

    It 'README.md існує й фіксує порядок запуску' {
        Assert-True (Test-Path "$script:ProjectRoot\README.md") 'немає README.md'
        $readme = Get-Content -LiteralPath "$script:ProjectRoot\README.md" -Raw -Encoding UTF8
        Assert-True ($readme -match 'Invoke-PostInstall\.ps1') 'у README.md не згадано Invoke-PostInstall.ps1'
    }

    It 'усі відносні посилання в .md ведуть на існуючі файли, а посилання на рядки - у межах файлу' {
        # Перевіряє існування й межі, а чи описує рядок те, що написано в тексті, - звіряйте вручну
        $docs = @(Get-ChildItem -LiteralPath $script:ProjectRoot -Recurse -Filter '*.md' -File | Where-Object { $_.FullName -notmatch '\\(\.git|node_modules)\\' })
        $bad = foreach ($doc in $docs) {
            $dir = Split-Path -Path $doc.FullName -Parent
            $text = Get-Content -LiteralPath $doc.FullName -Raw -Encoding UTF8
            foreach ($m in [regex]::Matches($text, '\]\((?!https?:|mailto:|#)([^)#\s]+)(?:#L(\d+)(?:-L(\d+))?)?[^)]*\)')) {
                $rel = [uri]::UnescapeDataString($m.Groups[1].Value) -replace '/', '\'
                $path = [IO.Path]::GetFullPath((Join-Path $dir $rel))
                $where = Get-RelativePath $doc.FullName
                if (-not (Test-Path -LiteralPath $path)) { "${where}: немає файлу $rel"; continue }
                if ($m.Groups[2].Success -and -not (Get-Item -LiteralPath $path).PSIsContainer) {
                    $count = [IO.File]::ReadAllLines($path).Count
                    $last = if ($m.Groups[3].Success) { [int]$m.Groups[3].Value } else { [int]$m.Groups[2].Value }
                    if ($last -gt $count) { "${where}: $rel#L$last, а в файлі $count рядків" }
                }
            }
        }
        Assert-None $bad 'зламане посилання'
    }

    It 'LICENSE існує і не містить незаповнених позначок' {
        Assert-True (Test-Path "$script:ProjectRoot\LICENSE") 'немає LICENSE'
        $text = Get-Content -LiteralPath "$script:ProjectRoot\LICENSE" -Raw -Encoding UTF8
        Assert-True ($text -notmatch '\[[A-ZА-Я][^\]]*\]|<[^>]+>|TODO|ЗАПОВН') 'у LICENSE лишилась позначка-заповнювач'
    }
}
Describe 'Хелпери модуля' {
    BeforeAll {
        . "$PSScriptRoot\TestHelpers.ps1"
        Import-Module "$script:ProjectRoot\modules\PostInstall\PostInstall.psd1" -Force -DisableNameChecking
        $script:hive = "HKCU:\Software\PostInstall.Tests.$([guid]::NewGuid().ToString('N').Substring(0, 8))"
    }
    AfterAll {
        if (Test-Path -LiteralPath $script:hive) { Remove-Item -LiteralPath $script:hive -Recurse -Force }
    }

    It 'Set-RegValue створює ланцюжок ключів і записує значення' {
        Set-RegValue -Path "$script:hive\a\b" -Name Flag -Value 1 6>$null
        Assert-True ((Get-ItemProperty -LiteralPath "$script:hive\a\b" -Name Flag).Flag -eq 1) 'значення не записано'
    }

    It 'Set-RegValue порівнює ще й тип: рядок "0" - не DWord 0' {
        Set-RegValue -Path "$script:hive\t" -Name V -Value '0' -Type String 6>$null
        Set-RegValue -Path "$script:hive\t" -Name V -Value 0 -Type DWord 6>$null
        Assert-True ((Get-Item -LiteralPath "$script:hive\t").GetValueKind('V').ToString() -eq 'DWord') 'тип не змінено'
    }

    It 'Set-RegValue -WhatIf нічого не створює' {
        Set-RegValue -Path "$script:hive\whatif" -Name V -Value 1 -WhatIf 6>$null 5>$null
        Assert-True (-not (Test-Path -LiteralPath "$script:hive\whatif")) 'ключ створено попри -WhatIf'
    }

    It 'Invoke-Native: код 0 - без помилок (регресія: у 5.1 ExitCode міг бути порожнім)' {
        $errors = Get-ErrorRecords { Invoke-Native -FilePath cmd.exe -Arguments '/c', 'exit 0' }
        Assert-True ($errors.Count -eq 0) "несподівані помилки: $($errors.Count)"
    }

    It 'Invoke-Native: ненульовий код - рівно одна помилка з цим кодом' {
        $errors = @(Get-ErrorRecords { Invoke-Native -FilePath cmd.exe -Arguments '/c', 'exit 3' })
        Assert-True ($errors.Count -eq 1 -and $errors[0].Exception.Message -match '\b3\b') "помилок: $($errors.Count)"
    }

    It 'Invoke-Native: -SuccessCodes приймає додаткові коди' {
        $errors = Get-ErrorRecords { Invoke-Native -FilePath cmd.exe -Arguments '/c', 'exit 3010' -SuccessCodes 0, 3010 }
        Assert-True ($errors.Count -eq 0) 'код 3010 мав бути успіхом'
    }

    It 'Invoke-Native: -WhatIf не запускає програму' {
        $marker = Join-Path ([IO.Path]::GetTempPath()) "postinstall-test-$([guid]::NewGuid().ToString('N')).txt"
        Invoke-Native -FilePath cmd.exe -Arguments '/c', "echo x > `"$marker`"" -WhatIf 6>$null 5>$null
        $created = Test-Path -LiteralPath $marker
        if ($created) { Remove-Item -LiteralPath $marker -Force }
        Assert-True (-not $created) 'програму запущено попри -WhatIf'
    }

    It 'Set-ServiceStartup: відсутня служба - Skip, а не помилка' {
        $errors = Get-ErrorRecords { Set-ServiceStartup -Name 'PostInstall_Test_NoSuchService' -StartupType Manual }
        Assert-True ($errors.Count -eq 0) 'відсутня служба дала помилку'
    }

    It 'Show-ManualSteps: кроки пропущених задач не показує, файл пише з BOM' {
        $dir = Join-Path ([IO.Path]::GetTempPath()) "postinstall-test-$([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $data = Join-Path $dir 'steps.psd1'
        $out = Join-Path $dir 'out.txt'
        [IO.File]::WriteAllText($data, "@{ Steps = @(
            @{ Group = 'Г'; Title = 'Завжди'; How = @('a') }
            @{ Group = 'Г'; Title = 'ДляSoftware'; Task = 'Software'; How = @('b') }
            @{ Group = 'Г'; Title = 'ДляShell'; Task = 'Shell'; How = @('c') }
        ) }", (New-Object System.Text.UTF8Encoding $true))
        Show-ManualSteps -Path $data -Task 'Software' -OutFile $out 6>$null
        $text = [IO.File]::ReadAllText($out)
        $bom = Test-HasUtf8Bom $out
        Remove-Item -LiteralPath $dir -Recurse -Force
        Assert-True ($text -match 'Завжди' -and $text -match 'ДляSoftware') 'немає кроку, який мав показатись'
        Assert-True ($text -notmatch 'ДляShell') 'показано крок задачі, що не виконувалась'
        Assert-True $bom 'файл без BOM'
    }

    It 'AppTelemetry: доповнює наявні налаштування, не губить чужі ключі, повторний прогін нічого не змінює' {
        $dir = Join-Path ([IO.Path]::GetTempPath()) "postinstall-test-$([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path "$dir\full\home\.claude", "$dir\full\home\.codex", "$dir\full\appdata\Code\User" -Force | Out-Null
        [IO.File]::WriteAllText("$dir\full\home\.claude\settings.json", '{ "permissions": { "allow": ["Bash(git status)"] }, "env": { "FOO": "bar", "DISABLE_TELEMETRY": "0" } }')
        [IO.File]::WriteAllText("$dir\full\home\.codex\config.toml", "model = `"m`"`nanalytics.enabled = true`n[otel]`nmetrics_exporter = `"statsig`"`n[otel.exporter.otlp-http]`nendpoint = `"x`"`n")
        [IO.File]::WriteAllText("$dir\full\appdata\Code\User\settings.json", "// коментар`n{`n    `"editor.fontSize`": 14,`n}")
        $task = "$script:ProjectRoot\tasks\94-AppTelemetry.ps1"
        $errors = Get-ErrorRecords {
            foreach ($case in 'full', 'empty') {
                & $task -UserHome "$dir\$case\home" -AppData "$dir\$case\appdata" 6>$null
            }
        }
        $snapshot = { Get-ChildItem -LiteralPath $dir -Recurse -File | ForEach-Object { "$($_.FullName)|$([IO.File]::ReadAllText($_.FullName))" } }
        $first = @(& $snapshot)
        & $task -UserHome "$dir\full\home" -AppData "$dir\full\appdata" 6>$null
        & $task -UserHome "$dir\empty\home" -AppData "$dir\empty\appdata" 6>$null
        $second = @(& $snapshot)

        $claude = Get-Content -LiteralPath "$dir\full\home\.claude\settings.json" -Raw | ConvertFrom-Json
        $codex = [IO.File]::ReadAllText("$dir\full\home\.codex\config.toml")
        $codexEmpty = @([IO.File]::ReadAllLines("$dir\empty\home\.codex\config.toml"))
        $vscode = [IO.File]::ReadAllText("$dir\full\appdata\Code\User\settings.json")
        $bom = Test-HasUtf8Bom "$dir\empty\home\.claude\settings.json"
        $backups = @(Get-ChildItem -LiteralPath $dir -Recurse -Filter '*.postinstall.bak').Count
        Remove-Item -LiteralPath $dir -Recurse -Force

        Assert-True ($errors.Count -eq 0) "несподівані помилки: $($errors.Count)"
        Assert-True ($claude.env.DISABLE_TELEMETRY -eq '1' -and $claude.env.DISABLE_ERROR_REPORTING -eq '1') 'Claude: телеметрію не вимкнено'
        Assert-True ($claude.env.FOO -eq 'bar' -and @($claude.permissions.allow).Count -eq 1) 'Claude: загублено чужі налаштування'
        Assert-True ($codex -match '(?m)^analytics\.enabled = false' -and $codex -notmatch '\[analytics\]') 'Codex: форму з крапкою не виправлено на місці'
        Assert-True ($codex -match '(?m)^metrics_exporter = "none"' -and $codex -notmatch 'statsig' -and $codex -match 'endpoint = "x"') 'Codex: otel зіпсовано'
        Assert-True (($codexEmpty -join '|') -eq '[analytics]|enabled = false||[otel]|metrics_exporter = "none"') "Codex з нуля: $($codexEmpty -join '|')"
        Assert-True ($vscode -match '"telemetry\.telemetryLevel": "off"' -and $vscode -match '// коментар' -and $vscode -match 'editor\.fontSize') 'VS Code: не вимкнено або загублено вміст'
        Assert-True (-not $bom) 'JSON записано з BOM (Node.js його не прочитає)'
        Assert-True ($backups -eq 3) "резервних копій: $backups, очікувалось 3 (лише для наявних файлів)"
        Assert-None (Compare-Object $first $second | ForEach-Object { $_.InputObject.Split('|')[0] }) 'повторний прогін змінив файли'
    }

    It 'Cursors без архіву: статус Skipped, без помилок і без змін у системі' {
        $dir = Join-Path ([IO.Path]::GetTempPath()) "postinstall-test-$([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path "$dir\tasks", "$dir\data", "$dir\assets\cursors" -Force | Out-Null
        Copy-Item "$script:ProjectRoot\tasks\96-Cursors.ps1" "$dir\tasks"
        Copy-Item "$script:ProjectRoot\data\cursors.psd1" "$dir\data"
        $null = Get-TaskStatus -Reset
        $errors = Get-ErrorRecords { & "$dir\tasks\96-Cursors.ps1" -WindowsDir "$dir\Windows" -RegistryBase "$script:hive\cursors" -SkipApply }
        $status = Get-TaskStatus -Reset
        $touched = ((Test-Path "$dir\Windows") -or (Test-Path "$script:hive\cursors"))
        Remove-Item -LiteralPath $dir -Recurse -Force
        Assert-True ($errors.Count -eq 0) "несподівані помилки: $($errors.Count)"
        Assert-True ($status -and $status.Status -eq 'Skipped') "статус: $(if ($status) { $status.Status } else { '<немає>' })"
        Assert-True (-not $touched) 'задача щось створила попри відсутність архіву'
    }
}