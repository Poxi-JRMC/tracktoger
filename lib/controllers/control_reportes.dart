import '../models/reporte.dart';
import '../models/indicador.dart';
import 'package:tracktoger/controllers/control_pdf_generator.dart';
import 'package:flutter/material.dart';

/// Controlador para reportes e indicadores
/// Maneja la generación de reportes, exportación a PDF y cálculo de indicadores KPI
class ControlReportes {
  // Listas simuladas para almacenamiento en memoria
  static List<Reporte> _reportes = [];
  static List<Indicador> _indicadores = [];

  Future<Reporte> generarReporte(Reporte reporte, BuildContext context) async {
    // Simular proceso de generación
    final reporteGenerado = reporte.copyWith(
      estado: 'generando',
      fechaGeneracion: DateTime.now(),
    );

    _reportes.add(reporteGenerado);

    // Simular generación asíncrona
    await Future.delayed(const Duration(seconds: 2));

    // Marcar como completado
    var reporteCompletado = reporteGenerado.copyWith(
      estado: 'completado',
      archivoUrl: 'reports/${reporte.id}.${reporte.formato}',
    );

    // ✅ Generar PDF real si corresponde
    if (reporte.formato.toLowerCase() == 'pdf') {
      final generator = ControlPDFGenerator();
      final data = _armarDataPorTipo(reporte);

      // Asegúrate de pasar el 'context' correctamente
      final pdfFile = await generator.generar(
        reporte.tipo,
        data,
        context,
      ); // PASAMOS context AQUÍ

      reporteCompletado = reporteCompletado.copyWith(archivoUrl: pdfFile.path);
    }

    return reporteCompletado;
  }

  /// Obtiene un reporte por su ID
  Future<Reporte?> consultarReporte(String id) async {
    try {
      return _reportes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todos los reportes
  Future<List<Reporte>> consultarTodosReportes() async {
    return List.from(_reportes);
  }

  /// Obtiene reportes por tipo
  Future<List<Reporte>> consultarReportesPorTipo(String tipo) async {
    return _reportes.where((r) => r.tipo == tipo).toList();
  }

  /// Obtiene reportes por usuario
  Future<List<Reporte>> consultarReportesPorUsuario(String usuarioId) async {
    return _reportes.where((r) => r.usuarioGeneracion == usuarioId).toList();
  }

  /// Obtiene reportes por estado
  Future<List<Reporte>> consultarReportesPorEstado(String estado) async {
    return _reportes.where((r) => r.estado == estado).toList();
  }

  /// Elimina un reporte
  Future<bool> eliminarReporte(String id) async {
    final index = _reportes.indexWhere((r) => r.id == id);
    if (index == -1) return false;

    _reportes.removeAt(index);
    return true;
  }

  // ========== MÉTODOS PARA INDICADORES ==========

  Future<Indicador> crearIndicador(Indicador indicador) async {
    _indicadores.add(indicador);
    return indicador;
  }

  Future<Indicador> actualizarIndicador(Indicador indicador) async {
    final index = _indicadores.indexWhere((i) => i.id == indicador.id);
    if (index == -1) throw Exception('Indicador no encontrado');

    _indicadores[index] = indicador;
    return indicador;
  }

  Future<Indicador?> consultarIndicador(String id) async {
    try {
      return _indicadores.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Indicador>> consultarTodosIndicadores() async {
    return List.from(_indicadores);
  }

  Future<List<Indicador>> consultarIndicadoresPorCategoria(
    String categoria,
  ) async {
    return _indicadores.where((i) => i.categoria == categoria).toList();
  }

  Future<List<Indicador>> consultarIndicadoresActivos() async {
    return _indicadores.where((i) => i.activo).toList();
  }

  Future<Indicador> calcularIndicador(String id) async {
    final indicador = await consultarIndicador(id);
    if (indicador == null) throw Exception('Indicador no encontrado');

    final nuevoValor = await _calcularValorIndicador(indicador);
    final estado = _determinarEstadoIndicador(
      nuevoValor,
      indicador.valorObjetivo,
    );

    final indicadorActualizado = indicador.copyWith(
      valorAnterior: indicador.valorActual,
      valorActual: nuevoValor,
      estado: estado,
      fechaCalculo: DateTime.now(),
    );

    return await actualizarIndicador(indicadorActualizado);
  }

  Future<List<Indicador>> calcularTodosIndicadores() async {
    final activos = await consultarIndicadoresActivos();
    final calculados = <Indicador>[];

    for (final indicador in activos) {
      final calculado = await calcularIndicador(indicador.id);
      calculados.add(calculado);
    }

    return calculados;
  }

  Future<bool> eliminarIndicador(String id) async {
    final index = _indicadores.indexWhere((i) => i.id == id);
    if (index == -1) return false;

    _indicadores[index] = _indicadores[index].copyWith(activo: false);
    return true;
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  Future<double> _calcularValorIndicador(Indicador indicador) async {
    switch (indicador.categoria) {
      case 'disponibilidad':
        return await _calcularDisponibilidad();
      case 'rentabilidad':
        return await _calcularRentabilidad();
      case 'mantenimiento':
        return await _calcularEficienciaMantenimiento();
      case 'alquileres':
        return await _calcularUtilizacionAlquileres();
      default:
        return indicador.valorActual + (DateTime.now().millisecond % 10 - 5);
    }
  }

  Future<double> _calcularDisponibilidad() async =>
      95.5 + (DateTime.now().millisecond % 5);

  Future<double> _calcularRentabilidad() async =>
      24500.0 + (DateTime.now().millisecond % 1000);

  Future<double> _calcularEficienciaMantenimiento() async =>
      88.2 + (DateTime.now().millisecond % 3);

  Future<double> _calcularUtilizacionAlquileres() async =>
      78.5 + (DateTime.now().millisecond % 4);

  String _determinarEstadoIndicador(double valorActual, double? valorObjetivo) {
    if (valorObjetivo == null) return 'bueno';

    final diferencia = ((valorActual - valorObjetivo) / valorObjetivo * 100)
        .abs();

    if (diferencia <= 5) return 'bueno';
    if (diferencia <= 15) return 'regular';
    return 'malo';
  }

  Future<Map<String, dynamic>> obtenerEstadisticasReportes() async {
    final total = _reportes.length;
    final completados = _reportes.where((r) => r.estado == 'completado').length;
    final generando = _reportes.where((r) => r.estado == 'generando').length;
    final error = _reportes.where((r) => r.estado == 'error').length;

    return {
      'totalReportes': total,
      'reportesCompletados': completados,
      'reportesGenerando': generando,
      'reportesError': error,
      'totalIndicadores': _indicadores.length,
      'indicadoresActivos': _indicadores.where((i) => i.activo).length,
    };
  }

  // ========== GENERACIÓN DE DATA PARA PDF ==========

  Map<String, dynamic> _armarDataPorTipo(Reporte r) {
    switch (r.tipo) {
      case 'inventario':
        return {
          'empresa': 'Tracktoger',
          'fecha': DateTime.now(),
          'filtro': 'Todo',
          'resumen': {
            'total': 132,
            'disponibles': 98,
            'mantenimiento': 12,
            'alquilados': 22,
          },
          'items': [
            {
              'codigo': 'EXC-001',
              'nombre': 'Excavadora CAT 320',
              'categoria': 'Excavadora',
              'estado': 'Disponible',
              'ubicacion': 'Yacuiba',
              'horometro': 1234,
              'ingreso': '2024-11-02',
            },
            {
              'codigo': 'GRU-014',
              'nombre': 'Grúa Tadano 40T',
              'categoria': 'Grúa',
              'estado': 'Mantenimiento',
              'ubicacion': 'Santa Cruz',
              'horometro': 981,
              'ingreso': '2024-08-10',
            },
          ],
        };
      case 'alquileres':
        return {
          'empresa': 'Tracktoger',
          'fecha': DateTime.now(),
          'filtro': 'Activos',
          'items': [
            {
              'cliente': 'Constructora Alfa',
              'equipo': 'Retroexcavadora',
              'monto': 3500,
              'estado': 'Activo',
            },
            {
              'cliente': 'Obras del Sur',
              'equipo': 'Camión Mixer',
              'monto': 2200,
              'estado': 'Finalizado',
            },
          ],
        };
      case 'mantenimiento':
        return {
          'empresa': 'Tracktoger',
          'fecha': DateTime.now(),
          'items': [
            {
              'equipo': 'Excavadora CAT 320',
              'tipo': 'Preventivo',
              'costo': 450,
              'fecha': '2024-10-12',
            },
            {
              'equipo': 'Compactadora Dynapac',
              'tipo': 'Correctivo',
              'costo': 720,
              'fecha': '2024-09-20',
            },
          ],
        };
      case 'usuarios':
        return {
          'empresa': 'Tracktoger',
          'fecha': DateTime.now(),
          'items': [
            {
              'nombre': 'Juan Pérez',
              'rol': 'Administrador',
              'correo': 'juan@tracktoger.com',
            },
            {
              'nombre': 'Carla Flores',
              'rol': 'Supervisor',
              'correo': 'carla@tracktoger.com',
            },
          ],
        };
      default:
        return {'empresa': 'Tracktoger', 'fecha': DateTime.now(), 'items': []};
    }
  }

  // ========== DATOS DE PRUEBA ==========

  static void inicializarDatosPrueba() {
    _indicadores = [
      Indicador(
        id: 'ind_1',
        nombre: 'Disponibilidad Total',
        descripcion: 'Porcentaje de maquinaria disponible para alquiler',
        categoria: 'disponibilidad',
        tipo: 'porcentaje',
        valorActual: 95.5,
        valorObjetivo: 90.0,
        valorAnterior: 94.2,
        unidad: '%',
        fechaCalculo: DateTime.now(),
        formula: '(Maquinaria Disponible / Total Maquinaria) * 100',
        estado: 'bueno',
      ),
      Indicador(
        id: 'ind_2',
        nombre: 'Rentabilidad Mensual',
        descripcion: 'Ingresos generados por alquileres en el mes',
        categoria: 'rentabilidad',
        tipo: 'moneda',
        valorActual: 24500.0,
        valorObjetivo: 20000.0,
        valorAnterior: 22000.0,
        unidad: '\$',
        fechaCalculo: DateTime.now(),
        formula: 'Suma de ingresos por alquileres del mes',
        estado: 'bueno',
      ),
      Indicador(
        id: 'ind_3',
        nombre: 'Fallas Evitadas',
        descripcion: 'Número de fallas evitadas por mantenimiento predictivo',
        categoria: 'mantenimiento',
        tipo: 'numero',
        valorActual: 12.0,
        valorObjetivo: 10.0,
        valorAnterior: 8.0,
        unidad: 'fallas',
        fechaCalculo: DateTime.now(),
        formula: 'Alertas críticas resueltas antes de falla',
        estado: 'bueno',
      ),
    ];

    _reportes = [
      Reporte(
        id: 'rep_1',
        nombre: 'Reporte de Disponibilidad Mensual',
        tipo: 'inventario',
        descripcion: 'Reporte detallado de disponibilidad de maquinaria',
        fechaGeneracion: DateTime.now().subtract(const Duration(days: 1)),
        usuarioGeneracion: 'user_1',
        formato: 'pdf',
        estado: 'completado',
        archivoUrl: 'reports/disponibilidad_enero_2024.pdf',
        fechaInicio: DateTime(2024, 1, 1),
        fechaFin: DateTime(2024, 1, 31),
      ),
    ];
  }
}
