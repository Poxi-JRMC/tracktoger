/// Modelo de Registro de Mantenimiento para el sistema Tracktoger
/// Representa un registro completo de mantenimiento de maquinaria
class RegistroMantenimiento {
  final String id;
  final String idMaquinaria;
  final DateTime fechaProgramada;
  final DateTime? fechaRealizacion;
  final String tipoMantenimiento; // correctivo, preventivo, predictivo, emergencia
  final String descripcionTrabajo;
  final String estado; // pendiente, en_progreso, completado, cancelado
  final double costoRepuestos;
  final double costoManoObra;
  final double costoOtros;
  final String? notas;
  final String? tecnicoAsignado; // ID del técnico asignado
  final DateTime fechaCreacion;
  final List<String> tareas; // Lista de tareas realizadas
  final List<String> materiales; // Materiales utilizados
  final String? alertaId; // ID de la alerta que generó este mantenimiento

  RegistroMantenimiento({
    required this.id,
    required this.idMaquinaria,
    required this.fechaProgramada,
    this.fechaRealizacion,
    required this.tipoMantenimiento,
    required this.descripcionTrabajo,
    this.estado = 'pendiente',
    this.costoRepuestos = 0.0,
    this.costoManoObra = 0.0,
    this.costoOtros = 0.0,
    this.notas,
    this.tecnicoAsignado,
    required this.fechaCreacion,
    this.tareas = const [],
    this.materiales = const [],
    this.alertaId,
  });

  /// Calcula el costo total
  double get costoTotal => costoRepuestos + costoManoObra + costoOtros;

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idMaquinaria': idMaquinaria,
      'fechaProgramada': fechaProgramada.toIso8601String(),
      'fechaRealizacion': fechaRealizacion?.toIso8601String(),
      'tipoMantenimiento': tipoMantenimiento,
      'descripcionTrabajo': descripcionTrabajo,
      'estado': estado,
      'costoRepuestos': costoRepuestos,
      'costoManoObra': costoManoObra,
      'costoOtros': costoOtros,
      'costoTotal': costoTotal,
      'notas': notas,
      'tecnicoAsignado': tecnicoAsignado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'tareas': tareas,
      'materiales': materiales,
      'alertaId': alertaId,
    };
  }

  /// Crea un objeto RegistroMantenimiento desde un Map
  factory RegistroMantenimiento.fromMap(Map<String, dynamic> map) {
    // Manejar _id de MongoDB
    String id = map['id'] ?? '';
    if (id.isEmpty && map.containsKey('_id')) {
      id = map['_id'].toString();
    }
    
    return RegistroMantenimiento(
      id: id,
      idMaquinaria: map['idMaquinaria'] ?? map['maquinariaId'] ?? '',
      fechaProgramada: map['fechaProgramada'] is String
          ? DateTime.parse(map['fechaProgramada'])
          : (map['fechaProgramada'] as DateTime? ?? DateTime.now()),
      fechaRealizacion: map['fechaRealizacion'] != null
          ? (map['fechaRealizacion'] is String
              ? DateTime.parse(map['fechaRealizacion'])
              : map['fechaRealizacion'] as DateTime?)
          : null,
      tipoMantenimiento: map['tipoMantenimiento'] ?? map['tipoTrabajo'] ?? 'preventivo',
      descripcionTrabajo: map['descripcionTrabajo'] ?? map['descripcion'] ?? '',
      estado: map['estado'] ?? 'pendiente',
      costoRepuestos: (map['costoRepuestos'] ?? 0.0).toDouble(),
      costoManoObra: (map['costoManoObra'] ?? 0.0).toDouble(),
      costoOtros: (map['costoOtros'] ?? 0.0).toDouble(),
      notas: map['notas'] ?? map['observaciones'],
      tecnicoAsignado: map['tecnicoAsignado'],
      fechaCreacion: map['fechaCreacion'] is String
          ? DateTime.parse(map['fechaCreacion'])
          : (map['fechaCreacion'] as DateTime? ?? DateTime.now()),
      tareas: List<String>.from(map['tareas'] ?? []),
      materiales: List<String>.from(map['materiales'] ?? []),
      alertaId: map['alertaId'],
    );
  }

  /// Crea una copia del registro con campos modificados
  RegistroMantenimiento copyWith({
    String? id,
    String? idMaquinaria,
    DateTime? fechaProgramada,
    DateTime? fechaRealizacion,
    String? tipoMantenimiento,
    String? descripcionTrabajo,
    String? estado,
    double? costoRepuestos,
    double? costoManoObra,
    double? costoOtros,
    String? notas,
    String? tecnicoAsignado,
    DateTime? fechaCreacion,
    List<String>? tareas,
    List<String>? materiales,
    String? alertaId,
  }) {
    return RegistroMantenimiento(
      id: id ?? this.id,
      idMaquinaria: idMaquinaria ?? this.idMaquinaria,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      fechaRealizacion: fechaRealizacion ?? this.fechaRealizacion,
      tipoMantenimiento: tipoMantenimiento ?? this.tipoMantenimiento,
      descripcionTrabajo: descripcionTrabajo ?? this.descripcionTrabajo,
      estado: estado ?? this.estado,
      costoRepuestos: costoRepuestos ?? this.costoRepuestos,
      costoManoObra: costoManoObra ?? this.costoManoObra,
      costoOtros: costoOtros ?? this.costoOtros,
      notas: notas ?? this.notas,
      tecnicoAsignado: tecnicoAsignado ?? this.tecnicoAsignado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      tareas: tareas ?? this.tareas,
      materiales: materiales ?? this.materiales,
      alertaId: alertaId ?? this.alertaId,
    );
  }

  @override
  String toString() {
    return 'RegistroMantenimiento(id: $id, idMaquinaria: $idMaquinaria, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegistroMantenimiento && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

