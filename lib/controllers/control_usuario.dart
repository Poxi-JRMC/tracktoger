import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/usuario.dart';
import '../models/rol.dart';
import '../models/permiso.dart';
import '../data/services/database_service.dart';
import '../data/services/email_service.dart';
import '../core/auth_service.dart'; // 👈 Import necesario

class ControlUsuario {
  // ========== MÉTODOS PARA USUARIOS ==========

  Future<List<Rol>> consultarTodosRoles() async {
    return await DatabaseService().consultarTodosRoles();
  }

  /// Genera un código de verificación aleatorio
  String generarCodigoVerificacion() {
    var random = Random();
    return (random.nextInt(900000) + 100000).toString(); // Código de 6 dígitos
  }

  /// Registra un nuevo usuario desde el panel admin (sin verificación por email)
  Future<Map<String, String>> registrarUsuarioDesdeAdmin(
    Usuario usuario,
  ) async {
    final emailNormalized = usuario.email.trim().toLowerCase();

    // 🔹 Verificar si el email ya está registrado
    final usuarioExistente = await DatabaseService().consultarUsuarioPorEmail(
      emailNormalized,
    );
    if (usuarioExistente != null) {
      throw Exception('El email ya está registrado');
    }

    // 🔹 Generar ID si no viene
    String userId = usuario.id;
    if (userId.isEmpty) {
      userId = ObjectId().toHexString();
    }

    // 🔹 Usar contraseña por defecto o hasheada
    String hashedPassword = '';
    if (usuario.password != null && usuario.password!.isNotEmpty) {
      hashedPassword = BCrypt.hashpw(usuario.password!, BCrypt.gensalt());
    }

    // 🔹 Crear objeto para insertar (ACTIVO inmediatamente, sin verificación)
    final usuarioToInsert = usuario.copyWith(
      id: userId,
      email: emailNormalized,
      activo: true, // ✅ Admin users are active immediately
      codigoVerificacion: null,
      password: hashedPassword,
    );

    // 🔹 Insertar usuario en la base de datos
    await DatabaseService().insertarUsuario(usuarioToInsert.toMap());

    print(
      '✅ Usuario registrado desde admin correctamente (activo inmediatamente)',
    );
    return {'id': userId};
  }

  /// Registra un nuevo usuario con verificación por correo y contraseña encriptada
  Future<Map<String, String>> registrarUsuario(Usuario usuario) async {
    final emailNormalized = usuario.email.trim().toLowerCase();

    // 🔹 Verificar si el email ya está registrado
    final usuarioExistente = await DatabaseService().consultarUsuarioPorEmail(
      emailNormalized,
    );
    if (usuarioExistente != null) {
      throw Exception('El email ya está registrado');
    }

    // 🔹 Buscar el ID real del rol "Operador" por defecto
    final roles = await consultarTodosRoles();
    String operadorRoleId = '';
    for (var rol in roles) {
      final nombreRol = rol.nombre.toLowerCase();
      if (nombreRol.contains('operador') || nombreRol.contains('operator')) {
        operadorRoleId = rol.id;
        break;
      }
    }

    // Si no se encontró el rol Operador, usar el primer rol disponible o dejar vacío
    List<String> rolesFinales = operadorRoleId.isNotEmpty 
        ? [operadorRoleId] 
        : (usuario.roles.isNotEmpty ? usuario.roles : []);

    // 🔹 Generar código de verificación
    String codigoVerificacion = generarCodigoVerificacion();

    // 🔹 Generar ID si no viene
    String userId = usuario.id;
    if (userId.isEmpty) {
      userId = ObjectId().toHexString();
    }

    // 🔹 Hashear la contraseña antes de guardar
    String hashedPassword = BCrypt.hashpw(
      usuario.password ?? '',
      BCrypt.gensalt(),
    );

    // 🔹 Crear objeto actualizado para insertar
    final usuarioToInsert = usuario.copyWith(
      id: userId,
      email: emailNormalized,
      activo: false,
      codigoVerificacion: codigoVerificacion,
      password: hashedPassword,
      roles: rolesFinales, // Asignar el ID real del rol Operador
    );

    // 🔹 Insertar usuario en la base de datos
    await DatabaseService().insertarUsuario(usuarioToInsert.toMap());

    // 🔹 Enviar código de verificación
    await EmailService.sendVerificationEmail(usuario.email, codigoVerificacion);

    print('✅ Usuario registrado correctamente y correo enviado');
    return {'code': codigoVerificacion, 'id': userId};
  }

  /// Verifica el código enviado al correo del usuario
  Future<Usuario?> verificarCodigo(String email, String codigo) async {
    final emailNormalized = email.trim().toLowerCase();

    // 🔹 Buscar usuario
    final usuario = await DatabaseService().consultarUsuarioPorEmail(
      emailNormalized,
    );
    if (usuario == null) throw Exception('Usuario no encontrado');

    // 🔹 Validar código
    if (usuario.codigoVerificacion != codigo) {
      throw Exception('Código incorrecto');
    }

    // 🔹 Activar usuario y limpiar el código
    final usuarioVerificado = usuario.copyWith(
      activo: true,
      codigoVerificacion: null,
    );

    // 🔹 Actualizar en BD
    await DatabaseService().actualizarUsuario(usuarioVerificado.toMap());

    // 🔹 Actualizar usuario actual en memoria
    AuthService.actualizarUsuario(usuarioVerificado);

    print('✅ Usuario verificado correctamente');
    return usuarioVerificado;
  }

  /// Autentica un usuario por email y password
  Future<Usuario?> autenticarUsuario(String email, String password) async {
    final emailNormalized = email.trim().toLowerCase();
    final usuario = await consultarUsuarioPorEmail(emailNormalized);

    if (usuario == null) {
      print('❌ Usuario no encontrado');
      return null;
    }

    if (usuario.password == null || usuario.password!.isEmpty) {
      print('⚠️ Usuario sin contraseña almacenada');
      return null;
    }

    // 🔹 Verificar el password usando bcrypt
    bool passwordOk = BCrypt.checkpw(password, usuario.password!);
    if (!passwordOk) {
      print('❌ Contraseña incorrecta');
      return null;
    }

    if (usuario.activo != true) {
      print('⚠️ Usuario no verificado');
      return null;
    }

    print('✅ Autenticación exitosa');
    return usuario;
  }

  // ========== OTROS MÉTODOS CRUD ==========

  Future<Usuario> actualizarUsuario(Usuario usuario) async {
    final usuarioExistente = await DatabaseService().consultarUsuario(
      usuario.id,
    );
    if (usuarioExistente == null) {
      throw Exception('Usuario no encontrado');
    }

    await DatabaseService().actualizarUsuario(usuario.toMap());
    return usuario;
  }

  Future<Usuario?> consultarUsuario(String id) async {
    return await DatabaseService().consultarUsuario(id);
  }

  Future<Usuario?> consultarUsuarioPorId(String id) async {
    try {
      final usuario = await DatabaseService().consultarUsuario(id);
      return usuario;
    } catch (e) {
      print('Error al consultar usuario por ID: $e');
      return null;
    }
  }

  Future<Usuario?> consultarUsuarioPorEmail(String email) async {
    return await DatabaseService().consultarUsuarioPorEmail(email);
  }

  Future<List<Usuario>> consultarTodosUsuarios() async {
    return await DatabaseService().consultarTodosUsuarios();
  }

  /// Obtiene estadísticas de usuarios
  Future<Map<String, dynamic>> obtenerEstadisticasUsuarios() async {
    final usuarios = await consultarTodosUsuarios();
    final total = usuarios.length;
    final activos = usuarios.where((u) => u.activo).length;
    final inactivos = usuarios.where((u) => !u.activo).length;
    
    // Contar usuarios por rol (excluyendo "Sin rol")
    final roles = await consultarTodosRoles();
    final usuariosPorRol = <String, int>{};
    for (var usuario in usuarios) {
      for (var rolId in usuario.roles) {
        if (rolId.isEmpty) continue; // Saltar roles vacíos
        
        final rol = roles.firstWhere(
          (r) => r.id == rolId,
          orElse: () => Rol(
            id: '',
            nombre: '',
            descripcion: '',
            fechaCreacion: DateTime.now(),
          ),
        );
        
        // Solo agregar si el rol tiene nombre válido (no vacío y no "Sin rol")
        if (rol.nombre.isNotEmpty && 
            !rol.nombre.toLowerCase().contains('sin rol')) {
          usuariosPorRol[rol.nombre] = (usuariosPorRol[rol.nombre] ?? 0) + 1;
        }
      }
    }

    // Usuarios registrados en el último mes
    final ahora = DateTime.now();
    final haceUnMes = ahora.subtract(const Duration(days: 30));
    final nuevosUsuarios = usuarios.where(
      (u) => u.fechaRegistro.isAfter(haceUnMes),
    ).length;

    return {
      'total': total,
      'activos': activos,
      'inactivos': inactivos,
      'nuevosUsuarios': nuevosUsuarios,
      'usuariosPorRol': usuariosPorRol,
      'porcentajeActivos': total > 0 ? (activos / total * 100).round() : 0,
    };
  }

  Future<bool> eliminarUsuario(String id) async {
    final result = await DatabaseService().eliminarUsuario(id);
    return result;
  }

  /// Reactiva un usuario estableciendo `activo = true` en la BD
  Future<bool> activarUsuario(String id) async {
    try {
      final result = await DatabaseService().actualizarEstadoUsuarioAVerificado(
        id,
      );
      return result;
    } catch (e) {
      print('Error al activar usuario: $e');
      return false;
    }
  }

  // ========== ROLES Y PERMISOS ==========

  Future<Rol?> consultarRol(String id) async {
    return await DatabaseService().consultarRol(id);
  }

  Future<bool> usuarioTienePermiso(String usuarioId, String permisoId) async {
    final usuario = await consultarUsuario(usuarioId);
    if (usuario == null) return false;

    for (String rolId in usuario.roles) {
      final rol = await consultarRol(rolId);
      if (rol != null && rol.permisos.contains(permisoId)) {
        return true;
      }
    }
    return false;
  }

  Future<List<Permiso>> obtenerPermisosUsuario(String usuarioId) async {
    final usuario = await consultarUsuario(usuarioId);
    if (usuario == null) return [];

    List<Permiso> permisos = [];
    for (String rolId in usuario.roles) {
      final rol = await consultarRol(rolId);
      if (rol != null) {
        for (String permisoId in rol.permisos) {
          final permiso = await DatabaseService().consultarPermiso(permisoId);
          if (permiso != null) permisos.add(permiso);
        }
      }
    }
    return permisos;
  }

  /// Envía un código de recuperación de contraseña al email
  Future<void> enviarCodigoRecuperacion(String email) async {
    final emailNormalized = email.trim().toLowerCase();

    print('📧 Iniciando proceso de recuperación de contraseña');
    print('   Email: $emailNormalized');

    // Buscar usuario por email
    final usuario = await DatabaseService().consultarUsuarioPorEmail(
      emailNormalized,
    );
    if (usuario == null) {
      throw Exception('No existe usuario con ese correo');
    }

    print('   ✅ Usuario encontrado: ${usuario.nombre} (ID: ${usuario.id})');

    // Generar código de verificación
    String codigoRecuperacion = generarCodigoVerificacion();
    print('   🔑 Código generado: $codigoRecuperacion');

    // Actualizar usuario con código de recuperación
    final usuarioActualizado = usuario.copyWith(
      codigoVerificacion: codigoRecuperacion,
    );

    print('   💾 Guardando código en BD...');
    await DatabaseService().actualizarUsuario(usuarioActualizado.toMap());

    // Verificar que se guardó correctamente
    final usuarioVerificado = await DatabaseService().consultarUsuarioPorEmail(
      emailNormalized,
    );
    if (usuarioVerificado?.codigoVerificacion == codigoRecuperacion) {
      print('   ✅ Código guardado correctamente en BD');
    } else {
      print('   ⚠️ ADVERTENCIA: El código no se guardó correctamente');
      print('      Esperado: $codigoRecuperacion');
      print('      Obtenido: ${usuarioVerificado?.codigoVerificacion ?? "null"}');
    }

    // Enviar email con código de recuperación
    print('   📨 Enviando email...');
    await EmailService.sendPasswordRecoveryEmail(email, codigoRecuperacion);

    print('✅ Código de recuperación enviado a $email');
  }

  /// Verifica el código y cambia la contraseña
  Future<void> recuperarPassword(
    String email,
    String codigo,
    String newPassword,
  ) async {
    final emailNormalized = email.trim().toLowerCase();

    // Buscar usuario
    final usuario = await DatabaseService().consultarUsuarioPorEmail(
      emailNormalized,
    );
    if (usuario == null) {
      throw Exception('Usuario no encontrado');
    }

    // Verificar código
    print('🔍 Verificando código de recuperación');
    print('   Código recibido: $codigo');
    print('   Código en BD: ${usuario.codigoVerificacion ?? "null"}');
    print('   Email: $emailNormalized');
    
    if (usuario.codigoVerificacion == null || usuario.codigoVerificacion!.isEmpty) {
      throw Exception('No hay código de recuperación pendiente. Solicita uno nuevo.');
    }
    
    if (usuario.codigoVerificacion != codigo.trim()) {
      throw Exception('Código incorrecto o expirado');
    }

    // Hashear la nueva contraseña
    String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    // Actualizar usuario con nueva contraseña y limpiar código
    final usuarioActualizado = usuario.copyWith(
      password: hashedPassword,
      codigoVerificacion: null,
    );

    await DatabaseService().actualizarUsuario(usuarioActualizado.toMap());

    print('✅ Contraseña actualizada correctamente');
  }
}
