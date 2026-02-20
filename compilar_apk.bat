@echo off
echo ========================================
echo   Compilando APK de Tracktoger
echo ========================================
echo.

echo [1/4] Limpiando proyecto...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Fallo al limpiar el proyecto
    pause
    exit /b 1
)

echo.
echo [2/4] Obteniendo dependencias...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Fallo al obtener dependencias
    pause
    exit /b 1
)

echo.
echo [3/4] Verificando configuración...
call flutter doctor
if %errorlevel% neq 0 (
    echo ADVERTENCIA: Hay problemas con la configuración de Flutter
)

echo.
echo [4/4] Compilando APK de release...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Fallo al compilar la APK
    pause
    exit /b 1
)

echo.
echo ========================================
echo   APK compilada exitosamente!
echo ========================================
echo.
echo Ubicacion: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Para instalar en tu dispositivo:
echo   1. Conecta tu dispositivo por USB
echo   2. Ejecuta: adb install build\app\outputs\flutter-apk\app-release.apk
echo   3. O copia la APK manualmente a tu dispositivo
echo.
pause

