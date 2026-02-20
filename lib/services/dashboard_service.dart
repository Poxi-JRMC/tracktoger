import '../models/registro_mantenimiento.dart';
import '../controllers/control_mantenimiento.dart';

/// Servicio para calcular estadísticas del dashboard
class DashboardService {
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();

  /// Calcula el costo total de mantenimiento en un rango de fechas
  Future<double> calcularCostoTotalMantenimiento({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final registros = await _controlMantenimiento.consultarTodosRegistrosMantenimiento();
    
    // Filtrar solo completados
    final completados = registros.where((r) => r.estado == 'completado').toList();

    // Filtrar por rango de fechas si se proporciona
    if (fechaInicio != null || fechaFin != null) {
      final fechaInicioFiltro = fechaInicio ?? DateTime(1970);
      final fechaFinFiltro = fechaFin ?? DateTime.now().add(const Duration(days: 365));

      final filtrados = completados.where((r) {
        final fecha = r.fechaRealizacion ?? r.fechaProgramada;
        return fecha.isAfter(fechaInicioFiltro) && fecha.isBefore(fechaFinFiltro);
      }).toList();

      double total = 0.0;
      for (var registro in filtrados) {
        total += registro.costoTotal;
      }
      return total;
    }

    double total = 0.0;
    for (var registro in completados) {
      total += registro.costoTotal;
    }
    return total;
  }

  /// Calcula el costo total histórico
  Future<double> calcularCostoTotalHistorico() async {
    return await calcularCostoTotalMantenimiento();
  }

  /// Calcula el costo total de los últimos N días
  Future<double> calcularCostoUltimosDias(int dias) async {
    final fechaInicio = DateTime.now().subtract(Duration(days: dias));
    return await calcularCostoTotalMantenimiento(fechaInicio: fechaInicio);
  }

  /// Agrupa costos por tipo de mantenimiento
  Future<Map<String, double>> calcularCostosPorTipo({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final registros = await _controlMantenimiento.consultarTodosRegistrosMantenimiento();
    
    final completados = registros.where((r) => r.estado == 'completado').toList();

    // Filtrar por rango de fechas si se proporciona
    if (fechaInicio != null || fechaFin != null) {
      final fechaInicioFiltro = fechaInicio ?? DateTime(1970);
      final fechaFinFiltro = fechaFin ?? DateTime.now().add(const Duration(days: 365));

      final filtrados = completados.where((r) {
        final fecha = r.fechaRealizacion ?? r.fechaProgramada;
        return fecha.isAfter(fechaInicioFiltro) && fecha.isBefore(fechaFinFiltro);
      }).toList();

      return _agruparPorTipo(filtrados);
    }

    return _agruparPorTipo(completados);
  }

  Map<String, double> _agruparPorTipo(List<RegistroMantenimiento> registros) {
    final mapa = <String, double>{};
    
    for (var registro in registros) {
      final tipo = registro.tipoMantenimiento;
      mapa[tipo] = (mapa[tipo] ?? 0.0) + registro.costoTotal;
    }

    return mapa;
  }

  /// Obtiene estadísticas completas del dashboard
  Future<Map<String, dynamic>> obtenerEstadisticasCompletas() async {
    final costoTotal = await calcularCostoTotalHistorico();
    final costoUltimos30Dias = await calcularCostoUltimosDias(30);
    final costosPorTipo = await calcularCostosPorTipo();

    return {
      'costoTotalHistorico': costoTotal,
      'costoUltimos30Dias': costoUltimos30Dias,
      'costosPorTipo': costosPorTipo,
    };
  }
}

