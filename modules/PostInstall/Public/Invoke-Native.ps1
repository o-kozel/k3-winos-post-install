function Invoke-Native {
    <#
    .SYNOPSIS
        Запускає зовнішню програму, чекає її завершення і перевіряє код виходу.
    .DESCRIPTION
        PowerShell не перевіряє код виходу нативних програм ($ErrorActionPreference на них
        не діє), тому невдалий bcdedit / powercfg / choco виглядає так само, як успішний.

        Чому Start-Process, а не оператор виклику (&):
          * & не чекає GUI-програм (O&O ShutUp10), і наступні рядки скрипта починають
            писати в ті самі ключі реєстру паралельно з ними;
          * є тайм-аут і робоча тека без Set-Location.
        Вивід програми перенаправляється у файли й друкується через Write-Host, тому він
        потрапляє в транскрипт (прямий вивід дочірнього процесу туди не потрапляє).

        Невдача (код поза -SuccessCodes) - це помилка в потоці помилок: з -ErrorAction Stop
        вона зупиняє задачу, інакше її лише видно й зараховує оркестратор. -IgnoreFailure
        знижує її до попередження.
    .PARAMETER Arguments
        Аргументи окремими елементами; пробіли й лапки екрануються самою функцією.
    .PARAMETER SuccessCodes
        Коди, які вважаються успіхом. Наприклад choco: 0, 1641, 3010 (потрібне перезавантаження).
    .PARAMETER TimeoutSeconds
        0 = чекати без обмеження. Після тайм-ауту процес завершується примусово.
    .EXAMPLE
        Invoke-Native -FilePath powercfg.exe -Arguments '-change','-monitor-timeout-ac','30'
    .EXAMPLE
        Invoke-Native -FilePath $tool -Arguments $cfg,'/quiet' -WorkingDirectory C:\Support\Scripts -TimeoutSeconds 600
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [string[]] $Arguments = @(),
        [int[]] $SuccessCodes = @(0),
        [string] $WorkingDirectory,
        [int] $TimeoutSeconds = 0,
        [switch] $IgnoreFailure
    )

    # Правила розбору командного рядка Windows: аргумент з пробілами/лапками береться в лапки,
    # лапки всередині екрануються, зворотні скісні риски перед ними подвоюються
    $quote = {
        param($a)
        if ($a -ne '' -and $a -notmatch '[\s"]') { return $a }
        $s = $a -replace '(\\*)"', '$1$1\"'
        $s = $s -replace '(\\+)$', '$1$1'
        '"' + $s + '"'
    }
    $argString = (@($Arguments) | ForEach-Object { & $quote $_ }) -join ' '
    $display = "$FilePath $argString".Trim()

    $stdout = $null
    $stderr = $null
    $failure = $null            # текст помилки; пишемо ОДИН раз після прибирання (throw+catch+Write-Error давали 4-5 записів)
    $ignorable = $false         # -IgnoreFailure стосується лише коду виходу, не відсутньої програми чи тайм-ауту
    try {
        # Не Select-Object -First 1: у Windows PowerShell 5.1 він лишає "фантомну" помилку StopUpstreamCommandsException
        $exe = @(Get-Command -Name $FilePath -CommandType Application -ErrorAction Stop)[0].Source

        Write-Step $display
        if (-not $PSCmdlet.ShouldProcess($display, 'Запустити')) { return }

        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()
        $start = @{
            FilePath               = $exe
            PassThru               = $true
            NoNewWindow            = $true
            RedirectStandardOutput = $stdout
            RedirectStandardError  = $stderr
        }
        if ($argString)         { $start.ArgumentList = $argString }
        if ($WorkingDirectory)  { $start.WorkingDirectory = $WorkingDirectory }

        $process = Start-Process @start
        # Звернення до Handle кешує дескриптор: без нього ExitCode у Windows PowerShell 5.1
        # після завершення процесу буває порожнім, і успішний запуск виглядає як збій
        $null = $process.Handle

        # WaitForExit, а не Start-Process -Wait: той чекає й на всі дочірні процеси
        $finished = $true
        if ($TimeoutSeconds -gt 0) {
            $finished = $process.WaitForExit($TimeoutSeconds * 1000)
            if (-not $finished) {
                try { $process.Kill() } catch { Write-Verbose "Не вдалося завершити процес: $($_.Exception.Message)" }
            }
        }
        else {
            $process.WaitForExit()
        }

        # Консольні утиліти пишуть у кодуванні консолі (OEM), а не ANSI
        $encoding = [Console]::OutputEncoding
        foreach ($file in $stdout, $stderr) {
            foreach ($line in [System.IO.File]::ReadAllLines($file, $encoding)) {
                if ($line.Trim()) { Write-Host "      $line" -ForegroundColor DarkGray }
            }
        }

        if (-not $finished) {
            $failure = "$FilePath не завершився за $TimeoutSeconds с і був зупинений"
        }
        else {
            $code = $process.ExitCode
            if ($null -eq $code) {
                $failure = "Не вдалося отримати код виходу $FilePath"
            }
            elseif ($code -notin $SuccessCodes) {
                $failure = "$FilePath завершився з кодом $code (очікувалось: $($SuccessCodes -join ', '))"
                $ignorable = $true
            }
        }
    }
    catch {
        $failure = $_.Exception.Message
    }
    finally {
        foreach ($file in $stdout, $stderr) {
            if ($file) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue }
        }
    }

    if ($failure) {
        if ($IgnoreFailure -and $ignorable) { Write-Step $failure -Level Warn }
        else { Write-Error -Message $failure -TargetObject $display }
    }
}
