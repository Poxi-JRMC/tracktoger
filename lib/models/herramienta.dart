/// Modelo de Herramienta para el sistema Tracktoger
/// Representa una herramienta en el inventario
class Herramienta {
  final String id;
  final String nombre;
  final String tipo;
  final String? marca;
  final String? numeroSerie;
  final String? descripcion;
  final String condicion; // nueva, buena, regular, desgastada, dañada
  final String maquinariaId; // ID de la maquinaria a la que pertenece
  final List<String> imagenes; // URLs o base64 de las imágenes
  final DateTime fechaRegistro;
  final bool activo;

  Herramienta({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.marca,
    this.numeroSerie,
    this.descripcion,
    this.condicion = 'buena',
    required this.maquinariaId,
    this.imagenes = const [],
    required this.fechaRegistro,
    this.activo = true,
  });

  /// Convierte el objeto a Map para almacenamiento en MongoDB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'marca': marca,
      'numeroSerie': numeroSerie,
      'descripcion': descripcion,
      'condicion': condicion,
      'maquinariaId': maquinariaId,
      'imagenes': imagenes,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'activo': activo,
    };
  }

  /// Crea un objeto Herramienta desde un Map de MongoDB
  factory Herramienta.fromMap(Map<String, dynamic> map) {
    return Herramienta(
      id: map['id'] ?? map['_id']?.toString() ?? '',
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? '',
      marca: map['marca'],
      numeroSerie: map['numeroSerie'],
      descripcion: map['descripcion'],
      condicion: map['condicion'] ?? 'buena',
      maquinariaId: map['maquinariaId'] ?? '',
      imagenes: List<String>.from(map['imagenes'] ?? []),
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
      activo: map['activo'] ?? true,
    );
  }

  /// Crea una copia de la herramienta con campos modificados
  Herramienta copyWith({
    String? id,
    String? nombre,
    String? tipo,
    String? marca,
    String? numeroSerie,
    String? descripcion,
    String? condicion,
    String? maquinariaId,
    List<String>? imagenes,
    DateTime? fechaRegistro,
    bool? activo,
  }) {
    return Herramienta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      marca: marca ?? this.marca,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      descripcion: descripcion ?? this.descripcion,
      condicion: condicion ?? this.condicion,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      imagenes: imagenes ?? this.imagenes,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'Herramienta(id: $id, nombre: $nombre, tipo: $tipo, condicion: $condicion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Herramienta && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

