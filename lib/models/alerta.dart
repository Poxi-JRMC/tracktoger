/// Modelo de Alerta para el sistema Tracktoger
/// Representa una alerta generada por el sistema de mantenimiento predictivo
class Alerta {
  final String id;
  final String maquinariaId; // ID de la maquinaria
  final String tipoAlerta; // mantenimiento, falla, critica, informativa
  final String titulo;
  final String descripcion;
  final String prioridad; // baja, media, alta, critica
  final String estado; // activa, resuelta, cancelada
  final DateTime fechaCreacion;
  final DateTime? fechaResolucion;
  final String? usuarioAsignado; // ID del usuario asignado
  final String? observaciones;
  final Map<String, dynamic> datosAlerta; // Datos específicos de la alerta
  final List<String> accionesRequeridas; // Acciones que se deben tomar
  final DateTime? fechaVencimiento;

  Alerta({
    required this.id,
    required this.maquinariaId,
    required this.tipoAlerta,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    this.estado = 'activa',
    required this.fechaCreacion,
    this.fechaResolucion,
    this.usuarioAsignado,
    this.observaciones,
    this.datosAlerta = const {},
    this.accionesRequeridas = const [],
    this.fechaVencimiento,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maquinariaId': maquinariaId,
      'tipoAlerta': tipoAlerta,
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'estado': estado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaResolucion': fechaResolucion?.toIso8601String(),
      'usuarioAsignado': usuarioAsignado,
      'observaciones': observaciones,
      'datosAlerta': datosAlerta,
      'accionesRequeridas': accionesRequeridas,
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
    };
  }

  /// Crea un objeto Alerta desde un Map
  factory Alerta.fromMap(Map<String, dynamic> map) {
    return Alerta(
      id: map['id'] ?? '',
      maquinariaId: map['maquinariaId'] ?? '',
      tipoAlerta: map['tipoAlerta'] ?? '',
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      prioridad: map['prioridad'] ?? '',
      estado: map['estado'] ?? 'activa',
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaResolucion: map['fechaResolucion'] != null
          ? DateTime.parse(map['fechaResolucion'])
          : null,
      usuarioAsignado: map['usuarioAsignado'],
      observaciones: map['observaciones'],
      datosAlerta: Map<String, dynamic>.from(map['datosAlerta'] ?? {}),
      accionesRequeridas: List<String>.from(map['accionesRequeridas'] ?? []),
      fechaVencimiento: map['fechaVencimiento'] != null
          ? DateTime.parse(map['fechaVencimiento'])
          : null,
    );
  }

  /// Crea una copia de la alerta con campos modificados
  Alerta copyWith({
    String? id,
    String? maquinariaId,
    String? tipoAlerta,
    String? titulo,
    String? descripcion,
    String? prioridad,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaResolucion,
    String? usuarioAsignado,
    String? observaciones,
    Map<String, dynamic>? datosAlerta,
    List<String>? accionesRequeridas,
    DateTime? fechaVencimiento,
  }) {
    return Alerta(
      id: id ?? this.id,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      tipoAlerta: tipoAlerta ?? this.tipoAlerta,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaResolucion: fechaResolucion ?? this.fechaResolucion,
      usuarioAsignado: usuarioAsignado ?? this.usuarioAsignado,
      observaciones: observaciones ?? this.observaciones,
      datosAlerta: datosAlerta ?? this.datosAlerta,
      accionesRequeridas: accionesRequeridas ?? this.accionesRequeridas,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    );
  }

  @override
  String toString() {
    return 'Alerta(id: $id, titulo: $titulo, prioridad: $prioridad, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alerta && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
