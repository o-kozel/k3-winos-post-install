function Test-Prerequisites {
    <#
    .SYNOPSIS
        Перевіряє передумови до початку роботи. Критичне — виняток, решта — попередження.
    #>
    [CmdletBinding()]
    param()

    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Потрібні права адміністратора. Запустіть PowerShell від імені адміністратора.'
    }

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    if ([version]$os.Version -lt [version]'10.0') {
        throw "$($os.Caption) ($($os.Version)) не підтримується: потрібна Windows 10 або новіша."
    }
    Write-Step "$($os.Caption), збірка $build, PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
    if ($build -lt 22000) {
        Write-Step 'Це Windows 10: частина твіків розрахована на Windows 11 і нічого не зробить' -Level Warn
    }

    # Інтернет потрібен для Chocolatey/winget/O&O ShutUp. Це попередження, а не відмова:
    # частину конфігурації (реєстр, служби, живлення) можна застосувати й офлайн.
    $client = New-Object System.Net.Sockets.TcpClient
    $online = $false
    try {
        $async = $client.BeginConnect('github.com', 443, $null, $null)
        if ($async.AsyncWaitHandle.WaitOne(3000)) {
            $client.EndConnect($async)
            $online = $true
        }
    }
    catch {
        $online = $false
    }
    finally {
        $client.Close()
    }
    if (-not $online) {
        Write-Step 'Немає доступу до інтернету: завантаження та встановлення ПО не спрацюють' -Level Warn
    }
}
