# Build the wallpaper, install it to %LOCALAPPDATA%\CommonWallpaper, start it now, and at every login.
# Needs the .NET 8 SDK (winget install Microsoft.DotNet.SDK.8) and the WebView2 runtime, which Windows 10 and 11 include.
$ErrorActionPreference = "Stop"
$dir = Join-Path $env:LOCALAPPDATA "CommonWallpaper\App"
$exe = Join-Path $dir "CommonWallpaper.exe"
$run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

Get-Process CommonWallpaper -ErrorAction SilentlyContinue | Stop-Process -Force
dotnet publish "$PSScriptRoot\CommonWallpaper.csproj" -c Release -o $dir
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Set-ItemProperty -Path $run -Name CommonWallpaper -Value "`"$exe`""
Start-Process $exe
Write-Host "Installed to $dir and started it; it will also start at login."
