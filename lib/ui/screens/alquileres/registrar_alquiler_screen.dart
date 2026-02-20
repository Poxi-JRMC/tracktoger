import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/control_alquiler.dart';
import '../../../controllers/control_cliente.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../controllers/control_pago.dart';
import '../../../models/alquiler.dart';
import '../../../models/cliente.dart';
import '../../../models/maquinaria.dart';
import '../../../models/pago.dart';
import '../../../core/auth_service.dart';
import '../../../utils/image_utils.dart';
import 'registrar_cliente_screen.dart';

class RegistrarAlquilerScreen extends StatefulWidget {
  const RegistrarAlquilerScreen({super.key});

  @override
  State<RegistrarAlquilerScreen> createState() => _RegistrarAlquilerScreenState();
}

class _RegistrarAlquilerScreenState extends State<RegistrarAlquilerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _horasController = TextEditingController();
  final _precioPorHoraController = TextEditingController(); // Nuevo: precio por hora
  final _montoController = TextEditingController();
  final _montoAdelantoController = TextEditingController();
  final _proyectoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _tipoCambioController = TextEditingController(text: '7.00'); // Tipo de cambio paralelo por defecto
  final Map<String, TextEditingController> _especificacionesControllers = {};

  final ControlAlquiler _controlAlquiler = ControlAlquiler();
  final ControlCliente _controlCliente = ControlCliente();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ControlPago _controlPago = ControlPago();
  final ImagePicker _picker = ImagePicker();

  List<Cliente> _clientes = [];
  List<Maquinaria> _maquinariasDisponibles = [];
  Maquinaria? _maquinariaSeleccionadaObj;
  String? _clienteSeleccionado;
  String? _maquinariaSeleccionada;
  String _tipoAlquiler = 'meses'; // por defecto: meses
  String? _metodoPago; // 'qr', 'efectivo', 'transferencia'
  File? _imagenQR;
  String? _codigoQRBase64;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;
  int _mesesCalculados = 0; // Meses calculados automáticamente

  @override
  void initState() {
    super.initState();
    _calcularMeses(); // Calcular meses al inicializar
    _verificarPermisos();
  }

  Future<void> _verificarPermisos() async {
    final esAdmin = await AuthService.esAdministrador();
    if (!esAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo los administradores pueden registrar alquileres'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final clientes = await _controlCliente.consultarTodosClientes();
      final maquinarias = await _controlMaquinaria.consultarMaquinariasDisponibles();
      
      setState(() {
        _clientes = clientes;
        _maquinariasDisponibles = maquinarias;
        _loading = false;
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    try {
      final fecha = await showDatePicker(
        context: context,
        initialDate: _fechaInicio,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        locale: const Locale('es', 'MX'), // Español latinoamericano
        helpText: 'Seleccionar fecha de inicio',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme,
            ),
            child: child!,
          );
        },
      );
      if (fecha != null) {
        setState(() {
          _fechaInicio = fecha;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaFin = _fechaInicio.add(const Duration(days: 1));
          }
          _calcularMeses();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar fecha: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarFechaFin() async {
    try {
      final fecha = await showDatePicker(
        context: context,
        initialDate: _fechaFin,
        firstDate: _fechaInicio,
        lastDate: DateTime.now().add(const Duration(days: 365)),
        locale: const Locale('es', 'MX'), // Español latinoamericano
        helpText: 'Seleccionar fecha de fin',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
      );
      if (fecha != null) {
        setState(() {
          _fechaFin = fecha;
          _calcularMeses();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar fecha: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calcularMeses() {
    if (_fechaFin.isAfter(_fechaInicio) || _fechaFin.isAtSameMomentAs(_fechaInicio)) {
      // Calcular meses reales del calendario
      int meses = 0;
      DateTime fechaTemp = DateTime(_fechaInicio.year, _fechaInicio.month, _fechaInicio.day);
      
      while (fechaTemp.isBefore(_fechaFin) || fechaTemp.isAtSameMomentAs(_fechaFin)) {
        meses++;
        fechaTemp = DateTime(fechaTemp.year, fechaTemp.month + 1, fechaTemp.day);
      }
      
      _mesesCalculados = meses > 0 ? meses : 1;
    } else {
      _mesesCalculados = 0;
    }
  }

  double _calcularMontoTotal() {
    // Calcular monto total en USD = precio por hora × horas
    final precioPorHora = double.tryParse(_precioPorHoraController.text) ?? 0.0;
    final horas = int.tryParse(_horasController.text) ?? 0;
    return precioPorHora * horas;
  }

  double _calcularMontoTotalEnBolivianos() {
    // Convierte el monto total en USD a Bolivianos usando el tipo de cambio actual
    final montoDolares = _calcularMontoTotal();
    return _calcularMontoEnBolivianos(montoDolares);
  }

  double _calcularMontoEnBolivianos(double montoDolares) {
    final tipoCambio = double.tryParse(_tipoCambioController.text) ?? 7.00;
    return montoDolares * tipoCambio;
  }

  Future<void> _registrarAlquiler() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado == null || _maquinariaSeleccionada == null) {
      _mostrarError('Por favor seleccione un cliente y una maquinaria');
      return;
    }

    // Verificar disponibilidad
    try {
      final disponible = await _controlAlquiler.verificarDisponibilidad(
        _maquinariaSeleccionada!,
        _fechaInicio,
        _fechaFin,
      );

      if (!disponible) {
        _mostrarError('La maquinaria seleccionada no está disponible en el período especificado. Por favor, seleccione otras fechas o otra maquinaria.');
        return;
      }
    } catch (e) {
      _mostrarError('Error al verificar disponibilidad: $e');
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      // Si es por meses, usar los meses calculados automáticamente
      // Si es por horas, usar las horas ingresadas
      final horasAlquiler = _tipoAlquiler == 'meses' 
          ? _mesesCalculados 
          : (int.tryParse(_horasController.text) ?? 0);
      
      if (_tipoAlquiler == 'meses' && horasAlquiler == 0) {
        _mostrarError('Por favor seleccione fechas válidas para calcular los meses');
        setState(() => _loading = false);
        return;
      }
      
      if (_tipoAlquiler == 'horas' && horasAlquiler == 0) {
        _mostrarError('Por favor ingrese las horas de alquiler');
        setState(() => _loading = false);
        return;
      }
      
      // Para horas, el monto se calcula automáticamente en Bs (a partir de USD × tipo de cambio)
      // Para meses, el monto se ingresa manualmente directamente en Bs
      final monto = _tipoAlquiler == 'horas' 
          ? _calcularMontoTotalEnBolivianos()
          : (double.tryParse(_montoController.text) ?? 0.0);
      
      if (monto <= 0) {
        _mostrarError('El monto del alquiler debe ser mayor a 0');
        setState(() => _loading = false);
        return;
      }
      final montoAdelanto = _montoAdelantoController.text.trim().isNotEmpty
          ? double.tryParse(_montoAdelantoController.text.trim())
          : null;
      
      // Recopilar especificaciones
      Map<String, dynamic> especificaciones = {};
      _especificacionesControllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          especificaciones[key] = controller.text.trim();
        }
      });

      // Calcular monto cancelado (inicialmente igual al adelanto si existe)
      final montoCancelado = montoAdelanto ?? 0.0;

      final alquiler = Alquiler(
        id: '',
        clienteId: _clienteSeleccionado!,
        maquinariaId: _maquinariaSeleccionada!,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        horasAlquiler: horasAlquiler,
        tipoAlquiler: _tipoAlquiler,
        monto: monto,
        montoAdelanto: montoAdelanto,
        montoCancelado: montoCancelado > 0 ? montoCancelado : null,
        metodoPago: _metodoPago,
        codigoQR: _codigoQRBase64,
        proyecto: _proyectoController.text.trim().isEmpty ? null : _proyectoController.text.trim(),
        ubicacion: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
        estado: 'pendiente_entrega',
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        fechaRegistro: DateTime.now(),
        especificaciones: especificaciones.isEmpty ? null : especificaciones,
      );

      final alquilerRegistrado = await _controlAlquiler.registrarAlquiler(alquiler);

      // Si es por meses, crear pagos divididos automáticamente
      if (_tipoAlquiler == 'meses' && horasAlquiler > 0) {
        try {
          final montoPorMes = monto / horasAlquiler;
          final usuarioId = AuthService.usuarioActual?.id;
          
          for (int i = 0; i < horasAlquiler; i++) {
            final fechaPago = DateTime(
              _fechaInicio.year,
              _fechaInicio.month + i,
              _fechaInicio.day,
            );
            
            final pago = Pago(
              id: '',
              contratoId: alquilerRegistrado.id,
              monto: montoPorMes,
              fechaPago: fechaPago,
              metodoPago: _metodoPago ?? 'efectivo',
              estado: 'pendiente', // Los pagos se marcan como pendientes hasta que se confirmen
              observaciones: 'Pago mensual ${i + 1} de $horasAlquiler',
              fechaRegistro: DateTime.now(),
              usuarioRegistro: usuarioId,
            );
            
            await _controlPago.registrarPago(pago);
            print('✅ Pago mensual ${i + 1} creado automáticamente: \$${montoPorMes.toStringAsFixed(2)}');
          }
        } catch (e) {
          print('⚠️ Error al crear pagos automáticos: $e');
          // No bloqueamos el flujo si falla la creación de pagos
        }
      }

      if (mounted) {
        _mostrarExito('Alquiler registrado correctamente');
        
        // Generar PDF automáticamente
        try {
          await _controlAlquiler.generarPdfContrato(
            alquilerRegistrado.id,
            context,
            mostrarMonto: true, // Solo admin puede ver el monto
          );
        } catch (e) {
          print('⚠️ Error al generar PDF: $e');
          // No bloqueamos el flujo si falla la generación del PDF
        }
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarError('Error al registrar alquiler: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _seleccionarQR() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imagen != null) {
        final file = File(imagen.path);
        final base64 = await ImageUtils.imageToBase64(file);
        
        setState(() {
          _imagenQR = file;
          _codigoQRBase64 = base64;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarQRAutomaticamente() async {
    if (_metodoPago == 'qr' && _imagenQR == null) {
      await _seleccionarQR();
    }
  }

  @override
  void dispose() {
    _horasController.dispose();
    _precioPorHoraController.dispose();
    _montoController.dispose();
    _montoAdelantoController.dispose();
    _proyectoController.dispose();
    _ubicacionController.dispose();
    _observacionesController.dispose();
    _tipoCambioController.dispose();
    _especificacionesControllers.values.forEach((controller) => controller.dispose());
    _especificacionesControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fechaFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: _loading && _clientes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(isDark),
                    const SizedBox(height: 20),
                    // Selección de Cliente
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blue.shade400),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cliente',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegistrarClienteScreen(),
                                      ),
                                    );
                                    if (result == true) {
                                      await _cargarDatos();
                                    }
                                  },
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('Nuevo Cliente'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _clienteSeleccionado,
                              decoration: InputDecoration(
                                labelText: 'Seleccionar Cliente',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              items: _clientes.map((cliente) {
                                return DropdownMenuItem(
                                  value: cliente.id,
                                  child: Text('${cliente.nombre} ${cliente.apellido}${cliente.empresa != null ? ' - ${cliente.empresa}' : ''}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _clienteSeleccionado = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Seleccione un cliente';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Selección de Maquinaria
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
                            const SizedBox(height: 16),
                            if (_maquinariasDisponibles.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No hay maquinaria disponible en este momento',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                value: _maquinariaSeleccionada,
                                decoration: InputDecoration(
                                  labelText: 'Seleccionar Maquinaria',
                                  prefixIcon: const Icon(Icons.construction_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                isExpanded: true,
                                items: _maquinariasDisponibles.map((maq) {
                                  return DropdownMenuItem(
                                    value: maq.id,
                                    child: Text(
                                      maq.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _maquinariaSeleccionada = value;
                                  _maquinariaSeleccionadaObj = _maquinariasDisponibles.firstWhere(
                                    (m) => m.id == value,
                                    orElse: () => _maquinariasDisponibles.first,
                                  );
                                  // Limpiar controladores de especificaciones anteriores
                                  _especificacionesControllers.values.forEach((c) => c.dispose());
                                  _especificacionesControllers.clear();
                                  // Crear controladores para las especificaciones de la maquinaria
                                  if (_maquinariaSeleccionadaObj != null && 
                                      _maquinariaSeleccionadaObj!.especificaciones.isNotEmpty) {
                                    _maquinariaSeleccionadaObj!.especificaciones.forEach((key, value) {
                                      _especificacionesControllers[key] = TextEditingController(
                                        text: value.toString(),
                                      );
                                    });
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Fechas y Detalles
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
                                Icon(Icons.calendar_today, color: Colors.blue.shade400),
                                const SizedBox(width: 8),
                                Text(
                                  'Fechas y Detalles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            // Solo mostrar calendario cuando es por meses
                            if (_tipoAlquiler == 'meses') ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _seleccionarFechaInicio,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fecha de Inicio',
                                    prefixIcon: const Icon(Icons.event),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  ),
                                  child: Text(
                                    fechaFormat.format(_fechaInicio),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _seleccionarFechaFin,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fecha de Fin',
                                    prefixIcon: const Icon(Icons.event_available),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  ),
                                  child: Text(
                                    fechaFormat.format(_fechaFin),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              // Mostrar meses calculados automáticamente
                              if (_mesesCalculados > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month, color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Duración: $_mesesCalculados ${_mesesCalculados == 1 ? 'mes' : 'meses'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _tipoAlquiler,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Alquiler',
                                prefixIcon: const Icon(Icons.schedule),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              items: const [
                                DropdownMenuItem(value: 'horas', child: Text('Por Horas')),
                                DropdownMenuItem(value: 'meses', child: Text('Por Meses')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _tipoAlquiler = value ?? 'horas';
                                });
                              },
                            ),
                            // Campos para "Por Horas": Precio por hora (USD) × Horas = Monto Total (Bs) usando tipo de cambio
                            if (_tipoAlquiler == 'horas') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _precioPorHoraController,
                                decoration: InputDecoration(
                                  labelText: '¿Cuánto cobro por hora? (USD)',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  helperText: 'Precio por hora de alquiler',
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese el precio por hora';
                                  }
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'Ingrese un precio válido mayor a 0';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Calcular monto total automáticamente en Bs
                                  final montoTotalBs = _calcularMontoTotalEnBolivianos();
                                  _montoController.text = montoTotalBs > 0 ? montoTotalBs.toStringAsFixed(2) : '';
                                  setState(() {}); // Recalcular conversión
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _horasController,
                                decoration: InputDecoration(
                                  labelText: 'Horas de Alquiler',
                                  prefixIcon: const Icon(Icons.access_time),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  helperText: 'Cantidad de horas a alquilar',
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese las horas de alquiler';
                                  }
                                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                    return 'Ingrese un número válido mayor a 0';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Calcular monto total automáticamente en Bs
                                  final montoTotalBs = _calcularMontoTotalEnBolivianos();
                                  _montoController.text = montoTotalBs > 0 ? montoTotalBs.toStringAsFixed(2) : '';
                                  setState(() {}); // Recalcular conversión
                                },
                              ),
                              // Mostrar monto total calculado automáticamente (en Bs)
                              if (_calcularMontoTotalEnBolivianos() > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calculate, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Monto Total Calculado (Bs):',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              'Bs ${_calcularMontoTotalEnBolivianos().toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                            // Campo de monto total solo para "Por Meses" (ingreso manual en Bs)
                            if (_tipoAlquiler == 'meses') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _montoController,
                                decoration: InputDecoration(
                                  labelText: 'Monto Total del Alquiler (Bs)',
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
                                    return 'Ingrese el monto del alquiler';
                                  }
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'Ingrese un monto válido mayor a 0';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {}); // Recalcular conversión
                                },
                              ),
                            ],
                            // Mostrar conversión a bolivianos solo si es por horas y hay datos
                            if (_tipoAlquiler == 'horas' && _calcularMontoTotal() > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.currency_exchange, color: Colors.green.shade700),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Conversión a Bolivianos',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Monto en Bs: ${_calcularMontoEnBolivianos(_calcularMontoTotal()).toStringAsFixed(2)} Bs',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Campo para tipo de cambio paralelo: solo cuando es por horas (para conversión USD → Bs)
                            if (_tipoAlquiler == 'horas') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _tipoCambioController,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de Cambio Paralelo (Bs/USD)',
                                  prefixIcon: const Icon(Icons.currency_exchange),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  helperText: 'Tipo de cambio para conversión a bolivianos',
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese el tipo de cambio';
                                  }
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'Ingrese un tipo de cambio válido mayor a 0';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {}); // Recalcular conversión
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _montoAdelantoController,
                              decoration: InputDecoration(
                                labelText: 'Monto Adelantado (Bs, opcional)',
                                prefixIcon: const Icon(Icons.payment),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                helperText: 'Pago inicial del proyecto',
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                    return 'Ingrese un monto válido mayor a 0';
                                  }
                                  // Usar siempre el monto total REAL en Bs:
                                  // - Si es por horas: ya está calculado automáticamente en Bs
                                  // - Si es por meses: se ingresó manualmente en Bs
                                  final montoTotal = _tipoAlquiler == 'horas'
                                      ? _calcularMontoTotalEnBolivianos()
                                      : (double.tryParse(_montoController.text) ?? 0);
                                  final adelanto = double.parse(value);
                                  if (adelanto >= montoTotal) {
                                    return 'El adelanto debe ser menor al monto total';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _metodoPago,
                              decoration: InputDecoration(
                                labelText: 'Método de Pago (opcional)',
                                prefixIcon: const Icon(Icons.payment),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                helperText: 'Especifique cómo se realizará el pago',
                              ),
                              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              items: const [
                                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                                DropdownMenuItem(value: 'qr', child: Text('QR')),
                                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  _metodoPago = value;
                                  if (value != 'qr') {
                                    _imagenQR = null;
                                    _codigoQRBase64 = null;
                                  }
                                });
                                // Cargar QR automáticamente cuando se selecciona
                                if (value == 'qr') {
                                  await _cargarQRAutomaticamente();
                                }
                              },
                            ),
                            if (_metodoPago == 'qr') ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.qr_code, color: Colors.blue.shade400),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Código QR para Pago',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_imagenQR != null) ...[
                                      Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade400),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            _imagenQR!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: _seleccionarQR,
                                      icon: Icon(_imagenQR != null ? Icons.refresh : Icons.add_photo_alternate),
                                      label: Text(_imagenQR != null ? 'Cambiar QR' : 'Cargar Código QR'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Si es efectivo, solo mostrar proyecto
                            if (_metodoPago == 'efectivo') ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.money, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Método de pago: Efectivo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Datos del proyecto y ubicación (siempre visibles)
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _proyectoController,
                              decoration: InputDecoration(
                                labelText: 'Proyecto / Nombre de la obra',
                                prefixIcon: const Icon(Icons.work_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                helperText: 'Ej: Proyecto Minero San Juan, Construcción Vía, etc.',
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ubicacionController,
                              decoration: InputDecoration(
                                labelText: 'Ubicación del proyecto',
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                helperText: 'Ej: Santa Cruz, Yacuiba, Coordenadas o dirección exacta',
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _observacionesController,
                              decoration: InputDecoration(
                                labelText: 'Observaciones (opcional)',
                                prefixIcon: const Icon(Icons.note_outlined),
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
                    // Especificaciones del Contrato
                    if (_maquinariaSeleccionadaObj != null && 
                        _maquinariaSeleccionadaObj!.especificaciones.isNotEmpty) ...[
                      const SizedBox(height: 20),
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
                                  Icon(Icons.settings, color: Colors.blue.shade400),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Especificaciones del Contrato',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._especificacionesControllers.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TextFormField(
                                    controller: entry.value,
                                    decoration: InputDecoration(
                                      labelText: entry.key.replaceAll('_', ' ').toUpperCase(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                    ),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _registrarAlquiler,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Registrar Contrato',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
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
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Registrar Contrato",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Nuevo contrato de alquiler",
                  style: TextStyle(
                    fontSize: 12,
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
}

