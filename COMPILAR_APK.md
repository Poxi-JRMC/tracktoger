# 📱 Guía para Compilar APK de Tracktoger

## ✅ Permisos Configurados

Los siguientes permisos ya están configurados en `AndroidManifest.xml`:

- ✅ **INTERNET** - Para conexión a MongoDB y SendGrid
- ✅ **ACCESS_NETWORK_STATE** - Verificar estado de red
- ✅ **READ_EXTERNAL_STORAGE** - Leer archivos (Android ≤12)
- ✅ **WRITE_EXTERNAL_STORAGE** - Escribir archivos (Android ≤12)
- ✅ **MANAGE_EXTERNAL_STORAGE** - Gestión de almacenamiento (Android 11+)
- ✅ **POST_NOTIFICATIONS** - Notificaciones (Android 13+)
- ✅ **CAMERA** - Cámara para image_picker
- ✅ **READ_MEDIA_IMAGES** - Leer imágenes (Android 13+)

## 🔨 Pasos para Compilar la APK

### Opción 1: Compilar APK de Release (Recomendado)

```bash
# 1. Limpiar el proyecto
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Compilar APK de release
flutter build apk --release
```

La APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

### Opción 2: Compilar APK Dividida (APK Split)

Si quieres reducir el tamaño de la APK, puedes compilar por arquitectura:

```bash
# Para ARM64 (la mayoría de dispositivos modernos)
flutter build apk --release --split-per-abi

# Esto generará:
# - app-armeabi-v7a-release.apk (32-bit)
# - app-arm64-v8a-release.apk (64-bit) ← Usa esta para dispositivos modernos
# - app-x86_64-release.apk (emuladores)
```

### Opción 3: Compilar APK Bundle (para Google Play)

Si planeas subir a Google Play Store:

```bash
flutter build appbundle --release
```

El archivo se generará en: `build/app/outputs/bundle/release/app-release.aab`

## 📋 Verificar Configuración

### 1. Verificar minSdk y targetSdk

Abre `android/app/build.gradle.kts` y verifica:
- `minSdk` debe ser al menos 21 (Android 5.0)
- `targetSdk` debe ser 33 o superior

### 2. Verificar ProGuard (Opcional)

Si quieres ofuscar el código en release, edita `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    getByName("release") {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

## 🚀 Instalación en Dispositivo Físico

### Método 1: ADB (Android Debug Bridge)

```bash
# Conectar dispositivo por USB
# Habilitar "Depuración USB" en opciones de desarrollador

# Instalar APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Método 2: Transferir Manualmente

1. Copia `app-release.apk` a tu dispositivo
2. Abre el archivo en el dispositivo
3. Permite "Instalar desde fuentes desconocidas" si es necesario
4. Instala la APK

## ⚠️ Solución de Problemas

### Error: "Gradle build failed"

```bash
# Limpiar y reconstruir
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "SDK location not found"

Verifica que `android/local.properties` tenga:
```
sdk.dir=C:\\Users\\TU_USUARIO\\AppData\\Local\\Android\\Sdk
```

### Error: "Manifest merger failed"

Verifica que todos los permisos en `AndroidManifest.xml` estén correctamente escritos.

### APK muy grande

Usa `--split-per-abi` para generar APKs por arquitectura, o habilita ProGuard para reducir el tamaño.

## 📝 Notas Importantes

1. **Firma de la APK**: Actualmente está configurada para usar la firma de debug. Para producción, necesitas crear una keystore y configurarla.

2. **Versión de la App**: La versión se define en `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```
   El formato es: `versionName+versionCode`

3. **Variables de Entorno**: Asegúrate de que el archivo `.env` esté incluido en `pubspec.yaml`:
   ```yaml
   assets:
     - .env
   ```

## 🔐 Configurar Firma para Producción (Opcional)

Si quieres firmar la APK para producción:

1. Generar keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Crear `android/key.properties`:
```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. Modificar `android/app/build.gradle.kts` para usar la keystore.

