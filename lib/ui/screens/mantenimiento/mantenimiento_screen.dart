import 'package:flutter/material.dart';
import '../../../models/registro_mantenimiento.dart';
import '../../../models/maquinaria.dart';
import '../../../models/falla_predicha.dart';
import '../../../models/mantenimiento_recordatorio.dart';
import '../../../models/analisis.dart';
import '../../../controllers/control_mantenimiento.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../controllers/control_ml.dart';
import '../../../config/mantenimiento_config.dart';
import 'diagnostico_arbol_screen.dart';
import 'registro_parametros_maquina_screen.dart';
import 'detalles_maquina_mantenimiento_screen.dart';
import 'crear_registro_mantenimiento_screen.dart';

/// Pantalla de mantenimiento predictivo mejorada
/// Visualiza análisis, alertas, órdenes de trabajo y mantenimientos predictivos basados en horas
class MantenimientoScreen extends StatefulWidget {
  const MantenimientoScreen({super.key});

  @override
  State<MantenimientoScreen> createState() => _MantenimientoScreenState();
}

class _MantenimientoScreenState extends State<MantenimientoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  
  List<RegistroMantenimiento> _registrosMantenimiento = [];
  List<Maquinaria> _maquinarias = [];
  bool _loading = false;
  String _filtroMantenimiento = 'todos';
  String? _filtroMaquinaria; // Filtro por maquinaria (null = todas)
  int _refreshKey = 0; // Clave para forzar reconstrucción de tarjetas

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Solo 2 pestañas: Predictivos, Mantenimientos
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  /// Carga los datos iniciales
  /// Optimizado: Carga datos en paralelo para mayor velocidad
  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Carga secuencial para no saturar Atlas M0 (evita "connection reset" al cambiar tabs)
      final registros = await _controlMantenimiento.consultarTodosRegistrosMantenimiento();
      final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
      
      if (mounted) {
        setState(() {
          _registrosMantenimiento = registros;
          _maquinarias = maquinarias;
          _refreshKey++; // Incrementar clave para forzar reconstrucción de tarjetas
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar datos: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Muestra un mensaje de error
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Muestra un mensaje de éxito
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Obtiene la lista filtrada de registros de mantenimiento
  List<RegistroMantenimiento> _obtenerRegistrosFiltrados() {
    var registros = _registrosMantenimiento;
    
    // Filtrar por estado
    if (_filtroMantenimiento != 'todos') {
      registros = registros.where((r) => r.estado == _filtroMantenimiento).toList();
    }
    
    // Filtrar por maquinaria
    if (_filtroMaquinaria != null) {
      registros = registros.where((r) => r.idMaquinaria == _filtroMaquinaria).toList();
    }
    
    return registros;
  }

  /// Obtiene el color del estado
  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_progreso':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(isDark),
          TabBar(
            controller: _tabController,
            labelColor: Colors.yellow,
            unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            indicatorColor: Colors.yellow,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Predictivos', icon: Icon(Icons.auto_awesome)),
              Tab(text: 'Mantenimientos', icon: Icon(Icons.build)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMantenimientosPredictivos(isDark),
                _buildListaMantenimientos(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el header de la pantalla
  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.blue.shade100,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mantenimiento Predictivo",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                Text(
                  "Gestión inteligente basada en horas de uso",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la pestaña de mantenimientos predictivos
  Widget _buildMantenimientosPredictivos(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Botón para registrar horas de uso
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.speed, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar Horas de Uso',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Actualiza el odómetro de la máquina',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
                            if (mounted && maquinarias.isNotEmpty) {
                              _mostrarDialogoRegistrarHoras(isDark);
                            } else {
                              _mostrarError('No hay máquinas registradas');
                            }
                          },
                          icon: const Icon(Icons.speed, size: 20),
                          label: const Text(
                            'Registrar Horas',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
                            if (mounted && maquinarias.isNotEmpty) {
                              _mostrarSelectorMaquina(maquinarias);
                            } else {
                              _mostrarError('No hay máquinas registradas');
                            }
                          },
                          icon: const Icon(Icons.add_chart, size: 20),
                          label: const Text(
                            'Parámetros',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Resumen de máquinas
          _buildResumenMaquinas(isDark),
          const SizedBox(height: 16),
          // Tarjetas de estado de cada máquina - SOLO mostrar estado simple
          if (_maquinarias.isNotEmpty) ...[
            Text(
              'Estado de Máquinas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ..._maquinarias.map((maq) => _buildTarjetaMaquinaSimple(maq, isDark)),
          ] else ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay máquinas registradas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye el resumen de máquinas
  Widget _buildResumenMaquinas(bool isDark) {
    final totalHoras = _maquinarias.fold<int>(0, (sum, m) => sum + m.horasUso);
    final promedioHoras = _maquinarias.isNotEmpty ? totalHoras / _maquinarias.length : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : [Colors.purple.shade50, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.purple.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Resumen de Flota',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Máquinas',
                    '${_maquinarias.length}',
                    Icons.construction,
                    Colors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Horas',
                    totalHoras.toString(),
                    Icons.speed,
                    Colors.orange,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Promedio',
                    promedioHoras.toStringAsFixed(0),
                    Icons.trending_up,
                    Colors.green,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una tarjeta de estado completo de máquina (DEPRECATED - no se usa más)
  // ignore: unused_element
  Widget _buildTarjetaEstadoMaquina(MLPrediction prediccion, bool isDark) {
    final estado = prediccion.estadoGeneral;
    final colorEstado = _obtenerColorEstadoGeneral(estado.estadoGeneral);
    final fallaMasProbable = prediccion.fallasPredichas.isNotEmpty
        ? prediccion.fallasPredichas.first
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorEstado.withOpacity(0.1),
              colorEstado.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorEstado, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado general
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorEstado.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _obtenerIconoEstadoGeneral(estado.estadoGeneral),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediccion.maquinariaNombre,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorEstado,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                estado.estadoGeneral.replaceAll('_', ' '),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Salud: ${estado.scoreSalud.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorEstado,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Falla más probable
                  if (fallaMasProbable != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _obtenerColorSeveridad(fallaMasProbable.severidad).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _obtenerColorSeveridad(fallaMasProbable.severidad),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: _obtenerColorSeveridad(fallaMasProbable.severidad),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FALLA MÁS PROBABLE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _obtenerColorSeveridad(fallaMasProbable.severidad),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fallaMasProbable.nombreFalla,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fallaMasProbable.descripcion,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _obtenerColorSeveridad(fallaMasProbable.severidad).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Probabilidad: ${fallaMasProbable.probabilidad.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _obtenerColorSeveridad(fallaMasProbable.severidad),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.psychology, size: 12, color: Colors.purple.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ML',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (fallaMasProbable.fechaEstimada != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '📅 Fecha estimada: ${_formatearFecha(fallaMasProbable.fechaEstimada!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Todas las fallas predichas
                  if (prediccion.fallasPredichas.isNotEmpty) ...[
                    Text(
                      'Fallas Predichas (${prediccion.fallasPredichas.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...prediccion.fallasPredichas.map((falla) => _buildTarjetaFallaPredicha(falla, isDark)),
                    const SizedBox(height: 16),
                  ],
                  // Recordatorios de mantenimiento
                  if (prediccion.recordatorios.isNotEmpty) ...[
                    Text(
                      'Recordatorios de Mantenimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...prediccion.recordatorios.map((recordatorio) => 
                      _buildTarjetaRecordatorio(recordatorio, isDark)
                    ),
                  ],
                  // Botón para ver diagnóstico completo del árbol
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final maquinaria = _maquinarias.firstWhere(
                          (m) => m.id == prediccion.maquinariaId,
                          orElse: () => Maquinaria(
                            id: prediccion.maquinariaId,
                            nombre: prediccion.maquinariaNombre,
                            numeroSerie: '',
                            categoriaId: '',
                            estado: 'disponible',
                            horasUso: 0,
                            fechaAdquisicion: DateTime.now(),
                            fechaUltimoMantenimiento: DateTime.now(),
                            modelo: 'N/A',
                            marca: 'N/A',
                            valorAdquisicion: 0.0,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiagnosticoArbolScreen(
                              maquinaria: maquinaria,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_tree, size: 20),
                      label: const Text(
                        'Ver Diagnóstico Completo por Sistemas',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el widget de recomendaciones con límite de 3 y botón "Ver más"
  Widget _buildRecomendacionesMantenimiento(Maquinaria maq, Color colorEstado) {
    final recomendaciones = _obtenerRecomendacionesMantenimiento(maq);
    final mostrarTodas = recomendaciones.length <= 3;
    final recomendacionesMostrar = mostrarTodas 
        ? recomendaciones 
        : recomendaciones.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recomendacionesMostrar.map((recomendacion) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: colorEstado),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recomendacion,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorEstado,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )),
        if (!mostrarTodas) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              // Navegar a la pantalla de detalles de la máquina para ver todas las recomendaciones
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetallesMaquinaMantenimientoScreen(maquinaria: maq),
                ),
              );
            },
            child: Row(
              children: [
                Icon(Icons.arrow_forward, size: 14, color: colorEstado),
                const SizedBox(width: 6),
                Text(
                  'Ver más recomendaciones (${recomendaciones.length - 3} más)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorEstado,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Obtiene recomendaciones de mantenimiento basadas en horas trabajadas
  List<String> _obtenerRecomendacionesMantenimiento(Maquinaria maq) {
    final recomendaciones = <String>[];
    final horasMotor = maq.horasDesdeUltimoMantenimientoMotor;
    final horasHidraulico = maq.horasDesdeUltimoMantenimientoHidraulico;
    
    // Recomendación para aceite de motor
    final horasRestantesMotor = MantenimientoConfig.calcularHorasRestantesAceiteMotor(horasMotor);
    if (horasRestantesMotor <= 50) {
      recomendaciones.add(MantenimientoConfig.obtenerMensajeAceiteMotor(horasRestantesMotor));
    }
    
    // Recomendación para aceite hidráulico
    final horasRestantesHidraulico = MantenimientoConfig.calcularHorasRestantesAceiteHidraulico(horasHidraulico);
    if (horasRestantesHidraulico <= 100) {
      recomendaciones.add(MantenimientoConfig.obtenerMensajeAceiteHidraulico(horasRestantesHidraulico));
    }
    
    // Recomendación para filtros
    final horasRestantesFiltros = MantenimientoConfig.calcularHorasRestantesFiltros(horasMotor);
    if (horasRestantesFiltros <= 50) {
      recomendaciones.add(MantenimientoConfig.obtenerMensajeFiltros(horasRestantesFiltros));
    }
    
    return recomendaciones;
  }

  /// Construye una tarjeta simple para máquinas - Muestra estado considerando horas Y análisis
  Widget _buildTarjetaMaquinaSimple(Maquinaria maq, bool isDark) {
    // Estado inicial: todo en cero si no hay datos registrados
    // Mostrar estado basado en horas trabajadas Y análisis recientes
    String estadoGeneral = 'SIN DATOS';
    Color colorEstado = Colors.grey;
    IconData iconoEstado = Icons.info_outline;
    
    // Verificar si hay horas trabajadas registradas
    final horasMotor = maq.horasDesdeUltimoMantenimientoMotor;
    final horasHidraulico = maq.horasDesdeUltimoMantenimientoHidraulico;
    final tieneDatos = horasMotor > 0 || horasHidraulico > 0 || maq.horasUso > 0;
    
    // Consultar análisis recientes (últimos 30 días) para determinar estado crítico
    final analisisFuturo = _controlMantenimiento.consultarAnalisisPorMaquinaria(maq.id);
    
    return FutureBuilder<List<Analisis>>(
      future: analisisFuturo,
      key: ValueKey('analisis_${maq.id}_$_refreshKey'), // Forzar reconstrucción cuando se recargan datos
      builder: (context, snapshot) {
        int analisisCriticos = 0;
        int analisisAdvertencia = 0;
        
        if (snapshot.hasData) {
          final ahora = DateTime.now();
          // PRIORIZAR análisis de los últimos 7 días (más recientes)
          final analisisUltimos7Dias = snapshot.data!.where((a) => 
            ahora.difference(a.fechaAnalisis).inDays <= 7
          ).toList();
          
          // SIEMPRE usar solo análisis de los últimos 7 días
          // Si hay análisis recientes, evaluar solo esos
          // Si NO hay análisis recientes, no hay problemas (todo normal)
          if (analisisUltimos7Dias.isNotEmpty) {
            // Hay análisis recientes: evaluar solo esos
            analisisCriticos = analisisUltimos7Dias.where((a) => a.resultado == 'critico').length;
            analisisAdvertencia = analisisUltimos7Dias.where((a) => a.resultado == 'advertencia').length;
          } else {
            // NO hay análisis recientes: no hay problemas detectados
            // Ignorar análisis antiguos (más de 7 días) porque no reflejan el estado actual
            analisisCriticos = 0;
            analisisAdvertencia = 0;
          }
        }
        
        // Determinar estado basado en horas Y análisis
        if (tieneDatos || analisisCriticos > 0 || analisisAdvertencia > 0) {
          // Prioridad 1: Si hay análisis críticos recientes, estado es URGENTE
          if (analisisCriticos > 0) {
            estadoGeneral = 'URGENTE';
            colorEstado = Colors.red;
            iconoEstado = Icons.error;
          } 
          // Prioridad 2: Si hay análisis de advertencia, estado es ALERTA
          else if (analisisAdvertencia > 0) {
            estadoGeneral = 'ALERTA';
            colorEstado = Colors.orange;
            iconoEstado = Icons.warning;
          }
          // Prioridad 3: Basado en horas trabajadas desde último mantenimiento
          else if (tieneDatos) {
            final horasMax = horasMotor > horasHidraulico ? horasMotor : horasHidraulico;
            
            if (horasMax >= 500) {
              estadoGeneral = 'URGENTE';
              colorEstado = Colors.red;
              iconoEstado = Icons.error;
            } else if (horasMax >= 400) {
              estadoGeneral = 'ALERTA';
              colorEstado = Colors.orange;
              iconoEstado = Icons.warning;
            } else if (horasMax >= 200) {
              estadoGeneral = 'ATENCIÓN';
              colorEstado = Colors.yellow.shade700;
              iconoEstado = Icons.info;
            } else {
              estadoGeneral = 'ÓPTIMO';
              colorEstado = Colors.green;
              iconoEstado = Icons.check_circle;
            }
          }
        }
        
        return _buildTarjetaMaquinaSimpleContent(maq, isDark, estadoGeneral, colorEstado, iconoEstado, analisisCriticos, analisisAdvertencia);
      },
    );
  }
  
  /// Construye el contenido de la tarjeta de máquina
  Widget _buildTarjetaMaquinaSimpleContent(
    Maquinaria maq, 
    bool isDark, 
    String estadoGeneral, 
    Color colorEstado, 
    IconData iconoEstado,
    int analisisCriticos,
    int analisisAdvertencia,
  ) {
    final horasMotor = maq.horasDesdeUltimoMantenimientoMotor;
    final horasHidraulico = maq.horasDesdeUltimoMantenimientoHidraulico;
    final tieneDatos = horasMotor > 0 || horasHidraulico > 0 || maq.horasUso > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navegar a detalles completos de la máquina
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetallesMaquinaMantenimientoScreen(maquinaria: maq),
            ),
          ).then((result) {
            // Recargar datos al volver para actualizar estados y probabilidades
            if (result == true || result == null) {
              _cargarDatos();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorEstado.withOpacity(0.1),
                colorEstado.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorEstado, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconoEstado, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maq.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${maq.horasUso} horas de uso',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    // Mostrar información de análisis si hay
                    if (analisisCriticos > 0 || analisisAdvertencia > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            analisisCriticos > 0 ? Icons.error : Icons.warning,
                            size: 14,
                            color: analisisCriticos > 0 ? Colors.red : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              analisisCriticos > 0
                                  ? '$analisisCriticos análisis crítico${analisisCriticos > 1 ? 's' : ''}'
                                  : '$analisisAdvertencia advertencia${analisisAdvertencia > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: analisisCriticos > 0 ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (tieneDatos) ...[
                      const SizedBox(height: 8),
                      _buildRecomendacionesMantenimiento(maq, colorEstado),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estadoGeneral,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorEstado),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye una tarjeta de falla predicha
  Widget _buildTarjetaFallaPredicha(FallaPredicha falla, bool isDark) {
    final color = _obtenerColorSeveridad(falla.severidad);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  falla.nombreFalla,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${falla.probabilidad.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            falla.descripcion,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          if (falla.sintomas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Síntomas: ${falla.sintomas.take(2).join(', ')}',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye una tarjeta de recordatorio de mantenimiento
  Widget _buildTarjetaRecordatorio(MantenimientoRecordatorio recordatorio, bool isDark) {
    final color = recordatorio.urgente ? Colors.red : Colors.orange;
    final icono = _obtenerIconoTipoMantenimiento(recordatorio.tipoMantenimiento);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: recordatorio.urgente ? Colors.red : Colors.orange.withOpacity(0.5),
          width: recordatorio.urgente ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recordatorio.descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (recordatorio.urgente)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'URGENTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Faltan ${recordatorio.horasRestantes} horas (Cada ${recordatorio.horasIntervalo} horas)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (recordatorio.fechaEstimada != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '📅 Fecha estimada: ${_formatearFecha(recordatorio.fechaEstimada!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el color según el estado general
  Color _obtenerColorEstadoGeneral(String estado) {
    switch (estado) {
      case 'OPTIMO':
        return Colors.green;
      case 'BUENO':
        return Colors.lightGreen;
      case 'REGULAR':
        return Colors.yellow;
      case 'MALO':
        return Colors.orange;
      case 'URGENTE_REPARACION':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el icono según el estado general
  IconData _obtenerIconoEstadoGeneral(String estado) {
    switch (estado) {
      case 'OPTIMO':
        return Icons.check_circle;
      case 'BUENO':
        return Icons.thumb_up;
      case 'REGULAR':
        return Icons.info;
      case 'MALO':
        return Icons.warning;
      case 'URGENTE_REPARACION':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  /// Obtiene el color según la severidad
  Color _obtenerColorSeveridad(String severidad) {
    switch (severidad) {
      case 'critica':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'media':
        return Colors.yellow;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Construye una tarjeta de estadística
  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }


  /// Obtiene el icono según el tipo de mantenimiento
  IconData _obtenerIconoTipoMantenimiento(String tipo) {
    switch (tipo) {
      case 'Cambio de Aceite':
        return Icons.oil_barrel;
      case 'Mantenimiento General':
        return Icons.build;
      case 'Revisión Mayor':
        return Icons.engineering;
      default:
        return Icons.warning;
    }
  }

  /// Formatea una fecha para mostrar
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  /// Muestra un selector de máquinas para registrar parámetros
  void _mostrarSelectorMaquina(List<Maquinaria> maquinarias) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona una máquina para registrar sus parámetros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...maquinarias.map((maq) => ListTile(
              leading: const Icon(Icons.construction),
              title: Text(maq.nombre),
              subtitle: Text('${maq.horasUso} horas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistroParametrosMaquinaScreen(maquinaria: maq),
                  ),
                );
                // Recargar datos después de registrar parámetros para actualizar estados
                if (result == true) {
                  _cargarDatos();
                }
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo para registrar horas de uso
  Future<void> _mostrarDialogoRegistrarHoras(bool isDark) async {
    if (_maquinarias.isEmpty) {
      _mostrarError('No hay máquinas registradas');
      return;
    }

    Maquinaria? maquinariaSeleccionada;
    final horasController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Calcular información cuando se selecciona una máquina
          double? horasTrabajadas;
          double? horasRestantesMotor;
          double? horasRestantesHidraulico;
          
          if (maquinariaSeleccionada != null && horasController.text.isNotEmpty) {
            final nuevasHoras = double.tryParse(horasController.text);
            if (nuevasHoras != null && nuevasHoras >= maquinariaSeleccionada!.horasUso) {
              horasTrabajadas = nuevasHoras - maquinariaSeleccionada!.horasUso;
              horasRestantesMotor = MantenimientoConfig.calcularHorasRestantesAceiteMotor(
                maquinariaSeleccionada!.horasDesdeUltimoMantenimientoMotor + horasTrabajadas
              );
              horasRestantesHidraulico = MantenimientoConfig.calcularHorasRestantesAceiteHidraulico(
                maquinariaSeleccionada!.horasDesdeUltimoMantenimientoHidraulico + horasTrabajadas
              );
            }
          }
          
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.speed, color: Colors.blue),
                SizedBox(width: 8),
                Text('Registrar Horas de Uso'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccione la máquina:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Maquinaria>(
                      value: maquinariaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Máquina',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.construction),
                      ),
                      items: _maquinarias.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('${m.nombre} (${m.horasUso} hrs)'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          maquinariaSeleccionada = value;
                          if (value != null) {
                            horasController.text = value.horasUso.toString();
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione una máquina';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ingrese las horas actuales del odómetro:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: horasController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Horas de Uso',
                        hintText: 'Ej: 1500',
                        prefixIcon: Icon(Icons.speed),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {}); // Recalcular información
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese las horas de uso';
                        }
                        final horas = double.tryParse(value);
                        if (horas == null || horas < 0) {
                          return 'Por favor ingrese un número válido';
                        }
                        if (maquinariaSeleccionada != null && horas < maquinariaSeleccionada!.horasUso) {
                          return 'Las horas no pueden ser menores a las actuales (${maquinariaSeleccionada!.horasUso})';
                        }
                        return null;
                      },
                    ),
                    // Mostrar información detallada si hay datos
                    if (maquinariaSeleccionada != null && horasTrabajadas != null && horasTrabajadas > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📊 Información de la Máquina',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRowDialog('Horas Actuales', '${maquinariaSeleccionada!.horasUso.toStringAsFixed(1)} hrs'),
                            _buildInfoRowDialog('Nuevas Horas', '${double.tryParse(horasController.text)?.toStringAsFixed(1) ?? "0"} hrs'),
                            _buildInfoRowDialog('Horas Trabajadas', '${horasTrabajadas.toStringAsFixed(1)} hrs', Colors.green),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              '🔧 Próximos Mantenimientos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (horasRestantesMotor != null)
                              _buildMantenimientoRowDialog(
                                'Aceite Motor',
                                horasRestantesMotor,
                                MantenimientoConfig.UMBRAL_CAMBIO_ACEITE_MOTOR_HORAS,
                              ),
                            if (horasRestantesHidraulico != null)
                              _buildMantenimientoRowDialog(
                                'Aceite Hidráulico',
                                horasRestantesHidraulico,
                                MantenimientoConfig.UMBRAL_CAMBIO_ACEITE_HIDRAULICO_HORAS,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate() && maquinariaSeleccionada != null) {
                    final horas = double.tryParse(horasController.text);
                    if (horas != null) {
                      Navigator.pop(context);
                      _registrarHorasUso(maquinariaSeleccionada!, horas);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Registrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Registra las horas de uso de una máquina (horómetro)
  Future<void> _registrarHorasUso(Maquinaria maquinaria, double nuevasHoras) async {
    if (!mounted) return;
    try {
      setState(() => _loading = true);
      final horasAnteriores = maquinaria.horasUso;
      await _controlMaquinaria.actualizarHorasUso(maquinaria.id, nuevasHoras);
      await _cargarDatos();
      
      if (!mounted) return;
      
      // Recargar la máquina actualizada
      final maquinariaActualizada = await _controlMaquinaria.consultarMaquinaria(maquinaria.id);
      if (maquinariaActualizada != null && mounted) {
        final horasTrabajadas = nuevasHoras - horasAnteriores;
        final horasRestantesMotor = MantenimientoConfig.calcularHorasRestantesAceiteMotor(
          maquinariaActualizada.horasDesdeUltimoMantenimientoMotor
        );
        final horasRestantesHidraulico = MantenimientoConfig.calcularHorasRestantesAceiteHidraulico(
          maquinariaActualizada.horasDesdeUltimoMantenimientoHidraulico
        );
        
        final mensaje = '''
✅ Horas registradas exitosamente

📊 Resumen:
• Horas anteriores: ${horasAnteriores.toStringAsFixed(1)} hrs
• Horas nuevas: ${nuevasHoras.toStringAsFixed(1)} hrs
• Horas trabajadas: ${horasTrabajadas.toStringAsFixed(1)} hrs

🔧 Próximos Mantenimientos:
• Aceite Motor: ${horasRestantesMotor > 0 ? 'En ${horasRestantesMotor.toStringAsFixed(0)} hrs' : 'URGENTE - Ya vencido'}
• Aceite Hidráulico: ${horasRestantesHidraulico > 0 ? 'En ${horasRestantesHidraulico.toStringAsFixed(0)} hrs' : 'URGENTE - Ya vencido'}
''';
        _mostrarExito(mensaje);
      } else if (mounted) {
        _mostrarExito('Horas registradas: ${horasAnteriores.toStringAsFixed(1)} → ${nuevasHoras.toStringAsFixed(1)} horas');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al registrar horas: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  /// Helper para construir fila de información en el diálogo
  Widget _buildInfoRowDialog(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Helper para construir fila de mantenimiento en el diálogo
  Widget _buildMantenimientoRowDialog(String tipo, double horasRestantes, double umbral) {
    final isUrgente = horasRestantes <= 0;
    final isProximo = horasRestantes <= (umbral * 0.2); // 20% del umbral
    final color = isUrgente ? Colors.red : (isProximo ? Colors.orange : Colors.green);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tipo,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                isUrgente 
                    ? 'URGENTE' 
                    : 'En ${horasRestantes.toStringAsFixed(0)} hrs',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye la lista de registros de mantenimiento
  Widget _buildListaMantenimientos(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final registrosFiltrados = _obtenerRegistrosFiltrados();

    return Column(
      children: [
        // Botón para crear nuevo registro
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrearRegistroMantenimientoScreen(),
                  ),
                );
                if (result == true) {
                  _cargarDatos();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Registro de Mantenimiento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        // Filtros
        _buildFiltrosMantenimientos(isDark),
        // Lista
        Expanded(
          child: registrosFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_outlined,
                        size: 64,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay registros de mantenimiento',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildListaMantenimientosAgrupados(registrosFiltrados, isDark),
        ),
      ],
    );
  }

  /// Construye los filtros de mantenimientos
  Widget _buildFiltrosMantenimientos(bool isDark) {
    return Column(
      children: [
        // Filtro por estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Estado:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChipFiltroMantenimiento('todos', 'Todos', isDark),
                      _buildChipFiltroMantenimiento('pendiente', 'Pendientes', isDark),
                      _buildChipFiltroMantenimiento('en_progreso', 'En Progreso', isDark),
                      _buildChipFiltroMantenimiento('completado', 'Completados', isDark),
                      _buildChipFiltroMantenimiento('cancelado', 'Cancelados', isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Filtro por maquinaria
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Máquina:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChipFiltroMaquinaria(null, 'Todas', isDark),
                      ..._maquinarias.map((maq) => 
                        _buildChipFiltroMaquinaria(maq.id, maq.nombre, isDark)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye un chip de filtro para mantenimientos
  Widget _buildChipFiltroMantenimiento(String valor, String texto, bool isDark) {
    final isSelected = _filtroMantenimiento == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(texto),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroMantenimiento = valor;
          });
        },
        selectedColor: Colors.yellow.shade200,
        checkmarkColor: Colors.black,
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        labelStyle: TextStyle(
          color: isSelected 
              ? Colors.black 
              : (isDark ? Colors.white : Colors.grey.shade800),
        ),
      ),
    );
  }

  /// Construye un chip de filtro para maquinaria
  Widget _buildChipFiltroMaquinaria(String? valor, String texto, bool isDark) {
    final isSelected = _filtroMaquinaria == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(texto),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroMaquinaria = valor;
          });
        },
        selectedColor: Colors.blue.shade200,
        checkmarkColor: Colors.black,
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        labelStyle: TextStyle(
          color: isSelected 
              ? Colors.black 
              : (isDark ? Colors.white : Colors.grey.shade800),
          fontSize: 12,
        ),
      ),
    );
  }

  /// Construye la lista de mantenimientos agrupados por máquina
  Widget _buildListaMantenimientosAgrupados(List<RegistroMantenimiento> registros, bool isDark) {
    // Agrupar registros por máquina
    final Map<String, List<RegistroMantenimiento>> registrosPorMaquina = {};
    
    for (var registro in registros) {
      final maquinaId = registro.idMaquinaria;
      if (!registrosPorMaquina.containsKey(maquinaId)) {
        registrosPorMaquina[maquinaId] = [];
      }
      registrosPorMaquina[maquinaId]!.add(registro);
    }
    
    // Ordenar por fecha más reciente primero
    registrosPorMaquina.forEach((key, value) {
      value.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: registrosPorMaquina.length,
      itemBuilder: (context, index) {
        final maquinaId = registrosPorMaquina.keys.elementAt(index);
        final registrosMaquina = registrosPorMaquina[maquinaId]!;
        
        // Buscar la máquina
        final maquinaria = _maquinarias.firstWhere(
          (m) => m.id == maquinaId,
          orElse: () => Maquinaria(
            id: '',
            nombre: 'Máquina no encontrada',
            modelo: '',
            marca: '',
            numeroSerie: '',
            categoriaId: '',
            fechaAdquisicion: DateTime.now(),
            valorAdquisicion: 0,
            fechaUltimoMantenimiento: DateTime.now(),
          ),
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la máquina
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.construction,
                      color: Colors.yellow.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maquinaria.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${registrosMaquina.length} mantenimiento${registrosMaquina.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de mantenimientos de esta máquina
              ...registrosMaquina.map((registro) => 
                _buildTarjetaRegistroMantenimiento(registro, isDark, mostrarMaquina: false)
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye una tarjeta de registro de mantenimiento
  Widget _buildTarjetaRegistroMantenimiento(RegistroMantenimiento registro, bool isDark, {bool mostrarMaquina = true}) {
    // Buscar la máquina asociada
    final maquinaria = _maquinarias.firstWhere(
      (m) => m.id == registro.idMaquinaria,
      orElse: () => Maquinaria(
        id: '',
        nombre: 'Máquina no encontrada',
        modelo: '',
        marca: '',
        numeroSerie: '',
        categoriaId: '',
        fechaAdquisicion: DateTime.now(),
        valorAdquisicion: 0,
        fechaUltimoMantenimiento: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mostrarMaquina)
                        Text(
                          maquinaria.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      if (mostrarMaquina) const SizedBox(height: 4),
                      Text(
                        registro.descripcionTrabajo,
                        style: TextStyle(
                          fontSize: mostrarMaquina ? 14 : 16,
                          fontWeight: mostrarMaquina ? FontWeight.normal : FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _obtenerColorEstado(registro.estado).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _obtenerColorEstado(registro.estado),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    registro.estado.toUpperCase(),
                    style: TextStyle(
                      color: _obtenerColorEstado(registro.estado),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.build,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  registro.tipoMantenimiento,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.priority_high,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  registro.estado == 'pendiente' ? 'Pendiente' : 'Activo',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                const SizedBox(width: 4),
                Text(
                  'Bs ${registro.costoTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (registro.estado == 'pendiente') ...[
                  ElevatedButton.icon(
                    onPressed: () => _iniciarMantenimiento(registro),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Iniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (registro.estado == 'en_progreso') ...[
                  ElevatedButton.icon(
                    onPressed: () => _completarMantenimiento(registro),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Completar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _editarMantenimiento(registro),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Inicia un mantenimiento
  Future<void> _iniciarMantenimiento(RegistroMantenimiento registro) async {
    if (!mounted) return;
    try {
      final actualizado = registro.copyWith(estado: 'en_progreso');
      await _controlMantenimiento.actualizarRegistroMantenimiento(actualizado);
      if (mounted) {
        _cargarDatos();
        _mostrarExito('Mantenimiento iniciado');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error: $e');
      }
    }
  }

  /// Completa un mantenimiento
  Future<void> _completarMantenimiento(RegistroMantenimiento registro) async {
    if (!mounted) return;
    try {
      final actualizado = registro.copyWith(
        estado: 'completado',
        fechaRealizacion: DateTime.now(),
      );
      await _controlMantenimiento.actualizarRegistroMantenimiento(actualizado);
      
      // Resetear horas de mantenimiento según el tipo de trabajo realizado
      final descripcion = registro.descripcionTrabajo.toLowerCase();
      String tipoReset = 'ambos'; // Por defecto resetear ambos
      
      if (descripcion.contains('motor') && !descripcion.contains('hidráulico') && !descripcion.contains('hidraulico')) {
        tipoReset = 'motor';
      } else if ((descripcion.contains('hidráulico') || descripcion.contains('hidraulico')) && !descripcion.contains('motor')) {
        tipoReset = 'hidraulico';
      }
      // Si contiene ambos o no especifica, resetear ambos
      
      // Resetear las horas de mantenimiento
      await _controlMaquinaria.resetearHorasMantenimiento(registro.idMaquinaria, tipoReset);
      
      if (mounted) {
        _cargarDatos();
        _mostrarExito('Mantenimiento completado y horas reseteadas');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error: $e');
      }
    }
  }

  /// Edita un mantenimiento
  Future<void> _editarMantenimiento(RegistroMantenimiento registro) async {
    if (!mounted) return;
    
    // Buscar la maquinaria asociada
    final maquinaria = _maquinarias.firstWhere(
      (m) => m.id == registro.idMaquinaria,
      orElse: () => _maquinarias.isNotEmpty ? _maquinarias.first : Maquinaria(
        id: '',
        nombre: 'Máquina no encontrada',
        modelo: '',
        marca: '',
        numeroSerie: '',
        categoriaId: '',
        fechaAdquisicion: DateTime.now(),
        valorAdquisicion: 0,
        fechaUltimoMantenimiento: DateTime.now(),
      ),
    );
    
    // Navegar a la pantalla de edición (reutilizando CrearRegistroMantenimientoScreen)
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearRegistroMantenimientoScreen(
          maquinaria: maquinaria,
          registroEditar: registro, // Pasar el registro a editar
        ),
      ),
    );
    
    if (resultado == true && mounted) {
      _cargarDatos();
    }
  }
}
