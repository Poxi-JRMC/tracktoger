import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/maquinaria.dart';
import '../../../models/categoria.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../utils/image_utils.dart';
import '../../../core/auth_service.dart';
import 'editar_maquinaria_screen.dart';
import 'detalles_maquinaria_screen.dart';

/// Pantalla de gestión de maquinaria
/// Permite registrar, actualizar y visualizar maquinaria del inventario
class MaquinariaScreen extends StatefulWidget {
  const MaquinariaScreen({super.key});

  @override
  State<MaquinariaScreen> createState() => _MaquinariaScreenState();
}

class _MaquinariaScreenState extends State<MaquinariaScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  
  List<Maquinaria> _maquinaria = [];
  List<Categoria> _categorias = [];
  bool _loading = false;
  String _filtroEstado = 'todos';
  bool _esAdmin = false;

  // Controladores para el formulario
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _modeloController = TextEditingController();
  final _marcaController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _valorController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  String _categoriaSeleccionada = '';
  String _estadoSeleccionado = 'disponible';
  
  // Variables para imágenes
  final ImagePicker _picker = ImagePicker();
  File? _imagenSeleccionada;
  List<String> _imagenesBase64 = [];

  @override
  void initState() {
    super.initState();
    _inicializarTabs();
    ControlMaquinaria.inicializarDatosPrueba();
    _cargarDatos();
  }

  Future<void> _inicializarTabs() async {
    final esAdmin = await AuthService.esAdministrador();
    setState(() {
      _esAdmin = esAdmin;
      final length = esAdmin ? 3 : 2; // 3 si es admin (Inventario, Registrar, Estadísticas), 2 si no (Inventario, Estadísticas)
      _tabController = TabController(length: length, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nombreController.dispose();
    _modeloController.dispose();
    _marcaController.dispose();
    _numeroSerieController.dispose();
    _valorController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  /// Carga los datos iniciales
  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final maquinaria = await _controlMaquinaria.consultarTodasMaquinarias();
      final categorias = await _controlMaquinaria.consultarTodasCategorias();
      
      setState(() {
        _maquinaria = maquinaria;
        _categorias = categorias;
        if (_categorias.isNotEmpty && _categoriaSeleccionada.isEmpty) {
          _categoriaSeleccionada = _categorias.first.id;
        }
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Muestra un mensaje de error
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Muestra un mensaje de éxito
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Limpia el formulario
  void _limpiarFormulario() {
    _nombreController.clear();
    _modeloController.clear();
    _marcaController.clear();
    _numeroSerieController.clear();
    _valorController.clear();
    _descripcionController.clear();
    _ubicacionController.clear();
    _estadoSeleccionado = 'disponible';
    _imagenSeleccionada = null;
    _imagenesBase64 = [];
  }

  /// Selecciona una imagen desde la galería o cámara
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
        // Convertir a base64
        final base64 = await ImageUtils.imageToBase64(file);
        setState(() {
          _imagenesBase64 = [base64];
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  /// Registra una nueva maquinaria
  Future<void> _registrarMaquinaria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final maquinaria = Maquinaria(
        id: '', // Se generará automáticamente
        nombre: _nombreController.text.trim(),
        modelo: _modeloController.text.trim(),
        marca: _marcaController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim(),
        categoriaId: _categoriaSeleccionada,
        fechaAdquisicion: DateTime.now(),
        valorAdquisicion: double.tryParse(_valorController.text) ?? 0.0,
        estado: _estadoSeleccionado,
        ubicacion: _ubicacionController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        imagenes: _imagenesBase64, // Guardar imágenes en base64
        fechaUltimoMantenimiento: DateTime.now(),
      );

      await _controlMaquinaria.registrarMaquinaria(maquinaria);
      await _cargarDatos();
      _limpiarFormulario();
      _mostrarExito('Maquinaria registrada exitosamente');
    } catch (e) {
      _mostrarError('Error al registrar maquinaria: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Obtiene la lista filtrada de maquinaria
  List<Maquinaria> _obtenerMaquinariaFiltrada() {
    if (_filtroEstado == 'todos') {
      return _maquinaria;
    }
    return _maquinaria.where((m) => m.estado == _filtroEstado).toList();
  }

  /// Obtiene el color del estado
  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'disponible':
        return Colors.green.shade600;
      case 'alquilado':
        return Colors.blue.shade600;
      case 'mantenimiento':
        return Colors.orange.shade600;
      case 'fuera_servicio':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Obtiene el nombre de la categoría
  String _obtenerNombreCategoria(String categoriaId) {
    try {
      return _categorias.firstWhere((c) => c.id == categoriaId).nombre;
    } catch (e) {
      return 'Categoría no encontrada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Si el TabController aún no está inicializado, mostrar loading
    if (_tabController == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildFiltros(isDark),
          TabBar(
            controller: _tabController,
            labelColor: Colors.yellow,
            unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            indicatorColor: Colors.yellow,
            tabs: _esAdmin
                ? const [
                    Tab(text: 'Inventario', icon: Icon(Icons.inventory_2)),
                    Tab(text: 'Registrar', icon: Icon(Icons.add_box)),
                    Tab(text: 'Estadísticas', icon: Icon(Icons.analytics)),
                  ]
                : const [
                    Tab(text: 'Inventario', icon: Icon(Icons.inventory_2)),
                    Tab(text: 'Estadísticas', icon: Icon(Icons.analytics)),
                  ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _esAdmin
                  ? [
                      _buildListaMaquinaria(isDark),
                      _buildFormularioRegistro(isDark),
                      _buildEstadisticas(isDark),
                    ]
                  : [
                      _buildListaMaquinaria(isDark),
                      _buildEstadisticas(isDark),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el header de la pantalla
  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.construction, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gestión de Maquinaria",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              Text(
                "Administra el inventario de equipos",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye los filtros
  Widget _buildFiltros(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Filtrar por estado:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipFiltro('todos', 'Todos', isDark),
                  _buildChipFiltro('disponible', 'Disponible', isDark),
                  _buildChipFiltro('alquilado', 'Alquilado', isDark),
                  _buildChipFiltro('mantenimiento', 'Mantenimiento', isDark),
                  _buildChipFiltro('fuera_servicio', 'Fuera de Servicio', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un chip de filtro
  Widget _buildChipFiltro(String valor, String texto, bool isDark) {
    final isSelected = _filtroEstado == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(texto),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroEstado = valor;
          });
        },
        selectedColor: Colors.yellow.shade200,
        checkmarkColor: Colors.black,
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        labelStyle: TextStyle(
          color: isSelected 
              ? Colors.black 
              : (isDark ? Colors.white : Colors.grey.shade800),
        ),
      ),
    );
  }

  /// Construye la lista de maquinaria
  Widget _buildListaMaquinaria(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final maquinariaFiltrada = _obtenerMaquinariaFiltrada();

    if (maquinariaFiltrada.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay maquinaria registrada',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: maquinariaFiltrada.length,
      itemBuilder: (context, index) {
        final maquinaria = maquinariaFiltrada[index];
        return _buildTarjetaMaquinaria(maquinaria, isDark);
      },
    );
  }

  /// Construye una tarjeta de maquinaria
  Widget _buildTarjetaMaquinaria(Maquinaria maquinaria, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la maquinaria
                if (maquinaria.imagenes.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(maquinaria.imagenes.first),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.construction,
                      size: 40,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maquinaria.nombre,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '${maquinaria.marca} ${maquinaria.modelo}',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'S/N: ${maquinaria.numeroSerie}',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _obtenerColorEstado(maquinaria.estado).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _obtenerColorEstado(maquinaria.estado),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    maquinaria.estado.toUpperCase(),
                    style: TextStyle(
                      color: _obtenerColorEstado(maquinaria.estado),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _obtenerNombreCategoria(maquinaria.categoriaId),
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    maquinaria.ubicacion ?? 'Sin ubicación',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${maquinaria.horasUso} horas',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '\$${maquinaria.valorAdquisicion.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _actualizarHorasUso(maquinaria),
                  icon: const Icon(Icons.access_time, size: 16),
                  label: const Text('Horas'),
                ),
                const SizedBox(width: 8),
                // Botones de editar y eliminar solo para administradores
                FutureBuilder<bool>(
                  future: AuthService.esAdministrador(),
                  builder: (context, snapshot) {
                    final esAdmin = snapshot.data ?? false;
                    if (!esAdmin) {
                      return TextButton.icon(
                        onPressed: () => _verDetalles(maquinaria),
                        icon: const Icon(Icons.info, size: 16),
                        label: const Text('Detalles'),
                      );
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editarMaquinaria(maquinaria),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Editar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _verDetalles(maquinaria),
                          icon: const Icon(Icons.info, size: 16),
                          label: const Text('Detalles'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _darDeBaja(maquinaria),
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                          tooltip: 'Dar de baja',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario de registro
  Widget _buildFormularioRegistro(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        labelText: 'Estado inicial',
                        prefixIcon: const Icon(Icons.info),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
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
                    const SizedBox(height: 16),
                    // Widget para cargar foto
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
                                    'Toca para agregar foto',
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _registrarMaquinaria,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Registrar Maquinaria',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye las estadísticas
  Widget _buildEstadisticas(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _controlMaquinaria.obtenerEstadisticasMaquinaria(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar estadísticas: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTarjetaEstadistica(
                'Total de Equipos',
                '${stats['total'] ?? 0}',
                Icons.inventory_2,
                Colors.blue,
                isDark,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTarjetaEstadistica(
                      'Disponibles',
                      '${stats['disponibles'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTarjetaEstadistica(
                      'Alquilados',
                      '${stats['alquiladas'] ?? 0}',
                      Icons.assignment,
                      Colors.orange,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTarjetaEstadistica(
                      'Mantenimiento',
                      '${stats['mantenimiento'] ?? 0}',
                      Icons.build,
                      Colors.yellow,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTarjetaEstadistica(
                      'Fuera de Servicio',
                      '${stats['fueraServicio'] ?? 0}',
                      Icons.error,
                      Colors.red,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTarjetaEstadistica(
                'Disponibilidad',
                '${stats['porcentajeDisponibilidad'] ?? 0}%',
                Icons.pie_chart,
                Colors.purple,
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye una tarjeta de estadística
  Widget _buildTarjetaEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
    bool isDark,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Edita una maquinaria existente
  void _editarMaquinaria(Maquinaria maquinaria) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarMaquinariaScreen(maquinaria: maquinaria),
      ),
    ).then((_) => _cargarDatos());
  }

  /// Ve los detalles de una maquinaria
  void _verDetalles(Maquinaria maquinaria) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallesMaquinariaScreen(maquinaria: maquinaria),
      ),
    );
  }

  /// Actualiza las horas de uso
  Future<void> _actualizarHorasUso(Maquinaria maquinaria) async {
    final horasController = TextEditingController(
      text: maquinaria.horasUso.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Horas de Uso'),
        content: TextField(
          controller: horasController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Horas de uso',
            hintText: 'Ingrese las horas de uso',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final nuevasHoras = double.tryParse(horasController.text) ?? maquinaria.horasUso.toDouble();
        await _controlMaquinaria.actualizarHorasUso(maquinaria.id, nuevasHoras);
        await _cargarDatos();
        _mostrarExito('Horas de uso actualizadas');
      } catch (e) {
        _mostrarError('Error al actualizar horas: $e');
      }
    }
  }

  /// Da de baja una maquinaria
  Future<void> _darDeBaja(Maquinaria maquinaria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Baja'),
        content: Text('¿Está seguro de dar de baja "${maquinaria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Dar de Baja'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _controlMaquinaria.eliminarMaquinaria(maquinaria.id);
        await _cargarDatos();
        _mostrarExito('Maquinaria dada de baja');
      } catch (e) {
        _mostrarError('Error al dar de baja: $e');
      }
    }
  }
}
