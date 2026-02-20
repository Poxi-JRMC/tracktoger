import 'package:flutter/material.dart';
import '../../../models/alquiler.dart';
import '../../../controllers/control_alquiler.dart';

class RegistrarEntregaScreen extends StatefulWidget {
  final Alquiler alquiler;

  const RegistrarEntregaScreen({super.key, required this.alquiler});

  @override
  State<RegistrarEntregaScreen> createState() => _RegistrarEntregaScreenState();
}

class _RegistrarEntregaScreenState extends State<RegistrarEntregaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _proyectoController = TextEditingController();
  final _controlAlquiler = ControlAlquiler();
  bool _loading = false;

  @override
  void dispose() {
    _proyectoController.dispose();
    super.dispose();
  }

  Future<void> _registrarEntrega() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _controlAlquiler.registrarEntrega(
        widget.alquiler.id,
        _proyectoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega registrada correctamente'),
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
        title: const Text('Registrar Entrega'),
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
                        'Proyecto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _proyectoController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Proyecto',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el nombre del proyecto';
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
                onPressed: _loading ? null : _registrarEntrega,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar Entrega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

