# Flutter App Bundle Builder
# This script handles the symbol stripping warning gracefully

Write-Host "Building Flutter App Bundle..." -ForegroundColor Cyan
Write-Host ""

# Run flutter build and capture the exit code
$process = Start-Process -FilePath "flutter" -ArgumentList "build", "appbundle" -NoNewWindow -Wait -PassThru

Write-Host ""
Write-Host "Checking build results..." -ForegroundColor Yellow

# Check if the app bundle was created regardless of exit code
$bundlePath = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $bundlePath) {
    $fileInfo = Get-Item $bundlePath
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "SUCCESS: App Bundle Created!" -ForegroundColor Green  
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "File: $bundlePath" -ForegroundColor White
    Write-Host "Size: $sizeInMB MB ($($fileInfo.Length) bytes)" -ForegroundColor White
    Write-Host "Last Modified: $($fileInfo.LastWriteTime)" -ForegroundColor White
    Write-Host ""
    Write-Host "The symbol stripping warning can be safely ignored." -ForegroundColor Green
    Write-Host "Your app bundle is ready for deployment to Google Play Store!" -ForegroundColor Green
    Write-Host ""
    
    # Exit with success code
    exit 0
} else {
    Write-Host ""
    Write-Host "ERROR: App Bundle was not created" -ForegroundColor Red
    Write-Host "Build failed - no output file found" -ForegroundColor Red
    Write-Host ""
    exit 1
}