/// Modelo de estado general de maquinaria
class EstadoMaquinaria {
  final String maquinariaId;
  final String estadoGeneral; // 'OPTIMO', 'BUENO', 'REGULAR', 'MALO', 'URGENTE_REPARACION'
  final double scoreSalud; // 0-100
  final String? fallaMasProbable; // ID de la falla más probable
  final List<String> fallasPredichas; // IDs de fallas predichas
  final List<String> recordatoriosUrgentes; // IDs de recordatorios urgentes
  final DateTime fechaEvaluacion;
  final Map<String, dynamic> metricas; // Métricas de salud

  EstadoMaquinaria({
    required this.maquinariaId,
    required this.estadoGeneral,
    required this.scoreSalud,
    this.fallaMasProbable,
    this.fallasPredichas = const [],
    this.recordatoriosUrgentes = const [],
    required this.fechaEvaluacion,
    this.metricas = const {},
  });
}

