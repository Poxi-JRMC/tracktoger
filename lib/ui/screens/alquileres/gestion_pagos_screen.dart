import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/alquiler.dart';
import '../../../models/pago.dart';
import '../../../controllers/control_pago.dart';
import '../../../controllers/control_alquiler.dart';
import '../../../core/auth_service.dart';

class GestionPagosScreen extends StatefulWidget {
  final Alquiler alquiler;

  const GestionPagosScreen({super.key, required this.alquiler});

  @override
  State<GestionPagosScreen> createState() => _GestionPagosScreenState();
}

class _GestionPagosScreenState extends State<GestionPagosScreen> {
  final ControlPago _controlPago = ControlPago();
  final ControlAlquiler _controlAlquiler = ControlAlquiler();
  List<Pago> _pagos = [];
  bool _loading = false;
  late Alquiler _alquiler;

  @override
  void initState() {
    super.initState();
    _alquiler = widget.alquiler;
    _cargarPagos();
  }

  Future<void> _cargarPagos() async {
    setState(() => _loading = true);
    try {
      final pagos = await _controlPago.consultarPagosPorContrato(_alquiler.id);
      // También actualizar el alquiler para obtener el montoCancelado más reciente
      await _actualizarAlquiler();
      setState(() {
        _pagos = pagos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pagos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _actualizarAlquiler() async {
    final actualizado = await _controlAlquiler.consultarAlquiler(_alquiler.id);
    if (actualizado != null && mounted) {
      setState(() {
        _alquiler = actualizado;
      });
      print('✅ Alquiler actualizado: montoCancelado = ${_alquiler.montoCancelado}');
    }
  }

  Future<void> _calcularMontoCancelado() async {
    try {
      // Calcular monto cancelado sumando todos los pagos confirmados
      final pagos = await _controlPago.consultarPagosPorContrato(_alquiler.id);
      final montoPagos = pagos
          .where((p) => p.estado == 'confirmado')
          .fold<double>(0.0, (sum, p) => sum + p.monto);
      // Siempre sumar también el monto adelantado registrado en el contrato
      final montoAdelanto = _alquiler.montoAdelanto ?? 0.0;
      final montoCancelado = montoPagos + montoAdelanto;
      
      print('💰 Calculando monto cancelado: $montoCancelado (de ${pagos.length} pagos)');
      
      // Actualizar el alquiler en la BD
      final alquilerActualizado = _alquiler.copyWith(montoCancelado: montoCancelado);
      await _controlAlquiler.actualizarAlquiler(alquilerActualizado);
      
      print('✅ Alquiler actualizado en BD con montoCancelado: $montoCancelado');
      
      // Actualizar el estado local inmediatamente
      if (mounted) {
        setState(() {
          _alquiler = alquilerActualizado;
        });
        print('✅ Estado local actualizado con montoCancelado: ${_alquiler.montoCancelado}');
      }
      
      // También consultar desde la BD para asegurar sincronización
      final alquilerDesdeBD = await _controlAlquiler.consultarAlquiler(_alquiler.id);
      if (alquilerDesdeBD != null && mounted) {
        setState(() {
          _alquiler = alquilerDesdeBD;
        });
        print('✅ Alquiler recargado desde BD con montoCancelado: ${_alquiler.montoCancelado}');
      }
    } catch (e) {
      print('❌ Error al calcular monto cancelado: $e');
    }
  }

  Future<void> _agregarPago() async {
    final fechaFormat = DateFormat('dd/MM/yyyy');
    final fechaController = TextEditingController(text: fechaFormat.format(DateTime.now()));
    final montoController = TextEditingController();
    final metodoPagoController = TextEditingController(text: 'efectivo');
    final observacionesController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Nuevo Pago'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Pago',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: _alquiler.fechaInicio,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fecha != null) {
                    fechaController.text = fechaFormat.format(fecha);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: metodoPagoController.text,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: ['efectivo', 'qr', 'transferencia']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (value) => metodoPagoController.text = value ?? 'efectivo',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (montoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingrese el monto'), backgroundColor: Colors.red),
                );
                return;
              }
              final monto = double.tryParse(montoController.text);
              if (monto == null || monto <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monto inválido'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, {
                'fechaPago': fechaFormat.parse(fechaController.text),
                'monto': monto,
                'metodoPago': metodoPagoController.text,
                'observaciones': observacionesController.text,
              });
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _loading = true);
      try {
        final pago = Pago(
          id: '',
          contratoId: _alquiler.id,
          monto: result['monto'] as double,
          fechaPago: result['fechaPago'] as DateTime,
          metodoPago: result['metodoPago'] as String,
          estado: 'confirmado',
          observaciones: result['observaciones'] as String?,
          fechaRegistro: DateTime.now(),
          usuarioRegistro: AuthService.usuarioActual?.id,
        );
        await _controlPago.registrarPago(pago);
        print('✅ Pago registrado: ${pago.monto} - Estado: ${pago.estado}');
        
        // Recargar pagos primero para tener la lista actualizada
        final pagos = await _controlPago.consultarPagosPorContrato(_alquiler.id);
        print('📋 Pagos encontrados: ${pagos.length}');
        
        // Recalcular monto cancelado basado en todos los pagos (incluyendo el nuevo)
        await _calcularMontoCancelado();
        
        // Actualizar la lista de pagos en el estado
        if (mounted) {
          setState(() {
            _pagos = pagos;
          });
        }
        
        // Recargar el alquiler desde la BD para obtener el montoCancelado actualizado
        await _actualizarAlquiler();
        
        // Forzar un rebuild final para asegurar que la UI se actualice
        if (mounted) {
          setState(() {});
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago registrado exitosamente'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al registrar pago: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editarPago(Pago pago) async {
    final fechaFormat = DateFormat('dd/MM/yyyy');
    final fechaController = TextEditingController(text: fechaFormat.format(pago.fechaPago));
    final montoController = TextEditingController(text: pago.monto.toStringAsFixed(2));
    final metodoPagoController = TextEditingController(text: pago.metodoPago);
    final observacionesController = TextEditingController(text: pago.observaciones ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Pago'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Pago',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: pago.fechaPago,
                    firstDate: _alquiler.fechaInicio,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fecha != null) {
                    fechaController.text = fechaFormat.format(fecha);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: metodoPagoController.text,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: ['efectivo', 'qr', 'transferencia']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (value) => metodoPagoController.text = value ?? 'efectivo',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (montoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingrese el monto'), backgroundColor: Colors.red),
                );
                return;
              }
              final monto = double.tryParse(montoController.text);
              if (monto == null || monto <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monto inválido'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, {
                'fechaPago': fechaFormat.parse(fechaController.text),
                'monto': monto,
                'metodoPago': metodoPagoController.text,
                'observaciones': observacionesController.text,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _loading = true);
      try {
        final pagoActualizado = pago.copyWith(
          monto: result['monto'] as double,
          fechaPago: result['fechaPago'] as DateTime,
          metodoPago: result['metodoPago'] as String,
          observaciones: result['observaciones'] as String?,
        );
        await _controlPago.actualizarPago(pagoActualizado);
        // Recargar pagos para tener la lista actualizada
        final pagos = await _controlPago.consultarPagosPorContrato(_alquiler.id);
        setState(() {
          _pagos = pagos;
        });
        // Recalcular monto cancelado
        await _calcularMontoCancelado();
        // Recargar el alquiler desde la BD
        await _actualizarAlquiler();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago actualizado exitosamente'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar pago: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _eliminarPago(Pago pago) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pago'),
        content: Text('¿Está seguro de eliminar el pago de Bs ${pago.monto.toStringAsFixed(2)}?'),
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
      setState(() => _loading = true);
      try {
        await _controlPago.eliminarPago(pago.id);
        // Recargar pagos para tener la lista actualizada
        final pagos = await _controlPago.consultarPagosPorContrato(_alquiler.id);
        setState(() {
          _pagos = pagos;
        });
        // Recalcular monto cancelado
        await _calcularMontoCancelado();
        // Recargar el alquiler desde la BD
        await _actualizarAlquiler();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago eliminado exitosamente'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar pago: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _calcularPagosMensuales() {
    if (_alquiler.tipoAlquiler != 'meses') {
      return [];
    }

    final meses = _alquiler.horasAlquiler; // En este caso, horasAlquiler representa meses
    // La mensualidad se calcula sobre el monto total; el adelanto se considera como pago global,
    // no se reparte artificialmente entre meses aquí.
    final montoPorMes = meses > 0 ? _alquiler.monto / meses : 0.0;
    final pagosMensuales = <Map<String, dynamic>>[];

    // Solo consideramos pagos CONFIRMADOS para marcar meses como pagados
    final pagosConfirmados = _pagos.where((p) => p.estado == 'confirmado').toList();

    for (int i = 0; i < meses; i++) {
      final fechaInicioMes = DateTime(
        _alquiler.fechaInicio.year,
        _alquiler.fechaInicio.month + i,
        _alquiler.fechaInicio.day,
      );
      final fechaFinMes = DateTime(
        fechaInicioMes.year,
        fechaInicioMes.month + 1,
        0,
      );

      // Buscar pagos confirmados en este mes
      final pagosDelMes = pagosConfirmados.where((p) {
        return p.fechaPago.isAfter(fechaInicioMes.subtract(const Duration(days: 1))) &&
               p.fechaPago.isBefore(fechaFinMes.add(const Duration(days: 1)));
      }).toList();

      final montoPagado = pagosDelMes.fold<double>(0.0, (sum, p) => sum + p.monto);
      final estaCompleto = montoPagado >= montoPorMes;
      final estaIncompleto = montoPagado > 0 && montoPagado < montoPorMes;

      pagosMensuales.add({
        'mes': i + 1,
        'fechaInicio': fechaInicioMes,
        'fechaFin': fechaFinMes,
        'montoEsperado': montoPorMes,
        'montoPagado': montoPagado,
        'estaCompleto': estaCompleto,
        'estaIncompleto': estaIncompleto,
        'pagos': pagosDelMes,
      });
    }

    return pagosMensuales;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fechaFormat = DateFormat('dd/MM/yyyy');
    final montoAdelanto = _alquiler.montoAdelanto ?? 0.0;
    final montoCancelado = _alquiler.montoCancelado ?? 0.0;
    // La deuda considera todo lo ya pagado (adelanto + pagos), almacenado en montoCancelado
    double saldoPendiente = _alquiler.monto - montoCancelado;
    if (saldoPendiente < 0) {
      saldoPendiente = 0;
    }
    final pagosMensuales = _calcularPagosMensuales();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _agregarPago,
            tooltip: 'Agregar Pago',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Resumen de Pagos
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: saldoPendiente <= 0 ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: saldoPendiente <= 0 ? Colors.green.shade300 : Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                saldoPendiente <= 0 ? Icons.check_circle : Icons.pending,
                                color: saldoPendiente <= 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                saldoPendiente <= 0 ? 'PAGO COMPLETADO' : 'PAGO PENDIENTE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: saldoPendiente <= 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildResumenRow('Monto Total', 'Bs ${_alquiler.monto.toStringAsFixed(2)}', isDark, Colors.black),
                          if (montoAdelanto > 0)
                            _buildResumenRow('Monto Adelantado', 'Bs ${montoAdelanto.toStringAsFixed(2)}', isDark, Colors.black),
                          _buildResumenRow('Monto Cancelado', 'Bs ${montoCancelado.toStringAsFixed(2)}', isDark, Colors.green.shade700),
                          _buildResumenRow(
                            'Monto a Deuda',
                            'Bs ${saldoPendiente.toStringAsFixed(2)}',
                            isDark,
                            saldoPendiente > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pagos Mensuales (si aplica)
                  if (_alquiler.tipoAlquiler == 'meses' && pagosMensuales.isNotEmpty) ...[
                    Text(
                      'Pagos Mensuales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pagosMensuales.map((mes) => _buildMesCard(mes, fechaFormat, isDark)),
                    const SizedBox(height: 16),
                  ],
                  // Historial de Pagos
                  Text(
                    'Historial de Pagos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pagos.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay pagos registrados',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._pagos.map((pago) => _buildPagoCard(pago, fechaFormat, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildResumenRow(String label, String value, bool isDark, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? (isDark ? Colors.white : Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesCard(Map<String, dynamic> mes, DateFormat fechaFormat, bool isDark) {
    final estaCompleto = mes['estaCompleto'] as bool;
    final estaIncompleto = mes['estaIncompleto'] as bool;
    final montoEsperado = mes['montoEsperado'] as double;
    final montoPagado = mes['montoPagado'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleMes(mes, fechaFormat, isDark),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: estaCompleto
                ? Colors.green.shade50
                : estaIncompleto
                    ? Colors.orange.shade50
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estaCompleto
                  ? Colors.green.shade300
                  : estaIncompleto
                      ? Colors.orange.shade300
                      : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: estaCompleto
                      ? Colors.green
                      : estaIncompleto
                          ? Colors.orange
                          : Colors.grey,
                ),
                child: Icon(
                  estaCompleto
                      ? Icons.check_circle
                      : estaIncompleto
                          ? Icons.pending
                          : Icons.cancel,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes ${mes['mes']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fechaFormat.format(mes['fechaInicio'] as DateTime)} - ${fechaFormat.format(mes['fechaFin'] as DateTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estaCompleto
                          ? 'COMPLETO - Bs ${montoPagado.toStringAsFixed(2)} / Bs ${montoEsperado.toStringAsFixed(2)}'
                          : estaIncompleto
                              ? 'INCOMPLETO - Bs ${montoPagado.toStringAsFixed(2)} / Bs ${montoEsperado.toStringAsFixed(2)}'
                              : 'PENDIENTE - Bs ${montoEsperado.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: estaCompleto
                            ? Colors.green.shade700
                            : estaIncompleto
                                ? Colors.orange.shade700
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleMes(Map<String, dynamic> mes, DateFormat fechaFormat, bool isDark) async {
    final pagos = mes['pagos'] as List<Pago>;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mes ${mes['mes']} - Detalle de Pagos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fechaFormat.format(mes['fechaInicio'] as DateTime)} - ${fechaFormat.format(mes['fechaFin'] as DateTime)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              if (pagos.isEmpty)
                Text(
                  'No hay pagos registrados para este mes',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                )
              else
                ...pagos.map((pago) => ListTile(
                      title: Text('Bs ${pago.monto.toStringAsFixed(2)}'),
                      subtitle: Text('${fechaFormat.format(pago.fechaPago)} - ${pago.metodoPago.toUpperCase()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              Navigator.pop(context);
                              _editarPago(pago);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarPago(pago);
                            },
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _agregarPago();
            },
            child: const Text('Agregar Pago'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagoCard(Pago pago, DateFormat fechaFormat, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pago.estado == 'confirmado' ? Colors.green : Colors.orange,
          child: Icon(
            pago.estado == 'confirmado' ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Bs ${pago.monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fechaFormat.format(pago.fechaPago)} - ${pago.metodoPago.toUpperCase()}'),
            if (pago.observaciones != null && pago.observaciones!.isNotEmpty)
              Text(
                pago.observaciones!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editarPago(pago),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarPago(pago),
            ),
          ],
        ),
      ),
    );
  }
}

