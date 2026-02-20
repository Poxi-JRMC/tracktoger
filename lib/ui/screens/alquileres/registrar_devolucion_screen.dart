import 'package:flutter/material.dart';
import '../../../models/alquiler.dart';
import '../../../models/maquinaria.dart';
import '../../../controllers/control_alquiler.dart';
import '../../../controllers/control_maquinaria.dart';

class RegistrarDevolucionScreen extends StatefulWidget {
  final Alquiler alquiler;

  const RegistrarDevolucionScreen({super.key, required this.alquiler});

  @override
  State<RegistrarDevolucionScreen> createState() => _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState extends State<RegistrarDevolucionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _horasController = TextEditingController();
  final _controlAlquiler = ControlAlquiler();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  Maquinaria? _maquinaria;
  bool _loading = false;
  bool _loadingMaquinaria = false;

  @override
  void initState() {
    super.initState();
    _cargarMaquinaria();
  }

  Future<void> _cargarMaquinaria() async {
    setState(() {
      _loadingMaquinaria = true;
    });
    try {
      final maq = await _controlMaquinaria.consultarMaquinaria(widget.alquiler.maquinariaId);
      if (mounted) {
        setState(() {
          _maquinaria = maq;
        });
      }
    } catch (e) {
      // En caso de error, solo lo mostramos en consola y continuamos
      print('❌ Error al cargar maquinaria para devolución: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingMaquinaria = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _horasController.dispose();
    super.dispose();
  }

  Future<void> _registrarDevolucion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final horasUso = int.parse(_horasController.text);
      await _controlAlquiler.registrarDevolucion(widget.alquiler.id, horasUso);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devolución registrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Devolución'),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horas de Uso Real',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Horas actuales de la máquina (solo lectura, fondo gris)
                      if (_loadingMaquinaria)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(),
                        )
                      else if (_maquinaria != null) ...[
                        TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Horas actuales de la máquina',
                            prefixIcon: const Icon(Icons.info_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            // Fondo gris suave para dar efecto "deshabilitado"
                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          controller: TextEditingController(
                            text: '${_maquinaria!.horasUso} h',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _horasController,
                        decoration: InputDecoration(
                          labelText: 'Horas trabajadas en el proyecto',
                          helperText: 'Ingrese SOLO las horas trabajadas durante este contrato',
                          prefixIcon: const Icon(Icons.access_time),
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
                            return 'Ingrese las horas trabajadas';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Ingrese un número válido mayor o igual a 0';
                          }
                          // Aquí NO comparamos con las horas actuales:
                          // este valor representa las horas trabajadas en el contrato,
                          // y luego el controlador las suma a las horas actuales.
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _registrarDevolucion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar Devolución', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

