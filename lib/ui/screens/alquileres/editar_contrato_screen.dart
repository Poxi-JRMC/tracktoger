import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/alquiler.dart';
import '../../../controllers/control_alquiler.dart';

class EditarContratoScreen extends StatefulWidget {
  final Alquiler alquiler;

  const EditarContratoScreen({super.key, required this.alquiler});

  @override
  State<EditarContratoScreen> createState() => _EditarContratoScreenState();
}

class _EditarContratoScreenState extends State<EditarContratoScreen> {
  final ControlAlquiler _controlAlquiler = ControlAlquiler();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _montoController;
  late TextEditingController _montoAdelantoController;
  late TextEditingController _horasAlquilerController;
  late String _tipoAlquiler;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(text: widget.alquiler.monto.toStringAsFixed(2));
    _montoAdelantoController = TextEditingController(
      text: widget.alquiler.montoAdelanto?.toStringAsFixed(2) ?? '',
    );
    _horasAlquilerController = TextEditingController(text: widget.alquiler.horasAlquiler.toString());
    _tipoAlquiler = widget.alquiler.tipoAlquiler;
    _fechaInicio = widget.alquiler.fechaInicio;
    _fechaFin = widget.alquiler.fechaFin;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _montoAdelantoController.dispose();
    _horasAlquilerController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      final monto = double.parse(_montoController.text);
      final montoAdelanto = _montoAdelantoController.text.isNotEmpty
          ? double.tryParse(_montoAdelantoController.text)
          : null;
      final horasAlquiler = int.parse(_horasAlquilerController.text);

      if (montoAdelanto != null && montoAdelanto > monto) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El monto adelantado no puede ser mayor al monto total'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // Calcular fechaFin basada en tipoAlquiler
      DateTime nuevaFechaFin;
      if (_tipoAlquiler == 'meses') {
        nuevaFechaFin = DateTime(
          _fechaInicio.year,
          _fechaInicio.month + horasAlquiler,
          _fechaInicio.day,
        );
      } else {
        nuevaFechaFin = _fechaInicio.add(Duration(hours: horasAlquiler));
      }

      final alquilerActualizado = widget.alquiler.copyWith(
        monto: monto,
        montoAdelanto: montoAdelanto,
        horasAlquiler: horasAlquiler,
        tipoAlquiler: _tipoAlquiler,
        fechaInicio: _fechaInicio,
        fechaFin: nuevaFechaFin,
      );

      await _controlAlquiler.actualizarAlquiler(alquilerActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar contrato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fechaFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Editar Contrato'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
              tooltip: 'Guardar Cambios',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Contrato',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tipo de Alquiler
                      DropdownButtonFormField<String>(
                        value: _tipoAlquiler,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Alquiler',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        items: [
                          DropdownMenuItem(value: 'horas', child: const Text('Por Horas')),
                          DropdownMenuItem(value: 'meses', child: const Text('Por Meses')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipoAlquiler = value ?? 'horas';
                            // Recalcular fechaFin
                            if (_tipoAlquiler == 'meses') {
                              final meses = int.tryParse(_horasAlquilerController.text) ?? 0;
                              _fechaFin = DateTime(
                                _fechaInicio.year,
                                _fechaInicio.month + meses,
                                _fechaInicio.day,
                              );
                            } else {
                              final horas = int.tryParse(_horasAlquilerController.text) ?? 0;
                              _fechaFin = _fechaInicio.add(Duration(hours: horas));
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Duración (horas o meses)
                      TextFormField(
                        controller: _horasAlquilerController,
                        decoration: InputDecoration(
                          labelText: _tipoAlquiler == 'meses' ? 'Cantidad de Meses' : 'Cantidad de Horas',
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la duración';
                          }
                          final cantidad = int.tryParse(value);
                          if (cantidad == null || cantidad <= 0) {
                            return 'La cantidad debe ser mayor a 0';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Recalcular fechaFin cuando cambia la duración
                          final cantidad = int.tryParse(value) ?? 0;
                          if (cantidad > 0) {
                            setState(() {
                              if (_tipoAlquiler == 'meses') {
                                _fechaFin = DateTime(
                                  _fechaInicio.year,
                                  _fechaInicio.month + cantidad,
                                  _fechaInicio.day,
                                );
                              } else {
                                _fechaFin = _fechaInicio.add(Duration(hours: cantidad));
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Fecha de Inicio
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: fechaFormat.format(_fechaInicio)),
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Inicio',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (fecha != null) {
                            setState(() {
                              _fechaInicio = fecha;
                              // Recalcular fechaFin
                              final cantidad = int.tryParse(_horasAlquilerController.text) ?? 0;
                              if (cantidad > 0) {
                                if (_tipoAlquiler == 'meses') {
                                  _fechaFin = DateTime(
                                    _fechaInicio.year,
                                    _fechaInicio.month + cantidad,
                                    _fechaInicio.day,
                                  );
                                } else {
                                  _fechaFin = _fechaInicio.add(Duration(hours: cantidad));
                                }
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Fecha de Fin (solo lectura, calculada automáticamente)
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: fechaFormat.format(_fechaFin)),
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Fin (calculada automáticamente)',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de Pagos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Monto Total
                      TextFormField(
                        controller: _montoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Total',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el monto total';
                          }
                          final monto = double.tryParse(value);
                          if (monto == null || monto <= 0) {
                            return 'El monto debe ser mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Monto Adelantado
                      TextFormField(
                        controller: _montoAdelantoController,
                        decoration: const InputDecoration(
                          labelText: 'Monto Adelantado (opcional)',
                          prefixIcon: Icon(Icons.payment),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final monto = double.tryParse(value);
                            if (monto == null || monto < 0) {
                              return 'El monto debe ser mayor o igual a 0';
                            }
                            final montoTotal = double.tryParse(_montoController.text) ?? 0;
                            if (monto > montoTotal) {
                              return 'El monto adelantado no puede ser mayor al monto total';
                            }
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
                onPressed: _loading ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


