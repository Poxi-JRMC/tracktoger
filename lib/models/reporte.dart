/// Modelo de Reporte para el sistema Tracktoger
/// Representa un reporte generado por el sistema
class Reporte {
  final String id;
  final String nombre;
  final String tipo; // ventas, mantenimiento, inventario, financiero, etc.
  final String descripcion;
  final DateTime fechaGeneracion;
  final String? usuarioGeneracion; // ID del usuario que generó el reporte
  final Map<String, dynamic>
  parametros; // Parámetros utilizados para generar el reporte
  final String formato; // pdf, excel, csv, json
  final String? archivoUrl; // URL del archivo generado
  final String estado; // generando, completado, error
  final Map<String, dynamic> datos; // Datos del reporte
  final DateTime? fechaInicio; // Fecha de inicio del período del reporte
  final DateTime? fechaFin; // Fecha de fin del período del reporte
  final String? observaciones;

  Reporte({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.fechaGeneracion,
    this.usuarioGeneracion,
    this.parametros = const {},
    this.formato = 'pdf',
    this.archivoUrl,
    this.estado = 'generando',
    this.datos = const {},
    this.fechaInicio,
    this.fechaFin,
    this.observaciones,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
      'usuarioGeneracion': usuarioGeneracion,
      'parametros': parametros,
      'formato': formato,
      'archivoUrl': archivoUrl,
      'estado': estado,
      'datos': datos,
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  /// Crea un objeto Reporte desde un Map
  factory Reporte.fromMap(Map<String, dynamic> map) {
    return Reporte(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fechaGeneracion: DateTime.parse(map['fechaGeneracion']),
      usuarioGeneracion: map['usuarioGeneracion'],
      parametros: Map<String, dynamic>.from(map['parametros'] ?? {}),
      formato: map['formato'] ?? 'pdf',
      archivoUrl: map['archivoUrl'],
      estado: map['estado'] ?? 'generando',
      datos: Map<String, dynamic>.from(map['datos'] ?? {}),
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.parse(map['fechaInicio'])
          : null,
      fechaFin: map['fechaFin'] != null
          ? DateTime.parse(map['fechaFin'])
          : null,
      observaciones: map['observaciones'],
    );
  }

  /// Crea una copia del reporte con campos modificados
  Reporte copyWith({
    String? id,
    String? nombre,
    String? tipo,
    String? descripcion,
    DateTime? fechaGeneracion,
    String? usuarioGeneracion,
    Map<String, dynamic>? parametros,
    String? formato,
    String? archivoUrl,
    String? estado,
    Map<String, dynamic>? datos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? observaciones,
  }) {
    return Reporte(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      fechaGeneracion: fechaGeneracion ?? this.fechaGeneracion,
      usuarioGeneracion: usuarioGeneracion ?? this.usuarioGeneracion,
      parametros: parametros ?? this.parametros,
      formato: formato ?? this.formato,
      archivoUrl: archivoUrl ?? this.archivoUrl,
      estado: estado ?? this.estado,
      datos: datos ?? this.datos,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  String toString() {
    return 'Reporte(id: $id, nombre: $nombre, tipo: $tipo, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reporte && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
