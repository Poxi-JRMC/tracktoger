/// Modelo de recordatorio de mantenimiento basado en horas
class MantenimientoRecordatorio {
  final String id;
  final String maquinariaId;
  final String tipoMantenimiento; // 'aceite', 'filtro', 'revision_general', 'revision_mayor'
  final int horasIntervalo; // Cada cuántas horas se debe hacer
  final int horasUltimoMantenimiento; // Horas cuando se hizo el último
  final int horasActuales; // Horas actuales de la máquina
  final int horasRestantes; // Horas que faltan para el próximo
  final bool urgente; // Si está cerca del límite
  final DateTime? fechaEstimada; // Fecha estimada para el mantenimiento
  final String descripcion;
  final List<String> acciones; // Acciones a realizar

  MantenimientoRecordatorio({
    required this.id,
    required this.maquinariaId,
    required this.tipoMantenimiento,
    required this.horasIntervalo,
    required this.horasUltimoMantenimiento,
    required this.horasActuales,
    required this.horasRestantes,
    this.urgente = false,
    this.fechaEstimada,
    required this.descripcion,
    this.acciones = const [],
  });
}

