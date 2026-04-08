# Копирует yt-dlp.exe (и ffmpeg/ffprobe, если есть) из bin\Debug в bin\Release.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$debug = Join-Path $root "youtube-dl-gui\bin\Debug"
$release = Join-Path $root "youtube-dl-gui\bin\Release"
if (-not (Test-Path $release)) {
    Write-Error "Нет папки Release. Сначала: .\tools\build_release.ps1"
}
foreach ($name in @("yt-dlp.exe", "ffmpeg.exe", "ffprobe.exe")) {
    $src = Join-Path $debug $name
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $release $name)
        Write-Host "OK $name -> Release"
    }
}
