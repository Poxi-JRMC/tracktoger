import 'package:flutter/material.dart';
import '../../../controllers/control_cliente.dart';
import '../../../models/cliente.dart';

class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() => _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState extends State<RegistrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _documentoController = TextEditingController();
  final _empresaController = TextEditingController();
  final _controlCliente = ControlCliente();
  bool _loading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _documentoController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<void> _registrarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cliente = Cliente(
        id: '',
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        documentoIdentidad: _documentoController.text.trim().isEmpty ? null : _documentoController.text.trim(),
        empresa: _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim(),
        fechaRegistro: DateTime.now(),
      );

      await _controlCliente.registrarCliente(cliente);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente registrado correctamente'),
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
        title: const Text('Registrar Cliente'),
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
              _buildTextField(_nombreController, 'Nombre', Icons.person, isDark, true),
              _buildTextField(_apellidoController, 'Apellido', Icons.person_outline, isDark, true),
              _buildTextField(_emailController, 'Email', Icons.email, isDark, true, TextInputType.emailAddress),
              _buildTextField(_telefonoController, 'Teléfono', Icons.phone, isDark, true, TextInputType.phone),
              _buildTextField(_empresaController, 'Empresa (opcional)', Icons.business, isDark, false),
              _buildTextField(_direccionController, 'Dirección (opcional)', Icons.location_on, isDark, false),
              _buildTextField(_documentoController, 'Documento de Identidad (opcional)', Icons.badge, isDark, false),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _registrarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark,
    bool required, [
    TextInputType? keyboardType,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                if (label.contains('Email') && !value.contains('@')) {
                  return 'Ingrese un email válido';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

