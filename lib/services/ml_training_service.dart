import 'dart:convert';
import '../models/maquinaria.dart';
import '../controllers/control_maquinaria.dart';
import '../controllers/control_mantenimiento.dart';
import '../controllers/control_alquiler.dart';

/// Configuración de entrenamiento
class TrainingConfig {
    final double trainSplit;      // 0.7 = 70% para entrenamiento
    final double validationSplit; // 0.15 = 15% para validación
    final double testSplit;       // 0.15 = 15% para prueba
    final int batchSize;
    final int epochs;
    final double learningRate;
    final bool useEarlyStopping;
    final bool useDropout;
    final double dropoutRate;

    TrainingConfig({
      this.trainSplit = 0.7,
      this.validationSplit = 0.15,
      this.testSplit = 0.15,
      this.batchSize = 32,
      this.epochs = 100,
      this.learningRate = 0.001,
      this.useEarlyStopping = true,
      this.useDropout = true,
      this.dropoutRate = 0.3,
    });

    Map<String, dynamic> toMap() {
      return {
        'trainSplit': trainSplit,
        'validationSplit': validationSplit,
        'testSplit': testSplit,
        'batchSize': batchSize,
        'epochs': epochs,
        'learningRate': learningRate,
        'useEarlyStopping': useEarlyStopping,
        'useDropout': useDropout,
        'dropoutRate': dropoutRate,
      };
    }
  }

/// Resultado del entrenamiento
class TrainingResult {
    final bool exito;
    final double finalAccuracy;
    final double finalLoss;
    final Map<String, double> metricas;
    final DateTime fechaEntrenamiento;
    final int duracionSegundos;
    final String? rutaModelo;

    TrainingResult({
      required this.exito,
      required this.finalAccuracy,
      required this.finalLoss,
      required this.metricas,
      required this.fechaEntrenamiento,
      required this.duracionSegundos,
      this.rutaModelo,
    });

    Map<String, dynamic> toMap() {
      return {
        'exito': exito,
        'finalAccuracy': finalAccuracy,
        'finalLoss': finalLoss,
        'metricas': metricas,
        'fechaEntrenamiento': fechaEntrenamiento.toIso8601String(),
        'duracionSegundos': duracionSegundos,
        'rutaModelo': rutaModelo,
      };
    }
}

/// Servicio para gestión del entrenamiento de modelos ML
/// 
/// Este servicio prepara datos para entrenamiento y gestiona el ciclo de vida
/// del modelo. En producción, el entrenamiento real se haría en Python/TensorFlow,
/// pero este servicio prepara los datos y gestiona la integración.
class MLTrainingService {
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  final ControlAlquiler _controlAlquiler = ControlAlquiler();

  /// Prepara datos para entrenamiento
  /// 
  /// Extrae y formatea datos históricos en el formato necesario para entrenar
  /// el modelo en Python/TensorFlow
  Future<Map<String, dynamic>> prepararDatosEntrenamiento() async {
    final inicio = DateTime.now();
    
    // Obtener todas las máquinas
    final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
    
    // Obtener datos históricos
    final ordenesTrabajo = await _controlMantenimiento.consultarTodasOrdenesTrabajo();
    final todosAlquileres = await _controlAlquiler.consultarTodosAlquileres(
      soloActivos: false,
    );

    final datosEntrenamiento = <Map<String, dynamic>>[];

    for (var maq in maquinarias) {
      // Obtener datos históricos de esta máquina
      final alquileresMaq = todosAlquileres.where((a) => a.maquinariaId == maq.id).toList();
      final ordenesMaq = ordenesTrabajo.where((o) => o.maquinariaId == maq.id).toList();

      // Calcular features
      final features = await _calcularFeatures(maq, alquileresMaq, ordenesMaq);

      // Determinar etiqueta (¿falló o no?)
      final etiqueta = _determinarEtiqueta(ordenesMaq, maq);

      datosEntrenamiento.add({
        'maquinariaId': maq.id,
        'features': features,
        'etiqueta': etiqueta,
        'fecha': DateTime.now().toIso8601String(),
      });
    }

    final duracion = DateTime.now().difference(inicio).inSeconds;

    return {
      'datos': datosEntrenamiento,
      'totalRegistros': datosEntrenamiento.length,
      'totalFeatures': datosEntrenamiento.isNotEmpty 
          ? datosEntrenamiento.first['features'].length 
          : 0,
      'fechaPreparacion': DateTime.now().toIso8601String(),
      'duracionSegundos': duracion,
    };
  }

  /// Calcula features para una máquina
  Future<List<double>> _calcularFeatures(
    Maquinaria maq,
    List<dynamic> alquileres,
    List<dynamic> ordenes,
  ) async {
    // Calcular métricas históricas
    final alquileresCompletados = alquileres.where((a) => 
      a.estado == 'devuelta' && a.horasUsoReal != null
    ).toList();

    final totalHorasHistoricas = alquileresCompletados.fold<int>(
      0, (sum, a) => sum + ((a.horasUsoReal ?? 0) as int)
    );

    final diasDesdePrimerAlquiler = alquileres.isNotEmpty
        ? DateTime.now().difference(alquileres.first.fechaRegistro).inDays
        : 0;

    final intensidadUso = diasDesdePrimerAlquiler > 0
        ? (totalHorasHistoricas / diasDesdePrimerAlquiler) * 30
        : 0.0;

    final analisis = await _controlMantenimiento.consultarAnalisisPorMaquinaria(maq.id);
    final analisisCriticos = analisis.where((a) => a.resultado == 'critico').length;
    final analisisAdvertencia = analisis.where((a) => a.resultado == 'advertencia').length;

    final ordenesCompletadas = ordenes.where((o) => o.estado == 'completada').length;
    final mantenimientosEsperados = ((maq.horasUso + totalHorasHistoricas) / 500.0).round();
    final deficitMantenimientos = mantenimientosEsperados - ordenesCompletadas;

    final diasDesdeUltimoMantenimiento = DateTime.now()
        .difference(maq.fechaUltimoMantenimiento).inDays;

    // Retornar features normalizadas (0-1)
    return [
      (maq.horasUso / 10000.0).clamp(0.0, 1.0),
      (diasDesdeUltimoMantenimiento / 365.0).clamp(0.0, 1.0),
      (analisisCriticos / 10.0).clamp(0.0, 1.0),
      (analisisAdvertencia / 20.0).clamp(0.0, 1.0),
      (intensidadUso / 300.0).clamp(0.0, 1.0),
      (deficitMantenimientos / 5.0).clamp(0.0, 1.0),
      (ordenesCompletadas / 50.0).clamp(0.0, 1.0),
      (totalHorasHistoricas / 20000.0).clamp(0.0, 1.0),
      (alquileres.length / 100.0).clamp(0.0, 1.0),
      (diasDesdePrimerAlquiler / 3650.0).clamp(0.0, 1.0), // 10 años máximo
    ];
  }

  /// Determina la etiqueta (1 = falló, 0 = no falló)
  int _determinarEtiqueta(List<dynamic> ordenes, Maquinaria maq) {
    // Si hay órdenes de reparación o la máquina está fuera de servicio,
    // consideramos que "falló"
    final tieneReparaciones = ordenes.any((o) => 
      o.tipoTrabajo.toLowerCase().contains('reparacion') ||
      o.tipoTrabajo.toLowerCase().contains('falla') ||
      o.estado == 'completada' && o.prioridad == 'critica'
    );

    if (tieneReparaciones || maq.estado == 'fuera_servicio') {
      return 1; // Falló
    }

    return 0; // No falló
  }

  /// Divide datos en conjuntos de entrenamiento, validación y prueba
  Map<String, List<Map<String, dynamic>>> dividirDatos(
    List<Map<String, dynamic>> datos,
    TrainingConfig config,
  ) {
    // Mezclar datos aleatoriamente
    final datosMezclados = List<Map<String, dynamic>>.from(datos)..shuffle();

    final total = datosMezclados.length;
    final trainCount = (total * config.trainSplit).round();
    final validationCount = (total * config.validationSplit).round();

    return {
      'train': datosMezclados.sublist(0, trainCount),
      'validation': datosMezclados.sublist(trainCount, trainCount + validationCount),
      'test': datosMezclados.sublist(trainCount + validationCount),
    };
  }

  /// Exporta datos a formato JSON para entrenamiento en Python
  Future<String> exportarDatosParaEntrenamiento() async {
    final datos = await prepararDatosEntrenamiento();
    return jsonEncode(datos);
  }

  /// Genera script Python para entrenamiento
  String generarScriptEntrenamiento() {
    return '''
# Script de entrenamiento para modelo de mantenimiento predictivo
# Generado automáticamente por MLTrainingService

import tensorflow as tf
from tensorflow import keras
import numpy as np
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt

# Cargar datos
with open('datos_entrenamiento.json', 'r') as f:
    data = json.load(f)

# Extraer features y etiquetas
X = np.array([d['features'] for d in data['datos']])
y = np.array([d['etiqueta'] for d in data['datos']])

# Normalizar features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Dividir datos (70% train, 15% validation, 15% test)
X_train, X_temp, y_train, y_temp = train_test_split(
    X_scaled, y, test_size=0.3, random_state=42
)
X_val, X_test, y_val, y_test = train_test_split(
    X_temp, y_temp, test_size=0.5, random_state=42
)

# Definir arquitectura del modelo
model = keras.Sequential([
    keras.layers.Dense(64, activation='relu', input_shape=(X_train.shape[1],)),
    keras.layers.Dropout(0.3),
    keras.layers.Dense(32, activation='relu'),
    keras.layers.Dropout(0.3),
    keras.layers.Dense(16, activation='relu'),
    keras.layers.Dense(1, activation='sigmoid')
])

# Compilar modelo
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.001),
    loss='binary_crossentropy',
    metrics=['accuracy', 'precision', 'recall']
)

# Callbacks
callbacks = [
    keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=10,
        restore_best_weights=True
    ),
    keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=0.0001
    )
]

# Entrenar modelo
history = model.fit(
    X_train, y_train,
    batch_size=32,
    epochs=100,
    validation_data=(X_val, y_val),
    callbacks=callbacks,
    verbose=1
)

# Evaluar en conjunto de prueba
test_loss, test_accuracy, test_precision, test_recall = model.evaluate(
    X_test, y_test, verbose=0
)

print(f'Test Accuracy: {test_accuracy:.4f}')
print(f'Test Precision: {test_precision:.4f}')
print(f'Test Recall: {test_recall:.4f}')

# Guardar modelo
model.save('modelo_mantenimiento_predictivo.h5')

# Convertir a TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('modelo_mantenimiento_predictivo.tflite', 'wb') as f:
    f.write(tflite_model)

print('Modelo entrenado y exportado a TensorFlow Lite')
''';
  }
}

