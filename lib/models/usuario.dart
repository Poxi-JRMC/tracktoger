/// Modelo de Usuario para el sistema Tracktoger
/// Representa un usuario del sistema con sus datos básicos, roles y seguridad

class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String? avatar;
  final DateTime fechaRegistro;
  final bool activo;
  final List<String> roles; // IDs o nombres de roles
  final String? codigoVerificacion; // Código de verificación enviado por correo
  final String? password; // Contraseña (hashed con bcrypt)

  Usuario({
    required this.id,
    required this.nombre,
    this.apellido = '',
    required this.email,
    required this.telefono,
    this.avatar,
    required this.fechaRegistro,
    this.activo = true,
    this.roles = const [],
    this.codigoVerificacion,
    this.password,
  });

  /// Convierte el objeto a Map para guardarlo en MongoDB
  Map<String, dynamic> toMap() {
    return {
      '_id': id, // Mongo usa `_id` como clave primaria
      'id': id, // También guardamos 'id' para facilitar consultas desde Dart
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'avatar': avatar,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'activo': activo,
      'roles': roles,
      'codigoVerificacion': codigoVerificacion,
      'password': password,
    };
  }

  /// Crea un objeto Usuario desde un Map de MongoDB
  factory Usuario.fromMap(Map<String, dynamic> map) {
    String resolvedId = '';

    // Resolver el ID correctamente (ya sea _id o id)
    if (map.containsKey('_id')) {
      final idField = map['_id'];
      try {
        if (idField is String) {
          resolvedId = idField;
        } else {
          // Intentar extraer el ObjectId de Mongo
          resolvedId = idField?.toHexString() ?? idField.toString();
        }
      } catch (_) {
        resolvedId = idField?.toString() ?? '';
      }
    }

    // Si no tiene _id, usamos 'id'
    if (resolvedId.isEmpty) {
      resolvedId = map['id'] ?? '';
    }

    // ✅ Manejo seguro de fechaRegistro (acepta DateTime, String o null)
    DateTime fecha;
    final rawFecha = map['fechaRegistro'];
    if (rawFecha is DateTime) {
      fecha = rawFecha;
    } else if (rawFecha is String && rawFecha.isNotEmpty) {
      fecha = DateTime.tryParse(rawFecha) ?? DateTime.now();
    } else {
      fecha = DateTime.now();
    }

    return Usuario(
      id: resolvedId,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      avatar: map['avatar'],
      fechaRegistro: fecha,
      activo: map['activo'] ?? true,
      roles: List<String>.from(map['roles'] ?? []),
      codigoVerificacion: map['codigoVerificacion'],
      password: map['password'],
    );
  }

  /// Crea una copia del usuario con campos modificados
  Usuario copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? avatar,
    DateTime? fechaRegistro,
    bool? activo,
    List<String>? roles,
    String? codigoVerificacion,
    String? password,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      avatar: avatar ?? this.avatar,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
      roles: roles ?? this.roles,
      codigoVerificacion: codigoVerificacion ?? this.codigoVerificacion,
      password: password ?? this.password,
    );
  }

  @override
  String toString() {
    return 'Usuario(id: $id, nombre: $nombre $apellido, email: $email, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
