import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/control_alquiler.dart';
import '../../../controllers/control_cliente.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../models/alquiler.dart';
import '../../../models/cliente.dart';
import '../../../models/maquinaria.dart';
import '../../../core/auth_service.dart';
import 'registrar_alquiler_screen.dart';
import 'detalles_alquiler_screen.dart';
import 'gestion_clientes_screen.dart';
import 'registrar_entrega_screen.dart';
import 'registrar_devolucion_screen.dart';

class AlquileresScreen extends StatefulWidget {
  const AlquileresScreen({super.key});

  @override
  State<AlquileresScreen> createState() => _AlquileresScreenState();
}

class _AlquileresScreenState extends State<AlquileresScreen> {
  final ControlAlquiler _controlAlquiler = ControlAlquiler();
  final ControlCliente _controlCliente = ControlCliente();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  
  List<Alquiler> _alquileres = [];
  Map<String, Cliente> _clientes = {};
  Map<String, Maquinaria> _maquinarias = {};
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _filtroEstado = 'todos';
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  Future<void> _verificarPermisos() async {
    final esAdmin = await AuthService.esAdministrador();
    setState(() {
      _esAdmin = esAdmin;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Carga secuencial para no saturar Atlas M0 (evita "connection reset")
      final alquileresList = await _controlAlquiler.consultarTodosAlquileres(
        estado: _filtroEstado == 'todos' ? null : _filtroEstado,
      );
      final clientesList = await _controlCliente.consultarTodosClientes();
      final maquinariasList = await _controlMaquinaria.consultarTodasMaquinarias();
      final estadisticas = await _controlAlquiler.obtenerEstadisticasAlquileres();

      // Crear mapas para acceso rápido
      final clientesMap = <String, Cliente>{};
      for (var cliente in clientesList) {
        clientesMap[cliente.id] = cliente;
      }

      final maquinariasMap = <String, Maquinaria>{};
      for (var maq in maquinariasList) {
        maquinariasMap[maq.id] = maq;
      }

      setState(() {
        _alquileres = alquileresList;
        _clientes = clientesMap;
        _maquinarias = maquinariasMap;
        _stats = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar datos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alquileresFiltrados = _alquileres;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isDark),
            if (_esAdmin) _buildActionButtons(isDark),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStatsCards(isDark),
              _buildFiltros(isDark),
              _buildListaAlquileres(alquileresFiltrados, isDark),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month,
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
                  "Alquileres",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                Text(
                  _esAdmin ? "Gestión de Alquileres" : "Ver Alquileres",
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

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegistrarAlquilerScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Registrar Alquiler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GestionClientesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Clientes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCard(
            _stats['pendientes']?.toString() ?? "0",
            "Pendientes",
            Colors.orange,
            isDark,
          ),
          _statCard(
            _stats['entregados']?.toString() ?? "0",
            "Entregados",
            Colors.blue,
            isDark,
          ),
          _statCard(
            _stats['devueltos']?.toString() ?? "0",
            "Devueltos",
            Colors.green,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filtroEstado,
              decoration: InputDecoration(
                labelText: 'Filtrar por estado',
                prefixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              ),
              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente_entrega', child: Text('Pendientes a Entregar')),
                DropdownMenuItem(value: 'entregada', child: Text('Entregadas')),
                DropdownMenuItem(value: 'devuelta', child: Text('Devueltas')),
                DropdownMenuItem(value: 'cancelado', child: Text('Cancelados')),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroEstado = value ?? 'todos';
                });
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAlquileres(List<Alquiler> alquileres, bool isDark) {
    if (alquileres.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No hay alquileres registrados",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lista de Alquileres",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ...alquileres.map((alquiler) => _buildAlquilerCard(alquiler, isDark)),
        ],
      ),
    );
  }

  Widget _buildAlquilerCard(Alquiler alquiler, bool isDark) {
    final cliente = _clientes[alquiler.clienteId];
    final maquinaria = _maquinarias[alquiler.maquinariaId];
    final fechaFormat = DateFormat('dd/MM/yyyy');

    Color estadoColor;
    String estadoLabel;
    switch (alquiler.estado) {
      case 'pendiente_entrega':
        estadoColor = Colors.orange;
        estadoLabel = 'Pendiente a Entregar';
        break;
      case 'entregada':
        estadoColor = Colors.blue;
        estadoLabel = 'Entregada';
        break;
      case 'devuelta':
        estadoColor = Colors.green;
        estadoLabel = 'Devuelta';
        break;
      case 'cancelado':
        estadoColor = Colors.red;
        estadoLabel = 'Cancelado';
        break;
      default:
        estadoColor = Colors.grey;
        estadoLabel = alquiler.estado.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetallesAlquilerScreen(alquiler: alquiler),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente?.nombreCompleto ?? 'Cliente no encontrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        if (maquinaria != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            maquinaria.nombre,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estadoLabel,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${fechaFormat.format(alquiler.fechaInicio)} - ${fechaFormat.format(alquiler.fechaFin)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (_esAdmin) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '\$${alquiler.monto.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (!_esAdmin && alquiler.estado == 'pendiente_entrega') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegistrarEntregaScreen(alquiler: alquiler),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.local_shipping, size: 16),
                      label: const Text('Registrar Entrega'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
              if (!_esAdmin && alquiler.estado == 'entregada') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegistrarDevolucionScreen(alquiler: alquiler),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Registrar Devolución'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
