#Requires -Version 5.1
<#
Собирает полный «портативный» комплект для публикации на GitHub Releases.

Делает:
  1) (по умолчанию) запускает build.ps1 → Release;
  2) копирует всё из youtube-dl-gui\bin\Release в release-staging\MursMedia-<тег>-portable\;
  3) создаёт ZIP с тем же именем;
  4) пишет SHA-256 в *-exe-sha256.txt; копирует шаблон в release-staging\github-release-body-template.md; готовое описание в *-GITHUB-RELEASE-BODY.md.

Использование (из корня репозитория):
  powershell -ExecutionPolicy Bypass -File .\prepare-github-release.ps1
  powershell -ExecutionPolicy Bypass -File .\prepare-github-release.ps1 -VersionTag 1.0.0
  powershell -ExecutionPolicy Bypass -File .\prepare-github-release.ps1 -SkipBuild

На GitHub в Assets загрузите:
  • youtube-dl-gui.exe (отдельным файлом — обязательно для автообновления);
  • опционально ZIP из release-staging для удобной ручной установки.
#>
param(
    [string]$VersionTag = '1.0.0',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
$releaseDir = Join-Path $RepoRoot 'youtube-dl-gui\bin\Release'
$buildScript = Join-Path $RepoRoot 'build.ps1'

if (-not $SkipBuild) {
    if (-not (Test-Path -LiteralPath $buildScript)) {
        throw "Не найден build.ps1: $buildScript"
    }
    & $buildScript
}

$mainExe = Join-Path $releaseDir 'youtube-dl-gui.exe'
if (-not (Test-Path -LiteralPath $mainExe)) {
    throw @"
Не найден: $mainExe
Соберите Release (build.ps1) или уберите флаг -SkipBuild.
"@
}

$stagingRoot = Join-Path $RepoRoot 'release-staging'
$folderName = "MursMedia-$VersionTag-portable"
$destFolder = Join-Path $stagingRoot $folderName

New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
if (Test-Path -LiteralPath $destFolder) {
    Remove-Item -LiteralPath $destFolder -Recurse -Force
}

Write-Host ('Copy: ' + $releaseDir + ' -> ' + $destFolder)
Copy-Item -LiteralPath $releaseDir -Destination $destFolder -Recurse

$copiedExe = Join-Path $destFolder 'youtube-dl-gui.exe'
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $copiedExe).Hash.ToLowerInvariant()
$hashFile = Join-Path $stagingRoot "$folderName-exe-sha256.txt"
# UTF-8 with BOM so Notepad shows correctly; ASCII hint avoids mojibake from .ps1 encoding.
$hashFileBody = "exe sha256: $hash`r`n`r`nPaste the first line into GitHub Release notes only.`r`n"
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($hashFile, $hashFileBody, $utf8Bom)

$templatePath = Join-Path $RepoRoot 'github-release-body-template.md'
$releaseBodyOut = Join-Path $stagingRoot "$folderName-GITHUB-RELEASE-BODY.md"
$templateCopyInStaging = Join-Path $stagingRoot 'github-release-body-template.md'
if (Test-Path -LiteralPath $templatePath) {
    Copy-Item -LiteralPath $templatePath -Destination $templateCopyInStaging -Force
    $templateRaw = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
    $releaseBody = $templateRaw.Replace('{{TAG}}', $VersionTag).Replace('{{SHA256}}', $hash)
    [System.IO.File]::WriteAllText($releaseBodyOut, $releaseBody, $utf8Bom)
}

$zipPath = Join-Path $stagingRoot "$folderName.zip"
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path $destFolder -DestinationPath $zipPath -CompressionLevel Optimal -Force

Write-Host ''
Write-Host 'Done.'
Write-Host ('  Portable folder: ' + $destFolder)
Write-Host ('  Zip archive:     ' + $zipPath)
Write-Host ('  Release notes line: exe sha256: ' + $hash)
Write-Host ('  Hash saved to:   ' + $hashFile)
if (Test-Path -LiteralPath $releaseBodyOut) {
    Write-Host ('  GitHub description (copy all): ' + $releaseBodyOut)
}
if (Test-Path -LiteralPath $templateCopyInStaging) {
    Write-Host ('  Template copy in staging:      ' + $templateCopyInStaging)
}
Write-Host ''
Write-Host 'Upload to GitHub Release Assets:'
Write-Host ('  1) ' + $copiedExe)
Write-Host '     (rename on GitHub if needed to exactly: youtube-dl-gui.exe)'
Write-Host ('  2) optional zip: ' + $zipPath)
