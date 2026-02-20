import 'package:mongo_dart/mongo_dart.dart';

/// Modelo de Maquinaria para el sistema Tracktoger
/// Representa una pieza de maquinaria en el inventario
class Maquinaria {
  final String id;
  final String nombre;
  final String? apodo; // Apodo o nombre alternativo de la maquinaria
  final String modelo;
  final String marca;
  final String numeroSerie;
  final String categoriaId; // ID de la categoría
  final DateTime fechaAdquisicion;
  final double valorAdquisicion;
  final String estado; // disponible, alquilado, mantenimiento, fuera_servicio
  final String? ubicacion;
  final String? descripcion;
  final List<String> imagenes;
  final Map<String, dynamic> especificaciones;
  final DateTime fechaUltimoMantenimiento;
  final int horasUso; // Horas totales del horómetro (horas_uso_total)
  final double horasDesdeUltimoMantenimientoMotor; // Horas trabajadas desde último mantenimiento de motor
  final double horasDesdeUltimoMantenimientoHidraulico; // Horas trabajadas desde último mantenimiento hidráulico
  final bool activo;
  final String? operadorAsignadoId; // ID del operador asignado
  final String estadoAsignacion; // "libre" o "asignado"

  Maquinaria({
    required this.id,
    required this.nombre,
    this.apodo,
    required this.modelo,
    required this.marca,
    required this.numeroSerie,
    required this.categoriaId,
    required this.fechaAdquisicion,
    required this.valorAdquisicion,
    this.estado = 'disponible',
    this.ubicacion,
    this.descripcion,
    this.imagenes = const [],
    this.especificaciones = const {},
    required this.fechaUltimoMantenimiento,
    this.horasUso = 0,
    this.horasDesdeUltimoMantenimientoMotor = 0.0,
    this.horasDesdeUltimoMantenimientoHidraulico = 0.0,
    this.activo = true,
    this.operadorAsignadoId,
    this.estadoAsignacion = 'libre',
  });

  /// Convierte el objeto a Map para almacenamiento en MongoDB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apodo': apodo,
      'modelo': modelo,
      'marca': marca,
      'numeroSerie': numeroSerie,
      'categoriaId': categoriaId,
      'fechaAdquisicion': fechaAdquisicion.toIso8601String(),
      'valorAdquisicion': valorAdquisicion,
      'estado': estado,
      'ubicacion': ubicacion,
      'descripcion': descripcion,
      'imagenes': imagenes,
      'especificaciones': especificaciones,
      'fechaUltimoMantenimiento': fechaUltimoMantenimiento.toIso8601String(),
      'horasUso': horasUso,
      'horasDesdeUltimoMantenimientoMotor': horasDesdeUltimoMantenimientoMotor,
      'horasDesdeUltimoMantenimientoHidraulico': horasDesdeUltimoMantenimientoHidraulico,
      'activo': activo,
      'operadorAsignadoId': operadorAsignadoId,
      'estadoAsignacion': estadoAsignacion,
    };
  }

  /// Crea un objeto Maquinaria desde un Map de MongoDB
  factory Maquinaria.fromMap(Map<String, dynamic> map) {
    // Manejar ID que puede venir como _id (ObjectId) o id (String)
    String id = '';
    if (map['_id'] != null) {
      final objectId = map['_id'];
      // Si es un ObjectId, extraer el hex string
      if (objectId is ObjectId) {
        id = objectId.toHexString();
      } else {
        // Si es String, puede venir como "ObjectId('hex')" o solo el hex
        String idStr = objectId.toString();
        // Extraer el hex string si viene en formato ObjectId("hex")
        if (idStr.startsWith('ObjectId(') && idStr.endsWith(')')) {
          id = idStr.substring(9, idStr.length - 2).replaceAll('"', '').replaceAll("'", '');
        } else {
          id = idStr;
        }
      }
    } else if (map['id'] != null) {
      id = map['id'].toString();
    }

    return Maquinaria(
      id: id,
      nombre: map['nombre'] ?? '',
      apodo: map['apodo'],
      modelo: map['modelo'] ?? '',
      marca: map['marca'] ?? '',
      numeroSerie: map['numeroSerie'] ?? '',
      categoriaId: map['categoriaId'] ?? '',
      fechaAdquisicion: map['fechaAdquisicion'] != null
          ? DateTime.parse(map['fechaAdquisicion'])
          : DateTime.now(),
      valorAdquisicion: (map['valorAdquisicion'] ?? 0.0).toDouble(),
      estado: map['estado'] ?? 'disponible',
      ubicacion: map['ubicacion'],
      descripcion: map['descripcion'],
      imagenes: List<String>.from(map['imagenes'] ?? []),
      especificaciones: Map<String, dynamic>.from(
        map['especificaciones'] ?? {},
      ),
      fechaUltimoMantenimiento: map['fechaUltimoMantenimiento'] != null
          ? DateTime.parse(map['fechaUltimoMantenimiento'])
          : DateTime.now(),
      horasUso: map['horasUso'] ?? 0,
      horasDesdeUltimoMantenimientoMotor: (map['horasDesdeUltimoMantenimientoMotor'] ?? 0.0).toDouble(),
      horasDesdeUltimoMantenimientoHidraulico: (map['horasDesdeUltimoMantenimientoHidraulico'] ?? 0.0).toDouble(),
      activo: map['activo'] ?? true,
      operadorAsignadoId: map['operadorAsignadoId'],
      estadoAsignacion: map['estadoAsignacion'] ?? 'libre',
    );
  }

  /// Crea una copia de la maquinaria con campos modificados
  Maquinaria copyWith({
    String? id,
    String? nombre,
    String? apodo,
    String? modelo,
    String? marca,
    String? numeroSerie,
    String? categoriaId,
    DateTime? fechaAdquisicion,
    double? valorAdquisicion,
    String? estado,
    String? ubicacion,
    String? descripcion,
    List<String>? imagenes,
    Map<String, dynamic>? especificaciones,
    DateTime? fechaUltimoMantenimiento,
    int? horasUso,
    double? horasDesdeUltimoMantenimientoMotor,
    double? horasDesdeUltimoMantenimientoHidraulico,
    bool? activo,
    String? operadorAsignadoId,
    String? estadoAsignacion,
  }) {
    return Maquinaria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apodo: apodo ?? this.apodo,
      modelo: modelo ?? this.modelo,
      marca: marca ?? this.marca,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      categoriaId: categoriaId ?? this.categoriaId,
      fechaAdquisicion: fechaAdquisicion ?? this.fechaAdquisicion,
      valorAdquisicion: valorAdquisicion ?? this.valorAdquisicion,
      estado: estado ?? this.estado,
      ubicacion: ubicacion ?? this.ubicacion,
      descripcion: descripcion ?? this.descripcion,
      imagenes: imagenes ?? this.imagenes,
      especificaciones: especificaciones ?? this.especificaciones,
      fechaUltimoMantenimiento:
          fechaUltimoMantenimiento ?? this.fechaUltimoMantenimiento,
      horasUso: horasUso ?? this.horasUso,
      horasDesdeUltimoMantenimientoMotor: horasDesdeUltimoMantenimientoMotor ?? this.horasDesdeUltimoMantenimientoMotor,
      horasDesdeUltimoMantenimientoHidraulico: horasDesdeUltimoMantenimientoHidraulico ?? this.horasDesdeUltimoMantenimientoHidraulico,
      activo: activo ?? this.activo,
      operadorAsignadoId: operadorAsignadoId ?? this.operadorAsignadoId,
      estadoAsignacion: estadoAsignacion ?? this.estadoAsignacion,
    );
  }

  @override
  String toString() {
    return 'Maquinaria(id: $id, nombre: $nombre, modelo: $modelo, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Maquinaria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
