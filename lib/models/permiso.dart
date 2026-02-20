/// Modelo de Permiso para el sistema Tracktoger
/// Define los permisos específicos que pueden tener los roles
class Permiso {
  final String id;
  final String nombre;
  final String descripcion;
  final String modulo; // Módulo al que pertenece el permiso
  final String accion; // Acción específica (crear, leer, actualizar, eliminar)
  final bool activo;

  Permiso({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.modulo,
    required this.accion,
    this.activo = true,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'modulo': modulo,
      'accion': accion,
      'activo': activo,
    };
  }

  /// Crea un objeto Permiso desde un Map
  factory Permiso.fromMap(Map<String, dynamic> map) {
    return Permiso(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      modulo: map['modulo'] ?? '',
      accion: map['accion'] ?? '',
      activo: map['activo'] ?? true,
    );
  }

  /// Crea una copia del permiso con campos modificados
  Permiso copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? modulo,
    String? accion,
    bool? activo,
  }) {
    return Permiso(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      modulo: modulo ?? this.modulo,
      accion: accion ?? this.accion,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'Permiso(id: $id, nombre: $nombre, modulo: $modulo, accion: $accion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Permiso && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
