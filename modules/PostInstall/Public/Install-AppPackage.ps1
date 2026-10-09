function Install-AppPackage {
    <#
    .SYNOPSIS
        Встановлює пакет через Chocolatey або winget неінтерактивно, з перевіркою коду виходу.
    .DESCRIPTION
        Назва саме Install-AppPackage, а не Install-Package: остання вже є у вбудованому модулі
        PackageManagement, і власна функція перекривала б її.

        Прапорці - це умова працездатності, а не зручність: будь-який інтерактивний запит у
        неінтерактивному скрипті - це нескінченне очікування.
          * winget: --exact --id (пошук за підрядком з кількома збігами зависає на запиті вибору
            або ставить не той пакет), --accept-*-agreements, --disable-interactivity.
          * choco: -y завжди (без нього git.install чекав підтвердження), --no-progress.
        Невдача - помилка (Write-Error з Invoke-Native); цикл-викликач вирішує, що робити далі.
    .PARAMETER Params
        Лише для choco: рядок параметрів пакета, напр. '/GitAndUnixToolsOnPath /NoAutoCrlf'.
        Функція сама загортає його в одинарні лапки, як вимагає Chocolatey.
    .PARAMETER Comment
        Довідковий текст з data\packages.psd1; не використовується (дозволяє передавати запис цілим: @package).
    .EXAMPLE
        Install-AppPackage -Id 7zip
    .EXAMPLE
        Install-AppPackage -Id LocalSend.LocalSend -Source winget
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Id,
        [ValidateSet('choco', 'winget')][string] $Source = 'choco',
        [string] $Params,
        [string] $Comment
    )

    if (-not $PSCmdlet.ShouldProcess($Id, "Встановити через $Source")) { return }

    switch ($Source) {
        'choco' {
            $arguments = @('install', $Id, '-y', '--no-progress')
            if ($Params) { $arguments += @('--params', "'$Params'") }
            # 0 - успіх; 1641 і 3010 - успіх, але потрібне перезавантаження
            Invoke-Native -FilePath choco -Arguments $arguments -SuccessCodes 0, 1641, 3010
        }
        'winget' {
            if ($Params) { Write-Step "Params ігнорується для winget ($Id)" -Level Warn }
            $arguments = @(
                'install', '--exact', '--id', $Id, '--source', 'winget',
                '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
            )
            # Крім 0: 0x8A15002B (-1978335189) - немає застосовного оновлення, 0x8A150061 (-1978335135) - уже встановлено
            Invoke-Native -FilePath winget -Arguments $arguments -SuccessCodes 0, -1978335189, -1978335135
        }
    }
}
