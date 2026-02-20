import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/usuario.dart';
import '../../../models/rol.dart';
import '../../../controllers/control_usuario.dart';
import '../../../core/auth_service.dart';

/// Pantalla de gestión de usuarios
/// Permite registrar, actualizar y visualizar usuarios del sistema
class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ControlUsuario _controlUsuario = ControlUsuario();

  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];
  bool _loading = false;

  // Controladores para el formulario
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _normalizarYCargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Normaliza IDs inválidos y luego carga los datos
  Future<void> _normalizarYCargarDatos() async {
    setState(() => _loading = true);
    try {
      // Primero intenta cargar los usuarios
      var usuarios = await _controlUsuario.consultarTodosUsuarios();

      // Detectar usuarios con IDs inválidos (no hexadecimales)
      List<Usuario> usuariosANormalizar = [];
      for (final user in usuarios) {
        try {
          // Intentar convertir a ObjectId para verificar validez
          mongo.ObjectId.fromHexString(user.id);
        } catch (e) {
          // El ID no es válido, necesita normalización
          print('⚠️ Usuario ${user.nombre} tiene ID inválido: ${user.id}');
          usuariosANormalizar.add(user);
        }
      }

      // Si hay usuarios con IDs inválidos, notificar al usuario
      if (usuariosANormalizar.isNotEmpty) {
        _mostrarError(
          'Hay ${usuariosANormalizar.length} usuario(s) con IDs inválidos. '
          'Contacte al administrador.',
        );
      }

      await _cargarDatos();
    } catch (e) {
      print('Error en normalización: $e');
      await _cargarDatos();
    }
  }

  /// Carga los datos iniciales
  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      var usuarios = await _controlUsuario.consultarTodosUsuarios();
      final roles = await _controlUsuario.consultarTodosRoles();

      print('📋 Usuarios cargados: ${usuarios.length}');
      for (final u in usuarios) {
        print('   - ${u.nombre} (ID: ${u.id}) | Roles: ${u.roles}');
      }

      print('👤 Roles cargados: ${roles.length}');
      for (final r in roles) {
        print('   - ${r.nombre} (ID: ${r.id})');
      }

      // Normalizar: si un usuario tiene múltiples roles, quedarse solo con el primero
      for (final user in usuarios) {
        if (user.roles.length > 1) {
          print(
            '⚠️ Usuario ${user.nombre} tiene múltiples roles, normalizando...',
          );
          final normalized = user.copyWith(roles: [user.roles.first]);
          await _controlUsuario.actualizarUsuario(normalized);
        }
      }

      // Recargar después de normalizaciones
      usuarios = await _controlUsuario.consultarTodosUsuarios();

      setState(() {
        _usuarios = usuarios;
        _roles = roles;
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
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  /// Muestra un mensaje de éxito
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  /// Limpia el formulario de registro
  void _limpiarFormulario() {
    _nombreController.clear();
    _apellidoController.clear();
    _emailController.clear();
    _telefonoController.clear();
    _passwordController.clear();
    _obscurePassword = true;
  }

  /// Registra un nuevo usuario desde el panel admin
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // Buscar rol "operador" por defecto
      String defaultRoleId = '';
      for (var r in _roles) {
        if (r.nombre.toLowerCase().contains('oper') ||
            r.nombre.toLowerCase().contains('operador')) {
          defaultRoleId = r.id;
          break;
        }
      }

      final usuario = Usuario(
        id: '', // El controlador generará un ID válido
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        fechaRegistro: DateTime.now(),
        roles: defaultRoleId.isNotEmpty ? [defaultRoleId] : [],
        password: _passwordController.text.trim(), // Contraseña ingresada por el admin
      );

      await _controlUsuario.registrarUsuarioDesdeAdmin(usuario);
      await _cargarDatos();
      _limpiarFormulario();
      _mostrarExito('Usuario registrado exitosamente');
    } catch (e) {
      _mostrarError('Error al registrar usuario: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(isDark),
          TabBar(
            controller: _tabController,
            labelColor: Colors.yellow,
            unselectedLabelColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            indicatorColor: Colors.yellow,
            tabs: const [
              Tab(text: 'Lista de Usuarios', icon: Icon(Icons.list)),
              Tab(text: 'Registrar Usuario', icon: Icon(Icons.person_add)),
              Tab(
                text: 'Gestión de Roles',
                icon: Icon(Icons.admin_panel_settings),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaUsuarios(isDark),
                _buildFormularioRegistro(isDark),
                _buildGestionRoles(isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botón de volver
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.grey.shade800,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          // Icono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.yellow.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          // Título y subtítulo con Expanded para mejor proporción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Gestión de Usuarios",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Administra usuarios, roles y permisos",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de usuarios
  Widget _buildListaUsuarios(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios registrados',
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
      itemCount: _usuarios.length,
      itemBuilder: (context, index) {
        final usuario = _usuarios[index];
        return _buildTarjetaUsuario(usuario, isDark);
      },
    );
  }

  /// Construye una tarjeta de usuario
  Widget _buildTarjetaUsuario(Usuario usuario, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.yellow.shade600,
          child: Text(
            (() {
              final n = usuario.nombre.isNotEmpty ? usuario.nombre[0] : '';
              final a = usuario.apellido.isNotEmpty ? usuario.apellido[0] : '';
              return (n + a).toUpperCase();
            })(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${usuario.nombre} ${usuario.apellido}'.trim(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email),
            Text(
              'Tel: ${usuario.telefono}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            Text(
              'Rol: ${_roleNameById(usuario.roles.isNotEmpty ? usuario.roles.first : '')}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.orange),
              tooltip: 'Cambiar rol',
              onPressed: () => _cambiarRolUsuario(usuario),
            ),
            IconButton(
              icon: Icon(
                usuario.activo ? Icons.visibility : Icons.visibility_off,
                color: usuario.activo ? Colors.green : Colors.red,
              ),
              onPressed: () => _toggleUsuarioActivo(usuario),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: const Icon(Icons.person),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoController,
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El apellido es requerido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El email es requerido';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Ingrese un email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El teléfono es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La contraseña es requerida';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asignación de Roles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Por defecto: operador (se puede cambiar después en lista de usuarios)
                    Text(
                      'Rol: Operador (puede cambiarse desde la lista de usuarios)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _registrarUsuario,
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
                      'Registrar Usuario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la gestión de roles
  Widget _buildGestionRoles(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final rol = _roles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade600,
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
              ),
            ),
            title: Text(
              rol.nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rol.descripcion),
                Text(
                  'Permisos: ${rol.permisos.length}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              rol.activo ? Icons.check_circle : Icons.cancel,
              color: rol.activo ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }


  /// Activa/desactiva un usuario
  Future<void> _toggleUsuarioActivo(Usuario usuario) async {
    final actionLabel = usuario.activo ? 'Desactivar' : 'Reactivar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$actionLabel usuario'),
        content: Text(
          '¿Deseas ${actionLabel.toLowerCase()} a ${usuario.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      bool ok = false;
      if (usuario.activo) {
        // Desactivar usuario
        ok = await _controlUsuario.eliminarUsuario(usuario.id);
        if (ok) {
          _mostrarExito('Usuario desactivado correctamente');
        } else {
          // Verificar si el usuario ya estaba desactivado
          final usuarioActualizado = await _controlUsuario.consultarUsuario(usuario.id);
          if (usuarioActualizado != null && !usuarioActualizado.activo) {
            _mostrarExito('Usuario desactivado correctamente');
            ok = true; // Considerar como éxito si ya estaba desactivado
          } else {
            _mostrarError('No se pudo desactivar el usuario');
          }
        }
      } else {
        // Activar usuario
        ok = await _controlUsuario.activarUsuario(usuario.id);
        if (ok) {
          _mostrarExito('Usuario reactivado correctamente');
        } else {
          // Verificar si el usuario ya estaba activado
          final usuarioActualizado = await _controlUsuario.consultarUsuario(usuario.id);
          if (usuarioActualizado != null && usuarioActualizado.activo) {
            _mostrarExito('Usuario reactivado correctamente');
            ok = true; // Considerar como éxito si ya estaba activado
          } else {
            _mostrarError('No se pudo reactivar el usuario');
          }
        }
      }

      // Recargar datos solo si la operación fue exitosa
      if (ok) {
        await _cargarDatos();
      }
    } catch (e) {
      print('❌ Error al cambiar estado del usuario: $e');
      _mostrarError('Error al cambiar estado del usuario: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Obtiene el nombre de rol por su id (o 'N/D' si no existe)
  String _roleNameById(String id) {
    try {
      final rol = _roles.firstWhere((r) => r.id == id);
      return rol.nombre;
    } catch (_) {
      return id.isNotEmpty ? id : 'N/D';
    }
  }

  /// Permite cambiar el rol principal de un usuario entre Admin/Operador
  Future<void> _cambiarRolUsuario(Usuario usuario) async {
    print('\n🔄 ========== INICIANDO CAMBIO DE ROL ==========');
    print('   Usuario ID: ${usuario.id}');
    print('   Usuario nombre: ${usuario.nombre}');
    print('   Roles actuales: ${usuario.roles}');

    // Buscar roles admin y operador por nombre
    Rol? adminRole;
    Rol? operadorRole;

    for (var r in _roles) {
      final name = r.nombre.toLowerCase();
      if (name.contains('admin')) {
        adminRole = r;
      }
      if (name.contains('oper') || name.contains('operador')) {
        operadorRole = r;
      }
    }

    final choices = <Rol>[];
    if (adminRole != null) choices.add(adminRole);
    if (operadorRole != null) choices.add(operadorRole);
    if (choices.isEmpty) choices.addAll(_roles);

    print(
      '   Roles disponibles en dialog: ${choices.map((r) => r.nombre).toList()}',
    );

    // Determinar el rol actual del usuario
    String? initialSelected;

    if (usuario.roles.isNotEmpty) {
      final currentRoleId = usuario.roles.first;
      // Buscar el rol actual en las choices disponibles por ID
      for (var choice in choices) {
        if (choice.id == currentRoleId) {
          initialSelected = choice.id;
          break;
        }
      }
    }

    // Si no se encontró el rol actual, usar el primero disponible
    initialSelected ??= choices.isNotEmpty ? choices.first.id : null;

    print('   Rol inicial seleccionado: $initialSelected');

    final newRoleId = await showDialog<String?>(
      context: context,
      builder: (_) =>
          _RolePickerDialog(choices: choices, initialSelected: initialSelected),
    );

    print('   Rol seleccionado en dialog: $newRoleId');

    if (newRoleId == null || newRoleId.isEmpty) {
      print('   ❌ Cancelado: newRoleId es null o vacío');
      return;
    }

    if (newRoleId == usuario.roles.firstOrNull) {
      print('   ℹ️ Rol es el mismo, sin cambios necesarios');
      _mostrarError('Ya tiene este rol asignado');
      return;
    }

    setState(() => _loading = true);
    try {
      print('   📤 Enviando actualización a BD...');
      print('      ID: ${usuario.id}');
      print('      Rol anterior: ${usuario.roles}');
      print('      Nuevo rol: [$newRoleId]');

      // Crear copia del usuario con UN SOLO rol (limpiar cualquier rol anterior)
      final updated = usuario.copyWith(
        roles: [newRoleId], // Reemplazar completamente el array de roles
      );

      print('   Mapa a guardar:');
      final mapa = updated.toMap();
      print('      _id: ${mapa['_id']}');
      print('      roles: ${mapa['roles']}');

      // Guardar en la BD
      await _controlUsuario.actualizarUsuario(updated);

      print('   ✅ Guardado en BD exitosamente');

      // Si el usuario modificado es el mismo que está logueado, actualizar AuthService
      final usuarioActual = AuthService.usuarioActual;
      if (usuarioActual != null && usuarioActual.id == usuario.id) {
        print('   🔄 Actualizando usuario en AuthService (usuario logueado)');
        // Recargar el usuario desde la BD para obtener los datos actualizados
        final usuarioActualizado = await _controlUsuario.consultarUsuario(usuario.id);
        if (usuarioActualizado != null) {
          AuthService.actualizarUsuario(usuarioActualizado);
          // Notificar el cambio para que la UI se actualice inmediatamente
          AuthService.usuarioNotifier.value = usuarioActualizado;
          print('   ✅ Usuario actualizado en AuthService y notificado');
          print('   📱 El botón Admin debería aparecer/desaparecer automáticamente');
        }
      }

      _mostrarExito('Rol actualizado correctamente');

      // Recargar para refrescar la UI
      await _cargarDatos();
      print('🔄 ========== CAMBIO DE ROL COMPLETADO ==========\n');
    } catch (e) {
      print('❌ Error: $e');
      _mostrarError('Error al actualizar rol: $e');
      print('🔄 ========== CAMBIO DE ROL FALLÓ ==========\n');
    } finally {
      setState(() => _loading = false);
    }
  }
}

/// Diálogo standalone para seleccionar rol (evita conflictos con StatefulBuilder)
class _RolePickerDialog extends StatefulWidget {
  final List<Rol> choices;
  final String? initialSelected;

  const _RolePickerDialog({
    required this.choices,
    required this.initialSelected,
  });

  @override
  State<_RolePickerDialog> createState() => _RolePickerDialogState();
}

class _RolePickerDialogState extends State<_RolePickerDialog> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    // Encontrar el índice del rol actual
    selectedIndex = 0;
    if (widget.initialSelected != null && widget.initialSelected!.isNotEmpty) {
      for (int i = 0; i < widget.choices.length; i++) {
        if (widget.choices[i].id == widget.initialSelected) {
          selectedIndex = i;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar rol'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.choices.length, (index) {
            final r = widget.choices[index];
            return RadioListTile<int>(
              value: index,
              groupValue: selectedIndex,
              title: Text(r.nombre),
              onChanged: (newIndex) {
                if (newIndex != null) {
                  setState(() => selectedIndex = newIndex);
                }
              },
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            print('   [Dialog] Cancelar presionado');
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            print('   [Dialog] Cambiar presionado');
            print('      selectedIndex: $selectedIndex');
            print('      choices.length: ${widget.choices.length}');
            if (selectedIndex >= 0 && selectedIndex < widget.choices.length) {
              final selectedRole = widget.choices[selectedIndex];
              print(
                '      Rol seleccionado: ${selectedRole.nombre} (id: ${selectedRole.id})',
              );

              // Si el ID está vacío, usar el nombre como fallback
              String roleId = selectedRole.id.isEmpty
                  ? selectedRole.nombre
                  : selectedRole.id;
              print('      Usando roleId: $roleId');

              Navigator.pop(context, roleId);
            } else {
              print('      ❌ Índice fuera de rango');
              Navigator.pop(context);
            }
          },
          child: const Text('Cambiar'),
        ),
      ],
    );
  }
}
