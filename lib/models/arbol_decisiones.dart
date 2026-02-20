/// Modelo para árbol de decisiones de diagnóstico
/// Estructura jerárquica: Sistema -> Componente -> Síntoma -> Solución

/// Nodo del árbol de decisiones
class NodoDecision {
  final String id;
  final String nombre;
  final String tipo; // 'sistema', 'componente', 'sintoma', 'solucion'
  final String? descripcion;
  final Map<String, dynamic> criterios; // Criterios para evaluar este nodo
  final List<NodoDecision> hijos;
  final String? solucion;
  final List<String>? accionesRecomendadas;
  final int? prioridad; // 1-5, donde 5 es crítico

  NodoDecision({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.criterios = const {},
    this.hijos = const [],
    this.solucion,
    this.accionesRecomendadas,
    this.prioridad,
  });

  /// Evalúa si este nodo es relevante basado en los datos de la máquina
  bool evaluar(Map<String, dynamic> datosMaquina) {
    if (criterios.isEmpty) return true;

    for (var entry in criterios.entries) {
      final clave = entry.key;
      final valorEsperado = entry.value;

      if (!datosMaquina.containsKey(clave)) return false;

      final valorActual = datosMaquina[clave];
      
      // Evaluar según el tipo de criterio
      if (valorEsperado is Map) {
        // Criterio con operador (ej: {'operator': '>', 'value': 1000})
        final operador = valorEsperado['operator'] as String?;
        final valor = valorEsperado['value'];
        
        switch (operador) {
          case '>':
            if (valorActual is num && valor is num) {
              if (valorActual <= valor) return false;
            }
            break;
          case '>=':
            if (valorActual is num && valor is num) {
              if (valorActual < valor) return false;
            }
            break;
          case '<':
            if (valorActual is num && valor is num) {
              if (valorActual >= valor) return false;
            }
            break;
          case '<=':
            if (valorActual is num && valor is num) {
              if (valorActual > valor) return false;
            }
            break;
          case '==':
            if (valorActual != valor) return false;
            break;
          case 'contains':
            if (valorActual is String && valor is String) {
              if (!valorActual.toLowerCase().contains(valor.toLowerCase())) return false;
            }
            break;
        }
      } else {
        // Comparación directa
        if (valorActual != valorEsperado) return false;
      }
    }

    return true;
  }
}

/// Resultado de diagnóstico por sistema
class DiagnosticoSistema {
  final String sistemaId;
  final String sistemaNombre;
  final String? descripcion;
  final double scoreRiesgo; // 0-100
  final String nivelRiesgo; // 'critico', 'alto', 'medio', 'bajo', 'optimo'
  final List<DiagnosticoComponente> componentes;
  final List<String> problemasGenerales;
  final List<String> recomendacionesGenerales;

  DiagnosticoSistema({
    required this.sistemaId,
    required this.sistemaNombre,
    this.descripcion,
    required this.scoreRiesgo,
    required this.nivelRiesgo,
    this.componentes = const [],
    this.problemasGenerales = const [],
    this.recomendacionesGenerales = const [],
  });
}

/// Resultado de diagnóstico por componente
class DiagnosticoComponente {
  final String componenteId;
  final String componenteNombre;
  final String? descripcion;
  final double scoreRiesgo; // 0-100
  final String nivelRiesgo;
  final List<DiagnosticoSintoma> sintomas;
  final String? solucion;
  final List<String> accionesRecomendadas;
  final int prioridad; // 1-5

  DiagnosticoComponente({
    required this.componenteId,
    required this.componenteNombre,
    this.descripcion,
    required this.scoreRiesgo,
    required this.nivelRiesgo,
    this.sintomas = const [],
    this.solucion,
    this.accionesRecomendadas = const [],
    this.prioridad = 3,
  });
}

/// Resultado de diagnóstico por síntoma
class DiagnosticoSintoma {
  final String sintomaId;
  final String sintomaNombre;
  final String? descripcion;
  final bool presente;
  final double probabilidad; // 0-100
  final Map<String, dynamic> datosRelacionados;

  DiagnosticoSintoma({
    required this.sintomaId,
    required this.sintomaNombre,
    this.descripcion,
    required this.presente,
    required this.probabilidad,
    this.datosRelacionados = const {},
  });
}

/// Diagnóstico completo de una máquina
class DiagnosticoCompleto {
  final String maquinariaId;
  final String maquinariaNombre;
  final DateTime fechaDiagnostico;
  final double scoreRiesgoGeneral; // 0-100
  final String nivelRiesgoGeneral;
  final List<DiagnosticoSistema> sistemas;
  final List<String> recomendacionesGlobales;
  final Map<String, dynamic> datosEvaluados;

  DiagnosticoCompleto({
    required this.maquinariaId,
    required this.maquinariaNombre,
    required this.fechaDiagnostico,
    required this.scoreRiesgoGeneral,
    required this.nivelRiesgoGeneral,
    this.sistemas = const [],
    this.recomendacionesGlobales = const [],
    this.datosEvaluados = const {},
  });
}

