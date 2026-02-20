/// Modelo de Devolución para el sistema Tracktoger
/// Representa la devolución de maquinaria por parte de un cliente
class Devolucion {
  final String id;
  final String contratoId; // ID del contrato
  final String maquinariaId; // ID de la maquinaria
  final String clienteId; // ID del cliente
  final DateTime fechaDevolucion;
  final String? ubicacionDevolucion;
  final String? responsableDevolucion; // ID del usuario responsable
  final String? responsableEntrega; // Nombre del responsable del cliente
  final String estado; // devuelto, pendiente, cancelado
  final String? observaciones;
  final Map<String, dynamic> condicionesDevolucion; // Condiciones específicas
  final List<String> documentos; // URLs de documentos de devolución
  final DateTime fechaRegistro;
  final String? inspeccionTecnica; // Resultado de la inspección técnica

  Devolucion({
    required this.id,
    required this.contratoId,
    required this.maquinariaId,
    required this.clienteId,
    required this.fechaDevolucion,
    this.ubicacionDevolucion,
    this.responsableDevolucion,
    this.responsableEntrega,
    this.estado = 'pendiente',
    this.observaciones,
    this.condicionesDevolucion = const {},
    this.documentos = const [],
    required this.fechaRegistro,
    this.inspeccionTecnica,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contratoId': contratoId,
      'maquinariaId': maquinariaId,
      'clienteId': clienteId,
      'fechaDevolucion': fechaDevolucion.toIso8601String(),
      'ubicacionDevolucion': ubicacionDevolucion,
      'responsableDevolucion': responsableDevolucion,
      'responsableEntrega': responsableEntrega,
      'estado': estado,
      'observaciones': observaciones,
      'condicionesDevolucion': condicionesDevolucion,
      'documentos': documentos,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'inspeccionTecnica': inspeccionTecnica,
    };
  }

  /// Crea un objeto Devolucion desde un Map
  factory Devolucion.fromMap(Map<String, dynamic> map) {
    return Devolucion(
      id: map['id'] ?? '',
      contratoId: map['contratoId'] ?? '',
      maquinariaId: map['maquinariaId'] ?? '',
      clienteId: map['clienteId'] ?? '',
      fechaDevolucion: DateTime.parse(map['fechaDevolucion']),
      ubicacionDevolucion: map['ubicacionDevolucion'],
      responsableDevolucion: map['responsableDevolucion'],
      responsableEntrega: map['responsableEntrega'],
      estado: map['estado'] ?? 'pendiente',
      observaciones: map['observaciones'],
      condicionesDevolucion: Map<String, dynamic>.from(
        map['condicionesDevolucion'] ?? {},
      ),
      documentos: List<String>.from(map['documentos'] ?? []),
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
      inspeccionTecnica: map['inspeccionTecnica'],
    );
  }

  /// Crea una copia de la devolución con campos modificados
  Devolucion copyWith({
    String? id,
    String? contratoId,
    String? maquinariaId,
    String? clienteId,
    DateTime? fechaDevolucion,
    String? ubicacionDevolucion,
    String? responsableDevolucion,
    String? responsableEntrega,
    String? estado,
    String? observaciones,
    Map<String, dynamic>? condicionesDevolucion,
    List<String>? documentos,
    DateTime? fechaRegistro,
    String? inspeccionTecnica,
  }) {
    return Devolucion(
      id: id ?? this.id,
      contratoId: contratoId ?? this.contratoId,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      clienteId: clienteId ?? this.clienteId,
      fechaDevolucion: fechaDevolucion ?? this.fechaDevolucion,
      ubicacionDevolucion: ubicacionDevolucion ?? this.ubicacionDevolucion,
      responsableDevolucion:
          responsableDevolucion ?? this.responsableDevolucion,
      responsableEntrega: responsableEntrega ?? this.responsableEntrega,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      condicionesDevolucion:
          condicionesDevolucion ?? this.condicionesDevolucion,
      documentos: documentos ?? this.documentos,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      inspeccionTecnica: inspeccionTecnica ?? this.inspeccionTecnica,
    );
  }

  @override
  String toString() {
    return 'Devolucion(id: $id, contratoId: $contratoId, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Devolucion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
