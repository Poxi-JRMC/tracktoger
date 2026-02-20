import 'package:flutter/services.dart';
import '../models/registro_dataset_mantenimiento.dart';

/// Servicio para cargar y gestionar el dataset CSV de mantenimiento
class MantenimientoDatasetService {
  static final MantenimientoDatasetService _instance = MantenimientoDatasetService._internal();
  factory MantenimientoDatasetService() => _instance;
  MantenimientoDatasetService._internal();

  List<RegistroDatasetMantenimiento>? _registrosCache;
  bool _cargado = false;

  /// Carga todos los registros del CSV
  Future<List<RegistroDatasetMantenimiento>> cargarTodos() async {
    if (_cargado && _registrosCache != null) {
      return _registrosCache!;
    }

    try {
      final String contenido = await rootBundle.loadString(
        'assets/datasets/mantenimiento_maquinaria_sintetico.csv',
      );

      final lineas = contenido.split('\n');
      if (lineas.isEmpty) return [];

      // Primera línea es el encabezado
      final encabezados = _parsearLineaCSV(lineas[0]);
      final registros = <RegistroDatasetMantenimiento>[];

      // Procesar cada línea (saltar encabezado)
      for (int i = 1; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.isEmpty) continue;

        try {
          final valores = _parsearLineaCSV(linea);
          if (valores.length != encabezados.length) continue;

          final mapa = <String, dynamic>{};
          for (int j = 0; j < encabezados.length; j++) {
            final clave = encabezados[j].trim().toLowerCase();
            // Ignorar la columna 'falla' ya que es solo para entrenamiento
            if (clave == 'falla') continue;
            mapa[clave] = valores[j].trim();
          }

          final registro = RegistroDatasetMantenimiento.fromMap(mapa);
          registros.add(registro);
        } catch (e) {
          print('Error al parsear línea $i: $e');
          continue;
        }
      }

      _registrosCache = registros;
      _cargado = true;
      return registros;
    } catch (e) {
      // Silenciar el error del CSV si no existe (es opcional)
      // El sistema funcionará con valores por defecto conservadores
      return [];
    }
  }

  /// Busca el registro más cercano por horas de uso total
  Future<RegistroDatasetMantenimiento?> buscarRegistroMasCercanoPorHoras(
    double horasUsoTotal,
  ) async {
    final registros = await cargarTodos();
    if (registros.isEmpty) return null;

    RegistroDatasetMantenimiento? masCercano;
    double diferenciaMinima = double.infinity;

    for (var registro in registros) {
      final diferencia = (registro.horasUsoTotal - horasUsoTotal).abs();
      if (diferencia < diferenciaMinima) {
        diferenciaMinima = diferencia;
        masCercano = registro;
      }
    }

    return masCercano;
  }

  /// Obtiene estadísticas del dataset
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    final registros = await cargarTodos();
    if (registros.isEmpty) {
      return {
        'totalRegistros': 0,
        'horasMinimas': 0.0,
        'horasMaximas': 0.0,
        'promedioHoras': 0.0,
      };
    }

    final horas = registros.map((r) => r.horasUsoTotal).toList();
    horas.sort();

    return {
      'totalRegistros': registros.length,
      'horasMinimas': horas.first,
      'horasMaximas': horas.last,
      'promedioHoras': horas.reduce((a, b) => a + b) / horas.length,
    };
  }

  /// Parsea una línea CSV manejando comillas y comas
  List<String> _parsearLineaCSV(String linea) {
    final valores = <String>[];
    String valorActual = '';
    bool dentroComillas = false;

    for (int i = 0; i < linea.length; i++) {
      final char = linea[i];

      if (char == '"') {
        dentroComillas = !dentroComillas;
      } else if (char == ',' && !dentroComillas) {
        valores.add(valorActual);
        valorActual = '';
      } else {
        valorActual += char;
      }
    }

    // Agregar el último valor
    if (valorActual.isNotEmpty || linea.endsWith(',')) {
      valores.add(valorActual);
    }

    return valores;
  }

  /// Limpia el cache (útil para recargar datos)
  void limpiarCache() {
    _registrosCache = null;
    _cargado = false;
  }
}

