function Get-VerifiedDownload {
    <#
    .SYNOPSIS
        Завантажує файл і, за потреби, перевіряє цифровий підпис, перш ніж віддати його.
    .DESCRIPTION
        Виконуваний файл з інтернету запускається з правами адміністратора - це єдине місце
        проєкту, де скрипт довіряє зовнішньому коду повні права на систему. Тому:
          * файл спершу потрапляє у тимчасове ім'я, а в -OutFile - лише після перевірки;
          * невалідний підпис або підпис не того видавця = файл видаляється і кидається
            виняток (свідомо throw, а не Write-Error: викликач має зупинитись, а не йти далі).
        Перевірка підпису відсікає підмінений або побитий файл, але не доводить, що сам
        видавець надійний.
    .PARAMETER ExpectedSigner
        Фрагмент імені видавця в сертифікаті (Subject). Вмикає -RequireSignature.
    .OUTPUTS
        Шлях до завантаженого файлу.
    .EXAMPLE
        Get-VerifiedDownload -Uri $url -OutFile C:\Support\Scripts\tool.exe -ExpectedSigner 'O&O Software'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Uri,
        [Parameter(Mandatory)][string] $OutFile,
        [switch] $RequireSignature,
        [string] $ExpectedSigner
    )

    if ($ExpectedSigner) { $RequireSignature = $true }
    if (-not $PSCmdlet.ShouldProcess($Uri, "Завантажити в $OutFile")) { return }

    $directory = Split-Path -Path $OutFile -Parent
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    $partial = "$OutFile.download"
    try {
        # Windows PowerShell 5.1 за замовчуванням не вмикає TLS 1.2; індикатор прогресу сильно сповільнює завантаження
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
        $ProgressPreference = 'SilentlyContinue'

        Write-Step "Завантаження $Uri"
        Invoke-WebRequest -Uri $Uri -OutFile $partial -UseBasicParsing -ErrorAction Stop

        if ($RequireSignature) {
            $signature = Get-AuthenticodeSignature -FilePath $partial
            if ($signature.Status -ne 'Valid') {
                throw "Підпис $Uri невалідний ($($signature.Status)) - файл видалено"
            }
            $subject = $signature.SignerCertificate.Subject
            if ($ExpectedSigner -and $subject -notlike "*$ExpectedSigner*") {
                throw "Файл підписано не тим видавцем: '$subject' (очікувався '$ExpectedSigner') - файл видалено"
            }
            Write-Step "Підпис перевірено: $subject"
        }

        Move-Item -LiteralPath $partial -Destination $OutFile -Force
        $OutFile
    }
    finally {
        if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue }
    }
}
