#!/bin/bash

echo "========================================"
echo "  Compilando APK de Tracktoger"
echo "========================================"
echo ""

echo "[1/4] Limpiando proyecto..."
flutter clean
if [ $? -ne 0 ]; then
    echo "ERROR: Fallo al limpiar el proyecto"
    exit 1
fi

echo ""
echo "[2/4] Obteniendo dependencias..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Fallo al obtener dependencias"
    exit 1
fi

echo ""
echo "[3/4] Verificando configuración..."
flutter doctor

echo ""
echo "[4/4] Compilando APK de release..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "ERROR: Fallo al compilar la APK"
    exit 1
fi

echo ""
echo "========================================"
echo "  APK compilada exitosamente!"
echo "========================================"
echo ""
echo "Ubicación: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "Para instalar en tu dispositivo:"
echo "  1. Conecta tu dispositivo por USB"
echo "  2. Ejecuta: adb install build/app/outputs/flutter-apk/app-release.apk"
echo "  3. O copia la APK manualmente a tu dispositivo"
echo ""

