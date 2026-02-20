/// Modelo de Rol para el sistema Tracktoger
/// Define los roles que pueden tener los usuarios del sistema
class Rol {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> permisos; // IDs de permisos
  final bool activo;
  final DateTime fechaCreacion;

  Rol({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.permisos = const [],
    this.activo = true,
    required this.fechaCreacion,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'permisos': permisos,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea un objeto Rol desde un Map
  factory Rol.fromMap(Map<String, dynamic> map) {
    // Resolver el ID correctamente (puede venir como _id desde MongoDB)
    String resolvedId = '';

    if (map.containsKey('_id')) {
      final idField = map['_id'];
      try {
        if (idField is String) {
          resolvedId = idField;
        } else {
          // ObjectId de Mongo
          resolvedId = idField?.toHexString() ?? idField.toString();
        }
      } catch (e) {
        resolvedId = idField?.toString() ?? '';
      }
    }

    // Si no tiene _id, intentar con 'id'
    if (resolvedId.isEmpty) {
      resolvedId = map['id'] ?? '';
    }

    return Rol(
      id: resolvedId,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      permisos: List<String>.from(map['permisos'] ?? []),
      activo: map['activo'] ?? true,
      fechaCreacion: () {
        final fc = map['fechaCreacion'];
        if (fc == null) return DateTime.now();
        if (fc is DateTime) return fc;
        try {
          return DateTime.parse(fc.toString());
        } catch (_) {
          return DateTime.now();
        }
      }(),
    );
  }

  /// Crea una copia del rol con campos modificados
  Rol copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    List<String>? permisos,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Rol(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      permisos: permisos ?? this.permisos,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'Rol(id: $id, nombre: $nombre, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rol && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
