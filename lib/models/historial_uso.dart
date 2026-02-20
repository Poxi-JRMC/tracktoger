/// Modelo de Historial de Uso para el sistema Tracktoger
/// Registra el uso de maquinaria por parte de clientes
class HistorialUso {
  final String id;
  final String maquinariaId; // ID de la maquinaria
  final String contratoId; // ID del contrato asociado
  final String clienteId; // ID del cliente
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int horasUso;
  final String estado; // activo, finalizado, cancelado
  final String? observaciones;
  final Map<String, dynamic> datosUso; // Datos específicos del uso
  final DateTime fechaRegistro;

  HistorialUso({
    required this.id,
    required this.maquinariaId,
    required this.contratoId,
    required this.clienteId,
    required this.fechaInicio,
    this.fechaFin,
    this.horasUso = 0,
    this.estado = 'activo',
    this.observaciones,
    this.datosUso = const {},
    required this.fechaRegistro,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maquinariaId': maquinariaId,
      'contratoId': contratoId,
      'clienteId': clienteId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'horasUso': horasUso,
      'estado': estado,
      'observaciones': observaciones,
      'datosUso': datosUso,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  /// Crea un objeto HistorialUso desde un Map
  factory HistorialUso.fromMap(Map<String, dynamic> map) {
    return HistorialUso(
      id: map['id'] ?? '',
      maquinariaId: map['maquinariaId'] ?? '',
      contratoId: map['contratoId'] ?? '',
      clienteId: map['clienteId'] ?? '',
      fechaInicio: DateTime.parse(map['fechaInicio']),
      fechaFin: map['fechaFin'] != null
          ? DateTime.parse(map['fechaFin'])
          : null,
      horasUso: map['horasUso'] ?? 0,
      estado: map['estado'] ?? 'activo',
      observaciones: map['observaciones'],
      datosUso: Map<String, dynamic>.from(map['datosUso'] ?? {}),
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
    );
  }

  /// Crea una copia del historial con campos modificados
  HistorialUso copyWith({
    String? id,
    String? maquinariaId,
    String? contratoId,
    String? clienteId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? horasUso,
    String? estado,
    String? observaciones,
    Map<String, dynamic>? datosUso,
    DateTime? fechaRegistro,
  }) {
    return HistorialUso(
      id: id ?? this.id,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      contratoId: contratoId ?? this.contratoId,
      clienteId: clienteId ?? this.clienteId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      horasUso: horasUso ?? this.horasUso,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      datosUso: datosUso ?? this.datosUso,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  String toString() {
    return 'HistorialUso(id: $id, maquinariaId: $maquinariaId, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistorialUso && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
