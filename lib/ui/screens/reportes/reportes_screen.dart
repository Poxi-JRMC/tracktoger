import 'package:flutter/material.dart';
import '../../../models/reporte.dart';
import '../../../models/indicador.dart';
import '../../../controllers/control_reportes.dart';

/// Pantalla de reportes e indicadores
/// Genera reportes y visualiza indicadores KPI
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ControlReportes _controlReportes = ControlReportes();

  List<Reporte> _reportes = [];
  List<Indicador> _indicadores = [];
  bool _loading = false;
  String _filtroReporte = 'todos';
  String _filtroIndicador = 'todos';

  // Controladores para el formulario de reporte
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _tipoReporteSeleccionado = 'disponibilidad';
  String _formatoSeleccionado = 'pdf';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Carga los datos iniciales
  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final reportes = await _controlReportes.consultarTodosReportes();
      final indicadores = await _controlReportes.consultarTodosIndicadores();

      setState(() {
        _reportes = reportes;
        _indicadores = indicadores;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Muestra un mensaje de error
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  /// Muestra un mensaje de éxito
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  /// Limpia el formulario
  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _tipoReporteSeleccionado = 'disponibilidad';
    _formatoSeleccionado = 'pdf';
    _fechaInicio = null;
    _fechaFin = null;
  }

  /// Genera un nuevo reporte
  Future<void> _generarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final reporte = Reporte(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        nombre: _nombreController.text.trim(),
        tipo: _tipoReporteSeleccionado,
        descripcion: _descripcionController.text.trim(),
        fechaGeneracion: DateTime.now(),
        usuarioGeneracion: 'user_1',
        formato: _formatoSeleccionado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      await _controlReportes.generarReporte(reporte, context);
      await _cargarDatos();
      _limpiarFormulario();
      _mostrarExito('Reporte generado exitosamente');
    } catch (e) {
      _mostrarError('Error al generar reporte: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Calcula todos los indicadores
  Future<void> _calcularIndicadores() async {
    setState(() => _loading = true);
    try {
      await _controlReportes.calcularTodosIndicadores();
      await _cargarDatos();
      _mostrarExito('Indicadores calculados exitosamente');
    } catch (e) {
      _mostrarError('Error al calcular indicadores: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Obtiene la lista filtrada de reportes
  List<Reporte> _obtenerReportesFiltrados() {
    if (_filtroReporte == 'todos') {
      return _reportes;
    }
    return _reportes.where((r) => r.tipo == _filtroReporte).toList();
  }

  /// Obtiene la lista filtrada de indicadores
  List<Indicador> _obtenerIndicadoresFiltrados() {
    if (_filtroIndicador == 'todos') {
      return _indicadores;
    }
    return _indicadores.where((i) => i.categoria == _filtroIndicador).toList();
  }

  /// Obtiene el color del estado
  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'completado':
        return Colors.green;
      case 'generando':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el color del estado del indicador
  Color _obtenerColorEstadoIndicador(String estado) {
    switch (estado) {
      case 'bueno':
        return Colors.green;
      case 'regular':
        return Colors.orange;
      case 'malo':
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
            unselectedLabelColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            indicatorColor: Colors.yellow,
            tabs: const [
              Tab(text: 'Indicadores', icon: Icon(Icons.analytics)),
              Tab(text: 'Reportes', icon: Icon(Icons.description)),
              Tab(text: 'Generar', icon: Icon(Icons.add_chart)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaIndicadores(isDark),
                _buildListaReportes(isDark),
                _buildFormularioReporte(isDark),
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
            child: const Icon(Icons.analytics, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reportes e Indicadores",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              Text(
                "KPIs y análisis del sistema",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _calcularIndicadores,
            icon: const Icon(Icons.refresh, color: Colors.yellow),
            tooltip: 'Recalcular indicadores',
          ),
        ],
      ),
    );
  }

  /// Construye la lista de indicadores
  Widget _buildListaIndicadores(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final indicadoresFiltrados = _obtenerIndicadoresFiltrados();

    if (indicadoresFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay indicadores registrados',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFiltrosIndicadores(isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: indicadoresFiltrados.length,
            itemBuilder: (context, index) {
              final indicador = indicadoresFiltrados[index];
              return _buildTarjetaIndicador(indicador, isDark);
            },
          ),
        ),
      ],
    );
  }

  /// Construye los filtros de indicadores
  Widget _buildFiltrosIndicadores(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Filtrar por categoría:',
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
                  _buildChipFiltroIndicador('todos', 'Todos', isDark),
                  _buildChipFiltroIndicador(
                    'disponibilidad',
                    'Disponibilidad',
                    isDark,
                  ),
                  _buildChipFiltroIndicador(
                    'rentabilidad',
                    'Rentabilidad',
                    isDark,
                  ),
                  _buildChipFiltroIndicador(
                    'mantenimiento',
                    'Mantenimiento',
                    isDark,
                  ),
                  _buildChipFiltroIndicador('alquileres', 'Alquileres', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un chip de filtro para indicadores
  Widget _buildChipFiltroIndicador(String valor, String texto, bool isDark) {
    final isSelected = _filtroIndicador == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(texto),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroIndicador = valor;
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

  /// Construye una tarjeta de indicador
  Widget _buildTarjetaIndicador(Indicador indicador, bool isDark) {
    final tendencia = indicador.valorAnterior != null
        ? indicador.valorActual - indicador.valorAnterior!
        : 0.0;
    final esPositivo = tendencia >= 0;

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
                      Text(
                        indicador.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        indicador.descripcion,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _obtenerColorEstadoIndicador(
                      indicador.estado,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _obtenerColorEstadoIndicador(indicador.estado),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    indicador.estado.toUpperCase(),
                    style: TextStyle(
                      color: _obtenerColorEstadoIndicador(indicador.estado),
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
                Text(
                  '${indicador.valorActual.toStringAsFixed(1)}${indicador.unidad}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 16),
                if (indicador.valorObjetivo != null) ...[
                  Text(
                    'Objetivo: ${indicador.valorObjetivo!.toStringAsFixed(1)}${indicador.unidad}',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            if (indicador.valorAnterior != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    esPositivo ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: esPositivo ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${esPositivo ? '+' : ''}${tendencia.toStringAsFixed(1)}${indicador.unidad}',
                    style: TextStyle(
                      color: esPositivo ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'vs anterior',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  indicador.categoria,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${indicador.fechaCalculo.day}/${indicador.fechaCalculo.month}/${indicador.fechaCalculo.year}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la lista de reportes
  Widget _buildListaReportes(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reportesFiltrados = _obtenerReportesFiltrados();

    if (reportesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reportes generados',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFiltrosReportes(isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reportesFiltrados.length,
            itemBuilder: (context, index) {
              final reporte = reportesFiltrados[index];
              return _buildTarjetaReporte(reporte, isDark);
            },
          ),
        ),
      ],
    );
  }

  /// Construye los filtros de reportes
  Widget _buildFiltrosReportes(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Filtrar por tipo:',
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
                  _buildChipFiltroReporte('todos', 'Todos', isDark),
                  _buildChipFiltroReporte(
                    'disponibilidad',
                    'Disponibilidad',
                    isDark,
                  ),
                  _buildChipFiltroReporte('financiero', 'Financiero', isDark),
                  _buildChipFiltroReporte(
                    'mantenimiento',
                    'Mantenimiento',
                    isDark,
                  ),
                  _buildChipFiltroReporte('inventario', 'Inventario', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un chip de filtro para reportes
  Widget _buildChipFiltroReporte(String valor, String texto, bool isDark) {
    final isSelected = _filtroReporte == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(texto),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroReporte = valor;
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

  /// Construye una tarjeta de reporte
  Widget _buildTarjetaReporte(Reporte reporte, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _obtenerColorEstado(reporte.estado),
          child: Icon(_obtenerIconoEstado(reporte.estado), color: Colors.white),
        ),
        title: Text(
          reporte.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reporte.descripcion),
            Text(
              '${reporte.tipo} • ${reporte.formato.toUpperCase()} • ${reporte.fechaGeneracion.day}/${reporte.fechaGeneracion.month}/${reporte.fechaGeneracion.year}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reporte.estado == 'completado' && reporte.archivoUrl != null)
              IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () => _descargarReporte(reporte),
              ),
            IconButton(
              icon: const Icon(Icons.info, color: Colors.grey),
              onPressed: () => _verDetallesReporte(reporte),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario de reporte
  Widget _buildFormularioReporte(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Reporte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del reporte',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: const Icon(Icons.info),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _tipoReporteSeleccionado,
                            decoration: InputDecoration(
                              labelText: 'Tipo de reporte',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'disponibilidad',
                                child: Text('Disponibilidad'),
                              ),
                              DropdownMenuItem(
                                value: 'financiero',
                                child: Text('Financiero'),
                              ),
                              DropdownMenuItem(
                                value: 'mantenimiento',
                                child: Text('Mantenimiento'),
                              ),
                              DropdownMenuItem(
                                value: 'inventario',
                                child: Text('Inventario'),
                              ),
                              DropdownMenuItem(
                                value: 'alquileres',
                                child: Text('Alquileres'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _tipoReporteSeleccionado =
                                    value ?? 'disponibilidad';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _formatoSeleccionado,
                            decoration: InputDecoration(
                              labelText: 'Formato',
                              prefixIcon: const Icon(Icons.file_download),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pdf',
                                child: Text('PDF'),
                              ),
                              DropdownMenuItem(
                                value: 'excel',
                                child: Text('Excel'),
                              ),
                              DropdownMenuItem(
                                value: 'csv',
                                child: Text('CSV'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _formatoSeleccionado = value ?? 'pdf';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Período del Reporte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              _fechaInicio != null
                                  ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                  : 'Fecha de inicio',
                            ),
                            subtitle: const Text('Seleccionar fecha'),
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) {
                                setState(() {
                                  _fechaInicio = fecha;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              _fechaFin != null
                                  ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                                  : 'Fecha de fin',
                            ),
                            subtitle: const Text('Seleccionar fecha'),
                            onTap: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate:
                                    _fechaInicio ??
                                    DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) {
                                setState(() {
                                  _fechaFin = fecha;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _generarReporte,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Generar Reporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene el icono del estado
  IconData _obtenerIconoEstado(String estado) {
    switch (estado) {
      case 'completado':
        return Icons.check_circle;
      case 'generando':
        return Icons.schedule;
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Descarga un reporte
  void _descargarReporte(Reporte reporte) {
    // TODO: Implementar descarga de reporte
    _mostrarExito('Funcionalidad de descarga en desarrollo');
  }

  /// Ve los detalles de un reporte
  void _verDetallesReporte(Reporte reporte) {
    // TODO: Implementar vista de detalles
    _mostrarExito('Funcionalidad de detalles en desarrollo');
  }
}
