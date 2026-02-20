import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/alquiler.dart';
import '../../../models/cliente.dart';
import '../../../models/maquinaria.dart';
import '../../../controllers/control_cliente.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../controllers/control_alquiler.dart';
import '../../../core/auth_service.dart';
import 'registrar_devolucion_screen.dart';
import 'editar_contrato_screen.dart';
import 'gestion_pagos_screen.dart';

class DetallesAlquilerScreen extends StatefulWidget {
  final Alquiler alquiler;

  const DetallesAlquilerScreen({super.key, required this.alquiler});

  @override
  State<DetallesAlquilerScreen> createState() => _DetallesAlquilerScreenState();
}

class _DetallesAlquilerScreenState extends State<DetallesAlquilerScreen> {
  final ControlAlquiler _controlAlquiler = ControlAlquiler();
  late Alquiler _alquiler;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _alquiler = widget.alquiler;
  }

  Future<void> _actualizarAlquiler() async {
    final actualizado = await _controlAlquiler.consultarAlquiler(_alquiler.id);
    if (actualizado != null && mounted) {
      setState(() {
        _alquiler = actualizado;
      });
      print('✅ Alquiler actualizado en detalles: montoCancelado = ${_alquiler.montoCancelado}, monto = ${_alquiler.monto}');
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'pendiente_entrega':
        return 'Máquina Pendiente a Entregar';
      case 'entregada':
        return 'Máquina Entregada';
      case 'devuelta':
        return 'Máquina Devuelta';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado.toUpperCase();
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    if (_alquiler.estado == nuevoEstado) return;

    // Si se devuelve la máquina, pedir las horas de uso
    int? horasUsoReal = _alquiler.horasUsoReal;
    if (nuevoEstado == 'devuelta' && horasUsoReal == null) {
      horasUsoReal = await _pedirHorasUso();
      if (horasUsoReal == null) {
        // El usuario canceló, no cambiar el estado
        return;
      }
    }

    setState(() => _loading = true);
    try {
      // Si se devuelve la máquina, automáticamente finalizar el proyecto
      final finalizarProyecto = nuevoEstado == 'devuelta';
      
      // Si hay horas de uso real, actualizar la máquina
      if (nuevoEstado == 'devuelta' && horasUsoReal != null) {
        final controlMaquinaria = ControlMaquinaria();
        final maquinaria = await controlMaquinaria.consultarMaquinaria(_alquiler.maquinariaId);
        if (maquinaria != null) {
          final nuevasHoras = maquinaria.horasUso + horasUsoReal.toDouble();
          await controlMaquinaria.actualizarHorasUso(_alquiler.maquinariaId, nuevasHoras);
          print('✅ Horas de uso actualizadas: ${maquinaria.horasUso} + $horasUsoReal = $nuevasHoras');
        }
      }
      
      final alquilerActualizado = _alquiler.copyWith(
        estado: nuevoEstado,
        fechaEntrega: nuevoEstado == 'entregada' ? DateTime.now() : _alquiler.fechaEntrega,
        fechaDevolucion: nuevoEstado == 'devuelta' ? DateTime.now() : _alquiler.fechaDevolucion,
        proyectoFinalizado: finalizarProyecto ? true : _alquiler.proyectoFinalizado,
        horasUsoReal: horasUsoReal ?? _alquiler.horasUsoReal,
      );
      await _controlAlquiler.actualizarAlquiler(alquilerActualizado);
      await _actualizarAlquiler();
      
      if (mounted) {
        String mensaje = 'Estado actualizado: ${_getEstadoLabel(nuevoEstado)}';
        if (finalizarProyecto) {
          mensaje += '\nProyecto marcado como finalizado automáticamente';
        }
        if (horasUsoReal != null) {
          mensaje += '\nHoras de uso registradas: $horasUsoReal horas';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<int?> _pedirHorasUso() async {
    final horasController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.speed, color: Colors.blue),
            SizedBox(width: 8),
            Text('Registrar Horas de Uso'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingrese las horas actuales de uso de la máquina para este proyecto:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: horasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas de Uso',
                  hintText: 'Ej: 150',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese las horas de uso';
                  }
                  final horas = int.tryParse(value);
                  if (horas == null || horas < 0) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final horas = int.tryParse(horasController.text);
                Navigator.pop(context, horas);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoCambioEstado() async {
    final estados = [
      {'value': 'pendiente_entrega', 'label': 'Máquina Pendiente a Entregar'},
      {'value': 'entregada', 'label': 'Máquina Entregada'},
      {'value': 'devuelta', 'label': 'Máquina Devuelta'},
      {'value': 'cancelado', 'label': 'Cancelado'},
    ];
    final estadoActual = _alquiler.estado;

    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: estados.map((estado) {
            return ListTile(
              title: Text(estado['label'] as String),
              subtitle: estado['value'] == 'devuelta'
                  ? const Text('(Finalizará el proyecto automáticamente)', 
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic))
                  : null,
              selected: estado['value'] == estadoActual,
              onTap: () => Navigator.pop(context, estado['value'] as String),
            );
          }).toList(),
        ),
      ),
    );

    if (nuevoEstado != null && nuevoEstado != estadoActual) {
      await _cambiarEstado(nuevoEstado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fechaFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_alquiler.id + (_alquiler.montoCancelado?.toString() ?? '0')),
        future: _cargarDatos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cliente = snapshot.data?['cliente'] as Cliente?;
          final maquinaria = snapshot.data?['maquinaria'] as Maquinaria?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark, cliente, maquinaria),
                const SizedBox(height: 16),
                // Indicador de estado visual (luz verde/roja)
                _buildIndicadorEstado(isDark),
                const SizedBox(height: 16),
                // Información de Pagos
                if (_alquiler.monto > 0) _buildInfoPagos(isDark),
                const SizedBox(height: 16),
                // Información del Cliente
                _buildSectionCard(
                  'Información del Cliente',
                  Icons.person,
                  [
                    _buildInfoRow('Nombre', cliente?.nombreCompleto ?? 'N/A', isDark),
                    _buildInfoRow('Email', cliente?.email ?? 'N/A', isDark),
                    _buildInfoRow('Teléfono', cliente?.telefono ?? 'N/A', isDark),
                    if (cliente?.empresa != null)
                      _buildInfoRow('Empresa', cliente!.empresa!, isDark),
                  ],
                  isDark,
                ),
                const SizedBox(height: 16),
                // Información de la Maquinaria
                _buildSectionCard(
                  'Información de la Maquinaria',
                  Icons.construction,
                  [
                    _buildInfoRow('Nombre', maquinaria?.nombre ?? 'N/A', isDark),
                    _buildInfoRow('Marca', maquinaria?.marca ?? 'N/A', isDark),
                    _buildInfoRow('Modelo', maquinaria?.modelo ?? 'N/A', isDark),
                    _buildInfoRow('Número de Serie', maquinaria?.numeroSerie ?? 'N/A', isDark),
                    if (maquinaria?.apodo != null)
                      _buildInfoRow('Apodo', maquinaria!.apodo!, isDark),
                  ],
                  isDark,
                ),
                const SizedBox(height: 16),
                // Especificaciones de la Maquinaria
                if (maquinaria != null && maquinaria.especificaciones.isNotEmpty) ...[
                  _buildSectionCard(
                    'Especificaciones Técnicas de la Maquinaria',
                    Icons.settings,
                    maquinaria.especificaciones.entries.map((entry) {
                      return _buildInfoRow(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        entry.value.toString(),
                        isDark,
                      );
                    }).toList(),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                // Especificaciones del Contrato
                if (_alquiler.especificaciones != null && _alquiler.especificaciones!.isNotEmpty) ...[
                  _buildSectionCard(
                    'Especificaciones del Contrato',
                    Icons.description,
                    _alquiler.especificaciones!.entries.map((entry) {
                      return _buildInfoRow(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        entry.value.toString(),
                        isDark,
                      );
                    }).toList(),
                    isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                // Términos del Alquiler
                _buildSectionCard(
                  'Términos del Alquiler',
                  Icons.calendar_today,
                  [
                    _buildInfoRow('Fecha de Inicio', fechaFormat.format(_alquiler.fechaInicio), isDark),
                    _buildInfoRow('Fecha de Fin', fechaFormat.format(_alquiler.fechaFin), isDark),
                    _buildInfoRow(
                      'Duración',
                      _alquiler.tipoAlquiler == 'horas'
                          ? '${_alquiler.horasAlquiler} horas'
                          : '${_alquiler.horasAlquiler} meses',
                      isDark,
                    ),
                    _buildInfoRow('Tipo de Alquiler', _alquiler.tipoAlquiler == 'horas' ? 'Por Horas' : 'Por Meses', isDark),
                    if (_alquiler.proyecto != null)
                      _buildInfoRow('Proyecto', _alquiler.proyecto!, isDark),
                    FutureBuilder<bool>(
                      future: AuthService.esAdministrador(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Column(
                            children: [
                              _buildInfoRow('Monto Total', '\$${_alquiler.monto.toStringAsFixed(2)}', isDark),
                              if (_alquiler.montoAdelanto != null)
                                _buildInfoRow(
                                  'Monto Adelantado',
                                  '\$${_alquiler.montoAdelanto!.toStringAsFixed(2)}',
                                  isDark,
                                ),
                              if (_alquiler.montoAdelanto != null)
                                _buildInfoRow(
                                  'Saldo Pendiente',
                                  '\$${(_alquiler.monto - _alquiler.montoAdelanto!).toStringAsFixed(2)}',
                                  isDark,
                                  color: Colors.orange,
                                ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  isDark,
                ),
                const SizedBox(height: 16),
                // Estado y Fechas
                _buildSectionCard(
                  'Estado y Fechas',
                  Icons.info,
                  [
                    _buildInfoRow('Estado', _getEstadoLabel(_alquiler.estado), isDark),
                    _buildInfoRow('Fecha de Registro', fechaFormat.format(_alquiler.fechaRegistro), isDark),
                    if (_alquiler.fechaEntrega != null)
                      _buildInfoRow('Fecha de Entrega', fechaFormat.format(_alquiler.fechaEntrega!), isDark),
                    if (_alquiler.fechaDevolucion != null)
                      _buildInfoRow('Fecha de Devolución', fechaFormat.format(_alquiler.fechaDevolucion!), isDark),
                    if (_alquiler.horasUsoReal != null)
                      _buildInfoRow('Horas de Uso Real', '${_alquiler.horasUsoReal} horas', isDark),
                  ],
                  isDark,
                ),
                if (_alquiler.observaciones != null && _alquiler.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Observaciones',
                    Icons.note,
                    [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _alquiler.observaciones!,
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
                const SizedBox(height: 16),
                // Botones de Acción
                FutureBuilder<bool>(
                  future: AuthService.esAdministrador(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _loading ? null : _mostrarDialogoCambioEstado,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Cambiar Estado'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _controlAlquiler.generarPdfContrato(
                                        _alquiler.id,
                                        context,
                                        mostrarMonto: true,
                                      );
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error al generar PDF: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Generar PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditarContratoScreen(alquiler: _alquiler),
                                      ),
                                    );
                                    if (result == true) {
                                      await _actualizarAlquiler();
                                    }
                                  },
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text('Editar Contrato'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GestionPagosScreen(alquiler: _alquiler),
                                      ),
                                    );
                                    // Actualizar el alquiler después de regresar de gestión de pagos
                                    await _actualizarAlquiler();
                                    // Forzar un rebuild para mostrar los valores actualizados
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.payment),
                                  label: const Text('Gestionar Pagos'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_alquiler.estado == 'entregada' || _alquiler.estado == 'devuelta') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegistrarDevolucionScreen(alquiler: _alquiler),
                                    ),
                                  );
                                  if (result == true) {
                                    await _actualizarAlquiler();
                                  }
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Registrar Devolución / Finalizar Proyecto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, Cliente? cliente, Maquinaria? maquinaria) {
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
            onPressed: () => Navigator.pop(context, true),
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
                  "Detalles del Contrato",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cliente?.nombreCompleto ?? 'Cliente',
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

  Widget _buildInfoPagos(bool isDark) {
    final montoCancelado = _alquiler.montoCancelado ?? 0.0;
    final montoAdelanto = _alquiler.montoAdelanto ?? 0.0;
    final saldoPendiente = _alquiler.monto - montoCancelado;
    final estaPagado = saldoPendiente <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estaPagado ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estaPagado ? Colors.green.shade300 : Colors.orange.shade300,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  estaPagado ? Icons.check_circle : Icons.pending,
                  color: estaPagado ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  estaPagado ? 'PAGO COMPLETADO' : 'PAGO PENDIENTE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: estaPagado ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Monto Total', '\$${_alquiler.monto.toStringAsFixed(2)}', isDark, labelColor: Colors.black, valueColor: Colors.black),
            if (montoAdelanto > 0)
              _buildInfoRow('Monto Adelantado', '\$${montoAdelanto.toStringAsFixed(2)}', isDark, labelColor: Colors.black, valueColor: Colors.black),
            _buildInfoRow(
              'Monto Cancelado',
              '\$${montoCancelado.toStringAsFixed(2)}',
              isDark,
              labelColor: Colors.black,
              valueColor: Colors.green.shade700,
            ),
            _buildInfoRow(
              'Monto a Deuda',
              '\$${saldoPendiente.toStringAsFixed(2)}',
              isDark,
              labelColor: Colors.black,
              valueColor: saldoPendiente > 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
            if (_alquiler.metodoPago != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Método de Pago',
                _alquiler.metodoPago == 'qr'
                    ? 'QR'
                    : _alquiler.metodoPago == 'efectivo'
                        ? 'Efectivo'
                        : _alquiler.metodoPago == 'transferencia'
                            ? 'Transferencia'
                            : _alquiler.metodoPago == 'tarjeta'
                                ? 'Tarjeta'
                                : _alquiler.metodoPago!.toUpperCase(),
                isDark,
                color: isDark ? Colors.white : Colors.black,
              ),
            ],
            if (_alquiler.codigoQR != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código QR para Pago:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Image.memory(
                        base64Decode(_alquiler.codigoQR!),
                        height: 150,
                        width: 150,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadorEstado(bool isDark) {
    final bool activo = !_alquiler.proyectoFinalizado && 
                       _alquiler.estado != 'devuelta' && 
                       _alquiler.estado != 'cancelado';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: activo ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? Colors.green.shade300 : Colors.red.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo ? Colors.green : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: (activo ? Colors.green : Colors.red).withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activo ? 'PROYECTO ACTIVO' : 'PROYECTO FINALIZADO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: activo ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activo
                        ? 'Trabajo en curso - Luz Verde'
                        : 'Trabajo finalizado - Luz Roja',
                    style: TextStyle(
                      fontSize: 12,
                      color: activo ? Colors.green.shade600 : Colors.red.shade600,
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

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade400),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {Color? color, Color? labelColor, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: labelColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? color ?? (isDark ? Colors.white : Colors.grey.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _cargarDatos() async {
    final controlCliente = ControlCliente();
    final controlMaquinaria = ControlMaquinaria();

    final cliente = await controlCliente.consultarCliente(_alquiler.clienteId);
    final maquinaria = await controlMaquinaria.consultarMaquinaria(_alquiler.maquinariaId);

    return {
      'cliente': cliente,
      'maquinaria': maquinaria,
    };
  }
}
