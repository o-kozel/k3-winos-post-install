function Set-RegValue {
    <#
    .SYNOPSIS
        Безпечний запис значення в реєстр: створює відсутній ключ, пропускає вже встановлене.
    .DESCRIPTION
        Set-ItemProperty не створює ключ, якщо його немає, а просто падає, тому в чистій
        системі багато політик-ключів ніколи не застосовувались. Ця функція:
          * створює ключ (і проміжні) за потреби;
          * порівнює і значення, і тип (рядок "0" не дорівнює DWord 0);
          * в логу показує Skip (вже встановлено) або "було -> стало";
          * підтримує -WhatIf / -Confirm.
        Успіх у лог пишеться лише після реального запису. Помилка не ковтається: при
        -ErrorAction Stop вона зупиняє задачу, інакше це одна помилка в потоці помилок
        (її рахує оркестратор), а виконання продовжується.
    .EXAMPLE
        Set-RegValue -Path 'HKCU:\Software\Microsoft\Clipboard' -Name EnableClipboardHistory -Value 1
    .EXAMPLE
        Set-RegValue -Path $key -Name StartLayoutFile -Value $file -Type String
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)] $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = 'DWord'
    )

    $display = "$Path\$Name"

    # Масиви порівнюються інакше, ніж скаляри, тому зводимо до рядка
    $asText = {
        param($v)
        if ($v -is [byte[]])        { [BitConverter]::ToString($v) }
        elseif ($v -is [string[]])  { $v -join '|' }
        else                        { "$v" }
    }

    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            if ($PSCmdlet.ShouldProcess($Path, 'Створити ключ реєстру')) {
                New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            }
        }

        $current = $null
        $currentKind = $null
        if (Test-Path -LiteralPath $Path) {
            $key = Get-Item -LiteralPath $Path -ErrorAction Stop
            if ($key.GetValueNames() -contains $Name) {
                $currentKind = $key.GetValueKind($Name)
                # Без розкриття %змінних% - порівнюємо те, що реально записано
                $current = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            }
        }

        if ($null -ne $currentKind -and $currentKind -eq $Type -and (& $asText $current) -eq (& $asText $Value)) {
            Write-Step "$display вже = $Value" -Level Skip
            return
        }

        $before = if ($null -eq $currentKind) { '<немає>' } else { & $asText $current }
        if ($PSCmdlet.ShouldProcess($display, "Встановити $Value ($Type)")) {
            Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
            Write-Step "$display : $before -> $(& $asText $Value)"
        }
    }
    catch {
        Write-Error -Message "Не вдалося записати ${display}: $($_.Exception.Message)" -Exception $_.Exception -Category WriteError -TargetObject $display
    }
}
