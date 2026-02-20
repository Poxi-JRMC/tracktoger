/// Modelo de Análisis para el sistema Tracktoger
/// Representa un análisis de mantenimiento predictivo
class Analisis {
  final String id;
  final String maquinariaId; // ID de la maquinaria analizada
  final String tipoAnalisis; // vibracion, temperatura, presion, etc.
  final DateTime fechaAnalisis;
  final Map<String, dynamic> datosAnalisis; // Datos específicos del análisis
  final String resultado; // normal, advertencia, critico
  final double? valorMedido;
  final double? valorLimite;
  final String? observaciones;
  final String? recomendaciones;
  final String? tecnicoResponsable; // ID del técnico
  final List<String> archivos; // URLs de archivos adjuntos
  final DateTime fechaRegistro;

  Analisis({
    required this.id,
    required this.maquinariaId,
    required this.tipoAnalisis,
    required this.fechaAnalisis,
    this.datosAnalisis = const {},
    this.resultado = 'normal',
    this.valorMedido,
    this.valorLimite,
    this.observaciones,
    this.recomendaciones,
    this.tecnicoResponsable,
    this.archivos = const [],
    required this.fechaRegistro,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maquinariaId': maquinariaId,
      'tipoAnalisis': tipoAnalisis,
      'fechaAnalisis': fechaAnalisis.toIso8601String(),
      'datosAnalisis': datosAnalisis,
      'resultado': resultado,
      'valorMedido': valorMedido,
      'valorLimite': valorLimite,
      'observaciones': observaciones,
      'recomendaciones': recomendaciones,
      'tecnicoResponsable': tecnicoResponsable,
      'archivos': archivos,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  /// Crea un objeto Analisis desde un Map
  factory Analisis.fromMap(Map<String, dynamic> map) {
    // Manejar _id de MongoDB
    String id = map['id'] ?? '';
    if (id.isEmpty && map.containsKey('_id')) {
      id = map['_id'].toString();
    }
    
    return Analisis(
      id: id,
      maquinariaId: map['maquinariaId'] ?? '',
      tipoAnalisis: map['tipoAnalisis'] ?? '',
      fechaAnalisis: map['fechaAnalisis'] is String 
          ? DateTime.parse(map['fechaAnalisis'])
          : (map['fechaAnalisis'] as DateTime? ?? DateTime.now()),
      datosAnalisis: Map<String, dynamic>.from(map['datosAnalisis'] ?? {}),
      resultado: map['resultado'] ?? 'normal',
      valorMedido: map['valorMedido']?.toDouble(),
      valorLimite: map['valorLimite']?.toDouble(),
      observaciones: map['observaciones'],
      recomendaciones: map['recomendaciones'],
      tecnicoResponsable: map['tecnicoResponsable'],
      archivos: List<String>.from(map['archivos'] ?? []),
      fechaRegistro: map['fechaRegistro'] is String
          ? DateTime.parse(map['fechaRegistro'])
          : (map['fechaRegistro'] as DateTime? ?? DateTime.now()),
    );
  }

  /// Crea una copia del análisis con campos modificados
  Analisis copyWith({
    String? id,
    String? maquinariaId,
    String? tipoAnalisis,
    DateTime? fechaAnalisis,
    Map<String, dynamic>? datosAnalisis,
    String? resultado,
    double? valorMedido,
    double? valorLimite,
    String? observaciones,
    String? recomendaciones,
    String? tecnicoResponsable,
    List<String>? archivos,
    DateTime? fechaRegistro,
  }) {
    return Analisis(
      id: id ?? this.id,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      tipoAnalisis: tipoAnalisis ?? this.tipoAnalisis,
      fechaAnalisis: fechaAnalisis ?? this.fechaAnalisis,
      datosAnalisis: datosAnalisis ?? this.datosAnalisis,
      resultado: resultado ?? this.resultado,
      valorMedido: valorMedido ?? this.valorMedido,
      valorLimite: valorLimite ?? this.valorLimite,
      observaciones: observaciones ?? this.observaciones,
      recomendaciones: recomendaciones ?? this.recomendaciones,
      tecnicoResponsable: tecnicoResponsable ?? this.tecnicoResponsable,
      archivos: archivos ?? this.archivos,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  String toString() {
    return 'Analisis(id: $id, maquinariaId: $maquinariaId, resultado: $resultado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Analisis && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
