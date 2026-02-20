/// Modelo de Contrato para el sistema Tracktoger
/// Representa un contrato de alquiler de maquinaria
class Contrato {
  final String id;
  final String numeroContrato;
  final String clienteId; // ID del cliente
  final List<String> maquinariaIds; // IDs de maquinaria alquilada
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double valorTotal;
  final String tipoPago; // diario, semanal, mensual
  final double valorPorPeriodo;
  final String estado; // activo, finalizado, cancelado, suspendido
  final String? observaciones;
  final Map<String, dynamic> terminos; // Términos y condiciones específicas
  final DateTime fechaCreacion;
  final String? usuarioCreacion; // ID del usuario que creó el contrato
  final List<String> documentos; // URLs de documentos adjuntos

  Contrato({
    required this.id,
    required this.numeroContrato,
    required this.clienteId,
    required this.maquinariaIds,
    required this.fechaInicio,
    required this.fechaFin,
    required this.valorTotal,
    required this.tipoPago,
    required this.valorPorPeriodo,
    this.estado = 'activo',
    this.observaciones,
    this.terminos = const {},
    required this.fechaCreacion,
    this.usuarioCreacion,
    this.documentos = const [],
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroContrato': numeroContrato,
      'clienteId': clienteId,
      'maquinariaIds': maquinariaIds,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'valorTotal': valorTotal,
      'tipoPago': tipoPago,
      'valorPorPeriodo': valorPorPeriodo,
      'estado': estado,
      'observaciones': observaciones,
      'terminos': terminos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'usuarioCreacion': usuarioCreacion,
      'documentos': documentos,
    };
  }

  /// Crea un objeto Contrato desde un Map
  factory Contrato.fromMap(Map<String, dynamic> map) {
    return Contrato(
      id: map['id'] ?? '',
      numeroContrato: map['numeroContrato'] ?? '',
      clienteId: map['clienteId'] ?? '',
      maquinariaIds: List<String>.from(map['maquinariaIds'] ?? []),
      fechaInicio: DateTime.parse(map['fechaInicio']),
      fechaFin: DateTime.parse(map['fechaFin']),
      valorTotal: (map['valorTotal'] ?? 0.0).toDouble(),
      tipoPago: map['tipoPago'] ?? '',
      valorPorPeriodo: (map['valorPorPeriodo'] ?? 0.0).toDouble(),
      estado: map['estado'] ?? 'activo',
      observaciones: map['observaciones'],
      terminos: Map<String, dynamic>.from(map['terminos'] ?? {}),
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      usuarioCreacion: map['usuarioCreacion'],
      documentos: List<String>.from(map['documentos'] ?? []),
    );
  }

  /// Crea una copia del contrato con campos modificados
  Contrato copyWith({
    String? id,
    String? numeroContrato,
    String? clienteId,
    List<String>? maquinariaIds,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? valorTotal,
    String? tipoPago,
    double? valorPorPeriodo,
    String? estado,
    String? observaciones,
    Map<String, dynamic>? terminos,
    DateTime? fechaCreacion,
    String? usuarioCreacion,
    List<String>? documentos,
  }) {
    return Contrato(
      id: id ?? this.id,
      numeroContrato: numeroContrato ?? this.numeroContrato,
      clienteId: clienteId ?? this.clienteId,
      maquinariaIds: maquinariaIds ?? this.maquinariaIds,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      valorTotal: valorTotal ?? this.valorTotal,
      tipoPago: tipoPago ?? this.tipoPago,
      valorPorPeriodo: valorPorPeriodo ?? this.valorPorPeriodo,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      terminos: terminos ?? this.terminos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      usuarioCreacion: usuarioCreacion ?? this.usuarioCreacion,
      documentos: documentos ?? this.documentos,
    );
  }

  @override
  String toString() {
    return 'Contrato(id: $id, numeroContrato: $numeroContrato, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contrato && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
