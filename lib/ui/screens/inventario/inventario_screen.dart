import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tracktoger/controllers/control_maquinaria.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/models/maquinaria.dart';
import 'package:tracktoger/models/categoria.dart';
import 'package:tracktoger/models/usuario.dart';
import 'package:tracktoger/core/auth_service.dart';
import '../maquinaria/registrar_maquinaria_screen.dart';
import '../herramientas/registrar_herramienta_screen.dart';
import '../maquinaria/detalles_maquinaria_screen.dart';
import '../maquinaria/editar_maquinaria_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String searchTerm = "";
  String estadoFilter = "todos";
  String categoriaFilter = "todos";
  List<Maquinaria> maquinaria = [];
  List<Categoria> categorias = [];
  Map<String, Usuario> _operadores = {};
  bool isLoading = true;
  Map<String, dynamic> stats = {};
  final ControlUsuario _controlUsuario = ControlUsuario();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final maquinariaList = await ControlMaquinaria()
          .consultarTodasMaquinarias();
      final categoriasList = await ControlMaquinaria()
          .consultarTodasCategorias();
      final estadisticas = await ControlMaquinaria()
          .obtenerEstadisticasMaquinaria();

      // Cargar información de operadores asignados
      final operadoresMap = <String, Usuario>{};
      for (var maq in maquinariaList) {
        if (maq.operadorAsignadoId != null &&
            maq.operadorAsignadoId!.isNotEmpty &&
            !operadoresMap.containsKey(maq.operadorAsignadoId)) {
          final operador = await _controlUsuario.consultarUsuario(
            maq.operadorAsignadoId!,
          );
          if (operador != null) {
            operadoresMap[maq.operadorAsignadoId!] = operador;
          }
        }
      }

      setState(() {
        maquinaria = maquinariaList;
        categorias = categoriasList;
        stats = estadisticas;
        _operadores = operadoresMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMaquinaria = maquinaria.where((item) {
      final nombre = item.nombre.toLowerCase();
      final modelo = item.modelo.toLowerCase();
      final marca = item.marca.toLowerCase();
      final matchesSearch =
          nombre.contains(searchTerm.toLowerCase()) ||
          modelo.contains(searchTerm.toLowerCase()) ||
          marca.contains(searchTerm.toLowerCase());
      final matchesEstado =
          estadoFilter == "todos" || item.estado == estadoFilter;
      final matchesCategoria =
          categoriaFilter == "todos" || item.categoriaId == categoriaFilter;
      return matchesSearch && matchesEstado && matchesCategoria;
    }).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isDark),
            // Botones de registro solo para administradores
            FutureBuilder<bool>(
              future: AuthService.esAdministrador(),
              builder: (context, snapshot) {
                final esAdmin = snapshot.data ?? false;
                if (!esAdmin) return const SizedBox.shrink();
                return _buildActionButtons();
              },
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStats(isDark),
              _buildFiltros(isDark),
              _buildLista(filteredMaquinaria, isDark),
            ],
            const SizedBox(height: 100), // Espacio para el footer
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
              : [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.green.shade100,
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
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Inventario",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                Text(
                  "Gestión completa de maquinaria",
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

  // Aquí agregamos los botones de acción (Registrar Maquinaria y Registrar Herramientas)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _showRegistroMaquinaria,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Color de fondo verde
            ),
            child: const Text(
              "Registrar Maquinaria", // Texto del botón
              style: TextStyle(
                color: Colors.white, // Color del texto (blanco)
                fontSize: 13, // Tamaño del texto
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _showRegistroHerramientas,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Color de fondo azul
            ),
            child: const Text(
              "Registrar Herramientas", // Texto del botón
              style: TextStyle(
                color: Colors.white, // Color del texto (blanco)
                fontSize: 13, // Tamaño del texto
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar el formulario de "Registrar Maquinaria"
  void _showRegistroMaquinaria() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrarMaquinariaScreen(),
      ),
    );
    if (result == true) {
      _loadData(); // Recargar datos después de registrar
    }
  }

  // Método para mostrar el formulario de "Registrar Herramientas"
  void _showRegistroHerramientas() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrarHerramientaScreen(),
      ),
    );
    if (result == true) {
      _loadData(); // Recargar datos después de registrar
    }
  }

  // Otros métodos como _buildStats, _buildFiltros, etc. siguen igual...

  Widget _buildStats(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statCard(
            "Total",
            stats['total']?.toString() ?? "0",
            Colors.blue,
            isDark,
          ),
          _statCard(
            "Disponibles",
            stats['disponibles']?.toString() ?? "0",
            Colors.green,
            isDark,
          ),
          _statCard(
            "Alquiladas",
            stats['alquiladas']?.toString() ?? "0",
            Colors.orange,
            isDark,
          ),
          _statCard(
            "Mantenimiento",
            stats['mantenimiento']?.toString() ?? "0",
            Colors.red,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color borderColor, bool isDark) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildFiltros(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => searchTerm = val),
            decoration: InputDecoration(
              hintText: "Buscar por nombre, modelo o tipo...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: estadoFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      [
                            "todos",
                            "disponible",
                            "alquilado",
                            "mantenimiento",
                            "fuera_servicio",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => estadoFilter = val!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: categoriaFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ["todos", ...categorias.map((c) => c.id).toList()]
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e == "todos"
                                ? "Todos"
                                : categorias
                                      .firstWhere(
                                        (c) => c.id == e,
                                        orElse: () => Categoria(
                                          id: '',
                                          nombre: '',
                                          descripcion: '',
                                          icono: '',
                                          color: '',
                                          especificacionesRequeridas: [],
                                          fechaCreacion: DateTime.now(),
                                        ),
                                      )
                                      .nombre,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => categoriaFilter = val!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<Maquinaria> lista, bool isDark) {
    if (lista.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "No se encontró maquinaria",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final item = lista[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetallesMaquinariaScreen(maquinaria: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen de la maquinaria
                  if (item.imagenes.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(item.imagenes.first),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.construction,
                        size: 40,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${item.marca} - ${item.modelo}",
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.ubicacion ?? "Sin ubicación",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              item.estadoAsignacion == 'asignado'
                                  ? Icons.person
                                  : Icons.person_outline,
                              size: 12,
                              color: item.estadoAsignacion == 'asignado'
                                  ? Colors.green.shade600
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.estadoAsignacion == 'asignado' &&
                                        _operadores.containsKey(item.operadorAsignadoId)
                                    ? '${_operadores[item.operadorAsignadoId]!.nombre} ${_operadores[item.operadorAsignadoId]!.apellido}'
                                    : 'Sin operador',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: item.estadoAsignacion == 'asignado'
                                      ? Colors.green.shade600
                                      : Colors.grey.shade500,
                                  fontWeight: item.estadoAsignacion == 'asignado'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 12,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "\$${item.valorAdquisicion.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: Colors.orange.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge de estado y botones de acción alineados
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _badgeEstado(item.estado),
                      const SizedBox(height: 8),
                      // Botones de acción (solo para admins)
                      FutureBuilder<bool>(
                        future: AuthService.esAdministrador(),
                        builder: (context, snapshot) {
                          final esAdmin = snapshot.data ?? false;
                          if (!esAdmin) {
                            return Icon(
                              Icons.chevron_right,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            );
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditarMaquinariaScreen(maquinaria: item),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadData();
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 20),
                                color: Colors.blue.shade600,
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                onPressed: () => _eliminarMaquinaria(item),
                                icon: const Icon(Icons.delete, size: 20),
                                color: Colors.red.shade600,
                                tooltip: 'Eliminar',
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _eliminarMaquinaria(Maquinaria maquinaria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de eliminar "${maquinaria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ControlMaquinaria().eliminarMaquinaria(maquinaria.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maquinaria eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar maquinaria: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _badgeEstado(String estado) {
    Color backgroundColor;
    Color textColor;
    switch (estado) {
      case "disponible":
        backgroundColor = Colors.green.shade600;
        textColor = Colors.white;
        break;
      case "alquilado":
        backgroundColor = Colors.blue.shade600;
        textColor = Colors.white;
        break;
      case "mantenimiento":
        backgroundColor = Colors.orange.shade600;
        textColor = Colors.white;
        break;
      case "fuera_servicio":
        backgroundColor = Colors.red.shade600;
        textColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.grey.shade600;
        textColor = Colors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
