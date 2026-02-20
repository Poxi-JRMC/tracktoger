/// Modelo de Entrega para el sistema Tracktoger
/// Representa la entrega de maquinaria a un cliente
class Entrega {
  final String id;
  final String contratoId; // ID del contrato
  final String maquinariaId; // ID de la maquinaria
  final String clienteId; // ID del cliente
  final DateTime fechaEntrega;
  final String? ubicacionEntrega;
  final String? responsableEntrega; // ID del usuario responsable
  final String? responsableRecepcion; // Nombre del responsable del cliente
  final String estado; // entregado, pendiente, cancelado
  final String? observaciones;
  final Map<String, dynamic> condicionesEntrega; // Condiciones específicas
  final List<String> documentos; // URLs de documentos de entrega
  final DateTime fechaRegistro;

  Entrega({
    required this.id,
    required this.contratoId,
    required this.maquinariaId,
    required this.clienteId,
    required this.fechaEntrega,
    this.ubicacionEntrega,
    this.responsableEntrega,
    this.responsableRecepcion,
    this.estado = 'pendiente',
    this.observaciones,
    this.condicionesEntrega = const {},
    this.documentos = const [],
    required this.fechaRegistro,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contratoId': contratoId,
      'maquinariaId': maquinariaId,
      'clienteId': clienteId,
      'fechaEntrega': fechaEntrega.toIso8601String(),
      'ubicacionEntrega': ubicacionEntrega,
      'responsableEntrega': responsableEntrega,
      'responsableRecepcion': responsableRecepcion,
      'estado': estado,
      'observaciones': observaciones,
      'condicionesEntrega': condicionesEntrega,
      'documentos': documentos,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  /// Crea un objeto Entrega desde un Map
  factory Entrega.fromMap(Map<String, dynamic> map) {
    return Entrega(
      id: map['id'] ?? '',
      contratoId: map['contratoId'] ?? '',
      maquinariaId: map['maquinariaId'] ?? '',
      clienteId: map['clienteId'] ?? '',
      fechaEntrega: DateTime.parse(map['fechaEntrega']),
      ubicacionEntrega: map['ubicacionEntrega'],
      responsableEntrega: map['responsableEntrega'],
      responsableRecepcion: map['responsableRecepcion'],
      estado: map['estado'] ?? 'pendiente',
      observaciones: map['observaciones'],
      condicionesEntrega: Map<String, dynamic>.from(
        map['condicionesEntrega'] ?? {},
      ),
      documentos: List<String>.from(map['documentos'] ?? []),
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
    );
  }

  /// Crea una copia de la entrega con campos modificados
  Entrega copyWith({
    String? id,
    String? contratoId,
    String? maquinariaId,
    String? clienteId,
    DateTime? fechaEntrega,
    String? ubicacionEntrega,
    String? responsableEntrega,
    String? responsableRecepcion,
    String? estado,
    String? observaciones,
    Map<String, dynamic>? condicionesEntrega,
    List<String>? documentos,
    DateTime? fechaRegistro,
  }) {
    return Entrega(
      id: id ?? this.id,
      contratoId: contratoId ?? this.contratoId,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      clienteId: clienteId ?? this.clienteId,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      ubicacionEntrega: ubicacionEntrega ?? this.ubicacionEntrega,
      responsableEntrega: responsableEntrega ?? this.responsableEntrega,
      responsableRecepcion: responsableRecepcion ?? this.responsableRecepcion,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      condicionesEntrega: condicionesEntrega ?? this.condicionesEntrega,
      documentos: documentos ?? this.documentos,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  String toString() {
    return 'Entrega(id: $id, contratoId: $contratoId, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entrega && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
