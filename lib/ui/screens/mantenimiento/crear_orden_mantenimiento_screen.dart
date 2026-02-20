import 'package:flutter/material.dart';
import '../../../models/maquinaria.dart';
import '../../../models/orden_trabajo.dart';
import '../../../controllers/control_mantenimiento.dart';

/// Pantalla para crear una orden de mantenimiento
/// Permite registrar gastos y repuestos comprados
class CrearOrdenMantenimientoScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const CrearOrdenMantenimientoScreen({
    super.key,
    required this.maquinaria,
  });

  @override
  State<CrearOrdenMantenimientoScreen> createState() => _CrearOrdenMantenimientoScreenState();
}

class _CrearOrdenMantenimientoScreenState extends State<CrearOrdenMantenimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  
  final _descripcionController = TextEditingController();
  final _costoEstimadoController = TextEditingController();
  final _costoRealController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  String _tipoTrabajo = 'preventivo';
  String _prioridad = 'media';
  String _estado = 'pendiente';
  
  // Repuestos y gastos
  final List<Map<String, dynamic>> _repuestos = [];
  final _nombreRepuestoController = TextEditingController();
  final _cantidadRepuestoController = TextEditingController();
  final _precioRepuestoController = TextEditingController();

  @override
  void dispose() {
    _descripcionController.dispose();
    _costoEstimadoController.dispose();
    _costoRealController.dispose();
    _observacionesController.dispose();
    _nombreRepuestoController.dispose();
    _cantidadRepuestoController.dispose();
    _precioRepuestoController.dispose();
    super.dispose();
  }

  void _agregarRepuesto() {
    if (_nombreRepuestoController.text.isNotEmpty &&
        _cantidadRepuestoController.text.isNotEmpty &&
        _precioRepuestoController.text.isNotEmpty) {
      setState(() {
        _repuestos.add({
          'nombre': _nombreRepuestoController.text,
          'cantidad': int.tryParse(_cantidadRepuestoController.text) ?? 1,
          'precio': double.tryParse(_precioRepuestoController.text) ?? 0.0,
        });
        _nombreRepuestoController.clear();
        _cantidadRepuestoController.clear();
        _precioRepuestoController.clear();
      });
    }
  }

  void _eliminarRepuesto(int index) {
    setState(() {
      _repuestos.removeAt(index);
    });
  }

  Future<void> _crearOrden() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Calcular costo total de repuestos
        final costoRepuestos = _repuestos.fold<double>(
          0.0,
          (sum, repuesto) => sum + (repuesto['precio'] * repuesto['cantidad']),
        );
        
        // Calcular costo total
        final costoEstimado = double.tryParse(_costoEstimadoController.text) ?? 0.0;
        final costoReal = double.tryParse(_costoRealController.text) ?? costoRepuestos;
        final costoTotal = costoReal + costoRepuestos;
        
        final orden = OrdenTrabajo(
          id: 'orden_${DateTime.now().millisecondsSinceEpoch}',
          maquinariaId: widget.maquinaria.id,
          numeroOrden: 'OT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          descripcion: _descripcionController.text,
          tipoTrabajo: _tipoTrabajo,
          prioridad: _prioridad,
          estado: _estado,
          fechaCreacion: DateTime.now(),
          costoEstimado: costoEstimado > 0 ? costoEstimado : null,
          costoReal: costoTotal > 0 ? costoTotal : null,
          observaciones: _observacionesController.text.isNotEmpty 
              ? _observacionesController.text 
              : null,
          tareas: _repuestos.map((r) => 
            '${r['cantidad']}x ${r['nombre']} - \$${(r['precio'] * r['cantidad']).toStringAsFixed(2)}'
          ).toList(),
        );

        await _controlMantenimiento.crearOrdenTrabajo(orden);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Orden de trabajo creada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final costoTotalRepuestos = _repuestos.fold<double>(
      0.0,
      (sum, repuesto) => sum + (repuesto['precio'] * repuesto['cantidad']),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Orden: ${widget.maquinaria.nombre}'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción del Trabajo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        hintText: 'Describe el trabajo a realizar...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tipo de Trabajo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _tipoTrabajo,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'preventivo', child: const Text('Preventivo')),
                                  DropdownMenuItem(value: 'correctivo', child: const Text('Correctivo')),
                                  DropdownMenuItem(value: 'emergencia', child: const Text('Emergencia')),
                                ],
                                onChanged: (value) => setState(() => _tipoTrabajo = value!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prioridad',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _prioridad,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'baja', child: const Text('Baja')),
                                  DropdownMenuItem(value: 'media', child: const Text('Media')),
                                  DropdownMenuItem(value: 'alta', child: const Text('Alta')),
                                  DropdownMenuItem(value: 'critica', child: const Text('Crítica')),
                                ],
                                onChanged: (value) => setState(() => _prioridad = value!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Repuestos y gastos
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Repuestos y Piezas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        if (costoTotalRepuestos > 0)
                          Text(
                            'Total: \$${costoTotalRepuestos.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nombreRepuestoController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadRepuestoController,
                            decoration: InputDecoration(
                              labelText: 'Cant.',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _precioRepuestoController,
                            decoration: InputDecoration(
                              labelText: 'Precio',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _agregarRepuesto,
                          icon: const Icon(Icons.add_circle),
                          color: Colors.green,
                          iconSize: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_repuestos.isNotEmpty)
                      ..._repuestos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final repuesto = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${repuesto['cantidad']}x ${repuesto['nombre']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '\$${(repuesto['precio'] * repuesto['cantidad']).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _eliminarRepuesto(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Costos
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Costos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costoEstimadoController,
                      decoration: InputDecoration(
                        labelText: 'Costo Estimado (\$)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costoRealController,
                      decoration: InputDecoration(
                        labelText: 'Costo Real (\$)',
                        hintText: 'Si ya se completó el trabajo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacionesController,
                      decoration: InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Botón crear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _crearOrden,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Crear Orden de Trabajo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

