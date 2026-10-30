# Stop the wallpaper and remove it and its startup entry.
Get-Process CommonWallpaper -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name CommonWallpaper -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $env:LOCALAPPDATA "CommonWallpaper") -ErrorAction SilentlyContinue
Write-Host "Removed."
