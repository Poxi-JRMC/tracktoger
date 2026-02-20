import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/maquinaria.dart';
import '../../../models/categoria.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../utils/image_utils.dart';

/// Pantalla para editar una maquinaria existente
class EditarMaquinariaScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const EditarMaquinariaScreen({super.key, required this.maquinaria});

  @override
  State<EditarMaquinariaScreen> createState() => _EditarMaquinariaScreenState();
}

class _EditarMaquinariaScreenState extends State<EditarMaquinariaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apodoController = TextEditingController();
  final _modeloController = TextEditingController();
  final _marcaController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _valorController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _horasUsoController = TextEditingController();

  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ImagePicker _picker = ImagePicker();

  List<Categoria> _categorias = [];
  String _categoriaSeleccionada = '';
  String _estadoSeleccionado = 'disponible';
  File? _imagenSeleccionada;
  List<String> _imagenesBase64 = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _inicializarFormulario();
  }

  Future<void> _cargarDatos() async {
    final categorias = await _controlMaquinaria.consultarTodasCategorias();
    setState(() {
      _categorias = categorias;
    });
  }

  void _inicializarFormulario() {
    _nombreController.text = widget.maquinaria.nombre;
    _apodoController.text = widget.maquinaria.apodo ?? '';
    _modeloController.text = widget.maquinaria.modelo;
    _marcaController.text = widget.maquinaria.marca;
    _numeroSerieController.text = widget.maquinaria.numeroSerie;
    _valorController.text = widget.maquinaria.valorAdquisicion.toStringAsFixed(0);
    _descripcionController.text = widget.maquinaria.descripcion ?? '';
    _ubicacionController.text = widget.maquinaria.ubicacion ?? '';
    _horasUsoController.text = widget.maquinaria.horasUso.toString();
    _categoriaSeleccionada = widget.maquinaria.categoriaId;
    _estadoSeleccionado = widget.maquinaria.estado;
    _imagenesBase64 = List.from(widget.maquinaria.imagenes);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apodoController.dispose();
    _modeloController.dispose();
    _marcaController.dispose();
    _numeroSerieController.dispose();
    _valorController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _horasUsoController.dispose();
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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final maquinariaActualizada = widget.maquinaria.copyWith(
        nombre: _nombreController.text.trim(),
        apodo: _apodoController.text.trim().isEmpty ? null : _apodoController.text.trim(),
        modelo: _modeloController.text.trim(),
        marca: _marcaController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim(),
        categoriaId: _categoriaSeleccionada,
        valorAdquisicion: double.tryParse(_valorController.text) ?? widget.maquinaria.valorAdquisicion,
        estado: _estadoSeleccionado,
        ubicacion: _ubicacionController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        imagenes: _imagenesBase64,
        horasUso: int.tryParse(_horasUsoController.text) ?? widget.maquinaria.horasUso,
      );

      await _controlMaquinaria.actualizarMaquinaria(maquinariaActualizada);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maquinaria actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al actualizar maquinaria: $e');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Maquinaria'),
        backgroundColor: const Color(0xFF1B1B1B),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            TextButton(
              onPressed: _guardarCambios,
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto de la maquinaria
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto de la Maquinaria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          ),
                          child: _imagenSeleccionada != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imagenSeleccionada!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : _imagenesBase64.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(_imagenesBase64.first),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Toca para cambiar foto',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
              const SizedBox(height: 16),
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
                        'Información Básica',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del equipo',
                          prefixIcon: const Icon(Icons.construction),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apodoController,
                        decoration: InputDecoration(
                          labelText: 'Apodo (opcional)',
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Ej: "La Roca", "El Gigante"...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _marcaController,
                              decoration: InputDecoration(
                                labelText: 'Marca',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'La marca es requerida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _modeloController,
                              decoration: InputDecoration(
                                labelText: 'Modelo',
                                prefixIcon: const Icon(Icons.model_training),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El modelo es requerido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numeroSerieController,
                        decoration: InputDecoration(
                          labelText: 'Número de serie',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El número de serie es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _categoriaSeleccionada.isEmpty ? null : _categoriaSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _categorias.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria.id,
                            child: Text(categoria.nombre),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _categoriaSeleccionada = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione una categoría';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Información adicional
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información Adicional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valorController,
                        decoration: InputDecoration(
                          labelText: 'Valor de adquisición',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El valor es requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un valor válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _horasUsoController,
                        decoration: InputDecoration(
                          labelText: 'Horas de uso',
                          prefixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Las horas de uso son requeridas';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ubicacionController,
                        decoration: InputDecoration(
                          labelText: 'Ubicación actual',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _estadoSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: const Icon(Icons.info),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                          DropdownMenuItem(value: 'alquilado', child: Text('Alquilado')),
                          DropdownMenuItem(value: 'mantenimiento', child: Text('En Mantenimiento')),
                          DropdownMenuItem(value: 'fuera_servicio', child: Text('Fuera de Servicio')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _estadoSeleccionado = value ?? 'disponible';
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
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

