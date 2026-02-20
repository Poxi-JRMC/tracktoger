# 🔗 Configuración de App Links para Verificación por Email

Esta guía explica cómo configurar **app_links** (Deep Links) para que los enlaces de verificación en los correos electrónicos abran directamente la aplicación Flutter.

## 📋 Requisitos Previos

- Flutter SDK instalado
- Proyecto Flutter configurado
- Acceso a configuración de Android/iOS

## 📦 Paso 1: Agregar Dependencia

Agrega `app_links` a tu `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.1.1  # Última versión estable
```

Luego ejecuta:
```bash
flutter pub get
```

## 🤖 Paso 2: Configuración Android

### 2.1. Modificar `android/app/src/main/AndroidManifest.xml`

Agrega la configuración de intent-filter dentro de la actividad principal:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    ...>
    
    <!-- Intent filter para app links -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Reemplaza 'tracktoger.app' con tu dominio real -->
        <data
            android:scheme="https"
            android:host="tracktoger.app"
            android:pathPrefix="/verify" />
        
        <!-- También soporta http para desarrollo -->
        <data
            android:scheme="http"
            android:host="tracktoger.app"
            android:pathPrefix="/verify" />
    </intent-filter>
    
    <!-- Deep link alternativo con scheme personalizado -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="tracktoger" />
    </intent-filter>
</activity>
```

### 2.2. Configurar Asset Links (Verificación de Dominio)

Para que Android verifique automáticamente que tu app puede manejar los enlaces, necesitas crear un archivo `assetlinks.json` en tu servidor web.

**Ubicación:** `https://tracktoger.app/.well-known/assetlinks.json`

**Contenido del archivo:**

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.tracktoger.app",  // Reemplaza con tu package name
    "sha256_cert_fingerprints": [
      "TU_HUELLA_SHA256_AQUI"  // Ver instrucciones abajo
    ]
  }
}]
```

**Obtener la huella SHA256:**

1. **Para debug (desarrollo):**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Para release (producción):**
   ```bash
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
   ```

   Busca la línea que dice "SHA256:" y copia el valor.

### 2.3. Verificar Asset Links

Puedes verificar que tu configuración funciona con:
```bash
# Instalar herramienta de verificación
npm install -g assetlinks-validator

# Verificar
assetlinks-validator https://tracktoger.app/.well-known/assetlinks.json com.tracktoger.app
```

## 🍎 Paso 3: Configuración iOS

### 3.1. Modificar `ios/Runner/Info.plist`

Agrega la configuración de URL schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>tracktoger</string>
            <string>https</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.tracktoger.app</string>
    </dict>
</array>

<!-- Para Universal Links (iOS 9+) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:tracktoger.app</string>
</array>
```

### 3.2. Configurar Associated Domains en Xcode

1. Abre `ios/Runner.xcworkspace` en Xcode
2. Selecciona el target "Runner"
3. Ve a "Signing & Capabilities"
4. Agrega la capacidad "Associated Domains"
5. Agrega: `applinks:tracktoger.app`

### 3.3. Crear Apple App Site Association (AASA)

Crea un archivo `apple-app-site-association` en tu servidor web.

**Ubicación:** `https://tracktoger.app/.well-known/apple-app-site-association`

**IMPORTANTE:** Este archivo NO debe tener extensión `.json`, aunque es JSON.

**Contenido del archivo:**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.tracktoger.app",  // Reemplaza con tu Team ID y Bundle ID
        "paths": [
          "/verify/*",
          "/reset-password/*"
        ]
      }
    ]
  }
}
```

**Obtener Team ID:**
- Ve a [Apple Developer Portal](https://developer.apple.com/account)
- Tu Team ID está en la esquina superior derecha

## 💻 Paso 4: Implementar en Flutter

### 4.1. Crear servicio de manejo de links

Crea `lib/services/app_link_service.dart`:

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class AppLinkService {
  static final AppLinkService _instance = AppLinkService._internal();
  factory AppLinkService() => _instance;
  AppLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _initialLink;
  Uri? _latestLink;

  /// Inicializa el servicio y escucha enlaces entrantes
  Future<void> initialize() async {
    // Obtener el enlace inicial si la app fue abierta por un link
    try {
      _initialLink = await _appLinks.getInitialLink();
      if (_initialLink != null) {
        print('🔗 Link inicial: $_initialLink');
        _handleLink(_initialLink!);
      }
    } catch (e) {
      print('⚠️ Error obteniendo link inicial: $e');
    }

    // Escuchar enlaces mientras la app está ejecutándose
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Link recibido: $uri');
        _latestLink = uri;
        _handleLink(uri);
      },
      onError: (err) {
        print('❌ Error en stream de links: $err');
      },
    );
  }

  /// Maneja el enlace recibido
  void _handleLink(Uri uri) {
    final path = uri.path;
    final queryParams = uri.queryParameters;

    print('📥 Procesando link: $path');
    print('   Parámetros: $queryParams');

    // Manejar diferentes tipos de enlaces
    if (path.startsWith('/verify')) {
      // Verificación de email
      final email = queryParams['email'];
      final code = queryParams['code'];
      if (email != null && code != null) {
        _handleVerification(email, code);
      }
    } else if (path.startsWith('/reset-password')) {
      // Recuperación de contraseña
      final email = queryParams['email'];
      final code = queryParams['code'];
      if (email != null && code != null) {
        _handlePasswordReset(email, code);
      }
    }
  }

  /// Maneja la verificación de email
  void _handleVerification(String email, String code) {
    // Navegar a la pantalla de verificación con los parámetros
    // Esto requiere acceso al Navigator, así que puedes usar un GlobalKey
    // o un servicio de navegación
    print('✅ Verificando email: $email con código: $code');
    // TODO: Implementar navegación a pantalla de verificación
  }

  /// Maneja la recuperación de contraseña
  void _handlePasswordReset(String email, String code) {
    print('🔑 Recuperando contraseña para: $email con código: $code');
    // TODO: Implementar navegación a pantalla de recuperación
  }

  /// Limpia recursos
  void dispose() {
    _linkSubscription?.cancel();
  }
}
```

### 4.2. Inicializar en main.dart

Modifica `lib/main.dart`:

```dart
import 'services/app_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... código existente ...
  
  // Inicializar servicio de app links
  await AppLinkService().initialize();
  
  runApp(const GerotrackApp());
}
```

### 4.3. Actualizar EmailService para usar links

Modifica `lib/data/services/email_service.dart` para generar enlaces con app links:

```dart
// En lugar de solo el código, incluir un enlace
final verificationLink = 'https://tracktoger.app/verify?email=${Uri.encodeComponent(email)}&code=$codigo';

// O usar el scheme personalizado (más rápido, no requiere internet)
final verificationLink = 'tracktoger://verify?email=${Uri.encodeComponent(email)}&code=$codigo';
```

## 🧪 Paso 5: Probar App Links

### Android

1. **Probar con ADB:**
   ```bash
   # Scheme personalizado
   adb shell am start -a android.intent.action.VIEW -d "tracktoger://verify?email=test@example.com&code=123456"
   
   # HTTPS link
   adb shell am start -a android.intent.action.VIEW -d "https://tracktoger.app/verify?email=test@example.com&code=123456"
   ```

2. **Verificar Asset Links:**
   ```bash
   adb shell pm get-app-links com.tracktoger.app
   ```

### iOS

1. **Probar con Simulador:**
   ```bash
   xcrun simctl openurl booted "tracktoger://verify?email=test@example.com&code=123456"
   ```

2. **Probar Universal Links:**
   - Enviar un email con el link
   - Tocar el link en Mail app
   - Debería abrir la app directamente

## 🔧 Solución de Problemas

### Android: Asset Links no funcionan

1. **Verificar que el archivo esté accesible:**
   ```bash
   curl https://tracktoger.app/.well-known/assetlinks.json
   ```

2. **Verificar que el Content-Type sea correcto:**
   - Debe ser `application/json`
   - No debe tener extensión `.json` en la URL

3. **Limpiar cache de Android:**
   ```bash
   adb shell pm set-app-links --package com.tracktoger.app 0 all
   adb shell pm set-app-links-user-selection --package com.tracktoger.app true
   ```

### iOS: Universal Links no funcionan

1. **Verificar AASA:**
   ```bash
   curl https://tracktoger.app/.well-known/apple-app-site-association
   ```

2. **Verificar que no tenga extensión `.json`**

3. **Verificar Team ID y Bundle ID en AASA**

4. **Reinstalar la app** después de cambios en Associated Domains

## 📝 Notas Importantes

1. **Dominio:** Necesitas un dominio real para que funcionen los Universal Links (iOS) y App Links (Android). No funcionan con `localhost` o IPs.

2. **HTTPS:** Los App Links requieren HTTPS (excepto en desarrollo local).

3. **Testing:** Para desarrollo, puedes usar el scheme personalizado (`tracktoger://`) que no requiere configuración de servidor.

4. **Fallback:** Siempre incluye un fallback web en los emails por si el usuario no tiene la app instalada.

## 🎯 Ejemplo de Email con App Link

```html
<p>Haz clic en el siguiente enlace para verificar tu cuenta:</p>
<p>
  <a href="https://tracktoger.app/verify?email=usuario@example.com&code=123456">
    Verificar cuenta
  </a>
</p>
<p>O copia este código: <strong>123456</strong></p>
```

---

**¡Listo!** Con esta configuración, los enlaces de verificación en los emails abrirán directamente tu app Flutter. 🚀

