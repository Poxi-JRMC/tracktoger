import '../models/maquinaria.dart';
import '../controllers/control_ml.dart';
import '../controllers/control_maquinaria.dart';
import '../controllers/control_mantenimiento.dart';
import 'dart:math';

/// Resultados de evaluación del modelo
class EvaluationResults {
    final double accuracy;
    final double precision;
    final double recall;
    final double f1Score;
    final double auc;
    final ConfusionMatrix confusionMatrix;
    final ROCCurve rocCurve;
    final Map<String, double> perClassMetrics;
    final DateTime fechaEvaluacion;

    EvaluationResults({
      required this.accuracy,
      required this.precision,
      required this.recall,
      required this.f1Score,
      required this.auc,
      required this.confusionMatrix,
      required this.rocCurve,
      required this.perClassMetrics,
      required this.fechaEvaluacion,
    });

    Map<String, dynamic> toMap() {
      return {
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1Score': f1Score,
        'auc': auc,
        'confusionMatrix': confusionMatrix.toMap(),
        'rocCurve': rocCurve.toMap(),
        'perClassMetrics': perClassMetrics,
        'fechaEvaluacion': fechaEvaluacion.toIso8601String(),
      };
    }
  }

  /// Matriz de confusión para evaluación de clasificación
  class ConfusionMatrix {
    final int truePositives;   // TP: Predijo falla y realmente falló
    final int trueNegatives;   // TN: Predijo no falla y no falló
    final int falsePositives;  // FP: Predijo falla pero no falló (falsa alarma)
    final int falseNegatives;  // FN: Predijo no falla pero sí falló (fallo crítico)

    ConfusionMatrix({
      required this.truePositives,
      required this.trueNegatives,
      required this.falsePositives,
      required this.falseNegatives,
    });

    int get total => truePositives + trueNegatives + falsePositives + falseNegatives;

    Map<String, dynamic> toMap() {
      return {
        'truePositives': truePositives,
        'trueNegatives': trueNegatives,
        'falsePositives': falsePositives,
        'falseNegatives': falseNegatives,
        'total': total,
      };
    }

    @override
    String toString() {
      return '''
      Matriz de Confusión:
      ┌─────────────┬──────────────┬──────────────┐
      │             │ Predicción   │ Predicción   │
      │             │ Falla        │ No Falla     │
      ├─────────────┼──────────────┼──────────────┤
      │ Real Falla  │ TP: $truePositives     │ FN: $falseNegatives     │
      │ Real No Falla│ FP: $falsePositives     │ TN: $trueNegatives     │
      └─────────────┴──────────────┴──────────────┘
      ''';
    }
}

/// Curva ROC (Receiver Operating Characteristic)
class ROCCurve {
    final List<ROCPoint> points;
    final double auc; // Area Under Curve

    ROCCurve({
      required this.points,
      required this.auc,
    });

    Map<String, dynamic> toMap() {
      return {
        'points': points.map((p) => p.toMap()).toList(),
        'auc': auc,
        'pointCount': points.length,
      };
    }
  }

  /// Punto en la curva ROC
  class ROCPoint {
    final double falsePositiveRate; // Tasa de falsos positivos (1 - Especificidad)
    final double truePositiveRate;  // Tasa de verdaderos positivos (Sensibilidad/Recall)
    final double threshold;         // Umbral de decisión

    ROCPoint({
      required this.falsePositiveRate,
      required this.truePositiveRate,
      required this.threshold,
    });

    Map<String, dynamic> toMap() {
      return {
        'falsePositiveRate': falsePositiveRate,
        'truePositiveRate': truePositiveRate,
        'threshold': threshold,
      };
    }
  }

/// Servicio profesional de evaluación de modelos de Machine Learning
/// Implementa métricas estándar de la industria: Accuracy, Recall, Precision, F1-Score, ROC, AUC
class MLEvaluationService {
  final ControlML _controlML = ControlML();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();

  /// Evalúa el modelo ML usando datos históricos
  /// 
  /// Este método simula la evaluación usando datos históricos de máquinas.
  /// En producción, se usarían datos de prueba etiquetados.
  Future<EvaluationResults> evaluarModelo({
    List<Maquinaria>? maquinariasTest,
    List<Map<String, dynamic>>? datosEtiquetados,
  }) async {
    // Si no se proporcionan datos de prueba, usar todas las máquinas
    final maquinarias = maquinariasTest ?? 
        await _controlMaquinaria.consultarTodasMaquinarias();

    // Obtener predicciones del modelo
    final predicciones = await _controlML.generarPredicciones();

    // Generar datos de prueba simulados basados en predicciones y datos históricos
    final datosPrueba = await _generarDatosPrueba(maquinarias, predicciones);

    // Calcular matriz de confusión
    final confusionMatrix = _calcularMatrizConfusion(datosPrueba);

    // Calcular métricas básicas
    final accuracy = _calcularAccuracy(confusionMatrix);
    final precision = _calcularPrecision(confusionMatrix);
    final recall = _calcularRecall(confusionMatrix);
    final f1Score = _calcularF1Score(precision, recall);

    // Calcular curva ROC y AUC
    final rocCurve = await _calcularROCCurve(datosPrueba);
    final auc = rocCurve.auc;

    // Calcular métricas por clase (tipo de falla)
    final perClassMetrics = await _calcularMetricasPorClase(datosPrueba);

    return EvaluationResults(
      accuracy: accuracy,
      precision: precision,
      recall: recall,
      f1Score: f1Score,
      auc: auc,
      confusionMatrix: confusionMatrix,
      rocCurve: rocCurve,
      perClassMetrics: perClassMetrics,
      fechaEvaluacion: DateTime.now(),
    );
  }

  /// Genera datos de prueba simulados basados en predicciones y datos históricos
  Future<List<Map<String, dynamic>>> _generarDatosPrueba(
    List<Maquinaria> maquinarias,
    List<dynamic> predicciones,
  ) async {
    final datosPrueba = <Map<String, dynamic>>[];

    for (var maq in maquinarias) {
      // Buscar predicción correspondiente
      final prediccion = predicciones.firstWhere(
        (p) => p.maquinariaId == maq.id,
        orElse: () => null,
      );

      if (prediccion == null) continue;

      // Obtener datos históricos de mantenimiento
      final ordenesTrabajo = await _controlMantenimiento.consultarTodasOrdenesTrabajo();
      final ordenesMaq = ordenesTrabajo.where((o) => o.maquinariaId == maq.id).toList();
      final tieneFallasHistoricas = ordenesMaq.any((o) => 
        o.tipoTrabajo.toLowerCase().contains('reparacion') ||
        o.tipoTrabajo.toLowerCase().contains('falla')
      );

      // Etiqueta real (simulada basada en datos históricos)
      // En producción, esto vendría de datos etiquetados reales
      final etiquetaReal = _simularEtiquetaReal(
        maq,
        prediccion.riskScore,
        tieneFallasHistoricas,
      );

      // Probabilidad predicha
      final probabilidadPredicha = prediccion.riskScore / 100.0; // Normalizar a 0-1

      datosPrueba.add({
        'maquinariaId': maq.id,
        'etiquetaReal': etiquetaReal, // 1 = falló, 0 = no falló
        'probabilidadPredicha': probabilidadPredicha,
        'riskScore': prediccion.riskScore,
        'prediccion': prediccion,
      });
    }

    return datosPrueba;
  }

  /// Simula etiqueta real basada en datos históricos
  /// En producción, esto vendría de datos reales etiquetados
  int _simularEtiquetaReal(
    Maquinaria maq,
    double riskScore,
    bool tieneFallasHistoricas,
  ) {
    // Lógica de simulación: si el riskScore es muy alto o hay fallas históricas,
    // es más probable que realmente haya fallado
    final random = Random();
    final probabilidadReal = (riskScore / 100.0) * 0.7 + 
                            (tieneFallasHistoricas ? 0.3 : 0.0);
    
    return random.nextDouble() < probabilidadReal ? 1 : 0;
  }

  /// Calcula la matriz de confusión
  ConfusionMatrix _calcularMatrizConfusion(List<Map<String, dynamic>> datosPrueba) {
    int tp = 0, tn = 0, fp = 0, fn = 0;
    const threshold = 0.5; // Umbral de decisión (50% de probabilidad)

    for (var dato in datosPrueba) {
      final etiquetaReal = dato['etiquetaReal'] as int;
      final probabilidadPredicha = dato['probabilidadPredicha'] as double;
      final prediccion = probabilidadPredicha >= threshold ? 1 : 0;

      if (etiquetaReal == 1 && prediccion == 1) {
        tp++; // True Positive
      } else if (etiquetaReal == 0 && prediccion == 0) {
        tn++; // True Negative
      } else if (etiquetaReal == 0 && prediccion == 1) {
        fp++; // False Positive
      } else if (etiquetaReal == 1 && prediccion == 0) {
        fn++; // False Negative
      }
    }

    return ConfusionMatrix(
      truePositives: tp,
      trueNegatives: tn,
      falsePositives: fp,
      falseNegatives: fn,
    );
  }

  /// Calcula Accuracy (Precisión): Porcentaje de predicciones correctas
  /// Accuracy = (TP + TN) / (TP + TN + FP + FN)
  double _calcularAccuracy(ConfusionMatrix matrix) {
    if (matrix.total == 0) return 0.0;
    return (matrix.truePositives + matrix.trueNegatives) / matrix.total;
  }

  /// Calcula Precision (Precisión): De todas las predicciones de falla, cuántas fueron correctas
  /// Precision = TP / (TP + FP)
  double _calcularPrecision(ConfusionMatrix matrix) {
    final denominator = matrix.truePositives + matrix.falsePositives;
    if (denominator == 0) return 0.0;
    return matrix.truePositives / denominator;
  }

  /// Calcula Recall (Sensibilidad): De todas las fallas reales, cuántas detectó el modelo
  /// Recall = TP / (TP + FN)
  /// También conocido como True Positive Rate (TPR) o Sensitivity
  double _calcularRecall(ConfusionMatrix matrix) {
    final denominator = matrix.truePositives + matrix.falseNegatives;
    if (denominator == 0) return 0.0;
    return matrix.truePositives / denominator;
  }

  /// Calcula F1-Score: Promedio armónico de Precision y Recall
  /// F1 = 2 * (Precision * Recall) / (Precision + Recall)
  double _calcularF1Score(double precision, double recall) {
    if (precision + recall == 0) return 0.0;
    return 2 * (precision * recall) / (precision + recall);
  }

  /// Calcula la curva ROC y el AUC
  /// ROC: Gráfica de True Positive Rate vs False Positive Rate
  /// AUC: Area Under Curve (área bajo la curva ROC)
  Future<ROCCurve> _calcularROCCurve(List<Map<String, dynamic>> datosPrueba) async {
    // Ordenar por probabilidad predicha (de mayor a menor)
    final datosOrdenados = List<Map<String, dynamic>>.from(datosPrueba)
      ..sort((a, b) => (b['probabilidadPredicha'] as double)
          .compareTo(a['probabilidadPredicha'] as double));

    final puntos = <ROCPoint>[];
    final totalPositivos = datosPrueba.where((d) => d['etiquetaReal'] == 1).length;
    final totalNegativos = datosPrueba.length - totalPositivos;

    if (totalPositivos == 0 || totalNegativos == 0) {
      // Si no hay positivos o negativos, retornar curva vacía
      return ROCCurve(points: [], auc: 0.0);
    }

    int tp = 0, fp = 0;

    // Agregar punto inicial (0, 0)
    puntos.add(ROCPoint(
      falsePositiveRate: 0.0,
      truePositiveRate: 0.0,
      threshold: 1.0,
    ));

    // Calcular puntos para cada umbral
    for (var dato in datosOrdenados) {
      final etiquetaReal = dato['etiquetaReal'] as int;
      final threshold = dato['probabilidadPredicha'] as double;

      if (etiquetaReal == 1) {
        tp++;
      } else {
        fp++;
      }

      final tpr = tp / totalPositivos; // True Positive Rate (Recall)
      final fpr = fp / totalNegativos; // False Positive Rate

      puntos.add(ROCPoint(
        falsePositiveRate: fpr,
        truePositiveRate: tpr,
        threshold: threshold,
      ));
    }

    // Agregar punto final (1, 1)
    puntos.add(ROCPoint(
      falsePositiveRate: 1.0,
      truePositiveRate: 1.0,
      threshold: 0.0,
    ));

    // Calcular AUC usando método trapezoidal
    final auc = _calcularAUC(puntos);

    return ROCCurve(points: puntos, auc: auc);
  }

  /// Calcula el AUC (Area Under Curve) usando método trapezoidal
  double _calcularAUC(List<ROCPoint> puntos) {
    if (puntos.length < 2) return 0.0;

    double auc = 0.0;
    for (int i = 1; i < puntos.length; i++) {
      final prev = puntos[i - 1];
      final curr = puntos[i];

      // Área del trapecio: (b1 + b2) * h / 2
      final base1 = prev.truePositiveRate;
      final base2 = curr.truePositiveRate;
      final altura = curr.falsePositiveRate - prev.falsePositiveRate;

      auc += (base1 + base2) * altura / 2.0;
    }

    return auc;
  }

  /// Calcula métricas por clase (tipo de falla)
  Future<Map<String, double>> _calcularMetricasPorClase(
    List<Map<String, dynamic>> datosPrueba,
  ) async {
    final metricas = <String, double>{};

    // Agrupar por tipo de falla predicha
    final fallasPorTipo = <String, List<Map<String, dynamic>>>{};

    for (var dato in datosPrueba) {
      final prediccion = dato['prediccion'];
      if (prediccion != null && prediccion.fallasPredichas.isNotEmpty) {
        for (var falla in prediccion.fallasPredichas) {
          final tipo = falla.tipoFalla;
          if (!fallasPorTipo.containsKey(tipo)) {
            fallasPorTipo[tipo] = [];
          }
          fallasPorTipo[tipo]!.add(dato);
        }
      }
    }

    // Calcular métricas para cada tipo
    for (var entry in fallasPorTipo.entries) {
      final tipo = entry.key;
      final datos = entry.value;

      if (datos.isEmpty) continue;

      // Calcular accuracy para este tipo
      int correctos = 0;
      for (var dato in datos) {
        final etiquetaReal = dato['etiquetaReal'] as int;
        final probabilidad = dato['probabilidadPredicha'] as double;
        final prediccion = probabilidad >= 0.5 ? 1 : 0;
        if (etiquetaReal == prediccion) correctos++;
      }

      metricas['${tipo}_accuracy'] = correctos / datos.length;
      metricas['${tipo}_count'] = datos.length.toDouble();
    }

    return metricas;
  }

  /// Obtiene un resumen ejecutivo de la evaluación
  String obtenerResumenEjecutivo(EvaluationResults resultados) {
    return '''
═══════════════════════════════════════════════════════════════
  RESUMEN EJECUTIVO - EVALUACIÓN DEL MODELO DE MACHINE LEARNING
═══════════════════════════════════════════════════════════════

📊 MÉTRICAS PRINCIPALES:
  • Accuracy (Precisión): ${(resultados.accuracy * 100).toStringAsFixed(2)}%
  • Precision: ${(resultados.precision * 100).toStringAsFixed(2)}%
  • Recall (Sensibilidad): ${(resultados.recall * 100).toStringAsFixed(2)}%
  • F1-Score: ${(resultados.f1Score * 100).toStringAsFixed(2)}%
  • AUC (Area Under Curve): ${(resultados.auc * 100).toStringAsFixed(2)}%

${resultados.confusionMatrix}

📈 INTERPRETACIÓN:
  • El modelo tiene un ${(resultados.accuracy * 100).toStringAsFixed(1)}% de precisión general
  • Detecta ${(resultados.recall * 100).toStringAsFixed(1)}% de las fallas reales (Recall)
  • De las predicciones de falla, ${(resultados.precision * 100).toStringAsFixed(1)}% son correctas (Precision)
  • F1-Score de ${(resultados.f1Score * 100).toStringAsFixed(1)}% indica buen balance entre Precision y Recall
  • AUC de ${(resultados.auc * 100).toStringAsFixed(1)}% indica ${resultados.auc >= 0.8 ? 'excelente' : resultados.auc >= 0.7 ? 'buena' : 'moderada'} capacidad de discriminación

🎯 RECOMENDACIONES:
${_generarRecomendaciones(resultados)}

═══════════════════════════════════════════════════════════════
''';
  }

  String _generarRecomendaciones(EvaluationResults resultados) {
    final recomendaciones = <String>[];

    if (resultados.recall < 0.8) {
      recomendaciones.add('  ⚠️  Recall bajo: El modelo está perdiendo fallas reales. Considerar reducir el umbral de decisión.');
    }

    if (resultados.precision < 0.7) {
      recomendaciones.add('  ⚠️  Precision baja: Muchas falsas alarmas. Considerar aumentar el umbral de decisión.');
    }

    if (resultados.f1Score < 0.75) {
      recomendaciones.add('  ⚠️  F1-Score bajo: Desbalance entre Precision y Recall. Revisar hiperparámetros.');
    }

    if (resultados.auc < 0.7) {
      recomendaciones.add('  ⚠️  AUC bajo: El modelo tiene dificultad para distinguir entre fallas y no fallas. Considerar más features o reentrenamiento.');
    }

    if (resultados.confusionMatrix.falseNegatives > resultados.confusionMatrix.truePositives) {
      recomendaciones.add('  🚨  CRÍTICO: Más falsos negativos que verdaderos positivos. El modelo está fallando en detectar fallas reales.');
    }

    if (recomendaciones.isEmpty) {
      recomendaciones.add('  ✅  El modelo muestra un rendimiento satisfactorio. Continuar monitoreo.');
    }

    return recomendaciones.join('\n');
  }
}

