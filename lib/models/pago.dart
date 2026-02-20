/// Modelo de Pago para el sistema Tracktoger
/// Representa un pago realizado por un contrato
class Pago {
  final String id;
  final String contratoId; // ID del contrato
  final double monto;
  final DateTime fechaPago;
  final String metodoPago; // efectivo, transferencia, tarjeta, cheque
  final String estado; // pendiente, confirmado, rechazado, cancelado
  final String? numeroTransaccion;
  final String? banco;
  final String? observaciones;
  final String? comprobante; // URL del comprobante
  final DateTime fechaRegistro;
  final String? usuarioRegistro; // ID del usuario que registró el pago

  Pago({
    required this.id,
    required this.contratoId,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    this.estado = 'pendiente',
    this.numeroTransaccion,
    this.banco,
    this.observaciones,
    this.comprobante,
    required this.fechaRegistro,
    this.usuarioRegistro,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contratoId': contratoId,
      'monto': monto,
      'fechaPago': fechaPago.toIso8601String(),
      'metodoPago': metodoPago,
      'estado': estado,
      'numeroTransaccion': numeroTransaccion,
      'banco': banco,
      'observaciones': observaciones,
      'comprobante': comprobante,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'usuarioRegistro': usuarioRegistro,
    };
  }

  /// Crea un objeto Pago desde un Map
  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'] ?? '',
      contratoId: map['contratoId'] ?? '',
      monto: (map['monto'] ?? 0.0).toDouble(),
      fechaPago: DateTime.parse(map['fechaPago']),
      metodoPago: map['metodoPago'] ?? '',
      estado: map['estado'] ?? 'pendiente',
      numeroTransaccion: map['numeroTransaccion'],
      banco: map['banco'],
      observaciones: map['observaciones'],
      comprobante: map['comprobante'],
      fechaRegistro: DateTime.parse(map['fechaRegistro']),
      usuarioRegistro: map['usuarioRegistro'],
    );
  }

  /// Crea una copia del pago con campos modificados
  Pago copyWith({
    String? id,
    String? contratoId,
    double? monto,
    DateTime? fechaPago,
    String? metodoPago,
    String? estado,
    String? numeroTransaccion,
    String? banco,
    String? observaciones,
    String? comprobante,
    DateTime? fechaRegistro,
    String? usuarioRegistro,
  }) {
    return Pago(
      id: id ?? this.id,
      contratoId: contratoId ?? this.contratoId,
      monto: monto ?? this.monto,
      fechaPago: fechaPago ?? this.fechaPago,
      metodoPago: metodoPago ?? this.metodoPago,
      estado: estado ?? this.estado,
      numeroTransaccion: numeroTransaccion ?? this.numeroTransaccion,
      banco: banco ?? this.banco,
      observaciones: observaciones ?? this.observaciones,
      comprobante: comprobante ?? this.comprobante,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      usuarioRegistro: usuarioRegistro ?? this.usuarioRegistro,
    );
  }

  @override
  String toString() {
    return 'Pago(id: $id, contratoId: $contratoId, monto: $monto, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pago && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
