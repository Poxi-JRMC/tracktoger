import 'package:mongo_dart/mongo_dart.dart';

/// Modelo de Cliente para el sistema Tracktoger
/// Representa un cliente que puede alquilar maquinaria
class Cliente {
  final String id;
  final String nombre;
  final String apellido;
  final String? empresa;
  final String email;
  final String telefono;
  final String? direccion;
  final String? documentoIdentidad; // DNI, RUC, etc.
  final DateTime fechaRegistro;
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.empresa,
    required this.email,
    required this.telefono,
    this.direccion,
    this.documentoIdentidad,
    required this.fechaRegistro,
    this.activo = true,
  });

  /// Convierte el objeto a Map para almacenamiento en MongoDB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'empresa': empresa,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'documentoIdentidad': documentoIdentidad,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'activo': activo,
    };
  }

  /// Crea un objeto Cliente desde un Map de MongoDB
  factory Cliente.fromMap(Map<String, dynamic> map) {
    // Manejar ID que puede venir como _id (ObjectId) o id (String)
    String id = '';
    if (map['_id'] != null) {
      final objectId = map['_id'];
      if (objectId is ObjectId) {
        id = objectId.toHexString();
      } else {
        String idStr = objectId.toString();
        if (idStr.startsWith('ObjectId(') && idStr.endsWith(')')) {
          id = idStr.substring(9, idStr.length - 2).replaceAll('"', '').replaceAll("'", '');
        } else {
          id = idStr;
        }
      }
    } else if (map['id'] != null) {
      id = map['id'].toString();
    }

    return Cliente(
      id: id,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      empresa: map['empresa'],
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'],
      documentoIdentidad: map['documentoIdentidad'],
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
      activo: map['activo'] ?? true,
    );
  }

  /// Crea una copia del cliente con campos modificados
  Cliente copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? empresa,
    String? email,
    String? telefono,
    String? direccion,
    String? documentoIdentidad,
    DateTime? fechaRegistro,
    bool? activo,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      empresa: empresa ?? this.empresa,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      documentoIdentidad: documentoIdentidad ?? this.documentoIdentidad,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
    );
  }

  String get nombreCompleto => '$nombre $apellido';

  @override
  String toString() {
    return 'Cliente(id: $id, nombre: $nombreCompleto, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
