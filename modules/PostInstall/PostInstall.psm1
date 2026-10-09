# Завантажувач модуля: підключає кожен файл з Public\ (ім'я файлу = ім'я функції).
$script:TaskStatus = $null

$public = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File)
foreach ($file in $public) {
    . $file.FullName
}

Export-ModuleMember -Function $public.BaseName
