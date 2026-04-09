#Requires -Version 5.1
<#
Build youtube-dl-gui.sln with MSBuild (no Visual Studio IDE required if Build Tools are installed).

Usage (from repo root):
  powershell -ExecutionPolicy Bypass -File .\build.ps1
  powershell -ExecutionPolicy Bypass -File .\build.ps1 -Configuration Debug
  powershell -ExecutionPolicy Bypass -File .\build.ps1 -ErrorsOnly   # MSBuild: hide warnings (not C# only)

Requires: Visual Studio 2022 Build Tools (or full VS) with ".NET desktop development" + .NET Framework 4.7.2 targeting.
#>
param(
    [ValidateSet('Release', 'Debug')]
    [string]$Configuration = 'Release',

    # Only print errors (hides compiler warnings — prefer fixing code instead).
    [switch]$ErrorsOnly
)

$ErrorActionPreference = 'Stop'

function Get-MsBuildPath {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $found = & $vswhere -latest -products * -find 'MSBuild\**\Bin\MSBuild.exe' 2>$null
        if ($found) {
            return ($found | Select-Object -First 1)
        }
    }

    $suffixes = @(
        'MSBuild\Current\Bin\MSBuild.exe',
        'MSBuild\15.0\Bin\MSBuild.exe'
    )
    $roots = @(
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\BuildTools'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Community'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Professional'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Enterprise'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2019\BuildTools'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2019\Community')
    )
    foreach ($root in $roots) {
        foreach ($s in $suffixes) {
            $exe = Join-Path $root $s
            if (Test-Path -LiteralPath $exe) {
                return $exe
            }
        }
    }
    return $null
}

$RepoRoot = $PSScriptRoot
$sln = Join-Path $RepoRoot 'youtube-dl-gui.sln'
if (-not (Test-Path -LiteralPath $sln)) {
    throw "Solution not found: $sln"
}

$msbuild = Get-MsBuildPath
if (-not $msbuild) {
    throw @"
MSBuild.exe not found.
Install "Build Tools for Visual Studio 2022" from https://visualstudio.microsoft.com/downloads/
and select workload ".NET desktop build tools" (or full VS 2022 with ".NET desktop development"),
including .NET Framework 4.7.2 targeting / developer pack.
"@
}

Write-Host "MSBuild: $msbuild"
Write-Host "Solution: $sln"
Write-Host "Configuration: $Configuration"
Write-Host ""

$exeName = 'youtube-dl-gui'
$running = @(Get-Process -Name $exeName -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    $pids = ($running | ForEach-Object { $_.Id }) -join ', '
    throw @"
Сборка не может заменить ${exeName}.exe: программа уже запущена (PID: $pids).
Закройте окно Murs Media / youtube-dl-gui и снова запустите build.ps1.

(Ошибка MSBuild MSB3027 / «файл используется другим процессом» — из‑за этого.)
"@
}

$msbuildArgs = @(
    $sln,
    "/p:Configuration=$Configuration",
    '/p:Platform=Any CPU',
    '/v:m',
    '/nologo'
)
if ($ErrorsOnly) {
    $msbuildArgs += '/clp:ErrorsOnly'
}

& $msbuild @msbuildArgs
$code = $LASTEXITCODE
if ($code -ne 0) {
    exit $code
}

$exe = Join-Path $RepoRoot "youtube-dl-gui\bin\$Configuration\youtube-dl-gui.exe"
Write-Host ""
Write-Host "Build OK: $exe"
