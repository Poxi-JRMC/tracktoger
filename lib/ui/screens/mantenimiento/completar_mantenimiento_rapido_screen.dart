import 'package:flutter/material.dart';
import 'package:tracktoger/models/maquinaria.dart';
import 'package:tracktoger/models/registro_mantenimiento.dart';
import 'package:tracktoger/controllers/control_mantenimiento.dart';
import 'package:tracktoger/controllers/control_maquinaria.dart';

/// Pantalla simple para completar un mantenimiento desde una recomendación
/// Permite agregar costo y detalle rápidamente
class CompletarMantenimientoRapidoScreen extends StatefulWidget {
  final Maquinaria maquinaria;
  final String tipoMantenimiento;
  final String descripcionTrabajo;
  final String tipoReset; // 'motor', 'hidraulico', 'ambos'

  const CompletarMantenimientoRapidoScreen({
    super.key,
    required this.maquinaria,
    required this.tipoMantenimiento,
    required this.descripcionTrabajo,
    required this.tipoReset,
  });

  @override
  State<CompletarMantenimientoRapidoScreen> createState() =>
      _CompletarMantenimientoRapidoScreenState();
}

class _CompletarMantenimientoRapidoScreenState
    extends State<CompletarMantenimientoRapidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costoController = TextEditingController();
  final _detalleController = TextEditingController();
  final _controlMantenimiento = ControlMantenimiento();
  final _controlMaquinaria = ControlMaquinaria();
  bool _loading = false;

  @override
  void dispose() {
    _costoController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _completarMantenimiento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final costo = double.tryParse(_costoController.text) ?? 0.0;
      final detalle = _detalleController.text.trim();

      // Crear registro de mantenimiento completado
      final nuevoRegistro = RegistroMantenimiento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idMaquinaria: widget.maquinaria.id,
        tipoMantenimiento: 'preventivo',
        descripcionTrabajo: widget.descripcionTrabajo,
        estado: 'completado',
        fechaCreacion: DateTime.now(),
        fechaProgramada: DateTime.now(),
        fechaRealizacion: DateTime.now(),
        costoRepuestos: 0.0,
        costoManoObra: costo,
        costoOtros: 0.0,
        notas: detalle.isNotEmpty
            ? 'Detalle: $detalle\nCompletado desde recomendación de mantenimiento'
            : 'Completado desde recomendación de mantenimiento',
      );

      await _controlMantenimiento.crearRegistroMantenimiento(nuevoRegistro);

      // Resetear horas de mantenimiento según el tipo
      await _controlMaquinaria.resetearHorasMantenimiento(
        widget.maquinaria.id,
        widget.tipoReset,
      );

      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mantenimiento completado: ${widget.descripcionTrabajo}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al completar mantenimiento: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Completar Mantenimiento'),
        backgroundColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la máquina
              Card(
                color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.construction,
                            color: Colors.yellow.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.maquinaria.nombre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.descripcionTrabajo,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Campo de costo
              TextFormField(
                controller: _costoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Costo del Mantenimiento',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el costo del mantenimiento';
                  }
                  final costo = double.tryParse(value);
                  if (costo == null || costo < 0) {
                    return 'Ingrese un costo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Campo de detalle
              TextFormField(
                controller: _detalleController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Detalle del Mantenimiento',
                  hintText: 'Describa el trabajo realizado...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              
              // Botón de completar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _completarMantenimiento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Completar Mantenimiento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

