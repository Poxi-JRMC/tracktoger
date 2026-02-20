import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/herramienta.dart';
import '../../../models/maquinaria.dart';
import '../../../controllers/control_herramienta.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../utils/image_utils.dart';
import '../../../core/auth_service.dart';

/// Pantalla completa para registrar nueva herramienta
class RegistrarHerramientaScreen extends StatefulWidget {
  const RegistrarHerramientaScreen({super.key});

  @override
  State<RegistrarHerramientaScreen> createState() => _RegistrarHerramientaScreenState();
}

class _RegistrarHerramientaScreenState extends State<RegistrarHerramientaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _tipoController = TextEditingController();
  final _marcaController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _descripcionController = TextEditingController();

  final ControlHerramienta _controlHerramienta = ControlHerramienta();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ImagePicker _picker = ImagePicker();

  List<Maquinaria> _maquinarias = [];
  String _maquinariaSeleccionada = '';
  String _condicionSeleccionada = 'buena';
  File? _imagenSeleccionada;
  List<String> _imagenesBase64 = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  Future<void> _verificarPermisos() async {
    final esAdmin = await AuthService.esAdministrador();
    if (!esAdmin && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para registrar herramientas'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }
    _cargarMaquinarias();
  }

  Future<void> _cargarMaquinarias() async {
    setState(() => _loading = true);
    try {
      final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
      setState(() {
        _maquinarias = maquinarias;
        if (_maquinarias.isNotEmpty && _maquinariaSeleccionada.isEmpty) {
          _maquinariaSeleccionada = _maquinarias.first.id;
        }
      });
    } catch (e) {
      _mostrarError('Error al cargar maquinarias: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _marcaController.dispose();
    _numeroSerieController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        final file = File(image.path);
        if (await ImageUtils.getFileSizeMB(file) > 5) {
          _mostrarError('La imagen es demasiado grande. Máximo 5MB');
          return;
        }
        setState(() {
          _imagenSeleccionada = file;
        });
        final base64 = await ImageUtils.imageToBase64(file);
        setState(() {
          _imagenesBase64 = [base64];
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _registrarHerramienta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_maquinariaSeleccionada.isEmpty) {
      _mostrarError('Por favor seleccione una maquinaria');
      return;
    }

    setState(() => _loading = true);
    try {
      final herramienta = Herramienta(
        id: '', // Se generará automáticamente
        nombre: _nombreController.text.trim(),
        tipo: _tipoController.text.trim(),
        marca: _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim().isEmpty ? null : _numeroSerieController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        condicion: _condicionSeleccionada,
        maquinariaId: _maquinariaSeleccionada,
        imagenes: _imagenesBase64,
        fechaRegistro: DateTime.now(),
      );

      await _controlHerramienta.registrarHerramienta(herramienta);
      
      if (mounted) {
        _mostrarExito('Herramienta registrada exitosamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarError('Error al registrar herramienta: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Herramienta'),
        backgroundColor: const Color(0xFF1B1B1B),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            TextButton(
              onPressed: _registrarHerramienta,
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
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
                    // Foto de la herramienta
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.photo_camera, color: Colors.blue.shade400),
                                const SizedBox(width: 8),
                                Text(
                                  'Foto de la Herramienta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.photo_camera),
                                          title: const Text('Tomar foto'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _seleccionarImagen(ImageSource.camera);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo_library),
                                          title: const Text('Seleccionar de la galería'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _seleccionarImagen(ImageSource.gallery);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue.shade300, width: 2, style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                ),
                                child: _imagenSeleccionada != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _imagenSeleccionada!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 56,
                                            color: Colors.blue.shade300,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Toca para agregar foto',
                                            style: TextStyle(
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Información básica
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre de la herramienta',
                                prefixIcon: const Icon(Icons.build),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tipoController,
                              decoration: InputDecoration(
                                labelText: 'Tipo de herramienta',
                                prefixIcon: const Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: 'Ej: Martillo, Destornillador, Llave...',
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El tipo es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _marcaController,
                                    decoration: InputDecoration(
                                      labelText: 'Marca (opcional)',
                                      prefixIcon: const Icon(Icons.business),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                    ),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _numeroSerieController,
                                    decoration: InputDecoration(
                                      labelText: 'Número de serie (opcional)',
                                      prefixIcon: const Icon(Icons.qr_code),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                    ),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _maquinariaSeleccionada.isEmpty ? null : _maquinariaSeleccionada,
                              decoration: InputDecoration(
                                labelText: 'Maquinaria asociada',
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
                                  child: Text('${maq.nombre} - ${maq.marca} ${maq.modelo}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _maquinariaSeleccionada = value ?? '';
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
                    // Información adicional
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description, color: Colors.blue.shade400),
                                const SizedBox(width: 8),
                                Text(
                                  'Información Adicional',
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
                              value: _condicionSeleccionada,
                              decoration: InputDecoration(
                                labelText: 'Condición',
                                prefixIcon: const Icon(Icons.info),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              items: const [
                                DropdownMenuItem(value: 'nueva', child: Text('Nueva')),
                                DropdownMenuItem(value: 'buena', child: Text('Buena')),
                                DropdownMenuItem(value: 'regular', child: Text('Regular')),
                                DropdownMenuItem(value: 'desgastada', child: Text('Desgastada')),
                                DropdownMenuItem(value: 'dañada', child: Text('Dañada')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _condicionSeleccionada = value ?? 'buena';
                                });
                              },
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _registrarHerramienta,
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
                                  'Registrar Herramienta',
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
