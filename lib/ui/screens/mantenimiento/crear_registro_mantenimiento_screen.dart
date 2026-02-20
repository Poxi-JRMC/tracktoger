import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/maquinaria.dart';
import '../../../models/registro_mantenimiento.dart';
import '../../../controllers/control_mantenimiento.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../utils/image_utils.dart';

/// Pantalla para crear o editar un registro de mantenimiento completo
class CrearRegistroMantenimientoScreen extends StatefulWidget {
  final Maquinaria? maquinaria; // Opcional, puede ser null si se selecciona después
  final RegistroMantenimiento? registroEditar; // Si se proporciona, se edita en lugar de crear

  const CrearRegistroMantenimientoScreen({
    super.key,
    this.maquinaria,
    this.registroEditar,
  });

  @override
  State<CrearRegistroMantenimientoScreen> createState() => _CrearRegistroMantenimientoScreenState();
}

class _CrearRegistroMantenimientoScreenState extends State<CrearRegistroMantenimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final ImagePicker _picker = ImagePicker();
  
  final _descripcionController = TextEditingController();
  final _costoRepuestosController = TextEditingController();
  final _costoManoObraController = TextEditingController();
  final _costoOtrosController = TextEditingController();
  final _notasController = TextEditingController();
  
  // Controllers para repuestos
  final List<Map<String, TextEditingController>> _repuestos = [];
  final _nombreRepuestoController = TextEditingController();
  final _cantidadRepuestoController = TextEditingController();
  final _precioRepuestoController = TextEditingController();
  
  Maquinaria? _maquinariaSeleccionada;
  String _tipoMantenimiento = 'preventivo';
  String _prioridad = 'media';
  String _tipoRegistro = 'general'; // general, repuestos, mecanico
  DateTime _fechaProgramada = DateTime.now();
  File? _imagenSeleccionada;
  String? _imagenBase64;
  bool _loading = false;
  
  List<Maquinaria> _maquinarias = [];

  @override
  void initState() {
    super.initState();
    _maquinariaSeleccionada = widget.maquinaria;
    _cargarMaquinarias();
    
    // Si se está editando, cargar los datos del registro
    if (widget.registroEditar != null) {
      final registro = widget.registroEditar!;
      _descripcionController.text = registro.descripcionTrabajo;
      _costoRepuestosController.text = registro.costoRepuestos.toString();
      _costoManoObraController.text = registro.costoManoObra.toString();
      _costoOtrosController.text = registro.costoOtros.toString();
      _notasController.text = registro.notas ?? '';
      _tipoMantenimiento = registro.tipoMantenimiento;
      _fechaProgramada = registro.fechaProgramada;
      
      // Buscar la maquinaria asociada
      _cargarMaquinarias().then((_) {
        if (mounted) {
          setState(() {
            _maquinariaSeleccionada = _maquinarias.firstWhere(
              (m) => m.id == registro.idMaquinaria,
              orElse: () => _maquinarias.isNotEmpty ? _maquinarias.first : Maquinaria(
                id: '',
                nombre: '',
                modelo: '',
                marca: '',
                numeroSerie: '',
                categoriaId: '',
                fechaAdquisicion: DateTime.now(),
                valorAdquisicion: 0,
                fechaUltimoMantenimiento: DateTime.now(),
              ),
            );
          });
        }
      });
    }
  }

  Future<void> _cargarMaquinarias() async {
    try {
      final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
      setState(() {
        _maquinarias = maquinarias;
      });
    } catch (e) {
      print('Error al cargar maquinarias: $e');
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (imagen != null) {
        final file = File(imagen.path);
        final base64 = await ImageUtils.imageToBase64(file);
        setState(() {
          _imagenSeleccionada = file;
          _imagenBase64 = base64;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  double get _costoTotal {
    final repuestos = double.tryParse(_costoRepuestosController.text) ?? 0.0;
    final manoObra = double.tryParse(_costoManoObraController.text) ?? 0.0;
    final otros = double.tryParse(_costoOtrosController.text) ?? 0.0;
    return repuestos + manoObra + otros;
  }

  Future<void> _crearRegistro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_maquinariaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una máquina'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Preparar lista de materiales/repuestos
      final materiales = <String>[];
      if (_imagenBase64 != null) {
        materiales.add(_imagenBase64!);
      }
      
      // Agregar información de repuestos a las notas si hay
      String notasCompletas = _notasController.text;
      if (_repuestos.isNotEmpty) {
        final repuestosInfo = _repuestos.map((r) {
          final nombre = r['nombre']?.text ?? '';
          final cantidad = r['cantidad']?.text ?? '0';
          final precio = r['precio']?.text ?? '0.0';
          return '$nombre (Cant: $cantidad, Precio: \$$precio)';
        }).join('\n');
        notasCompletas = notasCompletas.isEmpty 
            ? 'Repuestos:\n$repuestosInfo'
            : '${notasCompletas}\n\nRepuestos:\n$repuestosInfo';
      }
      
      // Agregar tipo de registro a las notas
      if (_tipoRegistro != 'general') {
        notasCompletas = notasCompletas.isEmpty
            ? 'Tipo de registro: ${_tipoRegistro == 'repuestos' ? 'Repuestos' : 'Mecánico'}'
            : '${notasCompletas}\nTipo de registro: ${_tipoRegistro == 'repuestos' ? 'Repuestos' : 'Mecánico'}';
      }
      
      // Si se está editando, actualizar el registro existente
      if (widget.registroEditar != null) {
        final registroActualizado = widget.registroEditar!.copyWith(
          idMaquinaria: _maquinariaSeleccionada!.id,
          fechaProgramada: _fechaProgramada,
          tipoMantenimiento: _tipoMantenimiento,
          descripcionTrabajo: _descripcionController.text,
          costoRepuestos: double.tryParse(_costoRepuestosController.text) ?? 0.0,
          costoManoObra: double.tryParse(_costoManoObraController.text) ?? 0.0,
          costoOtros: double.tryParse(_costoOtrosController.text) ?? 0.0,
          notas: notasCompletas.isNotEmpty ? notasCompletas : null,
          materiales: materiales,
        );
        
        await _controlMantenimiento.actualizarRegistroMantenimiento(registroActualizado);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Mantenimiento actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }
      
      // Si no se está editando, crear un nuevo registro
      final registro = RegistroMantenimiento(
        id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
        idMaquinaria: _maquinariaSeleccionada!.id,
        fechaProgramada: _fechaProgramada,
        tipoMantenimiento: _tipoMantenimiento,
        descripcionTrabajo: _descripcionController.text,
        estado: 'pendiente',
        costoRepuestos: double.tryParse(_costoRepuestosController.text) ?? 0.0,
        costoManoObra: double.tryParse(_costoManoObraController.text) ?? 0.0,
        costoOtros: double.tryParse(_costoOtrosController.text) ?? 0.0,
        notas: notasCompletas.isNotEmpty ? notasCompletas : null,
        fechaCreacion: DateTime.now(),
        materiales: materiales,
      );

      await _controlMantenimiento.crearRegistroMantenimiento(registro);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro de mantenimiento creado correctamente'),
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
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaProgramada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() => _fechaProgramada = fecha);
    }
  }

  void _agregarRepuesto() {
    final nombre = _nombreRepuestoController.text.trim();
    final cantidad = int.tryParse(_cantidadRepuestoController.text) ?? 0;
    final precio = double.tryParse(_precioRepuestoController.text) ?? 0.0;
    
    if (nombre.isEmpty || cantidad <= 0 || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete todos los campos del repuesto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _repuestos.add({
        'nombre': TextEditingController(text: nombre),
        'cantidad': TextEditingController(text: cantidad.toString()),
        'precio': TextEditingController(text: precio.toStringAsFixed(2)),
      });
      _nombreRepuestoController.clear();
      _cantidadRepuestoController.clear();
      _precioRepuestoController.clear();
    });
    
    // Actualizar costo de repuestos
    _actualizarCostoRepuestos();
  }
  
  void _eliminarRepuesto(int index) {
    setState(() {
      _repuestos[index]['nombre']?.dispose();
      _repuestos[index]['cantidad']?.dispose();
      _repuestos[index]['precio']?.dispose();
      _repuestos.removeAt(index);
    });
    _actualizarCostoRepuestos();
  }
  
  void _actualizarCostoRepuestos() {
    double total = 0.0;
    for (var repuesto in _repuestos) {
      final cantidad = int.tryParse(repuesto['cantidad']?.text ?? '0') ?? 0;
      final precio = double.tryParse(repuesto['precio']?.text ?? '0') ?? 0.0;
      total += cantidad * precio;
    }
    _costoRepuestosController.text = total.toStringAsFixed(2);
    setState(() {});
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _costoRepuestosController.dispose();
    _costoManoObraController.dispose();
    _costoOtrosController.dispose();
    _notasController.dispose();
    _nombreRepuestoController.dispose();
    _cantidadRepuestoController.dispose();
    _precioRepuestoController.dispose();
    for (var repuesto in _repuestos) {
      repuesto['nombre']?.dispose();
      repuesto['cantidad']?.dispose();
      repuesto['precio']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.registroEditar != null
            ? 'Editar Mantenimiento'
            : (_maquinariaSeleccionada != null 
                ? 'Nuevo Mantenimiento: ${_maquinariaSeleccionada!.nombre}'
                : 'Nuevo Registro de Mantenimiento')),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selección de máquina
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Máquina',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Maquinaria>(
                      value: _maquinariaSeleccionada,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      ),
                      items: _maquinarias.map((maq) {
                        return DropdownMenuItem(
                          value: maq,
                          child: Text(maq.nombre),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _maquinariaSeleccionada = value),
                      validator: (value) => value == null ? 'Seleccione una máquina' : null,
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
                      'Información del Mantenimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción del trabajo',
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
                                'Tipo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _tipoMantenimiento,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'preventivo', child: Text('Preventivo')),
                                  DropdownMenuItem(value: 'correctivo', child: Text('Correctivo')),
                                  DropdownMenuItem(value: 'emergencia', child: Text('Emergencia')),
                                ],
                                onChanged: (value) => setState(() => _tipoMantenimiento = value!),
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
                                items: const [
                                  DropdownMenuItem(value: 'baja', child: Text('Baja')),
                                  DropdownMenuItem(value: 'media', child: Text('Media')),
                                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                                  DropdownMenuItem(value: 'critica', child: Text('Crítica')),
                                ],
                                onChanged: (value) => setState(() => _prioridad = value!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha Programada',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_fechaProgramada.day}/${_fechaProgramada.month}/${_fechaProgramada.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipo de registro
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de Registro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('General'),
                            selected: _tipoRegistro == 'general',
                            onSelected: (selected) {
                              if (selected) setState(() => _tipoRegistro = 'general');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Repuestos'),
                            selected: _tipoRegistro == 'repuestos',
                            onSelected: (selected) {
                              if (selected) setState(() => _tipoRegistro = 'repuestos');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Mecánico'),
                            selected: _tipoRegistro == 'mecanico',
                            onSelected: (selected) {
                              if (selected) setState(() => _tipoRegistro = 'mecanico');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Repuestos (si tipo es repuestos o general)
            if (_tipoRegistro == 'repuestos' || _tipoRegistro == 'general') ...[
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
                            'Repuestos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _agregarRepuesto,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Formulario para agregar repuesto
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _nombreRepuestoController,
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _cantidadRepuestoController,
                              decoration: InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _precioRepuestoController,
                              decoration: InputDecoration(
                                labelText: 'Precio',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      // Lista de repuestos agregados
                      if (_repuestos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        ..._repuestos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final repuesto = entry.value;
                          final nombre = repuesto['nombre']?.text ?? '';
                          final cantidad = repuesto['cantidad']?.text ?? '0';
                          final precio = repuesto['precio']?.text ?? '0.0';
                          final total = (int.tryParse(cantidad) ?? 0) * (double.tryParse(precio) ?? 0.0);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(nombre),
                              subtitle: Text('Cantidad: $cantidad × Bs$precio = Bs${total.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarRepuesto(index),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Costos
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
                          'Costos (Bs)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Total: Bs ${_costoTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costoRepuestosController,
                      decoration: InputDecoration(
                        labelText: 'Costo Repuestos (Bs)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        prefixText: 'Bs ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}), // Actualizar total
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costoManoObraController,
                      decoration: InputDecoration(
                        labelText: 'Costo Mano de Obra (Bs)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        prefixText: 'Bs ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}), // Actualizar total
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costoOtrosController,
                      decoration: InputDecoration(
                        labelText: 'Otros Costos (Bs)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        prefixText: 'Bs ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}), // Actualizar total
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Imagen
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Imagen (Opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_imagenSeleccionada != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imagenSeleccionada!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(() {
                                _imagenSeleccionada = null;
                                _imagenBase64 = null;
                              }),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarImagen,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Agregar Imagen'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notas
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas Adicionales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notasController,
                      decoration: InputDecoration(
                        hintText: 'Observaciones, comentarios...',
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
                onPressed: _loading ? null : _crearRegistro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Crear Registro de Mantenimiento',
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

