import 'package:flutter/material.dart';
import '../../../models/gasto_operativo.dart';
import '../../../models/maquinaria.dart';
import '../../../models/usuario.dart';
import '../../../controllers/control_gasto_operativo.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../controllers/control_usuario.dart';
import '../../../core/auth_service.dart';

/// Pantalla para registrar un nuevo gasto operativo
class RegistrarGastoScreen extends StatefulWidget {
  final Maquinaria? maquinaria;
  final Usuario? operador;

  const RegistrarGastoScreen({
    super.key,
    this.maquinaria,
    this.operador,
  });

  @override
  State<RegistrarGastoScreen> createState() => _RegistrarGastoScreenState();
}

class _RegistrarGastoScreenState extends State<RegistrarGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  final ControlGastoOperativo _controlGasto = ControlGastoOperativo();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlUsuario _controlUsuario = ControlUsuario();

  List<Maquinaria> _maquinarias = [];
  List<Usuario> _operadores = [];
  String _tipoGastoSeleccionado = 'pasajes';
  String? _maquinariaSeleccionada;
  String? _operadorSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  bool _loading = false;
  bool _esOperador = false;
  bool _operadorBloqueado = false; // Si el operador viene predefinido, bloquear edición

  final List<String> _tiposGasto = [
    'pasajes',
    'comida',
    'transporte',
    'combustible',
    'peaje',
    'hospedaje',
    'otros',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final usuarioActual = AuthService.usuarioActual;
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

      // Verificar si el usuario actual es operador
      bool esOperador = false;
      if (usuarioActual != null && operadorRoleId != null) {
        esOperador = usuarioActual.roles.contains(operadorRoleId);
      }

      List<Maquinaria> maquinariasDisponibles = [];
      List<Usuario> operadores = [];

      if (esOperador) {
        // Si es operador, solo puede ver sus máquinas asignadas
        maquinariasDisponibles = await _controlMaquinaria.consultarMaquinariasPorOperador(
          usuarioActual!.id,
        );
        
        // Si no tiene máquinas asignadas, no puede registrar gastos
        if (maquinariasDisponibles.isEmpty) {
          if (mounted) {
            _mostrarError('No tienes maquinarias asignadas. No puedes registrar gastos.');
            Navigator.pop(context);
          }
          return;
        }

        // El operador solo puede registrar gastos para sí mismo
        _operadorSeleccionado = usuarioActual.id;
        _operadorBloqueado = true;

        // Si viene una maquinaria específica, verificar que esté asignada al operador
        if (widget.maquinaria != null) {
          final maqAsignada = maquinariasDisponibles.any(
            (m) => m.id == widget.maquinaria!.id,
          );
          if (maqAsignada) {
            _maquinariaSeleccionada = widget.maquinaria!.id;
          } else {
            // Si la maquinaria no está asignada, usar la primera disponible
            _maquinariaSeleccionada = maquinariasDisponibles.first.id;
          }
        } else {
          _maquinariaSeleccionada = maquinariasDisponibles.first.id;
        }

        // Obtener el operador asignado de la maquinaria seleccionada
        if (_maquinariaSeleccionada != null) {
          final maqSeleccionada = maquinariasDisponibles.firstWhere(
            (m) => m.id == _maquinariaSeleccionada,
          );
          if (maqSeleccionada.operadorAsignadoId != null &&
              maqSeleccionada.operadorAsignadoId!.isNotEmpty) {
            _operadorSeleccionado = maqSeleccionada.operadorAsignadoId;
          }
        }
      } else {
        // Si es admin, puede ver todas las maquinarias y operadores
        maquinariasDisponibles = await _controlMaquinaria.consultarTodasMaquinarias();
        final usuarios = await _controlUsuario.consultarTodosUsuarios();

        if (operadorRoleId != null) {
          operadores = usuarios.where((u) => 
            u.activo && 
            u.roles.isNotEmpty && 
            u.roles.contains(operadorRoleId!)
          ).toList();
        } else {
          operadores = usuarios.where((u) => u.activo).toList();
        }

        // Si se pasó maquinaria, seleccionarla y obtener su operador asignado
        if (widget.maquinaria != null) {
          _maquinariaSeleccionada = widget.maquinaria!.id;
          final maq = maquinariasDisponibles.firstWhere(
            (m) => m.id == widget.maquinaria!.id,
            orElse: () => widget.maquinaria!,
          );
          if (maq.operadorAsignadoId != null && maq.operadorAsignadoId!.isNotEmpty) {
            _operadorSeleccionado = maq.operadorAsignadoId;
            _operadorBloqueado = true; // Bloquear si viene de la máquina
          }
        }

        // Si se pasó operador explícitamente, usarlo
        if (widget.operador != null) {
          _operadorSeleccionado = widget.operador!.id;
          _operadorBloqueado = true;
        }
      }

      setState(() {
        _maquinarias = maquinariasDisponibles;
        _operadores = operadores;
        _esOperador = esOperador;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _registrarGasto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_maquinariaSeleccionada == null || _maquinariaSeleccionada!.isEmpty) {
      _mostrarError('Por favor seleccione una maquinaria');
      return;
    }

    if (_operadorSeleccionado == null || _operadorSeleccionado!.isEmpty) {
      _mostrarError('Por favor seleccione un operador');
      return;
    }

    setState(() => _loading = true);
    try {
      final gasto = GastoOperativo(
        id: '', // Se generará automáticamente por el controlador
        tipoGasto: _tipoGastoSeleccionado,
        monto: double.parse(_montoController.text),
        fecha: _fechaSeleccionada,
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        maquinariaId: _maquinariaSeleccionada!,
        operadorId: _operadorSeleccionado!,
        fechaRegistro: DateTime.now(),
      );

      await _controlGasto.registrarGastoOperativo(gasto);

      if (mounted) {
        _mostrarExito('Gasto registrado correctamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarError('Error al registrar gasto: $e');
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
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Gasto Operativo'),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: _loading && _maquinarias.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información básica
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
                                Icon(Icons.info_outline, color: Colors.blue.shade400),
                                const SizedBox(width: 8),
                                Text(
                                  'Información Básica',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _tipoGastoSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Gasto',
                                prefixIcon: const Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              items: _tiposGasto.map((tipo) {
                                return DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _tipoGastoSeleccionado = value ?? 'pasajes';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Seleccione un tipo de gasto';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _montoController,
                              decoration: InputDecoration(
                                labelText: 'Monto',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El monto es requerido';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Ingrese un monto válido';
                                }
                                final monto = double.parse(value);
                                if (monto <= 0) {
                                  return 'El monto debe ser mayor a 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _seleccionarFecha,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Fecha',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                ),
                                child: Text(
                                  '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descripcionController,
                              decoration: InputDecoration(
                                labelText: 'Descripción (opcional)',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Asociaciones
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
                                Icon(Icons.link, color: Colors.blue.shade400),
                                const SizedBox(width: 8),
                                Text(
                                  'Asociaciones',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _maquinariaSeleccionada,
                              decoration: InputDecoration(
                                labelText: 'Maquinaria',
                                prefixIcon: const Icon(Icons.construction),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              items: _maquinarias.map((maq) {
                                return DropdownMenuItem(
                                  value: maq.id,
                                  child: Text(maq.nombre),
                                );
                              }).toList(),
                              onChanged: _esOperador ? null : (value) {
                                setState(() {
                                  _maquinariaSeleccionada = value;
                                  // Actualizar operador asignado cuando cambia la maquinaria
                                  if (value != null) {
                                    final maq = _maquinarias.firstWhere(
                                      (m) => m.id == value,
                                    );
                                    if (maq.operadorAsignadoId != null &&
                                        maq.operadorAsignadoId!.isNotEmpty) {
                                      _operadorSeleccionado = maq.operadorAsignadoId;
                                      _operadorBloqueado = true;
                                    } else {
                                      _operadorSeleccionado = null;
                                      _operadorBloqueado = false;
                                    }
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Seleccione una maquinaria';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Si el operador está bloqueado, mostrar solo texto
                            if (_operadorBloqueado && _operadorSeleccionado != null)
                              Builder(
                                builder: (context) {
                                  String nombreOperador = 'N/A';
                                  if (_operadores.isNotEmpty) {
                                    try {
                                      final operador = _operadores.firstWhere(
                                        (op) => op.id == _operadorSeleccionado,
                                      );
                                      nombreOperador = '${operador.nombre} ${operador.apellido}';
                                    } catch (e) {
                                      // Si no se encuentra, usar el primero disponible
                                      nombreOperador = '${_operadores.first.nombre} ${_operadores.first.apellido}';
                                    }
                                  }
                                  return TextFormField(
                                    initialValue: nombreOperador,
                                    decoration: InputDecoration(
                                      labelText: 'Operador Encargado',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                    ),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    readOnly: true,
                                  );
                                },
                              )
                            else
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
                                items: _operadores.map((op) {
                                  return DropdownMenuItem(
                                    value: op.id,
                                    child: Text('${op.nombre} ${op.apellido}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _operadorSeleccionado = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Seleccione un operador';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _registrarGasto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Registrar Gasto',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

