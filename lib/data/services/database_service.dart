import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';
import '/models/usuario.dart';
import '/models/rol.dart';
import '/models/permiso.dart';
import '/models/maquinaria.dart';
import '/models/herramienta.dart';
import '/models/gasto_operativo.dart';
import '/models/cliente.dart';
import '/models/alquiler.dart';
import '/models/pago.dart';
import '/models/analisis.dart';
import '/models/registro_mantenimiento.dart';

class DatabaseService {
  // ========= SINGLETON =========
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? db;
  DbCollection? usuariosCollection;
  DbCollection? rolesCollection;
  DbCollection? permisosCollection;
  DbCollection? maquinariaCollection;
  DbCollection? herramientasCollection;
  DbCollection? gastosOperativosCollection;
  DbCollection? clientesCollection;
  DbCollection? alquileresCollection;
  DbCollection? pagosCollection;
  DbCollection? analisisCollection;
  DbCollection? registrosMantenimientoCollection;

  bool get _useApi => (dotenv.env['API_BASE_URL'] ?? '').trim().isNotEmpty;
  ApiClient? _apiClient;
  ApiClient get _api => _apiClient ??= ApiClient((dotenv.env['API_BASE_URL'] ?? '').trim());

  bool get isConnected => _useApi ? true : (db != null && db!.state == State.open);
  bool _connecting = false;
  Timer? _keepAliveTimer;

  // ========= CONEXIÓN =========
  Future<void> conectar({int maxIntentos = 5, int delayInicial = 3}) async {
    if (_useApi) {
      print('✅ Modo API activo (API_BASE_URL configurada) - no se conecta a MongoDB');
      return;
    }
    if (isConnected) return;
    if (_connecting) {
      while (_connecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _connecting = true;
    int intento = 0;
    int delay = delayInicial;

    while (intento < maxIntentos) {
      try {
        String? dbUrl = dotenv.env['MONGO_DB_URL'];
        if (dbUrl == null || dbUrl.isEmpty) {
          print(
            '⚠️ ADVERTENCIA: MONGO_DB_URL no está definida — usando URL por defecto (no recomendado).',
          );
          dbUrl =
              'mongodb+srv://johanutb_db_user:KxHPmhF8PZwY3gUD@cluster0.xl6k3iu.mongodb.net/tracktoger?appName=Cluster0';
        }
        if (!dbUrl.contains('tls=true') && !dbUrl.contains('ssl=true')) {
          dbUrl += dbUrl.contains('?') ? '&tls=true' : '?tls=true';
        }

        // Cerrar conexión anterior si existe
        if (db != null) {
          try {
            await db?.close();
          } catch (e) {
            print('⚠️ Error al cerrar conexión anterior: $e');
          }
          db = null;
        }

        print('🔄 Intentando conectar a MongoDB... (Intento ${intento + 1}/$maxIntentos)');
        if (intento > 0) {
          print('   ⏳ Esperando ${delay} segundos (el cluster puede estar despertando)...');
          await Future.delayed(Duration(seconds: delay));
        }
        
        db = await Db.create(dbUrl);
        
        // Timeout más largo para la primera conexión (cluster puede estar despertando)
        // secure: true es obligatorio para MongoDB Atlas (TLS/SSL)
        // tlsAllowInvalidCertificates: necesario en Flutter/Android porque el SecurityContext
        // a veces no puede validar los certificados de Atlas correctamente
        final timeout = intento == 0 ? Duration(seconds: 30) : Duration(seconds: 15);
        await db!.open(
          secure: true,
          tlsAllowInvalidCertificates: true,
        ).timeout(timeout);

        usuariosCollection = db!.collection('usuarios');
        rolesCollection = db!.collection('roles');
        permisosCollection = db!.collection('permisos');
        maquinariaCollection = db!.collection('maquinaria');
        herramientasCollection = db!.collection('herramientas');
        gastosOperativosCollection = db!.collection('gastos_operativos');
        clientesCollection = db!.collection('clientes');
        alquileresCollection = db!.collection('alquileres');
        pagosCollection = db!.collection('pagos');
        analisisCollection = db!.collection('analisis');
        registrosMantenimientoCollection = db!.collection('registros_mantenimiento');

        // Verificar conexión con una consulta simple
        try {
          await usuariosCollection?.findOne(where.limit(1));
          print('✅ Conectado a MongoDB → ${db?.databaseName}');
        } catch (e) {
          print('⚠️ Conexión establecida pero verificación falló, reintentando...');
          throw Exception('Verificación de conexión falló');
        }
        
        // Iniciar keep-alive para mantener el cluster activo
        _iniciarKeepAlive();
        
        _connecting = false;
        return;
      } catch (e) {
        intento++;
        final errorMsg = e.toString().toLowerCase();
        final esErrorConexion = errorMsg.contains('no master') || 
                                errorMsg.contains('connection') ||
                                errorMsg.contains('timeout') ||
                                errorMsg.contains('network') ||
                                errorMsg.contains('verificación');

        if (esErrorConexion && intento < maxIntentos) {
          print('⚠️ Error de conexión (Intento $intento/$maxIntentos): $e');
          if (errorMsg.contains('no master')) {
            print('   💡 El cluster puede estar despertando. Esperando un poco más...');
            delay = delayInicial * (intento + 1); // Aumentar delay para "no master"
          } else {
            delay = delayInicial * (intento + 1); // Backoff: 3s, 6s, 9s, 12s...
          }
        } else {
          print('❌ Error al conectar a MongoDB después de $intento intentos: $e');
          db = null;
          usuariosCollection = null;
          rolesCollection = null;
          permisosCollection = null;
          maquinariaCollection = null;
          herramientasCollection = null;
          gastosOperativosCollection = null;
          clientesCollection = null;
          alquileresCollection = null;
          _connecting = false;
          rethrow;
        }
      }
    }
    
    _connecting = false;
  }

  // ========= KEEP-ALIVE =========
  // Mantiene el cluster activo haciendo pings periódicos
  // Este timer continúa funcionando incluso cuando la app está en segundo plano
  // (aunque puede pausarse en algunos sistemas, se reiniciará cuando la app vuelva)
  void _iniciarKeepAlive() {
    _cancelarKeepAlive();
    // Ping cada 2.5 minutos para mantener el cluster activo
    // Más frecuente para evitar que MongoDB Atlas entre en modo pausa
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 2, seconds: 30), (timer) async {
      try {
        if (isConnected && usuariosCollection != null) {
          // Hacer una consulta simple para mantener la conexión activa
          await usuariosCollection?.findOne(where.limit(1));
          print('💓 Keep-alive: Cluster activo (conexión mantenida)');
        } else {
          print('⚠️ Keep-alive: Conexión perdida, intentando reconectar...');
          await conectar();
        }
      } catch (e) {
        print('⚠️ Keep-alive falló: $e');
        // Intentar reconectar en el próximo ciclo
        try {
          await conectar();
        } catch (e2) {
          print('❌ No se pudo reconectar en keep-alive: $e2');
          // No cancelar el timer, seguir intentando
        }
      }
    });
    print('✅ Keep-alive iniciado (cada 2.5 minutos)');
  }

  void _cancelarKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<void> _ensureConnected({bool reintentar = true}) async {
    // Primero verificar si la conexión está activa y funciona
    final conexionActiva = await verificarConexion();
    
    if (!conexionActiva) {
      try {
        print('🔄 Conexión perdida o inactiva - reconectando...');
        await conectar();
      } catch (e) {
        if (reintentar) {
          print('🔄 Reconexión automática falló, reintentando...');
          // Esperar un poco y reintentar una vez más
          await Future.delayed(const Duration(seconds: 3));
          await conectar();
        } else {
          rethrow;
        }
      }
    }
  }

  /// Verifica que la conexión esté activa haciendo un ping simple
  /// Retorna true si la conexión está activa, false si no
  /// Incluye timeout para evitar esperas largas en conexiones muertas
  Future<bool> verificarConexion() async {
    if (_useApi) return _api.verificarConexion();
    try {
      // Verificar estado básico primero
      if (db == null || !isConnected) {
        print('⚠️ Conexión no existe o no está abierta');
        return false;
      }
      
      // Hacer un ping simple con timeout para verificar que la conexión realmente funciona
      // Timeout corto para detectar conexiones muertas rápidamente
      try {
        await usuariosCollection?.findOne(where.limit(1))
            .timeout(const Duration(seconds: 5));
        return true;
      } on TimeoutException {
        print('⚠️ Timeout al verificar conexión - conexión probablemente muerta');
        return false;
      }
    } catch (e) {
      print('⚠️ Verificación de conexión falló: $e');
      // Si hay error, la conexión está muerta
      return false;
    }
  }

  /// Método público para reconectar cuando la app vuelve al primer plano
  /// Incluye retry con backoff exponencial para mayor robustez
  Future<void> reconectarSiEsNecesario({int maxIntentos = 3}) async {
    // Verificar conexión primero
    final conexionActiva = await verificarConexion();
    if (conexionActiva) {
      print('✅ Conexión a BD activa y funcionando');
      return;
    }
    
    print('🔄 Conexión perdida - iniciando reconexión robusta...');
    
    // Cerrar conexión anterior si existe (puede estar en estado inconsistente)
    if (db != null) {
      try {
        await db?.close();
      } catch (e) {
        print('⚠️ Error al cerrar conexión anterior: $e');
      }
      db = null;
      usuariosCollection = null;
      rolesCollection = null;
      permisosCollection = null;
      maquinariaCollection = null;
      herramientasCollection = null;
      gastosOperativosCollection = null;
      clientesCollection = null;
      alquileresCollection = null;
      pagosCollection = null;
    }
    
    // Intentar reconectar con retry
    int intento = 0;
    int delay = 1; // Empezar con 1 segundo
    
    while (intento < maxIntentos) {
      try {
        print('🔄 Intento de reconexión ${intento + 1}/$maxIntentos...');
        
        // Esperar antes de reintentar (excepto en el primer intento)
        if (intento > 0) {
          print('   ⏳ Esperando ${delay} segundos antes de reintentar...');
          await Future.delayed(Duration(seconds: delay));
          delay *= 2; // Backoff exponencial: 1s, 2s, 4s...
        }
        
        // Intentar conectar
        await conectar(maxIntentos: 3, delayInicial: 1);
        
        // Verificar que la conexión realmente funciona
        final verificacion = await verificarConexion();
        if (verificacion) {
          print('✅ Conexión restaurada exitosamente');
          // Reiniciar keep-alive
          _iniciarKeepAlive();
          return;
        } else {
          print('⚠️ Conexión establecida pero verificación falló');
          throw Exception('Verificación de conexión falló después de conectar');
        }
      } catch (e) {
        intento++;
        print('❌ Error en intento ${intento}/$maxIntentos: $e');
        
        if (intento >= maxIntentos) {
          print('❌ No se pudo reconectar después de $maxIntentos intentos');
          // No lanzar error, la app seguirá funcionando y reintentará en la próxima operación
          // El keep-alive también intentará reconectar
          return;
        }
      }
    }
  }

  /// Asegura que el keep-alive esté activo (útil cuando la app vuelve al primer plano)
  void asegurarKeepAliveActivo() {
    if (isConnected && _keepAliveTimer == null) {
      print('🔄 Reiniciando keep-alive...');
      _iniciarKeepAlive();
    } else if (!isConnected) {
      print('⚠️ Conexión no activa, intentando reconectar...');
      conectar().catchError((e) {
        print('❌ Error al reconectar en asegurarKeepAliveActivo: $e');
      });
    }
  }

  // ========= USUARIOS =========
  Future<void> insertarUsuario(Map<String, dynamic> usuario) async {
    if (_useApi) return _api.insertarUsuario(usuario);
    try {
      await _ensureConnected();
      if (usuario.containsKey('id') &&
          (usuario['id'] ?? '').toString().isNotEmpty) {
        try {
          usuario['_id'] = ObjectId.fromHexString(usuario['id'].toString());
        } catch (e) {
          print('id no válido: ${usuario['id']}');
        }
      }

      print('🟢 Insertando usuario: $usuario');
      final insertResult = await usuariosCollection?.insert(usuario);
      print('Resultado insert: $insertResult');
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      final esErrorConexion = errorMsg.contains('no master') || 
                              errorMsg.contains('connection') ||
                              errorMsg.contains('timeout');
      
      if (esErrorConexion) {
        print('⚠️ Error de conexión al insertar usuario, reintentando...');
        // Cerrar conexión actual y reconectar
        try {
          await db?.close();
        } catch (_) {}
        db = null;
        await _ensureConnected();
        // Reintentar la inserción
        final insertResult = await usuariosCollection?.insert(usuario);
        print('✅ Usuario insertado después de reconexión: $insertResult');
      } else {
        print('❌ Error al insertar usuario: $e');
        rethrow;
      }
    }
  }

  Future<void> actualizarUsuario(Map<String, dynamic> usuario) async {
    if (_useApi) return _api.actualizarUsuario(usuario);
    await _ensureConnected();
    try {
      // El ID puede venir como string (del modelo Usuario.toMap())
      final userId = usuario['_id'] as String? ?? usuario['id'] as String?;
      if (userId == null || userId.isEmpty) {
        throw Exception('ID de usuario no válido: $userId');
      }

      print('📝 Actualizando usuario en BD: $userId');
      print('   Roles que se guardarán: ${usuario['roles']}');
      print('   Código verificación: ${usuario['codigoVerificacion'] ?? 'no se actualiza'}');
      print('   Password: ${usuario.containsKey('password') && usuario['password'] != null ? '***' : 'no se actualiza'}');

      // Verificar que el ID sea un ObjectId válido hexadecimal
      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(userId);
      } catch (e) {
        print('❌ ERROR: ID "$userId" no es un ObjectId hexadecimal válido');
        throw Exception('ID inválido para MongoDB: $userId');
      }

      // Preparar los datos a actualizar
      var updateData = modify
          .set('nombre', usuario['nombre'])
          .set('apellido', usuario['apellido'])
          .set('email', usuario['email'])
          .set('telefono', usuario['telefono'])
          .set('avatar', usuario['avatar'])
          .set('fechaRegistro', usuario['fechaRegistro'])
          .set('activo', usuario['activo'])
          .set('roles', usuario['roles'] ?? []);

      // Actualizar codigoVerificacion si está presente
      if (usuario.containsKey('codigoVerificacion')) {
        updateData = updateData.set('codigoVerificacion', usuario['codigoVerificacion']);
      }

      // Actualizar password si está presente
      if (usuario.containsKey('password') && usuario['password'] != null) {
        updateData = updateData.set('password', usuario['password']);
      }

      var result = await usuariosCollection?.update(
        where.eq('_id', objectId),
        updateData,
      );

      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;

      print('📊 Respuesta de actualización: nModified=$nModified, full=$r');

      if (nModified > 0) {
        print(
          '✅ Usuario actualizado correctamente (registros modificados: $nModified)',
        );
        // Verificar que se guardó correctamente leyendo de BD
        final verificacion = await usuariosCollection?.findOne(
          where.eq('_id', objectId),
        );
        if (verificacion != null) {
          print('   ✓ Verificación: roles en BD = ${verificacion['roles']}');
          if (usuario.containsKey('codigoVerificacion')) {
            print('   ✓ Verificación: codigoVerificacion en BD = ${verificacion['codigoVerificacion']}');
          }
        }
      } else {
        print('⚠️ No se encontró usuario o no hubo cambios');
        // Intentar búsqueda para debug
        final verificacion = await usuariosCollection?.findOne(
          where.eq('_id', objectId),
        );
        if (verificacion == null) {
          print('   ⚠️ No se encuentra el usuario con _id=$objectId');
        } else {
          print('   Usuario encontrado: ${verificacion['nombre']}');
        }
      }
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      rethrow;
    }
  }

  Future<Usuario?> consultarUsuarioPorEmail(String email) async {
    if (_useApi) return _api.consultarUsuarioPorEmail(email);
    await _ensureConnected();
    // Hacer búsqueda case-insensitive por email para mayor robustez
    final pattern = '^${RegExp.escape(email)}\$';
    // Consulta usando operador $regex y opción 'i' para case-insensitive
    var result = await usuariosCollection?.findOne({
      'email': {'\$regex': pattern, '\$options': 'i'},
    });
    print('🔍 consultarUsuarioPorEmail($email) → $result');
    return result != null ? Usuario.fromMap(result) : null;
  }

  Future<Usuario?> consultarUsuario(String id) async {
    if (_useApi) return _api.consultarUsuario(id);
    await _ensureConnected();
    var result = await usuariosCollection?.findOne(
      where.eq('_id', ObjectId.fromHexString(id)),
    );
    print('🔍 consultarUsuario($id) → $result');
    return result != null ? Usuario.fromMap(result) : null;
  }

  Future<List<Usuario>> consultarTodosUsuarios() async {
    if (_useApi) return _api.consultarTodosUsuarios();
    await _ensureConnected();
    var result = await usuariosCollection?.find().toList();
    return result?.map((e) => Usuario.fromMap(e)).toList() ?? [];
  }

  Future<bool> eliminarUsuario(String id) async {
    if (_useApi) return _api.eliminarUsuario(id);
    await _ensureConnected();
    try {
      var result = await usuariosCollection?.update(
        where.eq('_id', ObjectId.fromHexString(id)),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }

  Future<bool> actualizarEstadoUsuarioAVerificado(String userId) async {
    if (_useApi) return _api.actualizarEstadoUsuarioAVerificado(userId);
    await _ensureConnected();
    try {
      var result = await usuariosCollection?.update(
        where.eq('_id', ObjectId.fromHexString(userId)),
        modify.set('activo', true),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      if (nModified > 0) {
        print('✅ Usuario verificado correctamente');
        return true;
      } else {
        print('⚠️ Usuario no encontrado o sin cambios');
        return false;
      }
    } catch (e) {
      print('Error al verificar usuario: $e');
      return false;
    }
  }

  Future<bool> actualizarCodigoVerificacion(
    String userId,
    String codigo,
  ) async {
    if (_useApi) return _api.actualizarCodigoVerificacion(userId, codigo);
    await _ensureConnected();
    try {
      var result = await usuariosCollection?.update(
        where.eq('_id', ObjectId.fromHexString(userId)),
        modify.set('codigoVerificacion', codigo),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('Error al actualizar código verificación: $e');
      return false;
    }
  }

  // ========= ROLES =========
  Future<void> insertarRol(Map<String, dynamic> rol) async {
    if (_useApi) return _api.insertarRol(rol);
    await _ensureConnected();
    try {
      await rolesCollection?.insert(rol);
      print('✅ Rol insertado');
    } catch (e) {
      print('Error al insertar rol: $e');
    }
  }

  Future<Rol?> consultarRol(String id) async {
    if (_useApi) return _api.consultarRol(id);
    await _ensureConnected();
    try {
      // Primero intentar buscar por _id (ObjectId)
      var result = await rolesCollection?.findOne(
        where.eq('_id', ObjectId.fromHexString(id)),
      );
      if (result != null) {
        print('   ✅ Rol encontrado por _id: $id');
        return Rol.fromMap(result);
      }
      
      // Si no se encuentra, intentar buscar por el campo 'id'
      result = await rolesCollection?.findOne(
        where.eq('id', id),
      );
      if (result != null) {
        print('   ✅ Rol encontrado por campo id: $id');
        return Rol.fromMap(result);
      }
      
      print('   ⚠️ Rol no encontrado con ID: $id');
      return null;
    } catch (e) {
      print('   ❌ Error al consultar rol $id: $e');
      // Si falla con ObjectId, intentar buscar por campo 'id'
      try {
        var result = await rolesCollection?.findOne(
          where.eq('id', id),
        );
        if (result != null) {
          print('   ✅ Rol encontrado por campo id (fallback): $id');
          return Rol.fromMap(result);
        }
      } catch (e2) {
        print('   ❌ Error en fallback al consultar rol $id: $e2');
      }
      return null;
    }
  }

  Future<List<Rol>> consultarTodosRoles() async {
    if (_useApi) return _api.consultarTodosRoles();
    await _ensureConnected();
    var result = await rolesCollection?.find().toList();
    return result?.map((e) => Rol.fromMap(e)).toList() ?? [];
  }

  Future<bool> eliminarRol(String id) async {
    if (_useApi) return _api.eliminarRol(id);
    await _ensureConnected();
    try {
      var result = await rolesCollection?.update(
        where.eq('_id', ObjectId.fromHexString(id)),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('Error al eliminar rol: $e');
      return false;
    }
  }

  // ========= PERMISOS =========
  Future<void> insertarPermiso(Map<String, dynamic> permiso) async {
    if (_useApi) return _api.insertarPermiso(permiso);
    await _ensureConnected();
    try {
      await permisosCollection?.insert(permiso);
      print('✅ Permiso insertado');
    } catch (e) {
      print('Error al insertar permiso: $e');
    }
  }

  Future<Permiso?> consultarPermiso(String id) async {
    if (_useApi) return _api.consultarPermiso(id);
    await _ensureConnected();
    var result = await permisosCollection?.findOne(
      where.eq('_id', ObjectId.fromHexString(id)),
    );
    return result != null ? Permiso.fromMap(result) : null;
  }

  Future<List<Permiso>> consultarTodosPermisos() async {
    if (_useApi) return _api.consultarTodosPermisos();
    await _ensureConnected();
    var result = await permisosCollection?.find().toList();
    return result?.map((e) => Permiso.fromMap(e)).toList() ?? [];
  }

  Future<bool> eliminarPermiso(String id) async {
    if (_useApi) return _api.eliminarPermiso(id);
    await _ensureConnected();
    try {
      var result = await permisosCollection?.update(
        where.eq('_id', ObjectId.fromHexString(id)),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('Error al eliminar permiso: $e');
      return false;
    }
  }

  // ========= MAQUINARIA =========
  Future<void> insertarMaquinaria(Map<String, dynamic> maquinaria) async {
    if (_useApi) return _api.insertarMaquinaria(maquinaria);
    await _ensureConnected();
    try {
      if (maquinaria.containsKey('id') &&
          (maquinaria['id'] ?? '').toString().isNotEmpty) {
        try {
          maquinaria['_id'] = ObjectId.fromHexString(maquinaria['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${maquinaria['id']}');
        }
      }
      await maquinariaCollection?.insert(maquinaria);
      print('✅ Maquinaria insertada: ${maquinaria['nombre']}');
    } catch (e) {
      print('❌ Error al insertar maquinaria: $e');
      rethrow;
    }
  }

  Future<void> actualizarMaquinaria(Map<String, dynamic> maquinaria) async {
    if (_useApi) return _api.actualizarMaquinaria(maquinaria);
    await _ensureConnected();
    try {
      // Obtener el ID de la maquinaria
      final maquinariaId = maquinaria['id'] as String?;
      if (maquinariaId == null || maquinariaId.isEmpty) {
        throw Exception('ID de maquinaria no válido o vacío');
      }

      print('🔍 Intentando actualizar maquinaria con ID: $maquinariaId');

      // Limpiar el ID si viene en formato ObjectId("hex")
      String cleanId = maquinariaId;
      if (maquinariaId.startsWith('ObjectId(') && maquinariaId.endsWith(')')) {
        cleanId = maquinariaId.substring(9, maquinariaId.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
        print('🔧 ID limpiado de formato ObjectId: $cleanId');
      }

      // Intentar convertir a ObjectId
      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        print('⚠️ No se pudo convertir ID a ObjectId: $e');
        // Intentar buscar la maquinaria por el campo 'id' para obtener su _id
        final maq = await maquinariaCollection?.findOne(
          where.eq('id', cleanId),
        );
        if (maq != null && maq['_id'] != null) {
          final idValue = maq['_id'];
          if (idValue is ObjectId) {
            objectId = idValue;
          } else {
            // Intentar convertir a ObjectId
            objectId = ObjectId.fromHexString(idValue.toString());
          }
          print('✅ Obtenido _id de la maquinaria: $objectId');
        } else {
          throw Exception('No se pudo encontrar la maquinaria con ID: $maquinariaId');
        }
      }

      final updateData = modify
          .set('nombre', maquinaria['nombre'])
          .set('apodo', maquinaria['apodo'])
          .set('modelo', maquinaria['modelo'])
          .set('marca', maquinaria['marca'])
          .set('numeroSerie', maquinaria['numeroSerie'])
          .set('categoriaId', maquinaria['categoriaId'])
          .set('fechaAdquisicion', maquinaria['fechaAdquisicion'])
          .set('valorAdquisicion', maquinaria['valorAdquisicion'])
          .set('estado', maquinaria['estado'])
          .set('ubicacion', maquinaria['ubicacion'])
          .set('descripcion', maquinaria['descripcion'])
          .set('imagenes', maquinaria['imagenes'] ?? [])
          .set('especificaciones', maquinaria['especificaciones'] ?? {})
          .set('fechaUltimoMantenimiento', maquinaria['fechaUltimoMantenimiento'])
          .set('horasUso', maquinaria['horasUso'] ?? 0)
          .set('horasDesdeUltimoMantenimientoMotor', maquinaria['horasDesdeUltimoMantenimientoMotor'] ?? 0.0)
          .set('horasDesdeUltimoMantenimientoHidraulico', maquinaria['horasDesdeUltimoMantenimientoHidraulico'] ?? 0.0)
          .set('activo', maquinaria['activo'] ?? true)
          .set('operadorAsignadoId', maquinaria['operadorAsignadoId'])
          .set('estadoAsignacion', maquinaria['estadoAsignacion'] ?? 'libre');

      final result = await maquinariaCollection?.update(
        where.eq('_id', objectId),
        updateData,
      );
      
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      
      if (nModified > 0) {
        print('✅ Maquinaria actualizada: ${maquinaria['nombre']} (ID: $maquinariaId)');
      } else {
        print('⚠️ No se modificó ningún documento. Verificar que la maquinaria existe.');
      }
    } catch (e) {
      print('❌ Error al actualizar maquinaria: $e');
      rethrow;
    }
  }

  Future<Maquinaria?> consultarMaquinaria(String id) async {
    if (_useApi) return _api.consultarMaquinaria(id);
    await _ensureConnected();
    try {
      if (id.isEmpty) {
        print('⚠️ ID de maquinaria vacío');
        return null;
      }

      // Limpiar el ID si viene en formato ObjectId("hex")
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
        print('🔧 ID limpiado de formato ObjectId: $cleanId');
      }

      // Intentar buscar por _id (ObjectId)
      try {
        ObjectId objectId;
        try {
          objectId = ObjectId.fromHexString(cleanId);
        } catch (e) {
          print('⚠️ No se pudo convertir a ObjectId: $cleanId');
          // Intentar buscar por campo 'id' (String) directamente
          var result = await maquinariaCollection?.findOne(
            where.eq('id', cleanId),
          );
          if (result != null) {
            print('✅ Maquinaria encontrada por campo id: $cleanId');
            return Maquinaria.fromMap(result);
          }
          throw Exception('ID no válido para ObjectId');
        }

        var result = await maquinariaCollection?.findOne(
          where.eq('_id', objectId),
        );
        if (result != null) {
          print('✅ Maquinaria encontrada por _id: $cleanId');
          return Maquinaria.fromMap(result);
        }
      } catch (e) {
        print('⚠️ No se pudo buscar por _id (ObjectId): $e');
      }

      // Intentar buscar por campo 'id' (String)
      try {
        var result = await maquinariaCollection?.findOne(
          where.eq('id', cleanId),
        );
        if (result != null) {
          print('✅ Maquinaria encontrada por campo id: $cleanId');
          return Maquinaria.fromMap(result);
        }
      } catch (e) {
        print('⚠️ No se pudo buscar por campo id: $e');
      }

      print('❌ Maquinaria no encontrada con ID: $id (limpio: $cleanId)');
      return null;
    } catch (e) {
      print('❌ Error al consultar maquinaria: $e');
      return null;
    }
  }

  Future<List<Maquinaria>> consultarTodasMaquinarias({bool soloActivas = true}) async {
    if (_useApi) return _api.consultarTodasMaquinarias(soloActivas: soloActivas);
    await _ensureConnected();
    try {
      var query = soloActivas ? where.eq('activo', true) : where;
      var result = await maquinariaCollection?.find(query).toList();
      return result?.map((e) => Maquinaria.fromMap(e)).toList() ?? [];
    } catch (e) {
      print('❌ Error al consultar todas las maquinarias: $e');
      return [];
    }
  }

  Future<bool> eliminarMaquinaria(String id) async {
    if (_useApi) return _api.eliminarMaquinaria(id);
    await _ensureConnected();
    try {
      var result = await maquinariaCollection?.update(
        where.eq('_id', ObjectId.fromHexString(id)),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('❌ Error al eliminar maquinaria: $e');
      return false;
    }
  }

  // ========= HERRAMIENTAS =========
  Future<void> insertarHerramienta(Map<String, dynamic> herramienta) async {
    if (_useApi) return _api.insertarHerramienta(herramienta);
    await _ensureConnected();
    try {
      if (herramienta.containsKey('id') &&
          (herramienta['id'] ?? '').toString().isNotEmpty) {
        try {
          herramienta['_id'] = ObjectId.fromHexString(herramienta['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${herramienta['id']}');
        }
      }
      await herramientasCollection?.insert(herramienta);
      print('✅ Herramienta insertada: ${herramienta['nombre']}');
    } catch (e) {
      print('❌ Error al insertar herramienta: $e');
      rethrow;
    }
  }

  Future<void> actualizarHerramienta(Map<String, dynamic> herramienta) async {
    if (_useApi) return _api.actualizarHerramienta(herramienta);
    await _ensureConnected();
    try {
      final herramientaId = herramienta['_id'] as String? ?? herramienta['id'] as String?;
      if (herramientaId == null || herramientaId.isEmpty) {
        throw Exception('ID de herramienta no válido');
      }

      final objectId = ObjectId.fromHexString(herramientaId);
      final updateData = modify
          .set('nombre', herramienta['nombre'])
          .set('tipo', herramienta['tipo'])
          .set('marca', herramienta['marca'])
          .set('numeroSerie', herramienta['numeroSerie'])
          .set('descripcion', herramienta['descripcion'])
          .set('condicion', herramienta['condicion'])
          .set('maquinariaId', herramienta['maquinariaId'])
          .set('imagenes', herramienta['imagenes'] ?? [])
          .set('fechaRegistro', herramienta['fechaRegistro'])
          .set('activo', herramienta['activo'] ?? true);

      await herramientasCollection?.update(
        where.eq('_id', objectId),
        updateData,
      );
      print('✅ Herramienta actualizada: ${herramienta['nombre']}');
    } catch (e) {
      print('❌ Error al actualizar herramienta: $e');
      rethrow;
    }
  }

  Future<Herramienta?> consultarHerramienta(String id) async {
    if (_useApi) return _api.consultarHerramienta(id);
    await _ensureConnected();
    try {
      var result = await herramientasCollection?.findOne(
        where.eq('_id', ObjectId.fromHexString(id)),
      );
      if (result == null) {
        result = await herramientasCollection?.findOne(
          where.eq('id', id),
        );
      }
      return result != null ? Herramienta.fromMap(result) : null;
    } catch (e) {
      print('❌ Error al consultar herramienta: $e');
      return null;
    }
  }

  Future<List<Herramienta>> consultarTodasHerramientas({bool soloActivas = true}) async {
    if (_useApi) return _api.consultarTodasHerramientas(soloActivas: soloActivas);
    await _ensureConnected();
    try {
      var query = soloActivas ? where.eq('activo', true) : where;
      var result = await herramientasCollection?.find(query).toList();
      return result?.map((e) => Herramienta.fromMap(e)).toList() ?? [];
    } catch (e) {
      print('❌ Error al consultar todas las herramientas: $e');
      return [];
    }
  }

  Future<bool> eliminarHerramienta(String id) async {
    if (_useApi) return _api.eliminarHerramienta(id);
    await _ensureConnected();
    try {
      var result = await herramientasCollection?.update(
        where.eq('_id', ObjectId.fromHexString(id)),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('❌ Error al eliminar herramienta: $e');
      return false;
    }
  }

  // ========= GASTOS OPERATIVOS =========
  Future<void> insertarGastoOperativo(Map<String, dynamic> gasto) async {
    if (_useApi) return _api.insertarGastoOperativo(gasto);
    await _ensureConnected();
    try {
      if (gasto.containsKey('id') &&
          (gasto['id'] ?? '').toString().isNotEmpty) {
        try {
          gasto['_id'] = ObjectId.fromHexString(gasto['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${gasto['id']}');
        }
      }
      await gastosOperativosCollection?.insert(gasto);
      print('✅ Gasto operativo insertado: ${gasto['tipoGasto']}');
    } catch (e) {
      print('❌ Error al insertar gasto operativo: $e');
      rethrow;
    }
  }

  Future<void> actualizarGastoOperativo(Map<String, dynamic> gasto) async {
    if (_useApi) return _api.actualizarGastoOperativo(gasto);
    await _ensureConnected();
    try {
      final objectId = ObjectId.fromHexString(gasto['id']);
      final updateData = modify
          .set('tipoGasto', gasto['tipoGasto'])
          .set('monto', gasto['monto'])
          .set('fecha', gasto['fecha'])
          .set('descripcion', gasto['descripcion'])
          .set('maquinariaId', gasto['maquinariaId'])
          .set('operadorId', gasto['operadorId'])
          .set('fechaRegistro', gasto['fechaRegistro'])
          .set('activo', gasto['activo'] ?? true);

      await gastosOperativosCollection?.update(
        where.eq('_id', objectId),
        updateData,
      );
      print('✅ Gasto operativo actualizado: ${gasto['tipoGasto']}');
    } catch (e) {
      print('❌ Error al actualizar gasto operativo: $e');
      rethrow;
    }
  }

  Future<GastoOperativo?> consultarGastoOperativo(String id) async {
    if (_useApi) return _api.consultarGastoOperativo(id);
    await _ensureConnected();
    try {
      var result = await gastosOperativosCollection?.findOne(
        where.eq('_id', ObjectId.fromHexString(id)),
      );
      if (result == null) {
        result = await gastosOperativosCollection?.findOne(
          where.eq('id', id),
        );
      }
      return result != null ? GastoOperativo.fromMap(result) : null;
    } catch (e) {
      print('❌ Error al consultar gasto operativo: $e');
      return null;
    }
  }

  Future<List<GastoOperativo>> consultarTodosGastosOperativos({
    bool soloActivos = true,
    String? maquinariaId,
    String? operadorId,
  }) async {
    if (_useApi) return _api.consultarTodosGastosOperativos(maquinariaId: maquinariaId, operadorId: operadorId);
    await _ensureConnected();
    try {
      final query = <String, dynamic>{};
      if (soloActivos) {
        query['activo'] = true;
      }
      if (maquinariaId != null && maquinariaId.isNotEmpty) {
        query['maquinariaId'] = maquinariaId;
      }
      if (operadorId != null && operadorId.isNotEmpty) {
        query['operadorId'] = operadorId;
      }
      var result = await gastosOperativosCollection?.find(query).toList();
      return result?.map((e) => GastoOperativo.fromMap(e)).toList() ?? [];
    } catch (e) {
      print('❌ Error al consultar gastos operativos: $e');
      return [];
    }
  }

  Future<bool> eliminarGastoOperativo(String id) async {
    if (_useApi) return _api.eliminarGastoOperativo(id);
    await _ensureConnected();
    try {
      var result = await gastosOperativosCollection?.update(
        where.eq('_id', ObjectId.fromHexString(id)),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('❌ Error al eliminar gasto operativo: $e');
      return false;
    }
  }

  // ========= CLIENTES =========
  Future<void> insertarCliente(Map<String, dynamic> cliente) async {
    if (_useApi) return _api.insertarCliente(cliente);
    await _ensureConnected();
    try {
      if (cliente.containsKey('id') &&
          (cliente['id'] ?? '').toString().isNotEmpty) {
        try {
          cliente['_id'] = ObjectId.fromHexString(cliente['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${cliente['id']}');
        }
      }
      await clientesCollection?.insert(cliente);
      print('✅ Cliente insertado: ${cliente['nombre']} ${cliente['apellido']}');
    } catch (e) {
      print('❌ Error al insertar cliente: $e');
      rethrow;
    }
  }

  Future<void> actualizarCliente(Map<String, dynamic> cliente) async {
    if (_useApi) return _api.actualizarCliente(cliente);
    await _ensureConnected();
    try {
      final clienteId = cliente['id'] as String?;
      if (clienteId == null || clienteId.isEmpty) {
        throw Exception('ID de cliente no válido');
      }

      String cleanId = clienteId;
      if (clienteId.startsWith('ObjectId(') && clienteId.endsWith(')')) {
        cleanId = clienteId.substring(9, clienteId.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final cli = await clientesCollection?.findOne(where.eq('id', cleanId));
        if (cli != null && cli['_id'] != null) {
          final idValue = cli['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          throw Exception('No se pudo encontrar el cliente con ID: $clienteId');
        }
      }

      final updateData = modify
          .set('nombre', cliente['nombre'])
          .set('apellido', cliente['apellido'])
          .set('empresa', cliente['empresa'])
          .set('email', cliente['email'])
          .set('telefono', cliente['telefono'])
          .set('direccion', cliente['direccion'])
          .set('documentoIdentidad', cliente['documentoIdentidad'])
          .set('activo', cliente['activo'] ?? true);

      await clientesCollection?.update(where.eq('_id', objectId), updateData);
      print('✅ Cliente actualizado: ${cliente['nombre']} ${cliente['apellido']}');
    } catch (e) {
      print('❌ Error al actualizar cliente: $e');
      rethrow;
    }
  }

  Future<Cliente?> consultarCliente(String id) async {
    if (_useApi) return _api.consultarCliente(id);
    await _ensureConnected();
    try {
      if (id.isEmpty) return null;

      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      try {
        final objectId = ObjectId.fromHexString(cleanId);
        var result = await clientesCollection?.findOne(where.eq('_id', objectId));
        if (result != null) return Cliente.fromMap(result);
      } catch (e) {
        // Intentar por campo id
      }

      var result = await clientesCollection?.findOne(where.eq('id', cleanId));
      return result != null ? Cliente.fromMap(result) : null;
    } catch (e) {
      print('❌ Error al consultar cliente: $e');
      return null;
    }
  }

  Future<List<Cliente>> consultarTodosClientes({bool soloActivos = true}) async {
    if (_useApi) return _api.consultarTodosClientes(soloActivos: soloActivos);
    await _ensureConnected();
    try {
      var query = soloActivos ? where.eq('activo', true) : where;
      var result = await clientesCollection?.find(query).toList();
      return result?.map((e) => Cliente.fromMap(e)).toList() ?? [];
    } catch (e) {
      print('❌ Error al consultar todos los clientes: $e');
      return [];
    }
  }

  Future<bool> eliminarCliente(String id) async {
    if (_useApi) return _api.eliminarCliente(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final cli = await clientesCollection?.findOne(where.eq('id', cleanId));
        if (cli != null && cli['_id'] != null) {
          final idValue = cli['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          return false;
        }
      }

      var result = await clientesCollection?.update(
        where.eq('_id', objectId),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('❌ Error al eliminar cliente: $e');
      return false;
    }
  }

  // ========= ALQUILERES =========
  Future<void> insertarAlquiler(Map<String, dynamic> alquiler) async {
    if (_useApi) return _api.insertarAlquiler(alquiler);
    await _ensureConnected();
    try {
      if (alquiler.containsKey('id') &&
          (alquiler['id'] ?? '').toString().isNotEmpty) {
        try {
          alquiler['_id'] = ObjectId.fromHexString(alquiler['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${alquiler['id']}');
        }
      }
      await alquileresCollection?.insert(alquiler);
      print('✅ Alquiler insertado: ${alquiler['id']}');
    } catch (e) {
      print('❌ Error al insertar alquiler: $e');
      rethrow;
    }
  }

  Future<void> actualizarAlquiler(Map<String, dynamic> alquiler) async {
    if (_useApi) return _api.actualizarAlquiler(alquiler);
    await _ensureConnected();
    try {
      final alquilerId = alquiler['id'] as String?;
      if (alquilerId == null || alquilerId.isEmpty) {
        throw Exception('ID de alquiler no válido');
      }

      String cleanId = alquilerId;
      if (alquilerId.startsWith('ObjectId(') && alquilerId.endsWith(')')) {
        cleanId = alquilerId.substring(9, alquilerId.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final alq = await alquileresCollection?.findOne(where.eq('id', cleanId));
        if (alq != null && alq['_id'] != null) {
          final idValue = alq['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          throw Exception('No se pudo encontrar el alquiler con ID: $alquilerId');
        }
      }

      var updateData = modify
          .set('clienteId', alquiler['clienteId'])
          .set('maquinariaId', alquiler['maquinariaId'])
          .set('fechaInicio', alquiler['fechaInicio'])
          .set('fechaFin', alquiler['fechaFin'])
          .set('horasAlquiler', alquiler['horasAlquiler'])
          .set('tipoAlquiler', alquiler['tipoAlquiler'] ?? 'horas')
          .set('monto', alquiler['monto'])
          .set('proyecto', alquiler['proyecto'])
          .set('estado', alquiler['estado'])
          .set('observaciones', alquiler['observaciones'])
          .set('fechaEntrega', alquiler['fechaEntrega'])
          .set('fechaDevolucion', alquiler['fechaDevolucion'])
          .set('horasUsoReal', alquiler['horasUsoReal'])
          .set('activo', alquiler['activo'] ?? true)
          .set('proyectoFinalizado', alquiler['proyectoFinalizado'] ?? false);
      
      // Actualizar campos opcionales si existen
      if (alquiler.containsKey('montoAdelanto')) {
        updateData = updateData.set('montoAdelanto', alquiler['montoAdelanto']);
      }
      if (alquiler.containsKey('montoCancelado')) {
        updateData = updateData.set('montoCancelado', alquiler['montoCancelado']);
        print('💰 Actualizando montoCancelado en BD: ${alquiler['montoCancelado']}');
      }
      if (alquiler.containsKey('metodoPago')) {
        updateData = updateData.set('metodoPago', alquiler['metodoPago']);
      }
      if (alquiler.containsKey('codigoQR')) {
        updateData = updateData.set('codigoQR', alquiler['codigoQR']);
      }
      if (alquiler.containsKey('especificaciones')) {
        updateData = updateData.set('especificaciones', alquiler['especificaciones']);
      }

      await alquileresCollection?.update(where.eq('_id', objectId), updateData);
      print('✅ Alquiler actualizado: ${alquiler['id']}');
    } catch (e) {
      print('❌ Error al actualizar alquiler: $e');
      rethrow;
    }
  }

  Future<Alquiler?> consultarAlquiler(String id) async {
    if (_useApi) return _api.consultarAlquiler(id);
    await _ensureConnected();
    try {
      if (id.isEmpty) return null;

      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      try {
        final objectId = ObjectId.fromHexString(cleanId);
        var result = await alquileresCollection?.findOne(where.eq('_id', objectId));
        if (result != null) return Alquiler.fromMap(result);
      } catch (e) {
        // Intentar por campo id
      }

      var result = await alquileresCollection?.findOne(where.eq('id', cleanId));
      return result != null ? Alquiler.fromMap(result) : null;
    } catch (e) {
      print('❌ Error al consultar alquiler: $e');
      return null;
    }
  }

  Future<List<Alquiler>> consultarTodosAlquileres({
    bool soloActivos = true,
    String? clienteId,
    String? maquinariaId,
    String? estado,
  }) async {
    if (_useApi) return _api.consultarTodosAlquileres(estado: estado);
    await _ensureConnected();
    try {
      final query = <String, dynamic>{};
      if (soloActivos) {
        query['activo'] = true;
      }
      if (clienteId != null && clienteId.isNotEmpty) {
        query['clienteId'] = clienteId;
      }
      if (maquinariaId != null && maquinariaId.isNotEmpty) {
        query['maquinariaId'] = maquinariaId;
      }
      if (estado != null && estado.isNotEmpty) {
        query['estado'] = estado;
      }
      var result = await alquileresCollection?.find(query).toList();
      return result?.map((e) => Alquiler.fromMap(e)).toList() ?? [];
    } catch (e) {
      print('❌ Error al consultar todos los alquileres: $e');
      return [];
    }
  }

  Future<bool> eliminarAlquiler(String id) async {
    if (_useApi) return _api.eliminarAlquiler(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final alq = await alquileresCollection?.findOne(where.eq('id', cleanId));
        if (alq != null && alq['_id'] != null) {
          final idValue = alq['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          return false;
        }
      }

      var result = await alquileresCollection?.update(
        where.eq('_id', objectId),
        modify.set('activo', false),
      );
      final r = result as Map?;
      int nModified = (r?['nModified'] ?? r?['n'] ?? 0) is int
          ? (r?['nModified'] ?? r?['n'] ?? 0)
          : 0;
      return nModified > 0;
    } catch (e) {
      print('❌ Error al eliminar alquiler: $e');
      return false;
    }
  }

  // ========= PAGOS =========
  Future<void> insertarPago(Map<String, dynamic> pago) async {
    if (_useApi) return _api.insertarPago(pago);
    await _ensureConnected();
    try {
      if (pago.containsKey('id') && (pago['id'] ?? '').toString().isNotEmpty) {
        try {
          pago['_id'] = ObjectId.fromHexString(pago['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${pago['id']}');
        }
      }
      await pagosCollection?.insert(pago);
      print('✅ Pago insertado: ${pago['id']}');
    } catch (e) {
      print('❌ Error al insertar pago: $e');
      rethrow;
    }
  }

  Future<void> actualizarPago(Map<String, dynamic> pago) async {
    if (_useApi) return _api.actualizarPago(pago);
    await _ensureConnected();
    try {
      final pagoId = pago['id'] as String?;
      if (pagoId == null || pagoId.isEmpty) {
        throw Exception('ID de pago no válido');
      }

      String cleanId = pagoId;
      if (pagoId.startsWith('ObjectId(') && pagoId.endsWith(')')) {
        cleanId = pagoId.substring(9, pagoId.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final p = await pagosCollection?.findOne(where.eq('id', cleanId));
        if (p != null && p['_id'] != null) {
          final idValue = p['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          throw Exception('No se pudo encontrar el pago con ID: $pagoId');
        }
      }

      var updateData = modify;
      pago.forEach((key, value) {
        if (key != 'id' && key != '_id') {
          updateData = updateData.set(key, value);
        }
      });

      await pagosCollection?.update(where.eq('_id', objectId), updateData);
      print('✅ Pago actualizado: $pagoId');
    } catch (e) {
      print('❌ Error al actualizar pago: $e');
      rethrow;
    }
  }

  Future<Pago?> consultarPago(String id) async {
    if (_useApi) return _api.consultarPago(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId? objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        // Intentar buscar por el campo 'id'
        final p = await pagosCollection?.findOne(where.eq('id', cleanId));
        if (p != null && p['_id'] != null) {
          final idValue = p['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        }
      }

      if (objectId == null) {
        return null;
      }

      final result = await pagosCollection?.findOne(where.eq('_id', objectId));
      if (result == null) return null;
      return Pago.fromMap(result);
    } catch (e) {
      print('❌ Error al consultar pago: $e');
      return null;
    }
  }

  Future<List<Pago>> consultarPagosPorContrato(String contratoId) async {
    if (_useApi) return _api.consultarPagosPorContrato(contratoId);
    await _ensureConnected();
    try {
      var result = await pagosCollection?.find(where.eq('contratoId', contratoId)).toList();
      return result?.map((e) => Pago.fromMap(e)).toList() ?? [];
    } catch (e) {
      print('❌ Error al consultar pagos por contrato: $e');
      return [];
    }
  }

  Future<bool> eliminarPago(String id) async {
    if (_useApi) return _api.eliminarPago(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final p = await pagosCollection?.findOne(where.eq('id', cleanId));
        if (p != null && p['_id'] != null) {
          final idValue = p['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          return false;
        }
      }

      var result = await pagosCollection?.remove(where.eq('_id', objectId));
      return result != null;
    } catch (e) {
      print('❌ Error al eliminar pago: $e');
      return false;
    }
  }

  // ========= ANÁLISIS =========
  Future<void> insertarAnalisis(Map<String, dynamic> analisis) async {
    if (_useApi) return _api.insertarAnalisis(analisis);
    await _ensureConnected();
    try {
      if (analisis.containsKey('id') &&
          (analisis['id'] ?? '').toString().isNotEmpty) {
        try {
          analisis['_id'] = ObjectId.fromHexString(analisis['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${analisis['id']}');
        }
      }
      await analisisCollection?.insert(analisis);
      print('✅ Análisis insertado: ${analisis['id']}');
    } catch (e) {
      print('❌ Error al insertar análisis: $e');
      rethrow;
    }
  }

  Future<void> actualizarAnalisis(Map<String, dynamic> analisis) async {
    if (_useApi) return _api.actualizarAnalisis(analisis);
    await _ensureConnected();
    try {
      final analisisId = analisis['id'] as String?;
      if (analisisId == null || analisisId.isEmpty) {
        throw Exception('ID de análisis no válido');
      }

      String cleanId = analisisId;
      if (analisisId.startsWith('ObjectId(') && analisisId.endsWith(')')) {
        cleanId = analisisId.substring(9, analisisId.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final a = await analisisCollection?.findOne(where.eq('id', cleanId));
        if (a != null && a['_id'] != null) {
          final idValue = a['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          throw Exception('No se pudo encontrar el análisis con ID: $analisisId');
        }
      }

      var updateData = modify;
      analisis.forEach((key, value) {
        if (key != 'id' && key != '_id') {
          updateData = updateData.set(key, value);
        }
      });

      await analisisCollection?.update(where.eq('_id', objectId), updateData);
      print('✅ Análisis actualizado: $analisisId');
    } catch (e) {
      print('❌ Error al actualizar análisis: $e');
      rethrow;
    }
  }

  Future<Analisis?> consultarAnalisis(String id) async {
    if (_useApi) return _api.consultarAnalisis(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId? objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        // Intentar buscar por campo 'id' si no es ObjectId válido
        var result = await analisisCollection?.findOne(where.eq('id', cleanId));
        if (result != null) {
          return Analisis.fromMap(result);
        }
        return null;
      }

      var result = await analisisCollection?.findOne(where.eq('_id', objectId));
      if (result != null) {
        // Asegurar que el 'id' esté presente en el map
        if (!result.containsKey('id') && result.containsKey('_id')) {
          result['id'] = result['_id'].toString();
        }
        return Analisis.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Error al consultar análisis: $e');
      return null;
    }
  }

  Future<List<Analisis>> consultarTodosAnalisis() async {
    if (_useApi) return _api.consultarTodosAnalisis();
    await _ensureConnected();
    try {
      var results = await analisisCollection?.find().toList() ?? [];
      return results.map((e) {
        // Asegurar que el 'id' esté presente
        if (!e.containsKey('id') && e.containsKey('_id')) {
          e['id'] = e['_id'].toString();
        }
        return Analisis.fromMap(e);
      }).toList();
    } catch (e) {
      print('❌ Error al consultar todos los análisis: $e');
      return [];
    }
  }

  Future<List<Analisis>> consultarAnalisisPorMaquinaria(String maquinariaId) async {
    if (_useApi) return _api.consultarAnalisisPorMaquinaria(maquinariaId);
    await _ensureConnected();
    try {
      var results = await analisisCollection?.find(where.eq('maquinariaId', maquinariaId)).toList() ?? [];
      return results.map((e) {
        // Asegurar que el 'id' esté presente
        if (!e.containsKey('id') && e.containsKey('_id')) {
          e['id'] = e['_id'].toString();
        }
        return Analisis.fromMap(e);
      }).toList();
    } catch (e) {
      print('❌ Error al consultar análisis por maquinaria: $e');
      return [];
    }
  }

  Future<List<Analisis>> consultarAnalisisPorResultado(String resultado) async {
    if (_useApi) return _api.consultarAnalisisPorResultado(resultado);
    await _ensureConnected();
    try {
      var results = await analisisCollection?.find(where.eq('resultado', resultado)).toList() ?? [];
      return results.map((e) {
        // Asegurar que el 'id' esté presente
        if (!e.containsKey('id') && e.containsKey('_id')) {
          e['id'] = e['_id'].toString();
        }
        return Analisis.fromMap(e);
      }).toList();
    } catch (e) {
      print('❌ Error al consultar análisis por resultado: $e');
      return [];
    }
  }

  Future<bool> eliminarAnalisis(String id) async {
    if (_useApi) return _api.eliminarAnalisis(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final a = await analisisCollection?.findOne(where.eq('id', cleanId));
        if (a != null && a['_id'] != null) {
          final idValue = a['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          return false;
        }
      }

      var result = await analisisCollection?.remove(where.eq('_id', objectId));
      final r = result as Map?;
      int nRemoved = (r?['nRemoved'] ?? r?['n'] ?? 0) is int
          ? (r?['nRemoved'] ?? r?['n'] ?? 0)
          : 0;
      return nRemoved > 0;
    } catch (e) {
      print('❌ Error al eliminar análisis: $e');
      return false;
    }
  }

  /// Elimina análisis antiguos (más de X días) de una máquina específica
  Future<int> eliminarAnalisisAntiguos(String maquinariaId, {int diasAntiguedad = 7}) async {
    await _ensureConnected();
    try {
      final fechaLimite = DateTime.now().subtract(Duration(days: diasAntiguedad));
      
      var result = await analisisCollection?.remove(
        where.eq('maquinariaId', maquinariaId).lt('fechaAnalisis', fechaLimite)
      );
      
      final r = result as Map?;
      int nRemoved = (r?['nRemoved'] ?? r?['n'] ?? 0) is int
          ? (r?['nRemoved'] ?? r?['n'] ?? 0)
          : 0;
      
      if (nRemoved > 0) {
        print('✅ Eliminados $nRemoved análisis antiguos (más de $diasAntiguedad días) para máquina $maquinariaId');
      }
      
      return nRemoved;
    } catch (e) {
      print('❌ Error al eliminar análisis antiguos: $e');
      return 0;
    }
  }

  /// Elimina TODOS los análisis de una máquina específica
  /// Útil cuando se registran nuevos parámetros y se quiere reemplazar todos los anteriores
  Future<int> eliminarTodosAnalisis(String maquinariaId) async {
    await _ensureConnected();
    try {
      var result = await analisisCollection?.remove(
        where.eq('maquinariaId', maquinariaId)
      );
      
      final r = result as Map?;
      int nRemoved = (r?['nRemoved'] ?? r?['n'] ?? 0) is int
          ? (r?['nRemoved'] ?? r?['n'] ?? 0)
          : 0;
      
      if (nRemoved > 0) {
        print('✅ Eliminados TODOS los $nRemoved análisis anteriores para máquina $maquinariaId (serán reemplazados por nuevos)');
      }
      
      return nRemoved;
    } catch (e) {
      print('❌ Error al eliminar todos los análisis: $e');
      return 0;
    }
  }

  // ========= REGISTROS DE MANTENIMIENTO =========
  Future<void> insertarRegistroMantenimiento(Map<String, dynamic> registro) async {
    if (_useApi) return _api.insertarRegistroMantenimiento(registro);
    await _ensureConnected();
    try {
      if (registro.containsKey('id') &&
          (registro['id'] ?? '').toString().isNotEmpty) {
        try {
          registro['_id'] = ObjectId.fromHexString(registro['id'].toString());
        } catch (e) {
          print('⚠️ ID no válido para ObjectId: ${registro['id']}');
        }
      }
      await registrosMantenimientoCollection?.insert(registro);
      print('✅ Registro de mantenimiento insertado: ${registro['id']}');
    } catch (e) {
      print('❌ Error al insertar registro de mantenimiento: $e');
      rethrow;
    }
  }

  Future<void> actualizarRegistroMantenimiento(Map<String, dynamic> registro) async {
    if (_useApi) return _api.actualizarRegistroMantenimiento(registro);
    await _ensureConnected();
    try {
      final registroId = registro['id'] as String?;
      if (registroId == null || registroId.isEmpty) {
        throw Exception('ID de registro de mantenimiento no válido');
      }

      String cleanId = registroId;
      if (registroId.startsWith('ObjectId(') && registroId.endsWith(')')) {
        cleanId = registroId.substring(9, registroId.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final r = await registrosMantenimientoCollection?.findOne(where.eq('id', cleanId));
        if (r != null && r['_id'] != null) {
          final idValue = r['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          throw Exception('No se pudo encontrar el registro con ID: $registroId');
        }
      }

      var updateData = modify;
      registro.forEach((key, value) {
        if (key != 'id' && key != '_id') {
          updateData = updateData.set(key, value);
        }
      });

      await registrosMantenimientoCollection?.update(where.eq('_id', objectId), updateData);
      print('✅ Registro de mantenimiento actualizado: $registroId');
    } catch (e) {
      print('❌ Error al actualizar registro de mantenimiento: $e');
      rethrow;
    }
  }

  Future<RegistroMantenimiento?> consultarRegistroMantenimiento(String id) async {
    if (_useApi) return _api.consultarRegistroMantenimiento(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId? objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        var result = await registrosMantenimientoCollection?.findOne(where.eq('id', cleanId));
        if (result != null) {
          return RegistroMantenimiento.fromMap(result);
        }
        return null;
      }

      var result = await registrosMantenimientoCollection?.findOne(where.eq('_id', objectId));
      if (result != null) {
        if (!result.containsKey('id') && result.containsKey('_id')) {
          result['id'] = result['_id'].toString();
        }
        return RegistroMantenimiento.fromMap(result);
      }
      return null;
    } catch (e) {
      print('❌ Error al consultar registro de mantenimiento: $e');
      return null;
    }
  }

  Future<List<RegistroMantenimiento>> consultarTodosRegistrosMantenimiento() async {
    if (_useApi) return _api.consultarTodosRegistrosMantenimiento();
    await _ensureConnected();
    try {
      var results = await registrosMantenimientoCollection?.find().toList() ?? [];
      return results.map((e) {
        if (!e.containsKey('id') && e.containsKey('_id')) {
          e['id'] = e['_id'].toString();
        }
        return RegistroMantenimiento.fromMap(e);
      }).toList();
    } catch (e) {
      print('❌ Error al consultar todos los registros de mantenimiento: $e');
      return [];
    }
  }

  Future<List<RegistroMantenimiento>> consultarRegistrosMantenimientoPorMaquinaria(String maquinariaId) async {
    if (_useApi) return _api.consultarRegistrosMantenimientoPorMaquinaria(maquinariaId);
    await _ensureConnected();
    try {
      var results = await registrosMantenimientoCollection?.find(where.eq('idMaquinaria', maquinariaId)).toList() ?? [];
      return results.map((e) {
        if (!e.containsKey('id') && e.containsKey('_id')) {
          e['id'] = e['_id'].toString();
        }
        return RegistroMantenimiento.fromMap(e);
      }).toList();
    } catch (e) {
      print('❌ Error al consultar registros por maquinaria: $e');
      return [];
    }
  }

  Future<List<RegistroMantenimiento>> consultarRegistrosMantenimientoPorEstado(String estado) async {
    if (_useApi) return _api.consultarRegistrosMantenimientoPorEstado(estado);
    await _ensureConnected();
    try {
      var results = await registrosMantenimientoCollection?.find(where.eq('estado', estado)).toList() ?? [];
      return results.map((e) {
        if (!e.containsKey('id') && e.containsKey('_id')) {
          e['id'] = e['_id'].toString();
        }
        return RegistroMantenimiento.fromMap(e);
      }).toList();
    } catch (e) {
      print('❌ Error al consultar registros por estado: $e');
      return [];
    }
  }

  Future<bool> eliminarRegistroMantenimiento(String id) async {
    if (_useApi) return _api.eliminarRegistroMantenimiento(id);
    await _ensureConnected();
    try {
      String cleanId = id;
      if (id.startsWith('ObjectId(') && id.endsWith(')')) {
        cleanId = id.substring(9, id.length - 2).replaceAll('"', '').replaceAll("'", '').trim();
      }

      ObjectId objectId;
      try {
        objectId = ObjectId.fromHexString(cleanId);
      } catch (e) {
        final r = await registrosMantenimientoCollection?.findOne(where.eq('id', cleanId));
        if (r != null && r['_id'] != null) {
          final idValue = r['_id'];
          objectId = idValue is ObjectId ? idValue : ObjectId.fromHexString(idValue.toString());
        } else {
          return false;
        }
      }

      var result = await registrosMantenimientoCollection?.remove(where.eq('_id', objectId));
      final r = result as Map?;
      int nRemoved = (r?['nRemoved'] ?? r?['n'] ?? 0) is int
          ? (r?['nRemoved'] ?? r?['n'] ?? 0)
          : 0;
      return nRemoved > 0;
    } catch (e) {
      print('❌ Error al eliminar registro de mantenimiento: $e');
      return false;
    }
  }

  // ========= DESCONECTAR =========
  Future<void> cerrarConexion() async {
    _cancelarKeepAlive();
    if (db != null && isConnected) {
      await db?.close();
      db = null;
      usuariosCollection = null;
      rolesCollection = null;
      permisosCollection = null;
      maquinariaCollection = null;
      herramientasCollection = null;
      gastosOperativosCollection = null;
      clientesCollection = null;
      alquileresCollection = null;
      pagosCollection = null;
      analisisCollection = null;
      registrosMantenimientoCollection = null;
      print('🔒 Conexión MongoDB cerrada');
    } else {
      print('⚠️ No hay conexión activa para cerrar');
    }
  }
}
