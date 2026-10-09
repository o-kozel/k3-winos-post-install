# Профіль PowerShell 7 (pwsh). Розгортається задачею tasks\95-Shell.ps1.
# themes catalogue	https://ohmypo.sh/docs/themes
# capr4n		https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/capr4n.omp.json

# Кожен блок захищено перевіркою — профіль не має падати, якщо чогось бракує
$themeFile = Join-Path (Split-Path $PROFILE) 'themes\capr4n.omp.json'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    if (Test-Path $themeFile) { oh-my-posh init pwsh --config $themeFile | Invoke-Expression }
    else                      { oh-my-posh init pwsh | Invoke-Expression }   # тема за замовчуванням
}

if (Get-Module -ListAvailable -Name Terminal-Icons) { Import-Module -Name Terminal-Icons }

# PSReadLine: підказки з історії списком + пошук в історії за префіксом стрілками
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
