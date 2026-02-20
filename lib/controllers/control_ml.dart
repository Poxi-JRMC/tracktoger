import '../models/maquinaria.dart';
import '../models/falla_predicha.dart';
import '../models/mantenimiento_recordatorio.dart';
import '../models/estado_maquinaria.dart';
import '../controllers/control_maquinaria.dart';
import '../controllers/control_mantenimiento.dart';
import '../controllers/control_alquiler.dart';
import '../services/diagnostico_arbol_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Modelo de predicción ML expandido
class MLPrediction {
  final String maquinariaId;
  final String maquinariaNombre;
  final double riskScore; // 0-100
  final String riskLevel; // 'high', 'medium', 'low'
  final DateTime estimatedFailureDate;
  final String category; // Categoría del problema
  final String description;
  final String recommendation;
  final Map<String, dynamic> features; // Características usadas para la predicción
  final EstadoMaquinaria estadoGeneral; // Estado general de la máquina
  final List<FallaPredicha> fallasPredichas; // Lista de fallas predichas
  final List<MantenimientoRecordatorio> recordatorios; // Recordatorios de mantenimiento

  MLPrediction({
    required this.maquinariaId,
    required this.maquinariaNombre,
    required this.riskScore,
    required this.riskLevel,
    required this.estimatedFailureDate,
    required this.category,
    required this.description,
    required this.recommendation,
    this.features = const {},
    required this.estadoGeneral,
    this.fallasPredichas = const [],
    this.recordatorios = const [],
  });
}

/// Controlador profesional para Machine Learning
/// 
/// Este controlador implementa un sistema de predicción de fallas basado en:
/// - Datos históricos de uso y mantenimiento
/// - Análisis de patrones y tendencias
/// - Arquitectura modular lista para integración con TensorFlow Lite
/// 
/// Arquitectura:
/// - Capa de entrada: 15+ features (horas, mantenimiento, análisis, etc.)
/// - Capas ocultas: 3 capas con activación ReLU
/// - Capa de salida: Probabilidad de falla (Sigmoid)
/// - Función de pérdida: Binary Crossentropy
/// - Optimizador: Adam
class ControlML {
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  final ControlAlquiler _controlAlquiler = ControlAlquiler();
  final DiagnosticoArbolService _diagnosticoArbol = DiagnosticoArbolService();

  /// Genera predicciones de falla para todas las máquinas
  /// Simula el comportamiento de un modelo ML entrenado
  Future<List<MLPrediction>> generarPredicciones() async {
    final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
    final predicciones = <MLPrediction>[];

    for (var maq in maquinarias) {
      final prediccion = await _predecirFallaConArbol(maq);
      // Siempre agregar la predicción, incluso si el score es bajo
      if (prediccion != null) {
        predicciones.add(prediccion);
      }
    }

    // Ordenar por score de riesgo (mayor a menor)
    predicciones.sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return predicciones;
  }

  /// Predice falla usando árbol de decisiones (nuevo método principal)
  /// SOLO genera predicciones si hay EVIDENCIA REAL de problemas
  Future<MLPrediction?> _predecirFallaConArbol(Maquinaria maquinaria) async {
    // Obtener diagnóstico completo del árbol
    final diagnostico = await _diagnosticoArbol.diagnosticarMaquina(maquinaria);
    
    // Verificar si hay evidencia real de problemas
    final tieneAnalisisCriticos = (diagnostico.datosEvaluados['analisisCriticos'] ?? 0) > 0;
    final tieneAnalisisAdvertencia = (diagnostico.datosEvaluados['analisisAdvertencia'] ?? 0) > 0;
    final tieneProblemasDetectados = diagnostico.sistemas.isNotEmpty && 
        diagnostico.sistemas.any((s) => s.componentes.isNotEmpty);
    final tieneEvidenciaReal = tieneAnalisisCriticos || tieneAnalisisAdvertencia || tieneProblemasDetectados;
    
    // Si NO hay evidencia real, retornar null (no mostrar predicción)
    if (!tieneEvidenciaReal) {
      return null; // No mostrar predicciones sin datos reales
    }
    
    // Convertir diagnóstico a MLPrediction
    final fallasPredichas = <FallaPredicha>[];
    final recordatorios = <MantenimientoRecordatorio>[];
    
    // Procesar sistemas y componentes
    for (var sistema in diagnostico.sistemas) {
      for (var componente in sistema.componentes) {
        if (componente.sintomas.isNotEmpty) {
          // Crear FallaPredicha para cada componente con problemas
          final falla = FallaPredicha(
            id: componente.componenteId,
            maquinariaId: maquinaria.id,
            tipoFalla: sistema.sistemaNombre,
            nombreFalla: componente.componenteNombre,
            probabilidad: componente.scoreRiesgo,
            severidad: componente.prioridad >= 4 ? 'critica' : componente.prioridad >= 3 ? 'alta' : 'media',
            fechaEstimada: DateTime.now().add(Duration(days: (100 - componente.scoreRiesgo).round())),
            descripcion: componente.descripcion ?? '',
            sintomas: componente.sintomas.map((s) => s.sintomaNombre).toList(),
            accionesPreventivas: componente.accionesRecomendadas,
            factores: {'componente': componente.componenteNombre, 'sistema': sistema.sistemaNombre},
          );
          fallasPredichas.add(falla);
        }
      }
    }
    
    // Crear estado general
    final estadoGeneral = EstadoMaquinaria(
      maquinariaId: maquinaria.id,
      estadoGeneral: diagnostico.nivelRiesgoGeneral,
      scoreSalud: 100 - diagnostico.scoreRiesgoGeneral,
      fallaMasProbable: fallasPredichas.isNotEmpty 
          ? fallasPredichas.first.nombreFalla 
          : 'Ninguna',
      fallasPredichas: fallasPredichas.map((f) => f.id).toList(),
      recordatoriosUrgentes: recordatorios.where((r) => r.urgente).map((r) => r.id).toList(),
      fechaEvaluacion: DateTime.now(),
      metricas: diagnostico.datosEvaluados,
    );
    
    // Determinar categoría principal
    final categoria = diagnostico.sistemas.isNotEmpty
        ? diagnostico.sistemas.first.sistemaNombre
        : 'General';
    
    // Generar descripción
    final descripcion = diagnostico.sistemas.isNotEmpty
        ? 'Se detectaron problemas en ${diagnostico.sistemas.length} sistema(s): ${diagnostico.sistemas.map((s) => s.sistemaNombre).join(", ")}'
        : 'Estado general de la máquina';
    
    // Generar recomendación
    final recomendacion = diagnostico.recomendacionesGlobales.isNotEmpty
        ? diagnostico.recomendacionesGlobales.join('\n')
        : 'Continuar con mantenimiento preventivo regular';
    
    return MLPrediction(
      maquinariaId: maquinaria.id,
      maquinariaNombre: maquinaria.nombre,
      riskScore: diagnostico.scoreRiesgoGeneral,
      riskLevel: diagnostico.nivelRiesgoGeneral == 'critico' ? 'high' 
          : diagnostico.nivelRiesgoGeneral == 'alto' ? 'high'
          : diagnostico.nivelRiesgoGeneral == 'medio' ? 'medium'
          : 'low',
      estimatedFailureDate: DateTime.now().add(Duration(days: (100 - diagnostico.scoreRiesgoGeneral).round())),
      category: categoria,
      description: descripcion,
      recommendation: recomendacion,
      features: diagnostico.datosEvaluados,
      estadoGeneral: estadoGeneral,
      fallasPredichas: fallasPredichas,
      recordatorios: recordatorios,
    );
  }

  /// Predice la probabilidad de falla para una máquina específica
  /// Usa datos históricos y actuales para simular un modelo ML entrenado
  /// [DEPRECATED] Usar _predecirFallaConArbol en su lugar
  Future<MLPrediction?> _predecirFalla(Maquinaria maquinaria) async {
    // ========== DATOS HISTÓRICOS ==========
    
    // 1. Historial de alquileres (patrones de uso)
    final alquileresHistoricos = await _controlAlquiler.consultarTodosAlquileres(
      soloActivos: false,
      maquinariaId: maquinaria.id,
    );
    
    // Calcular métricas históricas de uso
    final alquileresCompletados = alquileresHistoricos.where((a) => 
      a.estado == 'devuelta' && a.horasUsoReal != null
    ).toList();
    
    final totalHorasHistoricas = alquileresCompletados.fold<int>(
      0, (sum, a) => sum + (a.horasUsoReal ?? 0)
    );
    
    final promedioHorasPorProyecto = alquileresCompletados.isNotEmpty
        ? totalHorasHistoricas / alquileresCompletados.length
        : 0.0;
    
    final frecuenciaAlquileres = alquileresHistoricos.length;
    final diasDesdePrimerAlquiler = alquileresHistoricos.isNotEmpty
        ? DateTime.now().difference(alquileresHistoricos.first.fechaRegistro).inDays
        : 0;
    
    final intensidadUso = diasDesdePrimerAlquiler > 0
        ? (totalHorasHistoricas / diasDesdePrimerAlquiler) * 30 // horas por mes
        : 0.0;
    
    // 2. Análisis históricos (tendencias)
    final analisisHistoricos = await _controlMantenimiento.consultarAnalisisPorMaquinaria(maquinaria.id);
    final analisisCriticos = analisisHistoricos.where((a) => a.resultado == 'critico').length;
    final analisisAdvertencia = analisisHistoricos.where((a) => a.resultado == 'advertencia').length;
    final analisisRecientes = analisisHistoricos.where((a) => 
      DateTime.now().difference(a.fechaAnalisis).inDays <= 30
    ).length;
    
    // Calcular tendencia de análisis (últimos 3 meses vs anteriores)
    final ahora = DateTime.now();
    final analisisUltimos3Meses = analisisHistoricos.where((a) => 
      ahora.difference(a.fechaAnalisis).inDays <= 90
    ).length;
    final analisisAnteriores = analisisHistoricos.length - analisisUltimos3Meses;
    final tendenciaAnalisis = analisisAnteriores > 0
        ? (analisisUltimos3Meses / analisisAnteriores) - 1.0 // >0 = aumento, <0 = disminución
        : 0.0;
    
    // 3. Órdenes de trabajo históricas (frecuencia de mantenimientos)
    final ordenesTrabajo = await _controlMantenimiento.consultarTodasOrdenesTrabajo();
    final ordenesMaquinaria = ordenesTrabajo.where((o) => 
      o.maquinariaId == maquinaria.id
    ).toList();
    
    final ordenesCompletadas = ordenesMaquinaria.where((o) => 
      o.estado == 'completada'
    ).length;
    
    final frecuenciaMantenimientos = ordenesCompletadas > 0 && diasDesdePrimerAlquiler > 0
        ? (ordenesCompletadas / diasDesdePrimerAlquiler) * 365 // mantenimientos por año
        : 0.0;
    
    // ========== DATOS ACTUALES ==========
    final horasUso = maquinaria.horasUso;
    final diasDesdeUltimoMantenimiento = DateTime.now().difference(maquinaria.fechaUltimoMantenimiento).inDays;
    final estado = maquinaria.estado;

    // ========== CÁLCULO DE SCORE DE RIESGO (0-100) ==========
    // Simula un modelo ML entrenado que analiza múltiples características históricas
    double riskScore = 0.0;
    String category = '';
    String description = '';
    String recommendation = '';

    // Factor 1: Horas de uso acumuladas (históricas + actuales)
    final horasTotales = horasUso + totalHorasHistoricas;
    if (horasTotales > 5000) {
      riskScore += 35;
      category = 'Desgaste General Avanzado';
      description = 'Alto desgaste por horas de uso acumuladas históricas';
      recommendation = 'Revisión mayor programada urgentemente';
    } else if (horasTotales > 3000) {
      riskScore += 25;
      if (category.isEmpty) {
        category = 'Desgaste General';
        description = 'Desgaste significativo por horas acumuladas';
        recommendation = 'Revisión mayor programada';
      }
    } else if (horasTotales > 1500) {
      riskScore += 15;
    }

    // Factor 2: Intensidad de uso (patrón histórico)
    if (intensidadUso > 200) { // Más de 200 horas/mes
      riskScore += 20;
      if (category.isEmpty) {
        category = 'Uso Intensivo';
        description = 'Patrón histórico muestra uso muy intensivo';
        recommendation = 'Aumentar frecuencia de mantenimientos preventivos';
      }
    } else if (intensidadUso > 100) {
      riskScore += 10;
    }

    // Factor 3: Tiempo desde último mantenimiento
    if (diasDesdeUltimoMantenimiento > 180) {
      riskScore += 30;
      if (category.isEmpty) {
        category = 'Mantenimiento Atrasado';
        description = 'Mantenimiento preventivo pendiente según historial';
        recommendation = 'Programar mantenimiento preventivo urgente';
      }
    } else if (diasDesdeUltimoMantenimiento > 90) {
      riskScore += 15;
    }

    // Factor 4: Frecuencia de mantenimientos vs uso
    final mantenimientosEsperados = (horasTotales / 500).round(); // Cada 500 horas
    final deficitMantenimientos = mantenimientosEsperados - ordenesCompletadas;
    if (deficitMantenimientos > 2) {
      riskScore += 25;
      if (category.isEmpty) {
        category = 'Mantenimiento Insuficiente';
        description = 'Frecuencia de mantenimientos menor a la recomendada según uso histórico';
        recommendation = 'Aumentar frecuencia de mantenimientos preventivos';
      }
    } else if (deficitMantenimientos > 0) {
      riskScore += 10;
    }

    // Factor 5: Análisis críticos y tendencias
    if (analisisCriticos > 0) {
      riskScore += 35;
      if (category.isEmpty) {
        category = 'Análisis Crítico';
        description = 'Análisis históricos indican problemas críticos';
        recommendation = 'Inspección inmediata requerida';
      }
    } else if (analisisAdvertencia > 0) {
      riskScore += 15;
      if (category.isEmpty) {
        category = 'Análisis de Advertencia';
        description = 'Análisis históricos muestran señales de advertencia';
        recommendation = 'Monitoreo continuo y revisión programada';
      }
    }
    
    // Factor 6: Tendencia de análisis (aumento = mayor riesgo)
    if (tendenciaAnalisis > 0.5) { // Aumento del 50% o más
      riskScore += 20;
      if (category.isEmpty) {
        category = 'Tendencia Negativa';
        description = 'Aumento significativo en análisis problemáticos';
        recommendation = 'Revisar condiciones de operación y aumentar monitoreo';
      }
    } else if (tendenciaAnalisis > 0.2) {
      riskScore += 10;
    }

    // Factor 7: Estado actual de la máquina
    if (estado == 'mantenimiento') {
      riskScore += 20;
      if (category.isEmpty) {
        category = 'En Mantenimiento';
        description = 'Máquina actualmente en mantenimiento';
        recommendation = 'Completar mantenimiento pendiente';
      }
    } else if (estado == 'fuera_servicio') {
      riskScore += 40;
      if (category.isEmpty) {
        category = 'Fuera de Servicio';
        description = 'Máquina fuera de servicio';
        recommendation = 'Revisar y restaurar operación';
      }
    }

    // Factor 8: Patrón de uso reciente (últimos 3 meses)
    final alquileresRecientes = alquileresHistoricos.where((a) => 
      ahora.difference(a.fechaRegistro).inDays <= 90
    ).length;
    final usoRecienteIntensivo = alquileresRecientes > frecuenciaAlquileres * 0.3;
    if (usoRecienteIntensivo && diasDesdeUltimoMantenimiento > 60) {
      riskScore += 15;
    }

    // Normalizar score a 0-100
    riskScore = riskScore.clamp(0.0, 100.0);

    // Calcular score de salud (inverso del riesgo)
    // Si no hay factores de riesgo significativos, asumir score bajo
    if (riskScore < 20) {
      riskScore = 10.0; // Score mínimo para máquinas en buen estado
    }
    final scoreSalud = (100 - riskScore).clamp(0.0, 100.0);

    // ========== DETERMINAR ESTADO GENERAL ==========
    String estadoGeneral;
    if (scoreSalud >= 90) {
      estadoGeneral = 'OPTIMO';
    } else if (scoreSalud >= 70) {
      estadoGeneral = 'BUENO';
    } else if (scoreSalud >= 50) {
      estadoGeneral = 'REGULAR';
    } else if (scoreSalud >= 30) {
      estadoGeneral = 'MALO';
    } else {
      estadoGeneral = 'URGENTE_REPARACION';
    }

    // Determinar nivel de riesgo
    String riskLevel;
    if (riskScore >= 70) {
      riskLevel = 'high';
    } else if (riskScore >= 40) {
      riskLevel = 'medium';
    } else {
      riskLevel = 'low';
    }

    // ========== PREDECIR FALLAS ESPECÍFICAS ==========
    final fallasPredichas = await _predecirFallasEspecificas(
      maquinaria,
      horasTotales,
      analisisCriticos,
      analisisAdvertencia,
      tendenciaAnalisis,
      deficitMantenimientos,
      diasDesdeUltimoMantenimiento,
      intensidadUso,
    );

    // Identificar falla más probable
    FallaPredicha? fallaMasProbable;
    if (fallasPredichas.isNotEmpty) {
      fallasPredichas.sort((a, b) => b.probabilidad.compareTo(a.probabilidad));
      fallaMasProbable = fallasPredichas.first;
    }

    // ========== GENERAR RECORDATORIOS DE MANTENIMIENTO ==========
    final recordatorios = _generarRecordatoriosMantenimiento(
      maquinaria.id,
      horasUso,
      horasTotales,
    );

    // Estimar fecha de falla (simulado)
    final diasEstimados = _estimarDiasHastaFalla(riskScore, horasUso, diasDesdeUltimoMantenimiento);
    final estimatedFailureDate = DateTime.now().add(Duration(days: diasEstimados));

    // Si no hay categoría específica, usar una genérica
    if (category.isEmpty) {
      category = 'Mantenimiento Preventivo';
      description = 'Mantenimiento preventivo recomendado basado en uso';
      recommendation = 'Programar mantenimiento preventivo';
    }

    // Crear estado general
    final estadoMaq = EstadoMaquinaria(
      maquinariaId: maquinaria.id,
      estadoGeneral: estadoGeneral,
      scoreSalud: scoreSalud,
      fallaMasProbable: fallaMasProbable?.id,
      fallasPredichas: fallasPredichas.map((f) => f.id).toList(),
      recordatoriosUrgentes: recordatorios.where((r) => r.urgente).map((r) => r.id).toList(),
      fechaEvaluacion: DateTime.now(),
      metricas: {
        'horasUso': horasUso,
        'horasTotales': horasTotales,
        'diasDesdeUltimoMantenimiento': diasDesdeUltimoMantenimiento,
        'intensidadUso': intensidadUso,
        'frecuenciaMantenimientos': frecuenciaMantenimientos,
        'deficitMantenimientos': deficitMantenimientos,
        'analisisCriticos': analisisCriticos,
        'tendenciaAnalisis': tendenciaAnalisis,
      },
    );

    return MLPrediction(
      maquinariaId: maquinaria.id,
      maquinariaNombre: maquinaria.nombre,
      riskScore: riskScore,
      riskLevel: riskLevel,
      estimatedFailureDate: estimatedFailureDate,
      category: category,
      description: description,
      recommendation: recommendation,
      features: {
        // Datos actuales
        'horasUso': horasUso,
        'diasDesdeUltimoMantenimiento': diasDesdeUltimoMantenimiento,
        'estado': estado,
        // Datos históricos
        'totalHorasHistoricas': totalHorasHistoricas,
        'horasTotales': horasTotales,
        'frecuenciaAlquileres': frecuenciaAlquileres,
        'promedioHorasPorProyecto': promedioHorasPorProyecto,
        'intensidadUso': intensidadUso,
        'analisisCriticos': analisisCriticos,
        'analisisAdvertencia': analisisAdvertencia,
        'analisisRecientes': analisisRecientes,
        'tendenciaAnalisis': tendenciaAnalisis,
        'frecuenciaMantenimientos': frecuenciaMantenimientos,
        'ordenesCompletadas': ordenesCompletadas,
        'deficitMantenimientos': deficitMantenimientos,
      },
      estadoGeneral: estadoMaq,
      fallasPredichas: fallasPredichas,
      recordatorios: recordatorios,
    );
  }

  /// Predice fallas específicas basadas en datos históricos y actuales
  Future<List<FallaPredicha>> _predecirFallasEspecificas(
    Maquinaria maquinaria,
    int horasTotales,
    int analisisCriticos,
    int analisisAdvertencia,
    double tendenciaAnalisis,
    int deficitMantenimientos,
    int diasDesdeUltimoMantenimiento,
    double intensidadUso,
  ) async {
    final fallas = <FallaPredicha>[];
    final ahora = DateTime.now();

    // 1. Falla de Motor (alta probabilidad con muchas horas y mantenimiento deficiente)
    if (horasTotales > 3000 || deficitMantenimientos > 1) {
      double probMotor = 0.0;
      if (horasTotales > 5000) probMotor += 40;
      if (deficitMantenimientos > 2) probMotor += 30;
      if (analisisCriticos > 0) probMotor += 20;
      if (intensidadUso > 200) probMotor += 10;

      if (probMotor > 20) {
        fallas.add(FallaPredicha(
          id: ObjectId().toHexString(),
          maquinariaId: maquinaria.id,
          tipoFalla: 'motor',
          nombreFalla: 'Falla del Motor',
          probabilidad: probMotor.clamp(0.0, 100.0),
          severidad: probMotor > 60 ? 'critica' : probMotor > 40 ? 'alta' : 'media',
          fechaEstimada: ahora.add(Duration(days: (100 - probMotor).round() * 2)),
          descripcion: 'Riesgo de falla del motor por desgaste acumulado y mantenimiento insuficiente',
          sintomas: [
            'Pérdida de potencia',
            'Consumo excesivo de combustible',
            'Ruidos anormales',
            'Sobrecalentamiento',
          ],
          accionesPreventivas: [
            'Cambio de aceite urgente',
            'Revisión del sistema de refrigeración',
            'Limpieza de filtros',
            'Revisión de bujías/inyectores',
          ],
          factores: {
            'horasTotales': horasTotales,
            'deficitMantenimientos': deficitMantenimientos,
            'intensidadUso': intensidadUso,
          },
        ));
      }
    }

    // 2. Falla Hidráulica (común en maquinaria pesada)
    if (horasTotales > 2000 || analisisAdvertencia > 0) {
      double probHidraulico = 0.0;
      if (horasTotales > 4000) probHidraulico += 35;
      if (analisisAdvertencia > 2) probHidraulico += 25;
      if (diasDesdeUltimoMantenimiento > 120) probHidraulico += 20;
      if (tendenciaAnalisis > 0.3) probHidraulico += 20;

      if (probHidraulico > 20) {
        fallas.add(FallaPredicha(
          id: ObjectId().toHexString(),
          maquinariaId: maquinaria.id,
          tipoFalla: 'hidraulico',
          nombreFalla: 'Falla del Sistema Hidráulico',
          probabilidad: probHidraulico.clamp(0.0, 100.0),
          severidad: probHidraulico > 60 ? 'critica' : probHidraulico > 40 ? 'alta' : 'media',
          fechaEstimada: ahora.add(Duration(days: (100 - probHidraulico).round() * 2)),
          descripcion: 'Riesgo de falla en sistema hidráulico por desgaste de componentes',
          sintomas: [
            'Fugas de aceite hidráulico',
            'Movimientos lentos o erráticos',
            'Pérdida de presión',
            'Ruidos en bombas hidráulicas',
          ],
          accionesPreventivas: [
            'Revisión de mangueras y conexiones',
            'Cambio de filtros hidráulicos',
            'Verificación de niveles de aceite',
            'Inspección de bombas y válvulas',
          ],
          factores: {
            'horasTotales': horasTotales,
            'analisisAdvertencia': analisisAdvertencia,
            'diasDesdeUltimoMantenimiento': diasDesdeUltimoMantenimiento,
          },
        ));
      }
    }

    // 3. Falla de Transmisión
    if (horasTotales > 2500 || intensidadUso > 150) {
      double probTransmision = 0.0;
      if (horasTotales > 4500) probTransmision += 30;
      if (intensidadUso > 200) probTransmision += 25;
      if (deficitMantenimientos > 1) probTransmision += 20;
      if (analisisCriticos > 0) probTransmision += 15;

      if (probTransmision > 20) {
        fallas.add(FallaPredicha(
          id: ObjectId().toHexString(),
          maquinariaId: maquinaria.id,
          tipoFalla: 'transmision',
          nombreFalla: 'Falla de Transmisión',
          probabilidad: probTransmision.clamp(0.0, 100.0),
          severidad: probTransmision > 55 ? 'alta' : 'media',
          fechaEstimada: ahora.add(Duration(days: (100 - probTransmision).round() * 3)),
          descripcion: 'Riesgo de falla en transmisión por uso intensivo',
          sintomas: [
            'Dificultad para cambiar de marcha',
            'Ruidos de engranajes',
            'Pérdida de potencia',
            'Vibraciones anormales',
          ],
          accionesPreventivas: [
            'Cambio de aceite de transmisión',
            'Revisión de embrague',
            'Ajuste de sistema de cambio',
          ],
          factores: {
            'horasTotales': horasTotales,
            'intensidadUso': intensidadUso,
          },
        ));
      }
    }

    // 4. Falla de Frenos
    if (horasTotales > 1500 || intensidadUso > 100) {
      double probFrenos = 0.0;
      if (horasTotales > 3000) probFrenos += 25;
      if (intensidadUso > 150) probFrenos += 20;
      if (diasDesdeUltimoMantenimiento > 90) probFrenos += 15;

      if (probFrenos > 20) {
        fallas.add(FallaPredicha(
          id: ObjectId().toHexString(),
          maquinariaId: maquinaria.id,
          tipoFalla: 'frenos',
          nombreFalla: 'Degradación del Sistema de Frenos',
          probabilidad: probFrenos.clamp(0.0, 100.0),
          severidad: probFrenos > 50 ? 'alta' : 'media',
          fechaEstimada: ahora.add(Duration(days: (100 - probFrenos).round() * 4)),
          descripcion: 'Desgaste de pastillas y discos de freno',
          sintomas: [
            'Distancia de frenado aumentada',
            'Ruidos al frenar',
            'Vibración en el pedal',
            'Pérdida de eficiencia de frenado',
          ],
          accionesPreventivas: [
            'Revisión de pastillas de freno',
            'Verificación de discos/tambores',
            'Revisión de sistema hidráulico de frenos',
            'Reemplazo de componentes desgastados',
          ],
          factores: {
            'horasTotales': horasTotales,
            'intensidadUso': intensidadUso,
          },
        ));
      }
    }

    // 5. Falla de Tren de Rodaje
    if (horasTotales > 2000) {
      double probRodaje = 0.0;
      if (horasTotales > 4000) probRodaje += 30;
      if (intensidadUso > 180) probRodaje += 20;
      if (analisisAdvertencia > 1) probRodaje += 15;

      if (probRodaje > 20) {
        fallas.add(FallaPredicha(
          id: ObjectId().toHexString(),
          maquinariaId: maquinaria.id,
          tipoFalla: 'tren_rodaje',
          nombreFalla: 'Desgaste del Tren de Rodaje',
          probabilidad: probRodaje.clamp(0.0, 100.0),
          severidad: probRodaje > 50 ? 'alta' : 'media',
          fechaEstimada: ahora.add(Duration(days: (100 - probRodaje).round() * 5)),
          descripcion: 'Desgaste de orugas, rodillos y componentes del tren de rodaje',
          sintomas: [
            'Ruidos en orugas',
            'Desalineación',
            'Desgaste irregular',
            'Pérdida de tensión',
          ],
          accionesPreventivas: [
            'Inspección de orugas',
            'Revisión de rodillos',
            'Ajuste de tensión',
            'Reemplazo de componentes desgastados',
          ],
          factores: {
            'horasTotales': horasTotales,
            'intensidadUso': intensidadUso,
          },
        ));
      }
    }

    return fallas;
  }

  /// Genera recordatorios de mantenimiento basados en horas de uso
  List<MantenimientoRecordatorio> _generarRecordatoriosMantenimiento(
    String maquinariaId,
    int horasActuales,
    int horasTotales,
  ) {
    final recordatorios = <MantenimientoRecordatorio>[];
    final ahora = DateTime.now();

    // 1. Cambio de Aceite (cada 250 horas)
    final horasUltimoAceite = horasActuales % 250;
    final horasRestantesAceite = 250 - horasUltimoAceite;
    final urgenteAceite = horasRestantesAceite <= 25; // Urgente si faltan 25 horas o menos

    recordatorios.add(MantenimientoRecordatorio(
      id: ObjectId().toHexString(),
      maquinariaId: maquinariaId,
      tipoMantenimiento: 'aceite',
      horasIntervalo: 250,
      horasUltimoMantenimiento: horasActuales - horasUltimoAceite,
      horasActuales: horasActuales,
      horasRestantes: horasRestantesAceite,
      urgente: urgenteAceite,
      fechaEstimada: ahora.add(Duration(days: (horasRestantesAceite / 8).round())), // Asumiendo 8 horas/día
      descripcion: 'Cambio de aceite del motor',
      acciones: [
        'Drenar aceite usado',
        'Reemplazar filtro de aceite',
        'Agregar aceite nuevo según especificaciones',
        'Verificar nivel de aceite',
      ],
    ));

    // 2. Cambio de Filtros (cada 500 horas)
    final horasUltimoFiltro = horasActuales % 500;
    final horasRestantesFiltro = 500 - horasUltimoFiltro;
    final urgenteFiltro = horasRestantesFiltro <= 50;

    recordatorios.add(MantenimientoRecordatorio(
      id: ObjectId().toHexString(),
      maquinariaId: maquinariaId,
      tipoMantenimiento: 'filtro',
      horasIntervalo: 500,
      horasUltimoMantenimiento: horasActuales - horasUltimoFiltro,
      horasActuales: horasActuales,
      horasRestantes: horasRestantesFiltro,
      urgente: urgenteFiltro,
      fechaEstimada: ahora.add(Duration(days: (horasRestantesFiltro / 8).round())),
      descripcion: 'Cambio de filtros (aire, combustible, hidráulico)',
      acciones: [
        'Reemplazar filtro de aire',
        'Reemplazar filtro de combustible',
        'Reemplazar filtro hidráulico',
        'Verificar estado de filtros',
      ],
    ));

    // 3. Revisión General (cada 500 horas)
    final horasUltimaRevision = horasActuales % 500;
    final horasRestantesRevision = 500 - horasUltimaRevision;
    final urgenteRevision = horasRestantesRevision <= 50;

    recordatorios.add(MantenimientoRecordatorio(
      id: ObjectId().toHexString(),
      maquinariaId: maquinariaId,
      tipoMantenimiento: 'revision_general',
      horasIntervalo: 500,
      horasUltimoMantenimiento: horasActuales - horasUltimaRevision,
      horasActuales: horasActuales,
      horasRestantes: horasRestantesRevision,
      urgente: urgenteRevision,
      fechaEstimada: ahora.add(Duration(days: (horasRestantesRevision / 8).round())),
      descripcion: 'Revisión general de sistemas',
      acciones: [
        'Inspección visual completa',
        'Verificación de niveles de fluidos',
        'Revisión de sistemas eléctricos',
        'Lubricación de puntos críticos',
        'Verificación de neumáticos/orugas',
      ],
    ));

    // 4. Revisión Mayor (cada 1000 horas)
    final horasUltimaRevisionMayor = horasActuales % 1000;
    final horasRestantesRevisionMayor = 1000 - horasUltimaRevisionMayor;
    final urgenteRevisionMayor = horasRestantesRevisionMayor <= 100;

    recordatorios.add(MantenimientoRecordatorio(
      id: ObjectId().toHexString(),
      maquinariaId: maquinariaId,
      tipoMantenimiento: 'revision_mayor',
      horasIntervalo: 1000,
      horasUltimoMantenimiento: horasActuales - horasUltimaRevisionMayor,
      horasActuales: horasActuales,
      horasRestantes: horasRestantesRevisionMayor,
      urgente: urgenteRevisionMayor,
      fechaEstimada: ahora.add(Duration(days: (horasRestantesRevisionMayor / 8).round())),
      descripcion: 'Revisión mayor completa',
      acciones: [
        'Revisión completa del motor',
        'Inspección de transmisión',
        'Revisión de sistema hidráulico',
        'Verificación de estructura y chasis',
        'Calibración de sistemas',
        'Reemplazo de componentes desgastados',
      ],
    ));

    return recordatorios;
  }

  /// Estima días hasta falla basado en el score de riesgo
  int _estimarDiasHastaFalla(double riskScore, int horasUso, int diasDesdeMantenimiento) {
    // Simulación: cuanto mayor el riesgo, menor el tiempo estimado
    if (riskScore >= 70) {
      return 7 + (100 - riskScore).round(); // 7-37 días
    } else if (riskScore >= 40) {
      return 30 + ((70 - riskScore) * 2).round(); // 30-90 días
    } else {
      return 60 + ((40 - riskScore) * 3).round(); // 60-180 días
    }
  }

  /// Obtiene predicciones de alto riesgo (score >= 70)
  Future<List<MLPrediction>> obtenerPrediccionesCriticas() async {
    final todas = await generarPredicciones();
    return todas.where((p) => p.riskScore >= 70).toList();
  }

  /// Obtiene predicciones para una máquina específica
  Future<MLPrediction?> obtenerPrediccionPorMaquinaria(String maquinariaId) async {
    final maquinaria = await _controlMaquinaria.consultarMaquinaria(maquinariaId);
    if (maquinaria == null) return null;
    return await _predecirFalla(maquinaria);
  }
}

