import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/usuario.dart';
import '../../models/rol.dart';
import '../../models/permiso.dart';
import '../../models/maquinaria.dart';
import '../../models/herramienta.dart';
import '../../models/gasto_operativo.dart';
import '../../models/cliente.dart';
import '../../models/alquiler.dart';
import '../../models/pago.dart';
import '../../models/analisis.dart';
import '../../models/registro_mantenimiento.dart';

/// Cliente HTTP para la API REST de Tracktoger.
/// Reemplaza la conexión directa a MongoDB cuando API_BASE_URL está configurada.
class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl) {
    if (!baseUrl.endsWith('/')) {}
  }

  String get _base => baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  Future<Map<String, dynamic>?> _get(String path) async {
    final r = await http.get(Uri.parse('$_base$path'));
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw Exception('API Error ${r.statusCode}: ${r.body}');
    return r.body.isEmpty ? null : jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(String path, [Map<String, String>? query]) async {
    var uri = Uri.parse('$_base$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final r = await http.get(uri);
    if (r.statusCode >= 400) throw Exception('API Error ${r.statusCode}: ${r.body}');
    final list = jsonDecode(r.body);
    return list is List ? list.cast<dynamic>() : [];
  }

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode >= 400) throw Exception('API Error ${r.statusCode}: ${r.body}');
  }

  Future<void> _put(String path, Map<String, dynamic> body) async {
    final r = await http.put(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode >= 400) throw Exception('API Error ${r.statusCode}: ${r.body}');
  }

  Future<bool> _delete(String path) async {
    final r = await http.delete(Uri.parse('$_base$path'));
    if (r.statusCode >= 400) throw Exception('API Error ${r.statusCode}: ${r.body}');
    if (r.body.isEmpty) return true;
    final m = jsonDecode(r.body) as Map<String, dynamic>?;
    return m?['ok'] == true;
  }

  // --- Usuarios ---
  Future<Usuario?> consultarUsuarioPorEmail(String email) async {
    final m = await _get('api/usuarios/email/${Uri.encodeComponent(email)}');
    return m != null ? Usuario.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<Usuario?> consultarUsuario(String id) async {
    final m = await _get('api/usuarios/$id');
    return m != null ? Usuario.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Usuario>> consultarTodosUsuarios() async {
    final list = await _getList('api/usuarios');
    return list.map((e) => Usuario.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarUsuario(Map<String, dynamic> usuario) async {
    await _post('api/usuarios', usuario);
  }

  Future<void> actualizarUsuario(Map<String, dynamic> usuario) async {
    final id = usuario['_id'] ?? usuario['id'];
    if (id == null) throw Exception('ID de usuario no válido');
    await _put('api/usuarios/$id', usuario);
  }

  Future<bool> eliminarUsuario(String id) async {
    return _delete('api/usuarios/$id');
  }

  Future<bool> actualizarEstadoUsuarioAVerificado(String userId) async {
    final r = await http.put(
      Uri.parse('${_base}api/usuarios/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'activo': true}),
    );
    if (r.statusCode >= 400) return false;
    try {
      final m = jsonDecode(r.body) as Map<String, dynamic>?;
      return m?['ok'] == true;
    } catch (_) {
      return r.statusCode == 200;
    }
  }

  Future<bool> actualizarCodigoVerificacion(String userId, String codigo) async {
    final r = await http.put(
      Uri.parse('${_base}api/usuarios/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'codigoVerificacion': codigo}),
    );
    if (r.statusCode >= 400) return false;
    try {
      final m = jsonDecode(r.body) as Map<String, dynamic>?;
      return m?['ok'] == true;
    } catch (_) {
      return r.statusCode == 200;
    }
  }

  // --- Roles ---
  Future<Rol?> consultarRol(String id) async {
    final m = await _get('api/roles/$id');
    return m != null ? Rol.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Rol>> consultarTodosRoles() async {
    final list = await _getList('api/roles');
    return list.map((e) => Rol.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarRol(Map<String, dynamic> rol) async => _post('api/roles', rol);
  Future<void> actualizarRol(Map<String, dynamic> rol) async {
    final id = rol['_id'] ?? rol['id'];
    if (id == null) throw Exception('ID de rol no válido');
    await _put('api/roles/$id', rol);
  }
  Future<bool> eliminarRol(String id) async => _delete('api/roles/$id');

  // --- Permisos ---
  Future<Permiso?> consultarPermiso(String id) async {
    final m = await _get('api/permisos/$id');
    return m != null ? Permiso.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Permiso>> consultarTodosPermisos() async {
    final list = await _getList('api/permisos');
    return list.map((e) => Permiso.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarPermiso(Map<String, dynamic> m) async => _post('api/permisos', m);
  Future<bool> eliminarPermiso(String id) async => _delete('api/permisos/$id');

  // --- Maquinaria ---
  Future<Maquinaria?> consultarMaquinaria(String id) async {
    final m = await _get('api/maquinaria/$id');
    return m != null ? Maquinaria.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Maquinaria>> consultarTodasMaquinarias({bool soloActivas = true}) async {
    final list = await _getList('api/maquinaria', soloActivas ? {'soloActivas': 'true'} : {});
    return list.map((e) => Maquinaria.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarMaquinaria(Map<String, dynamic> m) async => _post('api/maquinaria', m);
  Future<void> actualizarMaquinaria(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/maquinaria/$id', m);
  }
  Future<bool> eliminarMaquinaria(String id) async => _delete('api/maquinaria/$id');

  // --- Herramientas ---
  Future<Herramienta?> consultarHerramienta(String id) async {
    final m = await _get('api/herramientas/$id');
    return m != null ? Herramienta.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Herramienta>> consultarTodasHerramientas({bool soloActivas = true}) async {
    final list = await _getList('api/herramientas', soloActivas ? {'soloActivas': 'true'} : {});
    return list.map((e) => Herramienta.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarHerramienta(Map<String, dynamic> m) async => _post('api/herramientas', m);
  Future<void> actualizarHerramienta(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/herramientas/$id', m);
  }
  Future<bool> eliminarHerramienta(String id) async => _delete('api/herramientas/$id');

  // --- Gastos operativos ---
  Future<GastoOperativo?> consultarGastoOperativo(String id) async {
    final m = await _get('api/gastos-operativos/$id');
    return m != null ? GastoOperativo.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<GastoOperativo>> consultarTodosGastosOperativos({String? maquinariaId, String? operadorId}) async {
    final q = <String, String>{};
    if (maquinariaId != null) q['maquinariaId'] = maquinariaId;
    if (operadorId != null) q['operadorId'] = operadorId;
    final list = await _getList('api/gastos-operativos', q.isEmpty ? null : q);
    return list.map((e) => GastoOperativo.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarGastoOperativo(Map<String, dynamic> m) async => _post('api/gastos-operativos', m);
  Future<void> actualizarGastoOperativo(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/gastos-operativos/$id', m);
  }
  Future<bool> eliminarGastoOperativo(String id) async => _delete('api/gastos-operativos/$id');

  // --- Clientes ---
  Future<Cliente?> consultarCliente(String id) async {
    final m = await _get('api/clientes/$id');
    return m != null ? Cliente.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Cliente>> consultarTodosClientes({bool soloActivos = true}) async {
    final list = await _getList('api/clientes', soloActivos ? {'soloActivos': 'true'} : {});
    return list.map((e) => Cliente.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarCliente(Map<String, dynamic> m) async => _post('api/clientes', m);
  Future<void> actualizarCliente(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/clientes/$id', m);
  }
  Future<bool> eliminarCliente(String id) async => _delete('api/clientes/$id');

  // --- Alquileres ---
  Future<Alquiler?> consultarAlquiler(String id) async {
    final m = await _get('api/alquileres/$id');
    return m != null ? Alquiler.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Alquiler>> consultarTodosAlquileres({String? estado}) async {
    final q = estado != null ? {'estado': estado} : null;
    final list = await _getList('api/alquileres', q);
    return list.map((e) => Alquiler.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarAlquiler(Map<String, dynamic> m) async => _post('api/alquileres', m);
  Future<void> actualizarAlquiler(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/alquileres/$id', m);
  }
  Future<bool> eliminarAlquiler(String id) async => _delete('api/alquileres/$id');

  // --- Pagos ---
  Future<Pago?> consultarPago(String id) async {
    final m = await _get('api/pagos/$id');
    return m != null ? Pago.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Pago>> consultarPagosPorContrato(String contratoId) async {
    final list = await _getList('api/pagos/contrato/$contratoId');
    return list.map((e) => Pago.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarPago(Map<String, dynamic> m) async => _post('api/pagos', m);
  Future<void> actualizarPago(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/pagos/$id', m);
  }
  Future<bool> eliminarPago(String id) async => _delete('api/pagos/$id');

  // --- Análisis ---
  Future<Analisis?> consultarAnalisis(String id) async {
    final m = await _get('api/analisis/$id');
    return m != null ? Analisis.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<Analisis>> consultarTodosAnalisis() async {
    final list = await _getList('api/analisis');
    return list.map((e) => Analisis.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Analisis>> consultarAnalisisPorMaquinaria(String maquinariaId) async {
    final list = await _getList('api/analisis/maquinaria/$maquinariaId');
    return list.map((e) => Analisis.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Analisis>> consultarAnalisisPorResultado(String resultado) async {
    final list = await _getList('api/analisis/resultado/${Uri.encodeComponent(resultado)}');
    return list.map((e) => Analisis.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarAnalisis(Map<String, dynamic> m) async => _post('api/analisis', m);
  Future<void> actualizarAnalisis(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/analisis/$id', m);
  }
  Future<bool> eliminarAnalisis(String id) async => _delete('api/analisis/$id');

  // --- Registros mantenimiento ---
  Future<RegistroMantenimiento?> consultarRegistroMantenimiento(String id) async {
    final m = await _get('api/registros-mantenimiento/$id');
    return m != null ? RegistroMantenimiento.fromMap(Map<String, dynamic>.from(m)) : null;
  }

  Future<List<RegistroMantenimiento>> consultarTodosRegistrosMantenimiento() async {
    final list = await _getList('api/registros-mantenimiento');
    return list.map((e) => RegistroMantenimiento.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<RegistroMantenimiento>> consultarRegistrosMantenimientoPorMaquinaria(String maquinariaId) async {
    final list = await _getList('api/registros-mantenimiento/maquinaria/$maquinariaId');
    return list.map((e) => RegistroMantenimiento.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<RegistroMantenimiento>> consultarRegistrosMantenimientoPorEstado(String estado) async {
    final list = await _getList('api/registros-mantenimiento/estado/${Uri.encodeComponent(estado)}');
    return list.map((e) => RegistroMantenimiento.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> insertarRegistroMantenimiento(Map<String, dynamic> m) async =>
      _post('api/registros-mantenimiento', m);
  Future<void> actualizarRegistroMantenimiento(Map<String, dynamic> m) async {
    final id = m['_id'] ?? m['id'];
    if (id == null) throw Exception('ID no válido');
    await _put('api/registros-mantenimiento/$id', m);
  }
  Future<bool> eliminarRegistroMantenimiento(String id) async =>
      _delete('api/registros-mantenimiento/$id');

  /// Verificar que la API responde (equivalente a verificarConexion)
  Future<bool> verificarConexion() async {
    try {
      final r = await http.get(Uri.parse('${_base}api/health')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
