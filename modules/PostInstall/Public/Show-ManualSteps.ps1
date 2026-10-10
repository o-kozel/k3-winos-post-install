function Show-ManualSteps {
    <#
    .SYNOPSIS
        Друкує ручні кроки після прогону з data\manual-steps.psd1 і за потреби зберігає їх у текстовий файл.
    .DESCRIPTION
        Крок із полем Task показується, лише якщо ця задача є в -Task (тобто виконувалась у прогоні);
        крок без Task показується завжди. Розділи йдуть у порядку першої появи у файлі даних.
        Файл - не зміна системи, тому пишеться й у сухому прогоні, як і журнал.
    .PARAMETER Task
        Імена задач, які виконувались (не SKIPPED).
    .PARAMETER OutFile
        Куди зберегти той самий текст (UTF-8 з BOM - щоб Блокнот і 5.1 читали кирилицю).
    .EXAMPLE
        Show-ManualSteps -Path .\data\manual-steps.psd1 -Task Configuration, Software
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path,
        [string[]] $Task = @(),
        [string] $OutFile
    )

    $steps = @((Import-PowerShellDataFile -Path $Path).Steps | Where-Object { -not $_.Task -or $_.Task -in $Task })
    if ($steps.Count -eq 0) { return }

    $text = New-Object System.Collections.Generic.List[string]
    Write-Step 'ЗРОБІТЬ ВРУЧНУ' -Level Header
    $text.Add('ЗРОБІТЬ ВРУЧНУ після post-install')

    $groups = @($steps | ForEach-Object { $_.Group } | Select-Object -Unique)
    foreach ($group in $groups) {
        Write-Host ''
        Write-Host "  [$group]" -ForegroundColor Cyan
        $text.Add('')
        $text.Add("[$group]")
        $number = 0
        foreach ($step in @($steps | Where-Object { $_.Group -eq $group })) {
            $number++
            Write-Host "  $number. $($step.Title)" -ForegroundColor Yellow
            $text.Add("$number. $($step.Title)")
            foreach ($line in @($step.How)) {
                Write-Host "       $line"
                $text.Add("     $line")
            }
        }
    }

    if ($OutFile) {
        # Не Set-Content -Encoding UTF8: у PowerShell 7 він пише без BOM
        [IO.File]::WriteAllLines($OutFile, $text.ToArray(), (New-Object System.Text.UTF8Encoding $true))
        Write-Host ''
        Write-Step "Цей список збережено: $OutFile" -Level Info
    }
}
