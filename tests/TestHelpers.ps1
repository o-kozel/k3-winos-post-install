# Спільні допоміжні функції тестів. Підключається з BeforeAll кожного Describe (крапка-пробіл), бо Pester 5
# не бачить у тестах функцій, оголошених поза BeforeAll.
#
# Перевірки написано через throw, а не Should: Pester 3.4 (вбудований у Windows PowerShell 5.1) розуміє лише
# `Should Be`, а Pester 5 - лише `Should -Be`; throw працює в усіх версіях, і повідомлення пояснює, що саме не так.

$script:ProjectRoot = Split-Path -Path $PSScriptRoot -Parent

function Assert-True {
    param($Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-None {
    # Падає, якщо список порушників не порожній; у повідомленні - самі порушники
    param($Items, [string] $What)
    $list = @($Items | Where-Object { $_ })
    if ($list.Count -gt 0) { throw "$What`: $($list -join '; ')" }
}

function Get-ScriptFiles {
    # Усі скрипти проєкту, включно з підтеками (вони теж мають бути коректними)
    Get-ChildItem -LiteralPath $script:ProjectRoot -Recurse -File |
        Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1' }
}

function Get-RelativePath {
    param([string] $Path)
    $Path.Substring($script:ProjectRoot.Length).TrimStart('\')
}

function Get-ParsedFile {
    param([string] $Path)
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)
    [pscustomobject]@{ Ast = $ast; Errors = @($errors) }
}

function Get-CommandCalls {
    # Усі виклики команди за іменем у файлі (за AST: коментарі й рядки не враховуються)
    param([string] $Path, [string[]] $Name)
    $parsed = Get-ParsedFile $Path
    $parsed.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in $Name }, $true)
}

function Test-HasUtf8Bom {
    param([string] $Path)
    $b = [IO.File]::ReadAllBytes($Path)
    $b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF
}

function Test-HasNonAscii {
    param([string] $Path)
    foreach ($byte in [IO.File]::ReadAllBytes($Path)) { if ($byte -gt 127) { return $true } }
    $false
}

function Get-ErrorRecords {
    # Скільки помилок справді потрапило в ПОТІК помилок (так рахує і Invoke-LegacyScript)
    param([scriptblock] $Block)
    $ErrorActionPreference = 'Continue'   # помилки мають потрапляти в потік, а не обривати тест, хоч би з якою політикою його запущено
    @(& $Block 2>&1 6>$null | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
}
