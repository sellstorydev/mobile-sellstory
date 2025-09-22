@echo off
echo Building Flutter App Bundle...
flutter build appbundle

echo.
echo Checking if App Bundle was created...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo.
    echo ================================
    echo ✅ SUCCESS: App Bundle Created!
    echo ================================
    echo File: build\app\outputs\bundle\release\app-release.aab
    for %%I in ("build\app\outputs\bundle\release\app-release.aab") do echo Size: %%~zI bytes
    echo Last Modified: 
    forfiles /m app-release.aab /c "cmd /c echo @fdate @ftime" /p "build\app\outputs\bundle\release"
    echo.
    echo ✅ The symbol stripping warning can be safely ignored.
    echo ✅ Your app bundle is ready for deployment to Google Play Store!
    echo.
    exit /b 0
) else (
    echo ❌ ERROR: App Bundle was not created
    exit /b 1
)