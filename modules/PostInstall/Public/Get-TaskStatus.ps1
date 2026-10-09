function Get-TaskStatus {
    <#
    .SYNOPSIS
        Читає статус, виставлений задачею через Set-TaskStatus (або $null).
    #>
    [CmdletBinding()]
    param(
        # Скинути статус після читання (оркестратор робить це перед кожною задачею)
        [switch] $Reset
    )

    $current = $script:TaskStatus
    if ($Reset) { $script:TaskStatus = $null }
    $current
}
