# Скачивает последний win64 GPL-сборку FFmpeg (BtbN), кладёт ffmpeg.exe и ffprobe.exe
# в ту же папку, что и youtube-dl-gui.exe (так их находит Verification без PATH).
param(
    [string]$OutDir = (Join-Path $PSScriptRoot "..\youtube-dl-gui\bin\Debug")
)
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$tmp = Join-Path $env:TEMP ("ffmpeg_dl_" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp "ffmpeg.zip"
    $uri = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    Write-Host "Downloading $uri"
    curl.exe -sL $uri -o $zip
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $inner = Get-ChildItem -Path $tmp -Directory | Where-Object { $_.Name -like "ffmpeg-*" } | Select-Object -First 1
    if (-not $inner) { throw "Не найдена распакованная папка ffmpeg-*" }
    $bin = Join-Path $inner.FullName "bin"
    Copy-Item -Force (Join-Path $bin "ffmpeg.exe") (Join-Path $OutDir "ffmpeg.exe")
    Copy-Item -Force (Join-Path $bin "ffprobe.exe") (Join-Path $OutDir "ffprobe.exe")
    Get-Item (Join-Path $OutDir "ffmpeg.exe"), (Join-Path $OutDir "ffprobe.exe") | Format-List FullName, Length
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
