function Set-TaskStatus {
    <#
    .SYNOPSIS
        Задача повідомляє оркестратору, що завершилась не просто «OK».
    .DESCRIPTION
        Без виклику статус задачі — OK (або WHATIF у сухому прогоні). Warn означає
        «виконалась, але були помилки, які не зупинили її»; Skipped - задача свідомо нічого не робила
        (напр., немає потрібного файлу) і це очікуваний стан. Падіння задачі — це
        виняток (throw), а не статус.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Warn','WhatIf','Skipped')][string] $Status,
        [string] $Message
    )

    $script:TaskStatus = [pscustomobject]@{ Status = $Status; Message = $Message }
}
