import 'package:flutter/material.dart';
import '../../../models/maquinaria.dart';
import '../../../models/usuario.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../controllers/control_usuario.dart';

/// Pantalla para asignar o liberar un operador de una maquinaria
class AsignarOperadorScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const AsignarOperadorScreen({super.key, required this.maquinaria});

  @override
  State<AsignarOperadorScreen> createState() => _AsignarOperadorScreenState();
}

class _AsignarOperadorScreenState extends State<AsignarOperadorScreen> {
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlUsuario _controlUsuario = ControlUsuario();
  
  List<Usuario> _operadores = [];
  String? _operadorSeleccionado;
  Usuario? _operadorActual;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      // Cargar todos los usuarios y roles
      final usuarios = await _controlUsuario.consultarTodosUsuarios();
      final roles = await _controlUsuario.consultarTodosRoles();
      
      // Buscar el ID del rol "Operador"
      String? operadorRoleId;
      for (var rol in roles) {
        final nombreRol = rol.nombre.toLowerCase();
        if (nombreRol.contains('operador') || nombreRol.contains('operator')) {
          operadorRoleId = rol.id;
          break;
        }
      }

      // Filtrar solo operadores (usuarios con rol Operador)
      List<Usuario> operadores = [];
      if (operadorRoleId != null) {
        operadores = usuarios.where((u) => 
          u.activo && 
          u.roles.isNotEmpty && 
          u.roles.contains(operadorRoleId!)
        ).toList();
      } else {
        // Si no se encuentra el rol, mostrar todos los usuarios activos
        operadores = usuarios.where((u) => u.activo).toList();
      }

      // Obtener el operador actual si existe
      Usuario? operadorActual;
      if (widget.maquinaria.operadorAsignadoId != null &&
          widget.maquinaria.operadorAsignadoId!.isNotEmpty) {
        operadorActual = await _controlUsuario.consultarUsuario(
          widget.maquinaria.operadorAsignadoId!,
        );
      }

      setState(() {
        _operadores = operadores;
        _operadorActual = operadorActual;
        _operadorSeleccionado = widget.maquinaria.operadorAsignadoId;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _asignarOperador() async {
    if (_operadorSeleccionado == null || _operadorSeleccionado!.isEmpty) {
      _mostrarError('Por favor seleccione un operador');
      return;
    }

    print('🔍 AsignarOperadorScreen: ID de maquinaria=${widget.maquinaria.id}');
    print('🔍 AsignarOperadorScreen: ID de operador seleccionado=$_operadorSeleccionado');

    // Recargar la maquinaria desde la BD para asegurar que tenemos el ID correcto
    Maquinaria? maquinariaActualizada;
    try {
      maquinariaActualizada = await _controlMaquinaria.consultarMaquinaria(widget.maquinaria.id);
      if (maquinariaActualizada == null) {
        print('❌ No se pudo recargar la maquinaria desde la BD');
        _mostrarError('No se pudo encontrar la maquinaria. Por favor, intente nuevamente.');
        return;
      }
      print('✅ Maquinaria recargada desde BD: ${maquinariaActualizada.nombre} (ID: ${maquinariaActualizada.id})');
    } catch (e) {
      print('❌ Error al recargar maquinaria: $e');
      _mostrarError('Error al verificar la maquinaria: $e');
      return;
    }

    setState(() => _loading = true);
    try {
      await _controlMaquinaria.asignarOperador(
        maquinariaActualizada.id,
        _operadorSeleccionado!,
      );
      
      if (mounted) {
        _mostrarExito('Operador asignado correctamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error en AsignarOperadorScreen: $e');
      _mostrarError('Error al asignar operador: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _liberarOperador() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Liberación'),
        content: const Text('¿Está seguro de liberar el operador de esta maquinaria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _loading = true);
    try {
      await _controlMaquinaria.liberarOperador(widget.maquinaria.id);
      
      if (mounted) {
        _mostrarExito('Operador liberado correctamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarError('Error al liberar operador: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Operador'),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: _loading && _operadores.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información de la maquinaria
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.construction, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Maquinaria',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.maquinaria.nombre,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '${widget.maquinaria.marca} ${widget.maquinaria.modelo}',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Estado actual
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Estado Actual',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.maquinaria.estadoAsignacion == 'asignado'
                                  ? Colors.green.shade50
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.maquinaria.estadoAsignacion == 'asignado'
                                    ? Colors.green.shade600
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  widget.maquinaria.estadoAsignacion == 'asignado'
                                      ? 'Asignado'
                                      : 'Libre',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.maquinaria.estadoAsignacion == 'asignado'
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                if (_operadorActual != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${_operadorActual!.nombre} ${_operadorActual!.apellido}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Selector de operador
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_add, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Seleccionar Operador',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _operadorSeleccionado,
                            decoration: InputDecoration(
                              labelText: 'Operador',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                            ),
                            dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Ninguno (Liberar)'),
                              ),
                              ..._operadores.map((operador) {
                                return DropdownMenuItem<String>(
                                  value: operador.id,
                                  child: Text('${operador.nombre} ${operador.apellido}'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _operadorSeleccionado = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botones de acción
                  Row(
                    children: [
                      if (widget.maquinaria.estadoAsignacion == 'asignado')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loading ? null : _liberarOperador,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.orange.shade600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Liberar Operador',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (widget.maquinaria.estadoAsignacion == 'asignado')
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _asignarOperador,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  widget.maquinaria.estadoAsignacion == 'asignado'
                                      ? 'Cambiar Operador'
                                      : 'Asignar Operador',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

