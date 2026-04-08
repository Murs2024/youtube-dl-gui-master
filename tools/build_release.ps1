# Сборка solution в Release (MSBuild из Visual Studio).
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$sln = Join-Path $root "youtube-dl-gui.sln"
$candidates = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
$msb = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $msb) {
    Write-Error "MSBuild не найден. Установите Visual Studio 2022 или Build Tools."
}
& $msb $sln /p:Configuration=Release /v:m
