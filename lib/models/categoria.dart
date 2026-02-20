/// Modelo de Categoría para el sistema Tracktoger
/// Define las categorías de maquinaria en el inventario
class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final String? icono;
  final String? color;
  final List<String> especificacionesRequeridas; // Campos obligatorios
  final Map<String, dynamic>
  configuracion; // Configuración específica de la categoría
  final bool activo;
  final DateTime fechaCreacion;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.icono,
    this.color,
    this.especificacionesRequeridas = const [],
    this.configuracion = const {},
    this.activo = true,
    required this.fechaCreacion,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'color': color,
      'especificacionesRequeridas': especificacionesRequeridas,
      'configuracion': configuracion,
      'activo': activo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea un objeto Categoria desde un Map
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      icono: map['icono'],
      color: map['color'],
      especificacionesRequeridas: List<String>.from(
        map['especificacionesRequeridas'] ?? [],
      ),
      configuracion: Map<String, dynamic>.from(map['configuracion'] ?? {}),
      activo: map['activo'] ?? true,
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }

  /// Crea una copia de la categoría con campos modificados
  Categoria copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? icono,
    String? color,
    List<String>? especificacionesRequeridas,
    Map<String, dynamic>? configuracion,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      especificacionesRequeridas:
          especificacionesRequeridas ?? this.especificacionesRequeridas,
      configuracion: configuracion ?? this.configuracion,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'Categoria(id: $id, nombre: $nombre, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
