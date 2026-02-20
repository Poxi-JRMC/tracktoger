/// Modelo de Orden de Trabajo para el sistema Tracktoger
/// Representa una orden de trabajo para mantenimiento de maquinaria
class OrdenTrabajo {
  final String id;
  final String numeroOrden;
  final String maquinariaId; // ID de la maquinaria
  final String tipoTrabajo; // preventivo, correctivo, predictivo, emergencia
  final String prioridad; // baja, media, alta, critica
  final String estado; // pendiente, en_progreso, completada, cancelada
  final String descripcion;
  final String? tecnicoAsignado; // ID del técnico asignado
  final DateTime fechaCreacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaVencimiento;
  final double? costoEstimado;
  final double? costoReal;
  final List<String> tareas; // Lista de tareas a realizar
  final String? observaciones;
  final List<String> materiales; // Materiales utilizados
  final List<String> documentos; // URLs de documentos adjuntos
  final String? alertaId; // ID de la alerta que generó esta orden

  OrdenTrabajo({
    required this.id,
    required this.numeroOrden,
    required this.maquinariaId,
    required this.tipoTrabajo,
    required this.prioridad,
    this.estado = 'pendiente',
    required this.descripcion,
    this.tecnicoAsignado,
    required this.fechaCreacion,
    this.fechaInicio,
    this.fechaFin,
    this.fechaVencimiento,
    this.costoEstimado,
    this.costoReal,
    this.tareas = const [],
    this.observaciones,
    this.materiales = const [],
    this.documentos = const [],
    this.alertaId,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroOrden': numeroOrden,
      'maquinariaId': maquinariaId,
      'tipoTrabajo': tipoTrabajo,
      'prioridad': prioridad,
      'estado': estado,
      'descripcion': descripcion,
      'tecnicoAsignado': tecnicoAsignado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      'costoEstimado': costoEstimado,
      'costoReal': costoReal,
      'tareas': tareas,
      'observaciones': observaciones,
      'materiales': materiales,
      'documentos': documentos,
      'alertaId': alertaId,
    };
  }

  /// Crea un objeto OrdenTrabajo desde un Map
  factory OrdenTrabajo.fromMap(Map<String, dynamic> map) {
    return OrdenTrabajo(
      id: map['id'] ?? '',
      numeroOrden: map['numeroOrden'] ?? '',
      maquinariaId: map['maquinariaId'] ?? '',
      tipoTrabajo: map['tipoTrabajo'] ?? '',
      prioridad: map['prioridad'] ?? '',
      estado: map['estado'] ?? 'pendiente',
      descripcion: map['descripcion'] ?? '',
      tecnicoAsignado: map['tecnicoAsignado'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.parse(map['fechaInicio'])
          : null,
      fechaFin: map['fechaFin'] != null
          ? DateTime.parse(map['fechaFin'])
          : null,
      fechaVencimiento: map['fechaVencimiento'] != null
          ? DateTime.parse(map['fechaVencimiento'])
          : null,
      costoEstimado: map['costoEstimado']?.toDouble(),
      costoReal: map['costoReal']?.toDouble(),
      tareas: List<String>.from(map['tareas'] ?? []),
      observaciones: map['observaciones'],
      materiales: List<String>.from(map['materiales'] ?? []),
      documentos: List<String>.from(map['documentos'] ?? []),
      alertaId: map['alertaId'],
    );
  }

  /// Crea una copia de la orden de trabajo con campos modificados
  OrdenTrabajo copyWith({
    String? id,
    String? numeroOrden,
    String? maquinariaId,
    String? tipoTrabajo,
    String? prioridad,
    String? estado,
    String? descripcion,
    String? tecnicoAsignado,
    DateTime? fechaCreacion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? fechaVencimiento,
    double? costoEstimado,
    double? costoReal,
    List<String>? tareas,
    String? observaciones,
    List<String>? materiales,
    List<String>? documentos,
    String? alertaId,
  }) {
    return OrdenTrabajo(
      id: id ?? this.id,
      numeroOrden: numeroOrden ?? this.numeroOrden,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      tipoTrabajo: tipoTrabajo ?? this.tipoTrabajo,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      descripcion: descripcion ?? this.descripcion,
      tecnicoAsignado: tecnicoAsignado ?? this.tecnicoAsignado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      costoEstimado: costoEstimado ?? this.costoEstimado,
      costoReal: costoReal ?? this.costoReal,
      tareas: tareas ?? this.tareas,
      observaciones: observaciones ?? this.observaciones,
      materiales: materiales ?? this.materiales,
      documentos: documentos ?? this.documentos,
      alertaId: alertaId ?? this.alertaId,
    );
  }

  @override
  String toString() {
    return 'OrdenTrabajo(id: $id, numeroOrden: $numeroOrden, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrdenTrabajo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
