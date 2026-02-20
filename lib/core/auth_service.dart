import 'package:flutter/foundation.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación para manejar el estado del usuario actual
class AuthService {
  static Usuario? _usuarioActual;
  static final ValueNotifier<Usuario?> usuarioNotifier = ValueNotifier(null);
  static bool _isInitialized = false;
  /// Cache de esAdministrador para evitar múltiples consultas simultáneas a la BD
  static bool? _esAdminCache;
  static String? _esAdminCacheUserId;

  /// Inicializa el servicio de autenticación
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Intentar restaurar sesión desde SharedPreferences (userId)
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      if (storedUserId != null && storedUserId.isNotEmpty) {
        final usuario = await ControlUsuario().consultarUsuario(storedUserId);
        if (usuario != null) {
          _usuarioActual = usuario;
          usuarioNotifier.value = usuario;
        }
      }
    } catch (e) {
      // No crítico: si falla la restauración, arrancamos sin usuario
      print('Warning: no se pudo restaurar sesión: $e');
    }

    _isInitialized = true;
  }

  /// Obtiene el usuario actual
  static Usuario? get usuarioActual => _usuarioActual;

  /// Verifica si el usuario actual es administrador
  /// Resultado cacheado para evitar saturar la BD con consultas simultáneas (Atlas M0)
  static Future<bool> esAdministrador() async {
    if (_usuarioActual == null) {
      _esAdminCache = null;
      _esAdminCacheUserId = null;
      print('⚠️ esAdministrador: No hay usuario actual');
      return false;
    }
    if (_esAdminCache != null && _esAdminCacheUserId == _usuarioActual!.id) {
      return _esAdminCache!;
    }

    print('🔍 Verificando si usuario es admin. Usuario ID: ${_usuarioActual!.id}');
    print('   Roles del usuario: ${_usuarioActual!.roles}');

    if (_usuarioActual!.roles.isEmpty) {
      print('❌ Usuario NO tiene roles asignados');
      return false;
    }

    // Consultar cada rol del usuario desde la BD para verificar su nombre
    for (var rolId in _usuarioActual!.roles) {
      try {
        print('   Consultando rol ID: $rolId');
        final rol = await ControlUsuario().consultarRol(rolId);
        if (rol != null) {
          print('   ✅ Rol encontrado: ${rol.nombre} (activo: ${rol.activo})');
          final nombreRol = rol.nombre.toLowerCase().trim();
          
          // Verificar si el rol está activo y es administrador
          if (rol.activo && (nombreRol.contains('admin') || nombreRol == 'administrador')) {
            print('✅ Usuario es ADMIN (rol: ${rol.nombre}, id: $rolId)');
            _esAdminCache = true;
            _esAdminCacheUserId = _usuarioActual!.id;
            return true;
          } else {
            print('   ⚠️ Rol no es admin o está inactivo: ${rol.nombre}');
          }
        } else {
          print('   ⚠️ Rol no encontrado en BD para ID: $rolId');
        }
      } catch (e, stackTrace) {
        print('⚠️ Error al consultar rol $rolId: $e');
        print('   Stack trace: $stackTrace');
        // Continuar con el siguiente rol
      }
    }

    print('❌ Usuario NO es admin. Roles consultados: ${_usuarioActual!.roles}');
    _esAdminCache = false;
    _esAdminCacheUserId = _usuarioActual!.id;
    return false;
  }

  /// Verifica si el usuario actual tiene un permiso específico
  static Future<bool> tienePermiso(String permisoId) async {
    if (_usuarioActual == null) return false;

    try {
      return await ControlUsuario().usuarioTienePermiso(
        _usuarioActual!.id,
        permisoId,
      );
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario actual puede acceder al módulo de usuarios
  static Future<bool> puedeAccederUsuarios() async => await esAdministrador();

  /// Actualiza el usuario actual
  static void actualizarUsuario(Usuario usuario) {
    _esAdminCache = null;
    _esAdminCacheUserId = null;
    final previousId = _usuarioActual?.id;
    final previousRoles = _usuarioActual?.roles ?? [];
    _usuarioActual = usuario;
    print(
      'AuthService: actualizarUsuario -> id=${usuario.id}, email=${usuario.email} (previous=$previousId)',
    );
    print('   Roles anteriores: $previousRoles');
    print('   Roles nuevos: ${usuario.roles}');
    
    // Notificar siempre que se actualiza el usuario, incluso si es el mismo ID
    // porque los datos pueden haber cambiado (ej: roles, permisos, etc.)
    usuarioNotifier.value = usuario;
    
    // Persistir userId para restaurar sesión en próximos arranques
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString('userId', usuario.id);
        })
        .catchError((e) {
          print('Warning: no se pudo persistir userId: $e');
        });
  }

  /// Cierra la sesión
  static void cerrarSesion() {
    _usuarioActual = null;
    _esAdminCache = null;
    _esAdminCacheUserId = null;
    _isInitialized = false;
    usuarioNotifier.value = null;
    // Borrar persistencia
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.remove('userId');
        })
        .catchError((e) {
          print('Warning: no se pudo limpiar persistencia de sesión: $e');
        });
  }

  // ========== RECUÉRDAME (GUARDAR CREDENCIALES) ==========

  /// Guarda las credenciales del usuario para "Recuérdame"
  static Future<void> guardarCredenciales(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
      print('✅ Credenciales guardadas para "Recuérdame"');
    } catch (e) {
      print('⚠️ Error al guardar credenciales: $e');
    }
  }

  /// Carga las credenciales guardadas (si existen)
  static Future<Map<String, String?>> cargarCredenciales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && email != null && password != null) {
        print('✅ Credenciales encontradas para "Recuérdame"');
        return {
          'email': email,
          'password': password,
          'rememberMe': 'true',
        };
      }
      return {'email': null, 'password': null, 'rememberMe': 'false'};
    } catch (e) {
      print('⚠️ Error al cargar credenciales: $e');
      return {'email': null, 'password': null, 'rememberMe': 'false'};
    }
  }

  /// Elimina las credenciales guardadas
  static Future<void> eliminarCredenciales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
      print('✅ Credenciales eliminadas');
    } catch (e) {
      print('⚠️ Error al eliminar credenciales: $e');
    }
  }
}
