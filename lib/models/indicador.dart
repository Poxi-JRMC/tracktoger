/// Modelo de Indicador para el sistema Tracktoger
/// Representa un indicador KPI del sistema
class Indicador {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria; // disponibilidad, rentabilidad, mantenimiento, etc.
  final String tipo; // porcentaje, numero, moneda, tiempo
  final double valorActual;
  final double? valorObjetivo;
  final double? valorAnterior;
  final String unidad; // %, $, horas, unidades, etc.
  final DateTime fechaCalculo;
  final String? formula; // Fórmula utilizada para calcular el indicador
  final Map<String, dynamic> parametros; // Parámetros del cálculo
  final String estado; // bueno, regular, malo
  final String? observaciones;
  final List<String>
  dependencias; // IDs de otros indicadores de los que depende
  final bool activo;

  Indicador({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.valorActual,
    this.valorObjetivo,
    this.valorAnterior,
    this.unidad = '',
    required this.fechaCalculo,
    this.formula,
    this.parametros = const {},
    this.estado = 'bueno',
    this.observaciones,
    this.dependencias = const [],
    this.activo = true,
  });

  /// Convierte el objeto a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'tipo': tipo,
      'valorActual': valorActual,
      'valorObjetivo': valorObjetivo,
      'valorAnterior': valorAnterior,
      'unidad': unidad,
      'fechaCalculo': fechaCalculo.toIso8601String(),
      'formula': formula,
      'parametros': parametros,
      'estado': estado,
      'observaciones': observaciones,
      'dependencias': dependencias,
      'activo': activo,
    };
  }

  /// Crea un objeto Indicador desde un Map
  factory Indicador.fromMap(Map<String, dynamic> map) {
    return Indicador(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      categoria: map['categoria'] ?? '',
      tipo: map['tipo'] ?? '',
      valorActual: (map['valorActual'] ?? 0.0).toDouble(),
      valorObjetivo: map['valorObjetivo']?.toDouble(),
      valorAnterior: map['valorAnterior']?.toDouble(),
      unidad: map['unidad'] ?? '',
      fechaCalculo: DateTime.parse(map['fechaCalculo']),
      formula: map['formula'],
      parametros: Map<String, dynamic>.from(map['parametros'] ?? {}),
      estado: map['estado'] ?? 'bueno',
      observaciones: map['observaciones'],
      dependencias: List<String>.from(map['dependencias'] ?? []),
      activo: map['activo'] ?? true,
    );
  }

  /// Crea una copia del indicador con campos modificados
  Indicador copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? categoria,
    String? tipo,
    double? valorActual,
    double? valorObjetivo,
    double? valorAnterior,
    String? unidad,
    DateTime? fechaCalculo,
    String? formula,
    Map<String, dynamic>? parametros,
    String? estado,
    String? observaciones,
    List<String>? dependencias,
    bool? activo,
  }) {
    return Indicador(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
      valorActual: valorActual ?? this.valorActual,
      valorObjetivo: valorObjetivo ?? this.valorObjetivo,
      valorAnterior: valorAnterior ?? this.valorAnterior,
      unidad: unidad ?? this.unidad,
      fechaCalculo: fechaCalculo ?? this.fechaCalculo,
      formula: formula ?? this.formula,
      parametros: parametros ?? this.parametros,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      dependencias: dependencias ?? this.dependencias,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'Indicador(id: $id, nombre: $nombre, valorActual: $valorActual, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Indicador && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
