function Write-Step {
    <#
    .SYNOPSIS
        Єдиний спосіб виводу прогресу: рівень важливості -> колір і префікс.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Message,
        [ValidateSet('Header','Info','Warn','Error','Skip')][string] $Level = 'Info'
    )

    $color = @{
        Header = 'Cyan'; Info = 'DarkMagenta'; Warn = 'Yellow'; Error = 'Red'; Skip = 'DarkGray'
    }[$Level]
    $prefix = @{
        Header = '==='; Info = '  >'; Warn = '  !'; Error = ' !!'; Skip = '  -'
    }[$Level]

    # Час потрібен, щоб у журналі було видно, який крок забрав найбільше (напр. тихі операції в Configuration)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $prefix $Message" -ForegroundColor $color
}
