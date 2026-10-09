@{
    RootModule        = 'PostInstall.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '7f3c2a9e-5b41-4d8a-9c60-2e1f4b7a8d35'
    Description       = 'Хелпери для post-install конфігурації Windows: логування, статуси задач, перевірка передумов.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-TaskStatus'
        'Get-VerifiedDownload'
        'Install-AppPackage'
        'Invoke-LegacyScript'
        'Invoke-Native'
        'Set-RegValue'
        'Set-ServiceStartup'
        'Set-TaskStatus'
        'Test-Prerequisites'
        'Write-Step'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
