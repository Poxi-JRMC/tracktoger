import 'package:mongo_dart/mongo_dart.dart';
import '../models/gasto_operativo.dart';
import '../data/services/database_service.dart';

/// Controlador para la gestión de gastos operativos
/// Maneja las operaciones CRUD de gastos operativos usando MongoDB
class ControlGastoOperativo {
  final DatabaseService _dbService = DatabaseService();

  // ========== MÉTODOS PARA GASTOS OPERATIVOS ==========

  /// Registra un nuevo gasto operativo
  Future<GastoOperativo> registrarGastoOperativo(
    GastoOperativo gasto,
  ) async {
    // Generar ID si no viene
    String gastoId = gasto.id;
    if (gastoId.isEmpty) {
      gastoId = ObjectId().toHexString();
    }

    final gastoToInsert = gasto.copyWith(
      id: gastoId,
      fechaRegistro: DateTime.now(),
    );

    await _dbService.insertarGastoOperativo(gastoToInsert.toMap());
    print('✅ Gasto operativo registrado: ${gastoToInsert.tipoGasto}');
    return gastoToInsert;
  }

  /// Actualiza un gasto operativo existente
  Future<GastoOperativo> actualizarGastoOperativo(
    GastoOperativo gasto,
  ) async {
    final existente = await consultarGastoOperativo(gasto.id);
    if (existente == null) {
      throw Exception('Gasto operativo no encontrado');
    }

    await _dbService.actualizarGastoOperativo(gasto.toMap());
    return gasto;
  }

  /// Obtiene un gasto operativo por su ID
  Future<GastoOperativo?> consultarGastoOperativo(String id) async {
    return await _dbService.consultarGastoOperativo(id);
  }

  /// Obtiene todos los gastos operativos
  Future<List<GastoOperativo>> consultarTodosGastosOperativos({
    bool soloActivos = true,
    String? maquinariaId,
    String? operadorId,
  }) async {
    return await _dbService.consultarTodosGastosOperativos(
      soloActivos: soloActivos,
      maquinariaId: maquinariaId,
      operadorId: operadorId,
    );
  }

  /// Obtiene gastos operativos por maquinaria
  Future<List<GastoOperativo>> consultarGastosPorMaquinaria(
    String maquinariaId,
  ) async {
    return await consultarTodosGastosOperativos(
      maquinariaId: maquinariaId,
    );
  }

  /// Obtiene gastos operativos por operador
  Future<List<GastoOperativo>> consultarGastosPorOperador(
    String operadorId,
  ) async {
    return await consultarTodosGastosOperativos(
      operadorId: operadorId,
    );
  }

  /// Elimina un gasto operativo (desactiva)
  Future<bool> eliminarGastoOperativo(String id) async {
    return await _dbService.eliminarGastoOperativo(id);
  }

  /// Obtiene estadísticas de gastos operativos
  Future<Map<String, dynamic>> obtenerEstadisticasGastos({
    String? maquinariaId,
    String? operadorId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    List<GastoOperativo> gastos = await consultarTodosGastosOperativos(
      maquinariaId: maquinariaId,
      operadorId: operadorId,
    );

    // Filtrar por rango de fechas si se proporciona
    if (fechaInicio != null || fechaFin != null) {
      gastos = gastos.where((g) {
        if (fechaInicio != null && g.fecha.isBefore(fechaInicio)) {
          return false;
        }
        if (fechaFin != null && g.fecha.isAfter(fechaFin)) {
          return false;
        }
        return true;
      }).toList();
    }

    final total = gastos.length;
    final totalMonto = gastos.fold<double>(0.0, (sum, g) => sum + g.monto);
    final promedioMonto = total > 0 ? totalMonto / total : 0.0;

    // Agrupar por tipo de gasto
    final gastosPorTipo = <String, double>{};
    for (var gasto in gastos) {
      gastosPorTipo[gasto.tipoGasto] =
          (gastosPorTipo[gasto.tipoGasto] ?? 0.0) + gasto.monto;
    }

    return {
      'total': total,
      'totalMonto': totalMonto,
      'promedioMonto': promedioMonto,
      'gastosPorTipo': gastosPorTipo,
    };
  }
}

