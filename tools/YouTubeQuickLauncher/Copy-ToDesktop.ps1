$ErrorActionPreference = "Stop"
$desk = [Environment]::GetFolderPath("Desktop")
$here = $PSScriptRoot
Copy-Item -LiteralPath (Join-Path $here "YouTubeQuickLauncher.bat") -Destination $desk -Force
Copy-Item -LiteralPath (Join-Path $here "YouTubeQuickLauncher.ps1") -Destination $desk -Force
Write-Host "OK: Desktop now has YouTubeQuickLauncher.bat and YouTubeQuickLauncher.ps1"
