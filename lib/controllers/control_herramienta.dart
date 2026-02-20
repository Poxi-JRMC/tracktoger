import 'package:mongo_dart/mongo_dart.dart';
import '../models/herramienta.dart';
import '../data/services/database_service.dart';

/// Controlador para la gestión de herramientas
/// Maneja las operaciones CRUD de herramientas usando MongoDB
class ControlHerramienta {
  final DatabaseService _dbService = DatabaseService();

  // ========== MÉTODOS PARA HERRAMIENTAS ==========

  /// Registra una nueva herramienta en el inventario
  Future<Herramienta> registrarHerramienta(Herramienta herramienta) async {
    // Generar ID si no viene
    String herramientaId = herramienta.id;
    if (herramientaId.isEmpty) {
      herramientaId = ObjectId().toHexString();
    }

    // Validar que el número de serie sea único (si se proporciona)
    if (herramienta.numeroSerie != null && herramienta.numeroSerie!.isNotEmpty) {
      final todas = await consultarTodasHerramientas();
      if (todas.any((h) => 
          h.numeroSerie == herramienta.numeroSerie && 
          h.numeroSerie != null && 
          h.numeroSerie!.isNotEmpty &&
          h.id != herramientaId)) {
        throw Exception('Ya existe una herramienta con ese número de serie');
      }
    }

    final herramientaToInsert = herramienta.copyWith(id: herramientaId);
    await _dbService.insertarHerramienta(herramientaToInsert.toMap());
    return herramientaToInsert;
  }

  /// Actualiza una herramienta existente
  Future<Herramienta> actualizarHerramienta(Herramienta herramienta) async {
    final existente = await consultarHerramienta(herramienta.id);
    if (existente == null) {
      throw Exception('Herramienta no encontrada');
    }

    // Validar número de serie único (si se proporciona)
    if (herramienta.numeroSerie != null && herramienta.numeroSerie!.isNotEmpty) {
      final todas = await consultarTodasHerramientas();
      if (todas.any((h) => 
          h.numeroSerie == herramienta.numeroSerie && 
          h.numeroSerie != null && 
          h.numeroSerie!.isNotEmpty &&
          h.id != herramienta.id)) {
        throw Exception('Ya existe otra herramienta con ese número de serie');
      }
    }

    await _dbService.actualizarHerramienta(herramienta.toMap());
    return herramienta;
  }

  /// Obtiene una herramienta por su ID
  Future<Herramienta?> consultarHerramienta(String id) async {
    return await _dbService.consultarHerramienta(id);
  }

  /// Obtiene todas las herramientas
  Future<List<Herramienta>> consultarTodasHerramientas({bool soloActivas = true}) async {
    return await _dbService.consultarTodasHerramientas(soloActivas: soloActivas);
  }

  /// Obtiene herramientas por tipo
  Future<List<Herramienta>> consultarHerramientasPorTipo(String tipo) async {
    final todas = await consultarTodasHerramientas();
    return todas.where((h) => h.tipo == tipo).toList();
  }

  /// Obtiene herramientas por condición
  Future<List<Herramienta>> consultarHerramientasPorCondicion(String condicion) async {
    final todas = await consultarTodasHerramientas();
    return todas.where((h) => h.condicion == condicion).toList();
  }

  /// Obtiene herramientas asociadas a una maquinaria
  Future<List<Herramienta>> consultarHerramientasPorMaquinaria(String maquinariaId) async {
    final todas = await consultarTodasHerramientas();
    return todas.where((h) => h.maquinariaId == maquinariaId).toList();
  }

  /// Elimina una herramienta (desactiva)
  Future<bool> eliminarHerramienta(String id) async {
    return await _dbService.eliminarHerramienta(id);
  }

  /// Obtiene estadísticas de herramientas
  Future<Map<String, dynamic>> obtenerEstadisticasHerramientas() async {
    final todas = await consultarTodasHerramientas();
    final total = todas.length;
    final nuevas = todas.where((h) => h.condicion == 'nueva').length;
    final buenas = todas.where((h) => h.condicion == 'buena').length;
    final regulares = todas.where((h) => h.condicion == 'regular').length;
    final desgastadas = todas.where((h) => h.condicion == 'desgastada').length;
    final danadas = todas.where((h) => h.condicion == 'dañada').length;

    return {
      'total': total,
      'nuevas': nuevas,
      'buenas': buenas,
      'regulares': regulares,
      'desgastadas': desgastadas,
      'danadas': danadas,
    };
  }
}

