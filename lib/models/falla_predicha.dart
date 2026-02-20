/// Modelo de falla predicha por ML
class FallaPredicha {
  final String id;
  final String maquinariaId;
  final String tipoFalla; // 'motor', 'hidraulico', 'transmision', 'frenos', etc.
  final String nombreFalla; // Nombre específico de la falla
  final double probabilidad; // 0-100%
  final String severidad; // 'critica', 'alta', 'media', 'baja'
  final DateTime? fechaEstimada; // Fecha estimada de falla
  final String descripcion;
  final List<String> sintomas; // Síntomas que indican esta falla
  final List<String> accionesPreventivas; // Acciones para prevenir
  final Map<String, dynamic> factores; // Factores que contribuyen

  FallaPredicha({
    required this.id,
    required this.maquinariaId,
    required this.tipoFalla,
    required this.nombreFalla,
    required this.probabilidad,
    required this.severidad,
    this.fechaEstimada,
    required this.descripcion,
    this.sintomas = const [],
    this.accionesPreventivas = const [],
    this.factores = const {},
  });
}

