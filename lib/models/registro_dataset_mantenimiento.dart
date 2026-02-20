/// Modelo para representar un registro del dataset CSV
/// Contiene las mismas columnas del CSV excepto 'falla' (que es solo para entrenamiento)
class RegistroDatasetMantenimiento {
  final double horasUsoTotal;
  final double horasDesdeUltimoMantenimiento;
  final double tempRefrigeranteMotor;
  final double tempAceiteMotor;
  final double presionAceiteMotor;
  final double tempAceiteHidraulico;
  final double presionLineaHidraulica;
  final double nivelAceiteMotor;
  final double nivelAceiteHidraulico;
  final double diferencialPresionFiltroAceite;
  final double diferencialPresionFiltroHidraulico;
  final double porcentajeTiempoRalenti;
  final double promedioHorasDiariasUso;
  final int alertasCriticas30d;
  final int alertasMedias30d;

  RegistroDatasetMantenimiento({
    required this.horasUsoTotal,
    required this.horasDesdeUltimoMantenimiento,
    required this.tempRefrigeranteMotor,
    required this.tempAceiteMotor,
    required this.presionAceiteMotor,
    required this.tempAceiteHidraulico,
    required this.presionLineaHidraulica,
    required this.nivelAceiteMotor,
    required this.nivelAceiteHidraulico,
    required this.diferencialPresionFiltroAceite,
    required this.diferencialPresionFiltroHidraulico,
    required this.porcentajeTiempoRalenti,
    required this.promedioHorasDiariasUso,
    required this.alertasCriticas30d,
    required this.alertasMedias30d,
  });

  /// Convierte a lista de features en el orden esperado por el modelo ML
  /// (15 features según el orden del dataset)
  List<double> toFeaturesList() {
    return [
      horasUsoTotal,
      horasDesdeUltimoMantenimiento,
      tempRefrigeranteMotor,
      tempAceiteMotor,
      presionAceiteMotor,
      tempAceiteHidraulico,
      presionLineaHidraulica,
      nivelAceiteMotor,
      nivelAceiteHidraulico,
      diferencialPresionFiltroAceite,
      diferencialPresionFiltroHidraulico,
      porcentajeTiempoRalenti,
      promedioHorasDiariasUso,
      alertasCriticas30d.toDouble(),
      alertasMedias30d.toDouble(),
    ];
  }

  /// Crea desde un Map (después de parsear CSV)
  factory RegistroDatasetMantenimiento.fromMap(Map<String, dynamic> map) {
    return RegistroDatasetMantenimiento(
      horasUsoTotal: _parseDouble(map['horas_uso_total']),
      horasDesdeUltimoMantenimiento: _parseDouble(map['horas_desde_ultimo_mantenimiento']),
      tempRefrigeranteMotor: _parseDouble(map['temp_refrigerante_motor']),
      tempAceiteMotor: _parseDouble(map['temp_aceite_motor']),
      presionAceiteMotor: _parseDouble(map['presion_aceite_motor']),
      tempAceiteHidraulico: _parseDouble(map['temp_aceite_hidraulico']),
      presionLineaHidraulica: _parseDouble(map['presion_linea_hidraulica']),
      nivelAceiteMotor: _parseDouble(map['nivel_aceite_motor']),
      nivelAceiteHidraulico: _parseDouble(map['nivel_aceite_hidraulico']),
      diferencialPresionFiltroAceite: _parseDouble(map['diferencial_presion_filtro_aceite']),
      diferencialPresionFiltroHidraulico: _parseDouble(map['diferencial_presion_filtro_hidraulico']),
      porcentajeTiempoRalenti: _parseDouble(map['porcentaje_tiempo_ralenti']),
      promedioHorasDiariasUso: _parseDouble(map['promedio_horas_diarias_uso']),
      alertasCriticas30d: _parseInt(map['alertas_criticas_30d']),
      alertasMedias30d: _parseInt(map['alertas_medias_30d']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'horas_uso_total': horasUsoTotal,
      'horas_desde_ultimo_mantenimiento': horasDesdeUltimoMantenimiento,
      'temp_refrigerante_motor': tempRefrigeranteMotor,
      'temp_aceite_motor': tempAceiteMotor,
      'presion_aceite_motor': presionAceiteMotor,
      'temp_aceite_hidraulico': tempAceiteHidraulico,
      'presion_linea_hidraulica': presionLineaHidraulica,
      'nivel_aceite_motor': nivelAceiteMotor,
      'nivel_aceite_hidraulico': nivelAceiteHidraulico,
      'diferencial_presion_filtro_aceite': diferencialPresionFiltroAceite,
      'diferencial_presion_filtro_hidraulico': diferencialPresionFiltroHidraulico,
      'porcentaje_tiempo_ralenti': porcentajeTiempoRalenti,
      'promedio_horas_diarias_uso': promedioHorasDiariasUso,
      'alertas_criticas_30d': alertasCriticas30d,
      'alertas_medias_30d': alertasMedias30d,
    };
  }
}

