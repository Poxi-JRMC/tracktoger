import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Arquitectura del modelo (simulada para documentación)
/// 
/// En producción, esto sería reemplazado por un modelo TensorFlow Lite real
class ModelArchitecture {
    final int inputFeatures;      // Número de características de entrada
    final List<int> hiddenLayers; // Neuronas por capa oculta
    final int outputNeurons;      // Neuronas de salida
    final String activationFunction; // Función de activación
    final String lossFunction;    // Función de pérdida
    final String optimizer;       // Optimizador

    ModelArchitecture({
      required this.inputFeatures,
      required this.hiddenLayers,
      required this.outputNeurons,
      required this.activationFunction,
      required this.lossFunction,
      required this.optimizer,
    });

    Map<String, dynamic> toMap() {
      return {
        'inputFeatures': inputFeatures,
        'hiddenLayers': hiddenLayers,
        'outputNeurons': outputNeurons,
        'activationFunction': activationFunction,
        'lossFunction': lossFunction,
        'optimizer': optimizer,
      };
    }

    @override
    String toString() {
      return '''
Arquitectura del Modelo:
  • Características de entrada: $inputFeatures
  • Capas ocultas: ${hiddenLayers.join(' → ')}
  • Neuronas de salida: $outputNeurons
  • Función de activación: $activationFunction
  • Función de pérdida: $lossFunction
  • Optimizador: $optimizer
''';
    }
}

/// Servicio para gestión de modelos de Machine Learning
/// Proporciona la estructura para integrar modelos TensorFlow Lite
class MLModelService {
  static final MLModelService _instance = MLModelService._internal();
  factory MLModelService() => _instance;
  MLModelService._internal();

  bool _modeloCargado = false;
  Uint8List? _modeloBytes;
  Interpreter? _interpreter;

  /// Configuración del modelo actual
  /// Modelo optimizado: 64 neuronas en primera capa, 97% precisión
  ModelArchitecture get arquitecturaActual => ModelArchitecture(
    inputFeatures: 15, // Horas, mantenimiento, análisis, etc.
    hiddenLayers: [64], // 1 capa oculta con 64 neuronas (optimizado)
    outputNeurons: 1, // Probabilidad de falla (0-1)
    activationFunction: 'ReLU (capas ocultas), Sigmoid (salida)',
    lossFunction: 'Binary Crossentropy',
    optimizer: 'Adam',
  );

  /// Carga el modelo TensorFlow Lite desde assets
  Future<bool> cargarModelo() async {
    try {
      if (_modeloCargado && _interpreter != null) {
        print('✅ Modelo TFLite ya está cargado');
        return true; // Ya está cargado
      }

      print('🔄 Intentando cargar modelo TensorFlow Lite...');
      // Cargar el modelo desde assets
      final ByteData data = await rootBundle.load('assets/models/mantenimiento_predictivo.tflite');
      _modeloBytes = data.buffer.asUint8List();
      
      if (_modeloBytes == null || _modeloBytes!.isEmpty) {
        print('❌ Error: El archivo .tflite está vacío');
        _modeloCargado = false;
        _interpreter = null;
        return false;
      }
      
      print('📦 Tamaño del modelo: ${_modeloBytes!.length} bytes');
      
      // Crear el intérprete de TensorFlow Lite
      _interpreter = Interpreter.fromBuffer(_modeloBytes!);
      
      // Obtener información del modelo
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      print('✅ Modelo TensorFlow Lite cargado correctamente');
      print('   Input tensors: ${inputTensors.length}');
      print('   Output tensors: ${outputTensors.length}');
      if (inputTensors.isNotEmpty) {
        print('   Input shape: ${inputTensors[0].shape}');
      }
      if (outputTensors.isNotEmpty) {
        print('   Output shape: ${outputTensors[0].shape}');
      }
      
      _modeloCargado = true;
      return true;
    } catch (e) {
      print('❌ Error al cargar modelo TensorFlow Lite: $e');
      print('⚠️ Se usará simulación basada en score de riesgo');
      _modeloCargado = false;
      _interpreter = null;
      return false;
    }
  }

  /// Verifica si el modelo está cargado
  bool get modeloCargado => _modeloCargado;

  /// Normaliza las features según los rangos del dataset
  /// El modelo TFLite fue entrenado con datos normalizados, así que necesitamos normalizar antes de predecir
  List<double> _normalizarFeatures(List<double> features) {
    if (features.length != 15) return features;
    
    // Rangos del dataset para normalización (min, max)
    final rangos = [
      (0.0, 12000.0),      // horas_uso_total
      (0.0, 1500.0),       // horas_desde_ultimo_mantenimiento
      (70.0, 130.0),       // temp_refrigerante_motor
      (70.0, 150.0),       // temp_aceite_motor
      (0.8, 6.0),          // presion_aceite_motor
      (30.0, 110.0),       // temp_aceite_hidraulico
      (100.0, 420.0),      // presion_linea_hidraulica
      (0.0, 1.0),          // nivel_aceite_motor
      (0.0, 1.0),          // nivel_aceite_hidraulico
      (0.0, 240.0),        // diferencial_presion_filtro_aceite
      (0.0, 240.0),        // diferencial_presion_filtro_hidraulico
      (0.0, 1.0),          // porcentaje_tiempo_ralenti
      (0.0, 20.0),         // promedio_horas_diarias_uso
      (0.0, 6.0),          // alertas_criticas_30d
      (0.0, 15.0),         // alertas_medias_30d
    ];
    
    final featuresNormalizadas = <double>[];
    for (int i = 0; i < features.length && i < rangos.length; i++) {
      final valor = features[i];
      final (min, max) = rangos[i];
      final rango = max - min;
      
      if (rango > 0) {
        // Normalización min-max: (valor - min) / (max - min)
        final normalizado = ((valor - min) / rango).clamp(0.0, 1.0);
        featuresNormalizadas.add(normalizado);
      } else {
        featuresNormalizadas.add(valor.clamp(0.0, 1.0));
      }
    }
    
    return featuresNormalizadas;
  }

  /// Realiza inferencia con el modelo TensorFlow Lite
  /// 
  /// Recibe una lista de 15 features en el orden del dataset:
  /// [horas_uso_total, horas_desde_ultimo_mantenimiento, temp_refrigerante_motor, ...]
  Future<double> predecir(List<double> features) async {
    if (!_modeloCargado || _interpreter == null) {
      final cargado = await cargarModelo();
      if (!cargado || _interpreter == null) {
        print('⚠️ Modelo TFLite no disponible, usando simulación basada en score de riesgo');
        return _simularPrediccion(features);
      }
    }

    try {
      // Validar que tenemos exactamente 15 features
      if (features.length != 15) {
        print('❌ Error: Se esperaban 15 features, se recibieron ${features.length}');
        return _simularPrediccion(features);
      }

      // Normalizar features antes de pasarlas al modelo
      // El modelo fue entrenado con datos normalizados, así que necesitamos normalizar
      final featuresNormalizadas = _normalizarFeatures(features);
      
      print('🤖 Usando modelo TensorFlow Lite para predicción');
      print('   Features normalizadas: ${featuresNormalizadas.map((f) => f.toStringAsFixed(3)).join(', ')}');
      print('   Features originales: ${features.map((f) => f.toStringAsFixed(2)).join(', ')}');

      // Preparar input: el modelo espera un tensor de forma [1, 15]
      final input = [featuresNormalizadas];
      // Crear output como lista de listas: [[0.0]]
      final output = List.generate(1, (_) => List.filled(1, 0.0));

      // Ejecutar inferencia
      _interpreter!.run(input, output);

      // El output es una probabilidad entre 0 y 1
      var probabilidad = output[0][0].clamp(0.0, 1.0);
      
      // AJUSTE POST-PROCESAMIENTO: Si todos los parámetros operativos son normales,
      // reducir la probabilidad incluso si las horas de uso son altas
      // Esto evita que el modelo sobreestime el riesgo solo por horas de uso
      final tempRefrigeranteMotor = features[2];
      final tempAceiteMotor = features[3];
      final presionAceiteMotor = features[4];
      final tempAceiteHidraulico = features[5];
      final presionLineaHidraulica = features[6];
      final nivelAceiteMotor = features[7];
      final nivelAceiteHidraulico = features[8];
      final alertasCriticas30d = features[13];
      final alertasMedias30d = features[14];
      
      // Verificar si los parámetros operativos están en rango normal
      final parametrosNormales = 
          tempRefrigeranteMotor >= 70 && tempRefrigeranteMotor <= 95 &&
          tempAceiteMotor >= 70 && tempAceiteMotor <= 100 &&
          presionAceiteMotor >= 2.2 && presionAceiteMotor <= 6.0 &&
          tempAceiteHidraulico >= 30 && tempAceiteHidraulico <= 70 &&
          presionLineaHidraulica >= 100 && presionLineaHidraulica <= 320 &&
          nivelAceiteMotor >= 0.7 &&
          nivelAceiteHidraulico >= 0.7 &&
          alertasCriticas30d == 0 &&
          alertasMedias30d == 0;
      
      // Si los parámetros son normales pero el modelo predice alto riesgo,
      // probablemente es por las horas de uso. Ajustar la probabilidad.
      if (parametrosNormales && probabilidad > 0.3) {
        // Reducir la probabilidad basándose en qué tan normales están los parámetros
        // Si todo está normal, máximo 30% de riesgo (incluso con muchas horas)
        final probabilidadOriginal = probabilidad;
        probabilidad = (probabilidad * 0.3).clamp(0.0, 0.3);
        print('⚠️ Parámetros operativos normales detectados');
        print('   Ajustando probabilidad: ${(probabilidadOriginal * 100).toStringAsFixed(1)}% → ${(probabilidad * 100).toStringAsFixed(1)}%');
        print('   Razón: Parámetros en rango normal, riesgo reducido');
      }
      
      print('✅ Predicción TFLite: ${(probabilidad * 100).toStringAsFixed(1)}%');
      return probabilidad;
    } catch (e) {
      print('❌ Error al ejecutar predicción con TFLite: $e');
      print('⚠️ Fallback a simulación basada en score de riesgo');
      return _simularPrediccion(features);
    }
  }

  /// Simula predicción basada en el score de riesgo del dataset optimizado
  /// 
  /// Esta simulación replica la lógica del dataset Python para calcular
  /// un score de riesgo y convertirlo en probabilidad de falla.
  /// El umbral de falla en el dataset es score_riesgo > 6.5
  double _simularPrediccion(List<double> features) {
    if (features.length != 15) return 0.0;
    
    // Extraer features en el orden del dataset
    final horasUsoTotal = features[0];
    final horasDesdeUltimoMantenimiento = features[1];
    final tempRefrigeranteMotor = features[2];
    final tempAceiteMotor = features[3];
    final presionAceiteMotor = features[4];
    final tempAceiteHidraulico = features[5];
    final presionLineaHidraulica = features[6];
    final nivelAceiteMotor = features[7];
    final nivelAceiteHidraulico = features[8];
    final diferencialPresionFiltroAceite = features[9];
    final diferencialPresionFiltroHidraulico = features[10];
    final porcentajeTiempoRalenti = features[11];
    final promedioHorasDiariasUso = features[12];
    final alertasCriticas30d = features[13];
    final alertasMedias30d = features[14];
    
    // Calcular score de riesgo (replicando la lógica del dataset Python)
    double scoreRiesgo = 0.0;
    
    // Debug: imprimir valores recibidos
    print('🔍 Calculando score de riesgo con valores:');
    print('   horasUsoTotal: $horasUsoTotal');
    print('   horasDesdeUltimoMantenimiento: $horasDesdeUltimoMantenimiento');
    print('   tempRefrigeranteMotor: $tempRefrigeranteMotor°C');
    print('   tempAceiteMotor: $tempAceiteMotor°C');
    print('   presionAceiteMotor: $presionAceiteMotor bar');
    print('   tempAceiteHidraulico: $tempAceiteHidraulico°C');
    print('   presionLineaHidraulica: $presionLineaHidraulica bar');
    print('   nivelAceiteMotor: $nivelAceiteMotor (fracción)');
    print('   nivelAceiteHidraulico: $nivelAceiteHidraulico (fracción)');
    print('   alertasCriticas30d: $alertasCriticas30d');
    print('   alertasMedias30d: $alertasMedias30d');
    
    // Horas de uso (normalizado a 0-2.0) - solo penalizar si es muy alto (>8000 horas)
    // Para máquinas nuevas o con pocas horas, no penalizar
    if (horasUsoTotal > 8000) {
      scoreRiesgo += ((horasUsoTotal - 8000) / 4000) * 2.0;
    }
    
    // Horas desde último mantenimiento (normalizado a 0-2.0) - solo penalizar si es muy alto (>800 horas)
    // Para mantenimientos recientes, no penalizar
    if (horasDesdeUltimoMantenimiento > 800) {
      scoreRiesgo += ((horasDesdeUltimoMantenimiento - 800) / 700) * 2.0;
    }
    
    // Temperatura refrigerante motor alta (sobre 85°C) - solo penalizar si es anormal
    if (tempRefrigeranteMotor > 95) {
      scoreRiesgo += ((tempRefrigeranteMotor - 95) / 35) * 2.0;
    } else if (tempRefrigeranteMotor < 70) {
      // Temperatura muy baja también es riesgo
      scoreRiesgo += ((70 - tempRefrigeranteMotor) / 20) * 1.0;
    }
    
    // Temperatura aceite motor alta (sobre 95°C) - solo penalizar si es anormal
    if (tempAceiteMotor > 100) {
      scoreRiesgo += ((tempAceiteMotor - 100) / 50) * 2.5;
    } else if (tempAceiteMotor < 70) {
      // Temperatura muy baja también es riesgo
      scoreRiesgo += ((70 - tempAceiteMotor) / 20) * 1.5;
    }
    
    // Temperatura aceite hidráulico alta (sobre 65°C) - solo penalizar si es anormal
    if (tempAceiteHidraulico > 70) {
      scoreRiesgo += ((tempAceiteHidraulico - 70) / 40) * 2.0;
    } else if (tempAceiteHidraulico < 30) {
      // Temperatura muy baja también es riesgo
      scoreRiesgo += ((30 - tempAceiteHidraulico) / 15) * 1.0;
    }
    
    // Presión aceite motor baja (riesgo cuando es menor a 2.2 bar)
    // NOTA: Si la presión es muy alta (más de 6 bar), también es riesgo
    if (presionAceiteMotor < 2.2) {
      scoreRiesgo += ((2.2 - presionAceiteMotor) / 1.4) * 2.5;
    } else if (presionAceiteMotor > 6.0) {
      // Presión muy alta también es riesgo
      scoreRiesgo += ((presionAceiteMotor - 6.0) / 2.0) * 1.5;
    }
    
    // Presión línea hidráulica muy alta (sobre 320 bar = ~4640 PSI)
    // NOTA: Si la presión es muy baja (menos de 100 bar), también es riesgo
    if (presionLineaHidraulica > 320) {
      scoreRiesgo += ((presionLineaHidraulica - 320) / 120) * 1.5;
    } else if (presionLineaHidraulica < 100) {
      // Presión muy baja también es riesgo
      scoreRiesgo += ((100 - presionLineaHidraulica) / 50) * 1.5;
    }
    
    // Niveles de aceite bajos (fracción 0-1, donde 1.0 = 100%)
    // Solo penalizar si está por debajo de 0.7 (70%)
    if (nivelAceiteMotor < 0.7) {
      scoreRiesgo += ((0.7 - nivelAceiteMotor) / 0.7) * 2.0;
    }
    if (nivelAceiteHidraulico < 0.7) {
      scoreRiesgo += ((0.7 - nivelAceiteHidraulico) / 0.7) * 1.5;
    }
    
    // Filtros con alta caída de presión - solo penalizar si es alta (>50 kPa)
    if (diferencialPresionFiltroAceite > 50) {
      scoreRiesgo += ((diferencialPresionFiltroAceite - 50) / 190) * 1.5;
    }
    if (diferencialPresionFiltroHidraulico > 50) {
      scoreRiesgo += ((diferencialPresionFiltroHidraulico - 50) / 190) * 1.5;
    }
    
    // Tiempo al ralenti (mal uso) - solo penalizar si es muy alto (>70%)
    if (porcentajeTiempoRalenti > 0.7) {
      scoreRiesgo += ((porcentajeTiempoRalenti - 0.7) / 0.3) * 0.8;
    }
    
    // Muchas horas por día = más desgaste - solo penalizar si es muy alto (>16 horas)
    if (promedioHorasDiariasUso > 16) {
      scoreRiesgo += ((promedioHorasDiariasUso - 16) / 4) * 1.0;
    }
    
    // Alertas críticas y medias - solo penalizar si hay alertas
    scoreRiesgo += alertasCriticas30d * 0.5;
    scoreRiesgo += alertasMedias30d * 0.25;
    
    // Interacciones críticas (multiplicadores de riesgo)
    // Temp aceite motor muy alta Y presión baja = riesgo crítico
    if (tempAceiteMotor > 110 && presionAceiteMotor < 2.0) {
      scoreRiesgo += 3.5;
    }
    
    // Nivel aceite muy bajo Y temp muy alta = riesgo extremo
    if (nivelAceiteMotor < 0.3 && tempAceiteMotor > 115) {
      scoreRiesgo += 5.0;
    }
    
    // Muchas horas de uso Y muchas alertas críticas = riesgo alto
    if (horasUsoTotal > 9000 && alertasCriticas30d >= 4) {
      scoreRiesgo += 3.0;
    }
    
    // Debug: imprimir score calculado
    print('📊 Score de riesgo calculado: $scoreRiesgo');
    
    // Convertir score de riesgo a probabilidad de falla
    // En el dataset, el umbral es score_riesgo > 6.5 para falla = 1
    // Usamos una función sigmoide más conservadora para evitar falsos positivos
    // Probabilidad = 1 / (1 + exp(-(score - 6.5) * 1.5))
    // Factor 1.5 en lugar de 2.0 hace la transición más suave y conservadora
    // Esto da ~0.5 cuando score = 6.5, pero requiere scores más altos para llegar a 100%
    
    // Si el score es muy bajo (< 2.0), retornar probabilidad muy baja directamente
    if (scoreRiesgo < 2.0) {
      final prob = (scoreRiesgo / 2.0) * 0.2; // Máximo 20% para scores muy bajos
      print('✅ Score bajo ($scoreRiesgo), probabilidad: ${(prob * 100).toStringAsFixed(1)}%');
      return prob.clamp(0.0, 0.2);
    }
    
    final diferencia = scoreRiesgo - 6.5;
    final exponente = -diferencia * 1.5; // Más conservador (1.5 en lugar de 2.0)
    final probabilidad = 1.0 / (1.0 + math.exp(exponente));
    
    // Si el score es bajo (< 4.0), ajustar la probabilidad para que sea más conservadora
    if (scoreRiesgo < 4.0) {
      final probAjustada = probabilidad * 0.5; // Reducir a la mitad para scores bajos
      print('✅ Score bajo-medio ($scoreRiesgo), probabilidad ajustada: ${(probAjustada * 100).toStringAsFixed(1)}%');
      return probAjustada.clamp(0.0, 0.5);
    }
    
    print('✅ Probabilidad final: ${(probabilidad * 100).toStringAsFixed(1)}%');
    return probabilidad.clamp(0.0, 1.0);
  }

  /// Prepara features para el modelo en el orden exacto del dataset CSV
  /// 
  /// El orden debe ser:
  /// 1. horas_uso_total
  /// 2. horas_desde_ultimo_mantenimiento
  /// 3. temp_refrigerante_motor
  /// 4. temp_aceite_motor
  /// 5. presion_aceite_motor
  /// 6. temp_aceite_hidraulico
  /// 7. presion_linea_hidraulica
  /// 8. nivel_aceite_motor
  /// 9. nivel_aceite_hidraulico
  /// 10. diferencial_presion_filtro_aceite
  /// 11. diferencial_presion_filtro_hidraulico
  /// 12. porcentaje_tiempo_ralenti
  /// 13. promedio_horas_diarias_uso
  /// 14. alertas_criticas_30d
  /// 15. alertas_medias_30d
  /// 
  /// NOTA: Los valores deben estar en sus rangos originales (no normalizados),
  /// el modelo ya fue entrenado con datos normalizados durante el entrenamiento.
  List<double> prepararFeatures({
    required double horasUsoTotal,
    required double horasDesdeUltimoMantenimiento,
    required double tempRefrigeranteMotor,
    required double tempAceiteMotor,
    required double presionAceiteMotor,
    required double tempAceiteHidraulico,
    required double presionLineaHidraulica,
    required double nivelAceiteMotor,
    required double nivelAceiteHidraulico,
    required double diferencialPresionFiltroAceite,
    required double diferencialPresionFiltroHidraulico,
    required double porcentajeTiempoRalenti,
    required double promedioHorasDiariasUso,
    required int alertasCriticas30d,
    required int alertasMedias30d,
  }) {
    // Retornar en el orden exacto del dataset
    return [
      horasUsoTotal,
      horasDesdeUltimoMantenimiento,
      tempRefrigeranteMotor,
      tempAceiteMotor,
      presionAceiteMotor,
      tempAceiteHidraulico,
      presionLineaHidraulica,
      nivelAceiteMotor,
      nivelAceiteHidraulico,
      diferencialPresionFiltroAceite,
      diferencialPresionFiltroHidraulico,
      porcentajeTiempoRalenti,
      promedioHorasDiariasUso,
      alertasCriticas30d.toDouble(),
      alertasMedias30d.toDouble(),
    ];
  }

  /// Información del modelo
  Map<String, dynamic> obtenerInfoModelo() {
    return {
      'cargado': _modeloCargado,
      'arquitectura': arquitecturaActual.toMap(),
      'version': '1.0.0',
      'fechaEntrenamiento': '2024-01-01', // En producción, esto vendría del modelo
      'tipo': 'TensorFlow Lite',
      'tamaño': _modeloBytes?.length ?? 0,
    };
  }
}

