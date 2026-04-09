#Requires -Version 5.1
<#
Creates a Windows Desktop shortcut to youtube-dl-gui.exe.
Prefers Release build; falls back to Debug. Sets "Start in" to the exe folder.

Usage (from repo root):
  powershell -ExecutionPolicy Bypass -File .\create-desktop-shortcut.ps1
  powershell -ExecutionPolicy Bypass -File .\create-desktop-shortcut.ps1 -PreferDebug
  powershell -ExecutionPolicy Bypass -File .\create-desktop-shortcut.ps1 -ExePath "D:\path\youtube-dl-gui.exe"
#>
param(
    [string]$ExePath = "",
    [switch]$PreferDebug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

$release = Join-Path $RepoRoot 'youtube-dl-gui\bin\Release\youtube-dl-gui.exe'
$debug = Join-Path $RepoRoot 'youtube-dl-gui\bin\Debug\youtube-dl-gui.exe'

if ($ExePath) {
    if (-not (Test-Path -LiteralPath $ExePath)) {
        throw "File not found: $ExePath"
    }
    $target = (Resolve-Path -LiteralPath $ExePath).Path
}
elseif ($PreferDebug -and (Test-Path -LiteralPath $debug)) {
    $target = (Resolve-Path -LiteralPath $debug).Path
}
elseif (Test-Path -LiteralPath $release) {
    $target = (Resolve-Path -LiteralPath $release).Path
}
elseif (Test-Path -LiteralPath $debug) {
    $target = (Resolve-Path -LiteralPath $debug).Path
}
else {
    throw @"
youtube-dl-gui.exe not found under:
  $release
  $debug
Build the solution in Visual Studio first, or pass -ExePath with the full path to the exe.
"@
}

$workDir = Split-Path -Parent $target

# App reads translations from .\lang\*.ini next to the exe (see frmLanguage.cs).
$langSrc = Join-Path $RepoRoot 'Languages'
$langDst = Join-Path $workDir 'lang'
if (Test-Path -LiteralPath $langSrc) {
    New-Item -ItemType Directory -Force -Path $langDst | Out-Null
    Copy-Item -Path (Join-Path $langSrc '*.ini') -Destination $langDst -Force
    Write-Host "Languages: copied .ini files to $langDst"
}
else {
    Write-Host "Languages: folder not found at $langSrc (only English Internal in the app)"
}

$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop 'Murs Media.lnk'

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($lnkPath)
$shortcut.TargetPath = $target
$shortcut.WorkingDirectory = $workDir
$shortcut.Description = 'Murs Media (youtube-dl-gui)'
# Icon from the exe itself (index 0) so the desktop shows the current embedded icon, not a cached image.
$shortcut.IconLocation = "$target,0"
$shortcut.Save()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null

Write-Host "Shortcut: $lnkPath"
Write-Host "Target:   $target"
Write-Host "Start in: $workDir"
