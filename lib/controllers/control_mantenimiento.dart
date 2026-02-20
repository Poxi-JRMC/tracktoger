import 'package:mongo_dart/mongo_dart.dart';
import '../models/analisis.dart';
import '../models/alerta.dart';
import '../models/orden_trabajo.dart';
import '../models/registro_mantenimiento.dart';
import '../data/services/database_service.dart';

/// Controlador para el mantenimiento predictivo
/// Maneja las operaciones CRUD de análisis, alertas y órdenes de trabajo
class ControlMantenimiento {
  final DatabaseService _dbService = DatabaseService();
  
  // Listas simuladas para almacenamiento en memoria (solo para alertas y órdenes que aún no están en MongoDB)
  static List<Alerta> _alertas = [];
  static List<OrdenTrabajo> _ordenesTrabajo = [];

  // ========== MÉTODOS PARA ANÁLISIS ==========

  /// Registra un nuevo análisis en MongoDB
  Future<Analisis> registrarAnalisis(Analisis analisis) async {
    // Generar ID si no viene
    String analisisId = analisis.id;
    if (analisisId.isEmpty) {
      analisisId = ObjectId().toHexString();
    }

    final analisisToInsert = analisis.copyWith(id: analisisId);
    await _dbService.insertarAnalisis(analisisToInsert.toMap());
    print('✅ Análisis registrado en MongoDB: ${analisisToInsert.tipoAnalisis} (ID: $analisisId)');
    
    // Verificar si el análisis genera una alerta
    await _evaluarAlerta(analisisToInsert);
    
    return analisisToInsert;
  }

  /// Actualiza un análisis existente en MongoDB
  Future<Analisis> actualizarAnalisis(Analisis analisis) async {
    final existente = await consultarAnalisis(analisis.id);
    if (existente == null) {
      throw Exception('Análisis no encontrado');
    }

    await _dbService.actualizarAnalisis(analisis.toMap());
    print('✅ Análisis actualizado en MongoDB: ${analisis.id}');
    return analisis;
  }

  /// Obtiene un análisis por su ID desde MongoDB
  Future<Analisis?> consultarAnalisis(String id) async {
    return await _dbService.consultarAnalisis(id);
  }

  /// Obtiene todos los análisis desde MongoDB
  Future<List<Analisis>> consultarTodosAnalisis() async {
    return await _dbService.consultarTodosAnalisis();
  }

  /// Obtiene análisis por maquinaria desde MongoDB
  Future<List<Analisis>> consultarAnalisisPorMaquinaria(String maquinariaId) async {
    return await _dbService.consultarAnalisisPorMaquinaria(maquinariaId);
  }

  /// Obtiene análisis por tipo
  Future<List<Analisis>> consultarAnalisisPorTipo(String tipoAnalisis) async {
    final todos = await consultarTodosAnalisis();
    return todos.where((a) => a.tipoAnalisis == tipoAnalisis).toList();
  }

  /// Obtiene análisis por resultado
  Future<List<Analisis>> consultarAnalisisPorResultado(String resultado) async {
    return await _dbService.consultarAnalisisPorResultado(resultado);
  }

  /// Obtiene análisis críticos
  Future<List<Analisis>> consultarAnalisisCriticos() async {
    return await consultarAnalisisPorResultado('critico');
  }

  /// Elimina análisis antiguos (más de 7 días) de una máquina específica
  Future<int> eliminarAnalisisAntiguos(String maquinariaId, {int diasAntiguedad = 7}) async {
    return await _dbService.eliminarAnalisisAntiguos(maquinariaId, diasAntiguedad: diasAntiguedad);
  }

  /// Elimina TODOS los análisis de una máquina específica
  /// Útil cuando se registran nuevos parámetros y se quiere reemplazar todos los anteriores
  Future<int> eliminarTodosAnalisis(String maquinariaId) async {
    return await _dbService.eliminarTodosAnalisis(maquinariaId);
  }

  // ========== MÉTODOS PARA ALERTAS ==========

  /// Crea una nueva alerta
  Future<Alerta> crearAlerta(Alerta alerta) async {
    _alertas.add(alerta);
    return alerta;
  }

  /// Actualiza una alerta existente
  Future<Alerta> actualizarAlerta(Alerta alerta) async {
    final index = _alertas.indexWhere((a) => a.id == alerta.id);
    if (index == -1) {
      throw Exception('Alerta no encontrada');
    }

    _alertas[index] = alerta;
    return alerta;
  }

  /// Obtiene una alerta por su ID
  Future<Alerta?> consultarAlerta(String id) async {
    try {
      return _alertas.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las alertas
  Future<List<Alerta>> consultarTodasAlertas() async {
    return List.from(_alertas);
  }

  /// Obtiene alertas activas
  Future<List<Alerta>> consultarAlertasActivas() async {
    return _alertas.where((a) => a.estado == 'activa').toList();
  }

  /// Obtiene alertas por maquinaria
  Future<List<Alerta>> consultarAlertasPorMaquinaria(String maquinariaId) async {
    return _alertas.where((a) => a.maquinariaId == maquinariaId).toList();
  }

  /// Obtiene alertas por prioridad
  Future<List<Alerta>> consultarAlertasPorPrioridad(String prioridad) async {
    return _alertas.where((a) => a.prioridad == prioridad).toList();
  }

  /// Obtiene alertas críticas
  Future<List<Alerta>> consultarAlertasCriticas() async {
    return _alertas.where((a) => a.prioridad == 'critica').toList();
  }

  /// Resuelve una alerta
  Future<Alerta> resolverAlerta(String id, String observaciones) async {
    final alerta = await consultarAlerta(id);
    if (alerta == null) {
      throw Exception('Alerta no encontrada');
    }

    final alertaResuelta = alerta.copyWith(
      estado: 'resuelta',
      fechaResolucion: DateTime.now(),
      observaciones: observaciones,
    );

    return await actualizarAlerta(alertaResuelta);
  }

  /// Asigna una alerta a un usuario
  Future<Alerta> asignarAlerta(String id, String usuarioId) async {
    final alerta = await consultarAlerta(id);
    if (alerta == null) {
      throw Exception('Alerta no encontrada');
    }

    final alertaAsignada = alerta.copyWith(usuarioAsignado: usuarioId);
    return await actualizarAlerta(alertaAsignada);
  }

  // ========== MÉTODOS PARA ÓRDENES DE TRABAJO ==========

  /// Crea una nueva orden de trabajo
  Future<OrdenTrabajo> crearOrdenTrabajo(OrdenTrabajo orden) async {
    // Generar número de orden único
    final numeroOrden = await _generarNumeroOrden();
    final ordenConNumero = orden.copyWith(numeroOrden: numeroOrden);

    _ordenesTrabajo.add(ordenConNumero);
    return ordenConNumero;
  }

  /// Actualiza una orden de trabajo existente
  Future<OrdenTrabajo> actualizarOrdenTrabajo(OrdenTrabajo orden) async {
    final index = _ordenesTrabajo.indexWhere((o) => o.id == orden.id);
    if (index == -1) {
      throw Exception('Orden de trabajo no encontrada');
    }

    _ordenesTrabajo[index] = orden;
    return orden;
  }

  /// Obtiene una orden de trabajo por su ID
  Future<OrdenTrabajo?> consultarOrdenTrabajo(String id) async {
    try {
      return _ordenesTrabajo.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las órdenes de trabajo
  Future<List<OrdenTrabajo>> consultarTodasOrdenesTrabajo() async {
    return List.from(_ordenesTrabajo);
  }

  /// Obtiene órdenes de trabajo por maquinaria
  Future<List<OrdenTrabajo>> consultarOrdenesPorMaquinaria(String maquinariaId) async {
    return _ordenesTrabajo.where((o) => o.maquinariaId == maquinariaId).toList();
  }

  /// Obtiene órdenes de trabajo por estado
  Future<List<OrdenTrabajo>> consultarOrdenesPorEstado(String estado) async {
    return _ordenesTrabajo.where((o) => o.estado == estado).toList();
  }

  /// Obtiene órdenes de trabajo pendientes
  Future<List<OrdenTrabajo>> consultarOrdenesPendientes() async {
    return _ordenesTrabajo.where((o) => o.estado == 'pendiente').toList();
  }

  /// Obtiene órdenes de trabajo por técnico
  Future<List<OrdenTrabajo>> consultarOrdenesPorTecnico(String tecnicoId) async {
    return _ordenesTrabajo.where((o) => o.tecnicoAsignado == tecnicoId).toList();
  }

  /// Asigna una orden de trabajo a un técnico
  Future<OrdenTrabajo> asignarOrdenTrabajo(String id, String tecnicoId) async {
    final orden = await consultarOrdenTrabajo(id);
    if (orden == null) {
      throw Exception('Orden de trabajo no encontrada');
    }

    final ordenAsignada = orden.copyWith(tecnicoAsignado: tecnicoId);
    return await actualizarOrdenTrabajo(ordenAsignada);
  }

  /// Inicia una orden de trabajo
  Future<OrdenTrabajo> iniciarOrdenTrabajo(String id) async {
    final orden = await consultarOrdenTrabajo(id);
    if (orden == null) {
      throw Exception('Orden de trabajo no encontrada');
    }

    final ordenIniciada = orden.copyWith(
      estado: 'en_progreso',
      fechaInicio: DateTime.now(),
    );

    return await actualizarOrdenTrabajo(ordenIniciada);
  }

  /// Completa una orden de trabajo
  Future<OrdenTrabajo> completarOrdenTrabajo(String id, double costoReal, String observaciones) async {
    final orden = await consultarOrdenTrabajo(id);
    if (orden == null) {
      throw Exception('Orden de trabajo no encontrada');
    }

    final ordenCompletada = orden.copyWith(
      estado: 'completada',
      fechaFin: DateTime.now(),
      costoReal: costoReal,
      observaciones: observaciones,
    );

    return await actualizarOrdenTrabajo(ordenCompletada);
  }

  // ========== MÉTODOS PARA REGISTROS DE MANTENIMIENTO ==========

  /// Crea un nuevo registro de mantenimiento en MongoDB
  Future<RegistroMantenimiento> crearRegistroMantenimiento(RegistroMantenimiento registro) async {
    // Generar ID si no viene
    String registroId = registro.id;
    if (registroId.isEmpty) {
      registroId = ObjectId().toHexString();
    }

    final registroToInsert = registro.copyWith(id: registroId);
    await _dbService.insertarRegistroMantenimiento(registroToInsert.toMap());
    print('✅ Registro de mantenimiento guardado en MongoDB: ${registroToInsert.descripcionTrabajo} (ID: $registroId)');
    return registroToInsert;
  }

  /// Actualiza un registro de mantenimiento existente en MongoDB
  Future<RegistroMantenimiento> actualizarRegistroMantenimiento(RegistroMantenimiento registro) async {
    final existente = await consultarRegistroMantenimiento(registro.id);
    if (existente == null) {
      throw Exception('Registro de mantenimiento no encontrado');
    }

    await _dbService.actualizarRegistroMantenimiento(registro.toMap());
    print('✅ Registro de mantenimiento actualizado en MongoDB: ${registro.id}');
    return registro;
  }

  /// Obtiene un registro de mantenimiento por su ID desde MongoDB
  Future<RegistroMantenimiento?> consultarRegistroMantenimiento(String id) async {
    return await _dbService.consultarRegistroMantenimiento(id);
  }

  /// Obtiene todos los registros de mantenimiento desde MongoDB
  Future<List<RegistroMantenimiento>> consultarTodosRegistrosMantenimiento() async {
    return await _dbService.consultarTodosRegistrosMantenimiento();
  }

  /// Obtiene registros de mantenimiento por maquinaria desde MongoDB
  Future<List<RegistroMantenimiento>> consultarRegistrosPorMaquinaria(String maquinariaId) async {
    return await _dbService.consultarRegistrosMantenimientoPorMaquinaria(maquinariaId);
  }

  /// Obtiene registros de mantenimiento por estado desde MongoDB
  Future<List<RegistroMantenimiento>> consultarRegistrosPorEstado(String estado) async {
    return await _dbService.consultarRegistrosMantenimientoPorEstado(estado);
  }

  /// Obtiene registros de mantenimiento pendientes desde MongoDB
  Future<List<RegistroMantenimiento>> consultarRegistrosPendientes() async {
    return await consultarRegistrosPorEstado('pendiente');
  }

  /// Obtiene registros de mantenimiento completados desde MongoDB
  Future<List<RegistroMantenimiento>> consultarRegistrosCompletados() async {
    return await consultarRegistrosPorEstado('completado');
  }

  /// Marca un registro de mantenimiento como completado
  Future<RegistroMantenimiento> completarRegistroMantenimiento(
    String id, {
    DateTime? fechaRealizacion,
  }) async {
    final registro = await consultarRegistroMantenimiento(id);
    if (registro == null) {
      throw Exception('Registro de mantenimiento no encontrado');
    }

    final registroCompletado = registro.copyWith(
      estado: 'completado',
      fechaRealizacion: fechaRealizacion ?? DateTime.now(),
    );

    return await actualizarRegistroMantenimiento(registroCompletado);
  }

  /// Inicia un registro de mantenimiento
  Future<RegistroMantenimiento> iniciarRegistroMantenimiento(String id) async {
    final registro = await consultarRegistroMantenimiento(id);
    if (registro == null) {
      throw Exception('Registro de mantenimiento no encontrado');
    }

    final registroIniciado = registro.copyWith(
      estado: 'en_progreso',
    );

    return await actualizarRegistroMantenimiento(registroIniciado);
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  /// Evalúa si un análisis debe generar una alerta
  Future<void> _evaluarAlerta(Analisis analisis) async {
    if (analisis.resultado == 'critico' || analisis.resultado == 'advertencia') {
      final prioridad = analisis.resultado == 'critico' ? 'critica' : 'alta';
      
      final alerta = Alerta(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        maquinariaId: analisis.maquinariaId,
        tipoAlerta: 'mantenimiento',
        titulo: 'Análisis ${analisis.tipoAnalisis} - ${analisis.resultado.toUpperCase()}',
        descripcion: 'Se detectó un problema en el análisis de ${analisis.tipoAnalisis}. ${analisis.observaciones ?? ''}',
        prioridad: prioridad,
        fechaCreacion: DateTime.now(),
        datosAlerta: {
          'analisisId': analisis.id,
          'tipoAnalisis': analisis.tipoAnalisis,
          'valorMedido': analisis.valorMedido,
          'valorLimite': analisis.valorLimite,
        },
        accionesRequeridas: [
          'Revisar el equipo',
          'Programar mantenimiento preventivo',
          'Verificar condiciones de operación',
        ],
      );

      await crearAlerta(alerta);
    }
  }

  /// Genera un número de orden único
  Future<String> _generarNumeroOrden() async {
    final year = DateTime.now().year;
    final count = _ordenesTrabajo.length + 1;
    return 'OT-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Obtiene estadísticas de mantenimiento
  Future<Map<String, dynamic>> obtenerEstadisticasMantenimiento() async {
    final todosAnalisis = await consultarTodosAnalisis();
    final totalAnalisis = todosAnalisis.length;
    final analisisCriticos = todosAnalisis.where((a) => a.resultado == 'critico').length;
    final analisisAdvertencia = todosAnalisis.where((a) => a.resultado == 'advertencia').length;

    final totalAlertas = _alertas.length;
    final alertasActivas = _alertas.where((a) => a.estado == 'activa').length;
    final alertasCriticas = _alertas.where((a) => a.prioridad == 'critica').length;

    final totalOrdenes = _ordenesTrabajo.length;
    final ordenesPendientes = _ordenesTrabajo.where((o) => o.estado == 'pendiente').length;
    final ordenesEnProgreso = _ordenesTrabajo.where((o) => o.estado == 'en_progreso').length;
    final ordenesCompletadas = _ordenesTrabajo.where((o) => o.estado == 'completada').length;

    // Calcular costos de registros de mantenimiento completados
    final registrosCompletados = await consultarRegistrosCompletados();
    double costoTotal = 0.0;
    for (var registro in registrosCompletados) {
      costoTotal += registro.costoTotal;
    }

    return {
      'totalAnalisis': totalAnalisis,
      'analisisCriticos': analisisCriticos,
      'analisisAdvertencia': analisisAdvertencia,
      'totalAlertas': totalAlertas,
      'alertasActivas': alertasActivas,
      'alertasCriticas': alertasCriticas,
      'totalOrdenes': totalOrdenes,
      'ordenesPendientes': ordenesPendientes,
      'ordenesEnProgreso': ordenesEnProgreso,
      'ordenesCompletadas': ordenesCompletadas,
      'costoTotal': costoTotal, // Agregar costo total de mantenimientos completados
      'totalRegistrosCompletados': registrosCompletados.length,
    };
  }

  /// Inicializa datos de prueba
  /// NOTA: Este método ya no es necesario ya que los análisis se guardan en MongoDB
  /// Se mantiene por compatibilidad pero no hace nada
  static void inicializarDatosPrueba() {
    // Los análisis ahora se guardan en MongoDB, no en memoria
    // Este método se mantiene por compatibilidad pero está vacío
    return;
    /*
    // Crear análisis de prueba (deshabilitado - usar MongoDB)
    final _analisis = [
      Analisis(
        id: 'anal_1',
        maquinariaId: 'maq_1',
        tipoAnalisis: 'vibracion',
        fechaAnalisis: DateTime(2024, 1, 15),
        datosAnalisis: {
          'frecuencia': 50.5,
          'amplitud': 2.3,
          'temperatura': 45.0,
        },
        resultado: 'normal',
        valorMedido: 2.3,
        valorLimite: 5.0,
        observaciones: 'Vibraciones dentro de parámetros normales',
        tecnicoResponsable: 'user_1',
        fechaRegistro: DateTime(2024, 1, 15),
      ),
      Analisis(
        id: 'anal_2',
        maquinariaId: 'maq_2',
        tipoAnalisis: 'temperatura',
        fechaAnalisis: DateTime(2024, 1, 20),
        datosAnalisis: {
          'temperatura_motor': 95.0,
          'temperatura_aceite': 85.0,
          'presion_aceite': 3.2,
        },
        resultado: 'advertencia',
        valorMedido: 95.0,
        valorLimite: 90.0,
        observaciones: 'Temperatura del motor elevada, requiere atención',
        recomendaciones: 'Verificar sistema de refrigeración',
        tecnicoResponsable: 'user_1',
        fechaRegistro: DateTime(2024, 1, 20),
      ),
    ];

    // Crear alertas de prueba
    _alertas = [
      Alerta(
        id: 'alert_1',
        maquinariaId: 'maq_2',
        tipoAlerta: 'mantenimiento',
        titulo: 'Temperatura Elevada - Grúa LTM 1050',
        descripcion: 'La temperatura del motor está por encima de los límites normales',
        prioridad: 'alta',
        estado: 'activa',
        fechaCreacion: DateTime(2024, 1, 20),
        datosAlerta: {
          'analisisId': 'anal_2',
          'temperatura': 95.0,
          'limite': 90.0,
        },
        accionesRequeridas: [
          'Verificar sistema de refrigeración',
          'Revisar nivel de aceite',
          'Programar mantenimiento preventivo',
        ],
      ),
    ];

    // Crear órdenes de trabajo de prueba
    _ordenesTrabajo = [
      OrdenTrabajo(
        id: 'ot_1',
        numeroOrden: 'OT-2024-0001',
        maquinariaId: 'maq_2',
        tipoTrabajo: 'preventivo',
        prioridad: 'alta',
        estado: 'pendiente',
        descripcion: 'Mantenimiento preventivo del sistema de refrigeración',
        fechaCreacion: DateTime(2024, 1, 21),
        fechaVencimiento: DateTime(2024, 1, 25),
        costoEstimado: 500.0,
        tareas: [
          'Revisar nivel de refrigerante',
          'Limpiar radiador',
          'Verificar funcionamiento del termostato',
          'Cambiar filtro de aire',
        ],
        alertaId: 'alert_1',
      ),
    ];
    */
  }
}
