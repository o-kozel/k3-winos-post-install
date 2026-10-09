#Requires -Version 5.1
# PowerShell 7, oh-my-posh, тема, шрифт, Terminal-Icons, налаштування Windows Terminal і профіль (RP п. 4.3).
#
# Windows PowerShell 5.1 - компонент ОС: його не можна оновити чи видалити. "Оновити до 7" означає поставити
# pwsh 7 поруч і зробити його оболонкою за замовчуванням; далі він сам оновлюється через Microsoft Update.
#
# Порядок має значення: тему, шрифт і модуль встановлюємо ДО копіювання профілю.
[CmdletBinding(SupportsShouldProcess)]
param(
    # Параметри нижче - лише для тестів; у бойовому прогоні стандартні значення
    [string] $PwshPath = (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
    [ValidateSet('Machine', 'User', 'Process')][string] $EnvironmentScope = 'Machine',
    [string] $ThemeUri = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/capr4n.omp.json'
)

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$profileSource = Join-Path $projectRoot 'PowerShell profile\Microsoft.PowerShell_profile.ps1'
$terminalScript = Join-Path $projectRoot 'PowerShell profile\Set-WindowsTerminalDefaults.ps1'
$winget = @{ SuccessCodes = 0, -1978335189, -1978335135 }     # 0, "немає застосовного оновлення", "уже встановлено"

function Update-ProcessPath {
    # Поточний процес не бачить змін PATH після інсталятора. Нові каталоги дописуємо В КІНЕЦЬ: наявний
    # порядок пошуку команд не змінюється (інакше щойно доданий каталог міг би затінити вже знайдену програму).
    $env:Path = (@($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) |
        Where-Object { $_ }) -join ';'
}

# ---------------------------------------------------------------- 1. PowerShell 7 (критично: без нього решта не має сенсу)
Write-Step 'PowerShell 7: встановлення / оновлення'
# winget, а не choco: офіційний MSI з USE_MU/ENABLE_MU - далі pwsh оновлюється через Windows Update.
# Якщо pwsh уже стоїть, winget install оновить його до актуальної версії.
Invoke-Native -FilePath winget -SuccessCodes $winget.SuccessCodes -WhatIf:$WhatIfPreference -ErrorAction Stop -Arguments @(
    'install', '--exact', '--id', 'Microsoft.PowerShell', '--source', 'winget', '--scope', 'machine',
    '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity',
    '--override', '/quiet /norestart ADD_PATH=1 USE_MU=1 ENABLE_MU=1 REGISTER_MANIFEST=1 ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1')

if ($WhatIfPreference) {
    Write-Step 'Сухий прогін: подальші кроки залежать від встановленого pwsh 7 і не показуються' -Level Warn
    return
}

Update-ProcessPath
if (-not (Test-Path -LiteralPath $PwshPath)) { throw "PowerShell 7 не знайдено після встановлення: $PwshPath" }
$version = (& $PwshPath -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') | Select-Object -Last 1
if ($LASTEXITCODE -ne 0 -or -not $version -or [int](($version -split '\.')[0]) -lt 7) {
    throw "$PwshPath повернув неочікувану версію: '$version'"
}
Write-Step "PowerShell $version встановлено"

# Шлях профілю питаємо в самого pwsh: $PROFILE під 5.1 вказує на WindowsPowerShell, а Documents може
# бути перенесено в OneDrive, тож жорсткий $HOME\Documents не годиться.
$pwshProfile = (& $PwshPath -NoLogo -NoProfile -Command '$PROFILE.CurrentUserCurrentHost') | Select-Object -Last 1
if (-not $pwshProfile) { throw 'pwsh не повернув шлях до свого профілю' }

# ---------------------------------------------------------------- 2. решта кроків: збій одного не зупиняє інші
$failed = New-Object System.Collections.Generic.List[string]
function Invoke-ShellStep {
    param([string] $Title, [scriptblock] $Body)
    try { & $Body }
    catch {
        $failed.Add($Title)
        Write-Step "$Title : $($_.Exception.Message)" -Level Warn
    }
}

Invoke-ShellStep 'Змінні середовища pwsh' {
    # Телеметрія pwsh off (узгоджено з O&O ShutUp у Configuration.ps1); сповіщення про нову версію off -
    # оновлення приходять через Microsoft Update.
    foreach ($pair in @(@('POWERSHELL_TELEMETRY_OPTOUT', '1'), @('POWERSHELL_UPDATECHECK', 'Off'))) {
        if ($PSCmdlet.ShouldProcess($pair[0], "Встановити $($pair[1]) ($EnvironmentScope)")) {
            [Environment]::SetEnvironmentVariable($pair[0], $pair[1], $EnvironmentScope)
            Write-Step "$($pair[0]) = $($pair[1])"
        }
    }
}

$themesDir = Join-Path (Split-Path -Path $pwshProfile -Parent) 'themes'
Invoke-ShellStep 'Тека тем' {
    New-Item -ItemType Directory -Path $themesDir -Force | Out-Null
}

$ompReady = $false
Invoke-ShellStep 'oh-my-posh' {
    Install-AppPackage -Id JanDeDobbeleer.OhMyPosh -Source winget -WhatIf:$WhatIfPreference -ErrorAction Stop
    Update-ProcessPath
    if (-not (Get-Command oh-my-posh -CommandType Application -ErrorAction Ignore)) { throw 'oh-my-posh не знайдено в PATH після встановлення' }
    $script:ompReady = $true
}

Invoke-ShellStep 'Тема capr4n' {
    # Це JSON без підпису, тому без -RequireSignature; цінність функції тут - обробка помилок і файл під тимчасовим іменем
    Get-VerifiedDownload -Uri $ThemeUri -OutFile (Join-Path $themesDir 'capr4n.omp.json') | Out-Null
}

if ($ompReady) {
    Invoke-ShellStep 'Nerd Font (Meslo)' {
        # Вбудований інсталятор oh-my-posh - без вгадування Id пакета у winget
        Invoke-Native -FilePath oh-my-posh -Arguments 'font', 'install', 'meslo' -TimeoutSeconds 600 -WhatIf:$WhatIfPreference -ErrorAction Stop
    }
}
else {
    $failed.Add('Nerd Font (Meslo)')
    Write-Step 'Nerd Font пропущено: oh-my-posh не встановлено' -Level Warn
}

Invoke-ShellStep 'Модуль Terminal-Icons' {
    # Ставимо зсередини pwsh: Install-Module під 5.1 кладе модулі у WindowsPowerShell\Modules, і pwsh 7 їх не бачить
    Invoke-Native -FilePath $PwshPath -WhatIf:$WhatIfPreference -ErrorAction Stop -Arguments @(
        '-NoLogo', '-NoProfile', '-Command', 'Install-PSResource -Name Terminal-Icons -Scope CurrentUser -TrustRepository -Quiet')
    $installed = (& $PwshPath -NoLogo -NoProfile -Command '(Get-Module -ListAvailable -Name Terminal-Icons | Select-Object -First 1).Name') | Select-Object -Last 1
    if ($installed -ne 'Terminal-Icons') { throw 'Terminal-Icons не з''явився серед встановлених модулів pwsh' }
}

Invoke-ShellStep 'Windows Terminal' {
    # pwsh - профіль за замовчуванням, Meslo Nerd Font - шрифт (інакше значки oh-my-posh будуть квадратиками)
    Invoke-Native -FilePath $PwshPath -Arguments '-NoLogo', '-NoProfile', '-File', $terminalScript -WhatIf:$WhatIfPreference -ErrorAction Stop
}

# Профіль копіюємо останнім - коли тема, шрифт і модуль уже на місці. Лише Copy-Item (з -Force на ФАЙЛ він
# перезаписує вміст коректно; New-Item -Force на існуючий файл його б обнулив).
Invoke-ShellStep 'Профіль pwsh' {
    if ($PSCmdlet.ShouldProcess($pwshProfile, 'Скопіювати профіль')) {
        Copy-Item -LiteralPath $profileSource -Destination $pwshProfile -Force -ErrorAction Stop
        Write-Step "Профіль скопійовано: $pwshProfile"
    }
}

if ($failed.Count -gt 0) {
    Set-TaskStatus -Status Warn -Message "не вдалося: $($failed -join '; ')"
}
