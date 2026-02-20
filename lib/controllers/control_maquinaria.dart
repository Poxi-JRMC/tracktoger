import 'package:mongo_dart/mongo_dart.dart';
import '../models/maquinaria.dart';
import '../models/categoria.dart';
import '../data/services/database_service.dart';
import '../controllers/control_usuario.dart';

/// Controlador para la gestión de maquinaria
/// Maneja las operaciones CRUD de maquinaria usando MongoDB
class ControlMaquinaria {
  final DatabaseService _dbService = DatabaseService();

  // ========== MÉTODOS PARA MAQUINARIA ==========

  /// Registra una nueva maquinaria en el inventario
  Future<Maquinaria> registrarMaquinaria(Maquinaria maquinaria) async {
    // Generar ID si no viene
    String maquinariaId = maquinaria.id;
    if (maquinariaId.isEmpty) {
      maquinariaId = ObjectId().toHexString();
    }

    // Validar categoría si se proporciona (opcional, no bloquea el registro)
    if (maquinaria.categoriaId.isNotEmpty) {
      final categoria = await consultarCategoria(maquinaria.categoriaId);
      if (categoria == null) {
        print('⚠️ Advertencia: Categoría ${maquinaria.categoriaId} no encontrada, pero se continuará con el registro');
      }
    }

    // Validar que el número de serie sea único
    final todas = await consultarTodasMaquinarias();
    if (todas.any((m) => m.numeroSerie == maquinaria.numeroSerie && m.id != maquinariaId)) {
      throw Exception('Ya existe una maquinaria con ese número de serie');
    }

    final maquinariaToInsert = maquinaria.copyWith(id: maquinariaId);
    await _dbService.insertarMaquinaria(maquinariaToInsert.toMap());
    print('✅ Maquinaria registrada en MongoDB: ${maquinariaToInsert.nombre} (ID: $maquinariaId)');
    return maquinariaToInsert;
  }

  /// Actualiza una maquinaria existente
  Future<Maquinaria> actualizarMaquinaria(Maquinaria maquinaria) async {
    final existente = await consultarMaquinaria(maquinaria.id);
    if (existente == null) {
      throw Exception('Maquinaria no encontrada');
    }

    // Validar número de serie único (excepto para la misma maquinaria)
    final todas = await consultarTodasMaquinarias();
    if (todas.any((m) => m.numeroSerie == maquinaria.numeroSerie && m.id != maquinaria.id)) {
      throw Exception('Ya existe otra maquinaria con ese número de serie');
    }

    await _dbService.actualizarMaquinaria(maquinaria.toMap());
    return maquinaria;
  }

  /// Obtiene una maquinaria por su ID
  Future<Maquinaria?> consultarMaquinaria(String id) async {
    return await _dbService.consultarMaquinaria(id);
  }

  /// Obtiene todas las maquinarias
  Future<List<Maquinaria>> consultarTodasMaquinarias({bool soloActivas = true}) async {
    return await _dbService.consultarTodasMaquinarias(soloActivas: soloActivas);
  }

  /// Obtiene maquinarias por categoría
  Future<List<Maquinaria>> consultarMaquinariasPorCategoria(
    String categoriaId,
  ) async {
    final todas = await consultarTodasMaquinarias();
    return todas.where((m) => m.categoriaId == categoriaId).toList();
  }

  /// Obtiene maquinarias por estado
  Future<List<Maquinaria>> consultarMaquinariasPorEstado(String estado) async {
    final todas = await consultarTodasMaquinarias();
    return todas.where((m) => m.estado == estado).toList();
  }

  /// Obtiene maquinarias disponibles para alquiler
  Future<List<Maquinaria>> consultarMaquinariasDisponibles() async {
    final todas = await consultarTodasMaquinarias();
    return todas
        .where((m) => m.estado == 'disponible' && m.activo)
        .toList();
  }

  /// Elimina una maquinaria (desactiva)
  Future<bool> eliminarMaquinaria(String id) async {
    return await _dbService.eliminarMaquinaria(id);
  }

  /// Actualiza el estado de una maquinaria
  Future<Maquinaria> actualizarEstadoMaquinaria(
    String id,
    String nuevoEstado,
  ) async {
    final maquinaria = await consultarMaquinaria(id);
    if (maquinaria == null) {
      throw Exception('Maquinaria no encontrada');
    }

    return await actualizarMaquinaria(maquinaria.copyWith(estado: nuevoEstado));
  }

  /// Actualiza las horas de uso de una maquinaria y calcula horas trabajadas
  /// Las horas trabajadas se suman a las horas desde último mantenimiento
  Future<Maquinaria> actualizarHorasUso(
    String id,
    double nuevasHoras,
  ) async {
    final maquinaria = await consultarMaquinaria(id);
    if (maquinaria == null) {
      throw Exception('Maquinaria no encontrada');
    }

    // Validar que las nuevas horas no sean menores a las actuales
    if (nuevasHoras < maquinaria.horasUso) {
      throw Exception('Las nuevas horas no pueden ser menores a las actuales (${maquinaria.horasUso})');
    }

    // Calcular horas trabajadas (diferencia entre nuevas y anteriores)
    final horasTrabajadas = nuevasHoras - maquinaria.horasUso;

    // Sumar las horas trabajadas a los contadores de horas desde último mantenimiento
    final nuevasHorasMotor = maquinaria.horasDesdeUltimoMantenimientoMotor + horasTrabajadas;
    final nuevasHorasHidraulico = maquinaria.horasDesdeUltimoMantenimientoHidraulico + horasTrabajadas;

    return await actualizarMaquinaria(
      maquinaria.copyWith(
        horasUso: nuevasHoras.toInt(),
        horasDesdeUltimoMantenimientoMotor: nuevasHorasMotor,
        horasDesdeUltimoMantenimientoHidraulico: nuevasHorasHidraulico,
      ),
    );
  }

  /// Resetea las horas desde último mantenimiento según el tipo
  /// tipo: 'motor', 'hidraulico', 'ambos'
  Future<Maquinaria> resetearHorasMantenimiento(
    String id,
    String tipo, // 'motor', 'hidraulico', 'ambos'
  ) async {
    final maquinaria = await consultarMaquinaria(id);
    if (maquinaria == null) {
      throw Exception('Maquinaria no encontrada');
    }

    double nuevasHorasMotor = maquinaria.horasDesdeUltimoMantenimientoMotor;
    double nuevasHorasHidraulico = maquinaria.horasDesdeUltimoMantenimientoHidraulico;

    if (tipo == 'motor' || tipo == 'ambos') {
      nuevasHorasMotor = 0.0;
    }
    if (tipo == 'hidraulico' || tipo == 'ambos') {
      nuevasHorasHidraulico = 0.0;
    }

    return await actualizarMaquinaria(
      maquinaria.copyWith(
        horasDesdeUltimoMantenimientoMotor: nuevasHorasMotor,
        horasDesdeUltimoMantenimientoHidraulico: nuevasHorasHidraulico,
        fechaUltimoMantenimiento: DateTime.now(),
      ),
    );
  }

  /// Obtiene estadísticas de maquinaria
  Future<Map<String, dynamic>> obtenerEstadisticasMaquinaria() async {
    final todas = await consultarTodasMaquinarias();
    final total = todas.length;
    final disponibles = todas.where((m) => m.estado == 'disponible').length;
    final alquiladas = todas.where((m) => m.estado == 'alquilado').length;
    final mantenimiento = todas.where((m) => m.estado == 'mantenimiento').length;
    final fueraServicio = todas.where((m) => m.estado == 'fuera_servicio').length;

    return {
      'total': total,
      'disponibles': disponibles,
      'alquiladas': alquiladas,
      'mantenimiento': mantenimiento,
      'fueraServicio': fueraServicio,
      'porcentajeDisponibilidad': total > 0
          ? (disponibles / total * 100).round()
          : 0,
    };
  }

  // ========== MÉTODOS PARA CATEGORÍAS ==========
  // Nota: Las categorías se mantienen en memoria por ahora
  // Si necesitas persistirlas en MongoDB, se puede agregar después

  static List<Categoria> _categorias = [];

  /// Crea una nueva categoría
  Future<Categoria> crearCategoria(Categoria categoria) async {
    if (_categorias.any((c) => c.nombre == categoria.nombre)) {
      throw Exception('Ya existe una categoría con ese nombre');
    }
    _categorias.add(categoria);
    return categoria;
  }

  /// Obtiene una categoría por su ID
  Future<Categoria?> consultarCategoria(String id) async {
    try {
      return _categorias.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las categorías
  Future<List<Categoria>> consultarTodasCategorias() async {
    return List.from(_categorias);
  }

  /// Inicializa datos de prueba (categorías)
  static void inicializarDatosPrueba() {
    _categorias = [
      Categoria(
        id: 'cat_1',
        nombre: 'Excavadoras',
        descripcion: 'Maquinaria pesada para excavación',
        icono: 'excavator',
        color: '#2196F3',
        especificacionesRequeridas: ['peso', 'capacidad_cuchara', 'motor'],
        fechaCreacion: DateTime.now(),
      ),
      Categoria(
        id: 'cat_2',
        nombre: 'Grúas',
        descripcion: 'Equipos para elevación de cargas',
        icono: 'crane',
        color: '#FF9800',
        especificacionesRequeridas: [
          'capacidad_carga',
          'altura_maxima',
          'alcance',
        ],
        fechaCreacion: DateTime.now(),
      ),
      Categoria(
        id: 'cat_3',
        nombre: 'Compactadoras',
        descripcion: 'Equipos para compactación de suelos',
        icono: 'compactor',
        color: '#4CAF50',
        especificacionesRequeridas: [
          'peso',
          'frecuencia_vibracion',
          'amplitud',
        ],
        fechaCreacion: DateTime.now(),
      ),
      Categoria(
        id: 'cat_4',
        nombre: 'Pala Hidráulica',
        descripcion: 'Equipos de carga y excavación con sistema hidráulico',
        icono: 'loader',
        color: '#9C27B0',
        especificacionesRequeridas: [
          'peso',
          'capacidad_cuchara',
          'motor',
          'capacidad_carga',
        ],
        fechaCreacion: DateTime.now(),
      ),
      Categoria(
        id: 'cat_5',
        nombre: 'Motoniveladora',
        descripcion: 'Equipos para nivelación y perfilado de terrenos',
        icono: 'grader',
        color: '#F44336',
        especificacionesRequeridas: [
          'peso',
          'ancho_hoja',
          'motor',
          'alcance_hoja',
        ],
        fechaCreacion: DateTime.now(),
      ),
    ];
  }

  // ========== MÉTODOS PARA ASIGNACIÓN DE OPERADORES ==========

  /// Asigna un operador a una maquinaria
  Future<Maquinaria> asignarOperador(
    String maquinariaId,
    String operadorId,
  ) async {
    print('🔍 AsignarOperador: maquinariaId=$maquinariaId, operadorId=$operadorId');
    
    if (maquinariaId.isEmpty) {
      print('❌ ID de maquinaria vacío');
      throw Exception('ID de maquinaria no válido');
    }

    final maquinaria = await consultarMaquinaria(maquinariaId);
    if (maquinaria == null) {
      print('❌ Maquinaria no encontrada con ID: $maquinariaId');
      throw Exception('Maquinaria no encontrada con ID: $maquinariaId');
    }

    print('✅ Maquinaria encontrada: ${maquinaria.nombre} (ID: ${maquinaria.id})');

    // Verificar que el operador existe
    final controlUsuario = ControlUsuario();
    final operador = await controlUsuario.consultarUsuario(operadorId);
    if (operador == null) {
      print('❌ Operador no encontrado con ID: $operadorId');
      throw Exception('Operador no encontrado');
    }

    print('✅ Operador encontrado: ${operador.nombre} ${operador.apellido}');

    final maquinariaActualizada = maquinaria.copyWith(
      operadorAsignadoId: operadorId,
      estadoAsignacion: 'asignado',
    );

    print('🔄 Actualizando maquinaria con operador asignado...');
    final resultado = await actualizarMaquinaria(maquinariaActualizada);
    print('✅ Maquinaria actualizada exitosamente');
    
    return resultado;
  }

  /// Libera un operador de una maquinaria
  Future<Maquinaria> liberarOperador(String maquinariaId) async {
    final maquinaria = await consultarMaquinaria(maquinariaId);
    if (maquinaria == null) {
      throw Exception('Maquinaria no encontrada');
    }

    final maquinariaActualizada = maquinaria.copyWith(
      operadorAsignadoId: null,
      estadoAsignacion: 'libre',
    );

    return await actualizarMaquinaria(maquinariaActualizada);
  }

  /// Obtiene maquinarias asignadas a un operador
  Future<List<Maquinaria>> consultarMaquinariasPorOperador(
    String operadorId,
  ) async {
    final todas = await consultarTodasMaquinarias();
    return todas
        .where((m) => m.operadorAsignadoId == operadorId && m.activo)
        .toList();
  }
}
