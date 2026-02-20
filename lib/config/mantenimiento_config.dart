/// Configuración de umbrales para mantenimiento basado en horas
class MantenimientoConfig {
  // Umbrales de horas trabajadas para diferentes tipos de mantenimiento
  static const double UMBRAL_CAMBIO_ACEITE_MOTOR_HORAS = 250.0;
  static const double UMBRAL_CAMBIO_ACEITE_HIDRAULICO_HORAS = 500.0;
  static const double UMBRAL_CAMBIO_FILTROS_HORAS = 300.0;
  
  // Umbrales de horas para otros mantenimientos preventivos
  static const double UMBRAL_REVISION_GENERAL_HORAS = 1000.0;
  static const double UMBRAL_MANTENIMIENTO_MAYOR_HORAS = 5000.0;

  /// Calcula horas restantes hasta el próximo cambio de aceite de motor
  static double calcularHorasRestantesAceiteMotor(double horasDesdeUltimoMantenimiento) {
    return UMBRAL_CAMBIO_ACEITE_MOTOR_HORAS - horasDesdeUltimoMantenimiento;
  }

  /// Calcula horas restantes hasta el próximo cambio de aceite hidráulico
  static double calcularHorasRestantesAceiteHidraulico(double horasDesdeUltimoMantenimiento) {
    return UMBRAL_CAMBIO_ACEITE_HIDRAULICO_HORAS - horasDesdeUltimoMantenimiento;
  }

  /// Calcula horas restantes hasta el próximo cambio de filtros
  static double calcularHorasRestantesFiltros(double horasDesdeUltimoMantenimiento) {
    return UMBRAL_CAMBIO_FILTROS_HORAS - horasDesdeUltimoMantenimiento;
  }

  /// Obtiene mensaje de recomendación para aceite de motor
  static String obtenerMensajeAceiteMotor(double horasRestantes) {
    if (horasRestantes <= 0) {
      return 'Cambio de aceite de motor recomendado de inmediato';
    } else if (horasRestantes <= 50) {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas de trabajo se recomienda cambiar aceite de motor (URGENTE)';
    } else {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas de trabajo se recomienda cambiar aceite de motor';
    }
  }

  /// Obtiene mensaje de recomendación para aceite hidráulico
  static String obtenerMensajeAceiteHidraulico(double horasRestantes) {
    if (horasRestantes <= 0) {
      return 'Mantenimiento hidráulico atrasado, realizar cuanto antes';
    } else if (horasRestantes <= 100) {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas de trabajo se recomienda mantenimiento del sistema hidráulico (PRÓXIMO)';
    } else {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas de trabajo se recomienda mantenimiento del sistema hidráulico';
    }
  }

  /// Obtiene mensaje de recomendación para filtros
  static String obtenerMensajeFiltros(double horasRestantes) {
    if (horasRestantes <= 0) {
      return 'Cambio de filtros recomendado de inmediato';
    } else {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas de trabajo se recomienda cambio de filtros';
    }
  }

  /// Obtiene mensaje para agregar/rellenar aceite de motor
  static String obtenerMensajeAgregarAceiteMotor(double horasDesdeUltimoMantenimiento) {
    if (horasDesdeUltimoMantenimiento >= 100) {
      return 'Verificar y agregar aceite de motor si es necesario (cada 100 horas)';
    } else {
      final horasFaltantes = 100 - horasDesdeUltimoMantenimiento;
      return 'En ${horasFaltantes.toStringAsFixed(0)} horas verificar nivel de aceite de motor';
    }
  }

  /// Obtiene mensaje para agregar/rellenar aceite hidráulico
  static String obtenerMensajeAgregarAceiteHidraulico(double horasDesdeUltimoMantenimiento) {
    if (horasDesdeUltimoMantenimiento >= 200) {
      return 'Verificar y agregar aceite hidráulico si es necesario (cada 200 horas)';
    } else {
      final horasFaltantes = 200 - horasDesdeUltimoMantenimiento;
      return 'En ${horasFaltantes.toStringAsFixed(0)} horas verificar nivel de aceite hidráulico';
    }
  }

  /// Obtiene mensaje para revisión general
  static String obtenerMensajeRevisionGeneral(double horasDesdeUltimoMantenimiento) {
    final horasRestantes = UMBRAL_REVISION_GENERAL_HORAS - horasDesdeUltimoMantenimiento;
    if (horasRestantes <= 0) {
      return 'Revisión general recomendada de inmediato (cada 1000 horas)';
    } else if (horasRestantes <= 200) {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas se recomienda revisión general (PRÓXIMO)';
    } else {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas se recomienda revisión general';
    }
  }

  /// Obtiene mensaje para mantenimiento mayor
  static String obtenerMensajeMantenimientoMayor(double horasDesdeUltimoMantenimiento) {
    final horasRestantes = UMBRAL_MANTENIMIENTO_MAYOR_HORAS - horasDesdeUltimoMantenimiento;
    if (horasRestantes <= 0) {
      return 'Mantenimiento mayor recomendado de inmediato (cada 5000 horas)';
    } else if (horasRestantes <= 500) {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas se recomienda mantenimiento mayor (PRÓXIMO)';
    } else {
      return 'En ${horasRestantes.toStringAsFixed(0)} horas se recomienda mantenimiento mayor';
    }
  }
}

