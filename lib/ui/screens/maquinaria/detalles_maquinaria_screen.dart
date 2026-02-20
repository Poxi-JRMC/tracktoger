import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/maquinaria.dart';
import '../../../models/herramienta.dart';
import '../../../models/categoria.dart';
import '../../../models/usuario.dart';
import '../../../models/gasto_operativo.dart';
import '../../../controllers/control_herramienta.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../controllers/control_usuario.dart';
import '../../../controllers/control_gasto_operativo.dart';
import '../../../core/auth_service.dart';
import 'asignar_operador_screen.dart';
import '../gastos/registrar_gasto_screen.dart';
import '../gastos/historial_gastos_screen.dart' as gastos;

/// Pantalla para ver los detalles completos de una maquinaria
class DetallesMaquinariaScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const DetallesMaquinariaScreen({super.key, required this.maquinaria});

  @override
  State<DetallesMaquinariaScreen> createState() => _DetallesMaquinariaScreenState();
}

class _DetallesMaquinariaScreenState extends State<DetallesMaquinariaScreen> {
  final ControlHerramienta _controlHerramienta = ControlHerramienta();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlUsuario _controlUsuario = ControlUsuario();
  final ControlGastoOperativo _controlGasto = ControlGastoOperativo();
  List<Herramienta> _herramientas = [];
  List<Categoria> _categorias = [];
  Usuario? _operadorAsignado;
  List<GastoOperativo> _gastos = [];
  bool _loadingHerramientas = false;
  bool _loadingOperador = false;
  bool _loadingGastos = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loadingHerramientas = true;
      _loadingOperador = true;
      _loadingGastos = true;
    });
    try {
      final herramientas = await _controlHerramienta.consultarHerramientasPorMaquinaria(widget.maquinaria.id);
      final categorias = await _controlMaquinaria.consultarTodasCategorias();
      
      // Cargar operador asignado
      Usuario? operador;
      if (widget.maquinaria.operadorAsignadoId != null &&
          widget.maquinaria.operadorAsignadoId!.isNotEmpty) {
        operador = await _controlUsuario.consultarUsuario(
          widget.maquinaria.operadorAsignadoId!,
        );
      }

      // Cargar gastos operativos
      final gastos = await _controlGasto.consultarGastosPorMaquinaria(
        widget.maquinaria.id,
      );

      setState(() {
        _herramientas = herramientas;
        _categorias = categorias;
        _operadorAsignado = operador;
        _gastos = gastos;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
    } finally {
      setState(() {
        _loadingHerramientas = false;
        _loadingOperador = false;
        _loadingGastos = false;
      });
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'disponible':
        return Colors.green.shade600;
      case 'alquilado':
        return Colors.blue.shade600;
      case 'mantenimiento':
        return Colors.orange.shade600;
      case 'fuera_servicio':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _obtenerNombreEstado(String estado) {
    switch (estado) {
      case 'disponible':
        return 'Disponible';
      case 'alquilado':
        return 'Alquilado';
      case 'mantenimiento':
        return 'En Mantenimiento';
      case 'fuera_servicio':
        return 'Fuera de Servicio';
      default:
        return estado;
    }
  }

  String _obtenerNombreCategoria(String categoriaId) {
    try {
      final categoria = _categorias.firstWhere((c) => c.id == categoriaId);
      return categoria.nombre;
    } catch (e) {
      return 'Categoría no encontrada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Maquinaria'),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen principal
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              child: widget.maquinaria.imagenes.isNotEmpty
                  ? Image.memory(
                      base64Decode(widget.maquinaria.imagenes.first),
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.construction,
                      size: 100,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
            ),
            // Información principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.maquinaria.nombre,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _obtenerColorEstado(widget.maquinaria.estado).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _obtenerColorEstado(widget.maquinaria.estado),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _obtenerNombreEstado(widget.maquinaria.estado),
                          style: TextStyle(
                            color: _obtenerColorEstado(widget.maquinaria.estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.maquinaria.marca} ${widget.maquinaria.modelo}',
                    style: TextStyle(
                      fontSize: 20,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'S/N: ${widget.maquinaria.numeroSerie}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // Tarjetas de información
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoCard(
                    'Información General',
                    [
                      _buildInfoRow('Categoría', _obtenerNombreCategoria(widget.maquinaria.categoriaId), Icons.category, isDark),
                      _buildInfoRow('Ubicación', widget.maquinaria.ubicacion ?? 'No especificada', Icons.location_on, isDark),
                      _buildInfoRow('Valor', '\$${widget.maquinaria.valorAdquisicion.toStringAsFixed(0)}', Icons.attach_money, isDark),
                      _buildInfoRow('Fecha de Adquisición', _formatearFecha(widget.maquinaria.fechaAdquisicion), Icons.calendar_today, isDark),
                    ],
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Estado y Uso',
                    [
                      _buildInfoRow('Estado', _obtenerNombreEstado(widget.maquinaria.estado), Icons.info, isDark),
                      _buildInfoRow('Horas de Uso', '${widget.maquinaria.horasUso} horas', Icons.access_time, isDark),
                      _buildInfoRow('Último Mantenimiento', _formatearFecha(widget.maquinaria.fechaUltimoMantenimiento), Icons.build, isDark),
                    ],
                    isDark,
                  ),
                  // Operador asignado
                  const SizedBox(height: 16),
                  _buildOperadorCard(isDark),
                  // Gastos operativos
                  const SizedBox(height: 16),
                  _buildGastosCard(isDark),
                  if (widget.maquinaria.descripcion != null && widget.maquinaria.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Descripción',
                      [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            widget.maquinaria.descripcion!,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      isDark,
                    ),
                  ],
                  if (widget.maquinaria.especificaciones.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Especificaciones Técnicas',
                      widget.maquinaria.especificaciones.entries.map((entry) {
                        return _buildInfoRow(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          entry.value.toString(),
                          Icons.settings,
                          isDark,
                        );
                      }).toList(),
                      isDark,
                    ),
                  ],
                  // Herramientas asociadas
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Herramientas Asociadas',
                    [
                      if (_loadingHerramientas)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_herramientas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.build_circle_outlined,
                                  size: 48,
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No hay herramientas asociadas',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._herramientas.map((herramienta) => _buildHerramientaItem(herramienta, isDark)),
                    ],
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String titulo, List<Widget> children, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.green.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHerramientaItem(Herramienta herramienta, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Imagen de la herramienta
          if (herramienta.imagenes.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(herramienta.imagenes.first),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.build,
                size: 30,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  herramienta.nombre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${herramienta.tipo}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (herramienta.marca != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Marca: ${herramienta.marca}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _obtenerColorCondicion(herramienta.condicion).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _obtenerColorCondicion(herramienta.condicion),
                width: 1,
              ),
            ),
            child: Text(
              herramienta.condicion.toUpperCase(),
              style: TextStyle(
                color: _obtenerColorCondicion(herramienta.condicion),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorCondicion(String condicion) {
    switch (condicion) {
      case 'nueva':
        return Colors.green;
      case 'buena':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'desgastada':
        return Colors.deepOrange;
      case 'dañada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOperadorCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.maquinaria.estadoAsignacion == 'asignado'
                          ? Icons.person
                          : Icons.person_outline,
                      color: widget.maquinaria.estadoAsignacion == 'asignado'
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Operador Asignado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                FutureBuilder<bool>(
                  future: AuthService.esAdministrador(),
                  builder: (context, snapshot) {
                    final esAdmin = snapshot.data ?? false;
                    if (!esAdmin) return const SizedBox.shrink();
                    return IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AsignarOperadorScreen(
                              maquinaria: widget.maquinaria,
                            ),
                          ),
                        );
                        if (result == true) {
                          _cargarDatos();
                        }
                      },
                      icon: Icon(
                        widget.maquinaria.estadoAsignacion == 'asignado'
                            ? Icons.edit
                            : Icons.person_add,
                        color: Colors.blue.shade600,
                      ),
                      tooltip: widget.maquinaria.estadoAsignacion == 'asignado'
                          ? 'Cambiar operador'
                          : 'Asignar operador',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingOperador)
              const Center(child: CircularProgressIndicator())
            else if (widget.maquinaria.estadoAsignacion == 'asignado' && _operadorAsignado != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green.shade600, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_operadorAsignado!.nombre} ${_operadorAsignado!.apellido}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _operadorAsignado!.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey.shade600, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Sin operador asignado',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
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

  Widget _buildGastosCard(bool isDark) {
    final totalGastos = _gastos.fold<double>(0.0, (sum, g) => sum + g.monto);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Gastos Operativos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                FutureBuilder<bool>(
                  future: AuthService.esAdministrador(),
                  builder: (context, adminSnapshot) {
                    final esAdmin = adminSnapshot.data ?? false;
                    final usuarioActual = AuthService.usuarioActual;
                    
                    // Verificar si el operador actual está asignado a esta máquina
                    bool puedeRegistrarGasto = esAdmin;
                    if (!esAdmin && usuarioActual != null) {
                      puedeRegistrarGasto = widget.maquinaria.operadorAsignadoId == usuarioActual.id;
                    }

                    if (!puedeRegistrarGasto) {
                      return const SizedBox.shrink();
                    }

                    return IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegistrarGastoScreen(
                              maquinaria: widget.maquinaria,
                              operador: _operadorAsignado,
                            ),
                          ),
                        );
                        if (result == true) {
                          _cargarDatos();
                        }
                      },
                      icon: Icon(Icons.add, color: Colors.blue.shade600),
                      tooltip: 'Registrar gasto',
                    );
                  },
                ),
                FutureBuilder<bool>(
                  future: AuthService.esAdministrador(),
                  builder: (context, adminSnapshot) {
                    final esAdmin = adminSnapshot.data ?? false;
                    final usuarioActual = AuthService.usuarioActual;
                    
                    // Verificar si el operador actual está asignado a esta máquina
                    bool puedeVerHistorial = esAdmin;
                    if (!esAdmin && usuarioActual != null) {
                      puedeVerHistorial = widget.maquinaria.operadorAsignadoId == usuarioActual.id;
                    }

                    if (!puedeVerHistorial) {
                      return const SizedBox.shrink();
                    }

                    return IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => gastos.HistorialGastosScreen(
                              maquinaria: widget.maquinaria,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.history, color: Colors.blue.shade600),
                      tooltip: 'Ver historial',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingGastos)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Gastos',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalGastos.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Registros',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_gastos.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_gastos.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Últimos gastos:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._gastos.take(3).map((gasto) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gasto.tipoGasto.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                                if (gasto.descripcion != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    gasto.descripcion!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${gasto.monto.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              Text(
                                _formatearFecha(gasto.fecha),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                if (_gastos.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => gastos.HistorialGastosScreen(
                              maquinaria: widget.maquinaria,
                            ),
                          ),
                        );
                      },
                      child: const Text('Ver todos los gastos'),
                    ),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay gastos registrados',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
