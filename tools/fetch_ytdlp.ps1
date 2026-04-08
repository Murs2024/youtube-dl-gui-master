# Скачивает yt-dlp.exe рядом с собранным GUI (по умолчанию youtube-dl-gui\bin\Debug).
param(
    [string]$OutDir = (Join-Path $PSScriptRoot "..\youtube-dl-gui\bin\Debug")
)
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$dest = Join-Path $OutDir "yt-dlp.exe"
$uri = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
Write-Host "Downloading $uri -> $dest"
curl.exe -sL $uri -o $dest
Get-Item $dest | Format-List FullName, Length, LastWriteTime
