/// Modelo de Gasto Operativo para el sistema Tracktoger
/// Representa un gasto relacionado con el uso de maquinaria y operadores
class GastoOperativo {
  final String id;
  final String tipoGasto; // pasajes, comida, transporte, etc.
  final double monto;
  final DateTime fecha;
  final String? descripcion;
  final String maquinariaId; // ID de la maquinaria asociada
  final String operadorId; // ID del operador que incurrió el gasto
  final DateTime fechaRegistro;
  final bool activo;

  GastoOperativo({
    required this.id,
    required this.tipoGasto,
    required this.monto,
    required this.fecha,
    this.descripcion,
    required this.maquinariaId,
    required this.operadorId,
    required this.fechaRegistro,
    this.activo = true,
  });

  /// Convierte el objeto a Map para almacenamiento en MongoDB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoGasto': tipoGasto,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'maquinariaId': maquinariaId,
      'operadorId': operadorId,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'activo': activo,
    };
  }

  /// Crea un objeto GastoOperativo desde un Map de MongoDB
  factory GastoOperativo.fromMap(Map<String, dynamic> map) {
    // Manejar ID que puede venir como _id (ObjectId) o id (String)
    String id = '';
    if (map['_id'] != null) {
      id = map['_id'].toString();
    } else if (map['id'] != null) {
      id = map['id'].toString();
    }

    return GastoOperativo(
      id: id,
      tipoGasto: map['tipoGasto'] ?? '',
      monto: (map['monto'] ?? 0.0).toDouble(),
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'])
          : DateTime.now(),
      descripcion: map['descripcion'],
      maquinariaId: map['maquinariaId'] ?? '',
      operadorId: map['operadorId'] ?? '',
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
      activo: map['activo'] ?? true,
    );
  }

  /// Crea una copia del gasto con campos modificados
  GastoOperativo copyWith({
    String? id,
    String? tipoGasto,
    double? monto,
    DateTime? fecha,
    String? descripcion,
    String? maquinariaId,
    String? operadorId,
    DateTime? fechaRegistro,
    bool? activo,
  }) {
    return GastoOperativo(
      id: id ?? this.id,
      tipoGasto: tipoGasto ?? this.tipoGasto,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      operadorId: operadorId ?? this.operadorId,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'GastoOperativo(id: $id, tipo: $tipoGasto, monto: $monto, fecha: $fecha)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GastoOperativo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

