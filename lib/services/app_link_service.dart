import 'dart:async';
import 'package:app_links/app_links.dart';

/// Servicio para manejar deep links y app links
/// Permite que los enlaces en emails abran directamente la app
class AppLinkService {
  static final AppLinkService _instance = AppLinkService._internal();
  factory AppLinkService() => _instance;
  AppLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _initialLink;
  Uri? _latestLink;

  // Callbacks para manejar diferentes tipos de links
  Function(String email, String code)? onVerificationLink;
  Function(String email, String code)? onPasswordResetLink;

  /// Inicializa el servicio y escucha enlaces entrantes
  Future<void> initialize() async {
    print('🔗 Inicializando AppLinkService...');
    
    // Obtener el enlace inicial si la app fue abierta por un link
    try {
      _initialLink = await _appLinks.getInitialLink();
      if (_initialLink != null) {
        print('🔗 Link inicial detectado: $_initialLink');
        // Procesar el link inicial después de un pequeño delay
        // para asegurar que la app esté completamente inicializada
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleLink(_initialLink!);
        });
      }
    } catch (e) {
      print('⚠️ Error obteniendo link inicial: $e');
    }

    // Escuchar enlaces mientras la app está ejecutándose
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Link recibido mientras la app está ejecutándose: $uri');
        _latestLink = uri;
        _handleLink(uri);
      },
      onError: (err) {
        print('❌ Error en stream de links: $err');
      },
    );

    print('✅ AppLinkService inicializado');
  }

  /// Maneja el enlace recibido
  void _handleLink(Uri uri) {
    // El path puede ser vacío para scheme personalizado (tracktoger://verify?email=...)
    // o puede tener path (tracktoger://verify/...)
    final path = uri.path.isEmpty ? uri.scheme : uri.path;
    final queryParams = uri.queryParameters;
    final host = uri.host; // Puede ser vacío para scheme personalizado

    print('📥 Procesando link:');
    print('   Scheme: ${uri.scheme}');
    print('   Host: $host');
    print('   Path: ${uri.path}');
    print('   Parámetros: $queryParams');

    // Manejar diferentes tipos de enlaces
    // Para scheme personalizado: tracktoger://verify?email=...&code=...
    // El path puede ser "verify" o vacío, y los parámetros están en queryParams
    final isVerify = path.contains('verify') || 
                     uri.toString().contains('verify') ||
                     (path.isEmpty && queryParams.containsKey('email') && queryParams.containsKey('code'));
    
    final isResetPassword = path.contains('reset-password') || 
                           uri.toString().contains('reset-password');

    if (isVerify) {
      // Verificación de email
      final email = queryParams['email'];
      final code = queryParams['code'];
      if (email != null && code != null) {
        print('✅ Link de verificación detectado: email=$email, code=$code');
        if (onVerificationLink != null) {
          onVerificationLink!(Uri.decodeComponent(email), code);
        } else {
          print('⚠️ No hay callback registrado para verificación (la pantalla aún no está abierta)');
          print('   El link se guardará y se procesará cuando VerificationScreen se abra');
        }
      } else {
        print('⚠️ Link de verificación incompleto: faltan email o code');
      }
    } else if (isResetPassword) {
      // Recuperación de contraseña
      final email = queryParams['email'];
      final code = queryParams['code'];
      if (email != null && code != null) {
        print('✅ Link de recuperación de contraseña detectado: email=$email, code=$code');
        if (onPasswordResetLink != null) {
          onPasswordResetLink!(Uri.decodeComponent(email), code);
        } else {
          print('⚠️ No hay callback registrado para recuperación de contraseña (la pantalla aún no está abierta)');
          print('   El link se guardará y se procesará cuando ForgotPasswordScreen se abra');
        }
      } else {
        print('⚠️ Link de recuperación incompleto: faltan email o code');
      }
    } else {
      print('⚠️ Tipo de link no reconocido: $path');
      print('   URI completo: $uri');
    }
  }

  /// Registra un callback para manejar links de verificación
  void setVerificationCallback(Function(String email, String code) callback) {
    onVerificationLink = callback;
  }

  /// Registra un callback para manejar links de recuperación de contraseña
  void setPasswordResetCallback(Function(String email, String code) callback) {
    onPasswordResetLink = callback;
  }

  /// Obtiene el último link recibido
  Uri? getLatestLink() => _latestLink;

  /// Obtiene el link inicial (si la app fue abierta por un link)
  Uri? getInitialLink() => _initialLink;

  /// Limpia recursos
  void dispose() {
    print('🔗 Limpiando AppLinkService...');
    _linkSubscription?.cancel();
    _linkSubscription = null;
    onVerificationLink = null;
    onPasswordResetLink = null;
  }
}

