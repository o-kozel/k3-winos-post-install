#Requires -Version 5.1
# ТИМЧАСОВО (Етап 1): обгортка над старим Configuration.ps1.
# Зникне, коли вміст скрипта розійдеться по tasks\20-Power.ps1 ... 80-Debloat.ps1 (Етапи 2-3).
[CmdletBinding()]
param()

$legacy = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Configuration.ps1'))
Invoke-LegacyScript -Path $legacy -DryRun:$WhatIfPreference
