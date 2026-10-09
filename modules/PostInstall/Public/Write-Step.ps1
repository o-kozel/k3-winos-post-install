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

    Write-Host "$prefix $Message" -ForegroundColor $color
}
