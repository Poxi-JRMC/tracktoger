import 'package:flutter/material.dart';
import 'dart:io';

import 'package:tracktoger/ui/widgets/custom_button.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/core/auth_service.dart';
import 'package:tracktoger/models/usuario.dart';
import 'package:tracktoger/models/rol.dart';
import 'package:tracktoger/ui/screens/perfil/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String email;
  final String role;
  final String joinDate;
  final String lastActivity;
  final int totalSessions;
  final String favoriteEquipment;

  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
    required this.lastActivity,
    required this.totalSessions,
    required this.favoriteEquipment,
  });
}

class PerfilScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const PerfilScreen({super.key, required this.onLogout});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? usuario;
  List<Rol> roles = [];
  bool isLoading = true;
  VoidCallback? _notifierListener;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Escuchar cambios en el usuario para actualizar la UI cuando AuthService cambie
    _notifierListener = () {
      _loadUserData();
    };
    AuthService.usuarioNotifier.addListener(_notifierListener!);
  }

  @override
  void dispose() {
    // Remover el listener para evitar memory leaks
    try {
      if (_notifierListener != null) {
        AuthService.usuarioNotifier.removeListener(_notifierListener!);
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      Usuario? usuarioActual = AuthService.usuarioActual;
      print(
        'PerfilScreen._loadUserData: AuthService.usuarioActual = $usuarioActual',
      );

      if (usuarioActual == null) {
        // Intentar restaurar desde SharedPreferences (por si el usuario se actualizó
        // en otro flujo y no llegó a esta pantalla a tiempo)
        try {
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getString('userId');
          if (storedUserId != null && storedUserId.isNotEmpty) {
            print(
              'PerfilScreen: recuperando usuario desde SharedPreferences id=$storedUserId',
            );
            final recovered = await ControlUsuario().consultarUsuarioPorId(
              storedUserId,
            );
            if (recovered != null) {
              AuthService.actualizarUsuario(recovered);
              usuarioActual = recovered;
            }
          }
        } catch (e) {
          print('PerfilScreen: error al leer SharedPreferences: $e');
        }
      } else {
        // Si ya hay usuario en memoria, refrescarlo desde la BD por si faltan campos
        final usuarioActualizado = await ControlUsuario().consultarUsuarioPorId(
          usuarioActual.id,
        );
        if (usuarioActualizado != null) {
          AuthService.actualizarUsuario(usuarioActualizado);
          usuarioActual = usuarioActualizado;
        }
      }

      final rolesList = await ControlUsuario().consultarTodosRoles();

      setState(() {
        usuario = usuarioActual;
        roles = rolesList;
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del perfil: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String getRoleLabel(String roleId) {
    // Intentar coincidencia por id o nombre exacto (case-insensitive)
    final search = roleId.toLowerCase();
    Rol? rolMatch;
    try {
      rolMatch = roles.firstWhere((r) => r.id == roleId);
    } catch (_) {
      try {
        rolMatch = roles.firstWhere((r) => r.nombre.toLowerCase() == search);
      } catch (_) {
        // Intentar coincidencias parciales (ej. 'operator' <-> 'operador')
        try {
          rolMatch = roles.firstWhere(
            (r) =>
                r.nombre.toLowerCase().contains(search) ||
                search.contains(r.nombre.toLowerCase()),
          );
        } catch (_) {
          rolMatch = null;
        }
      }
    }

    if (rolMatch != null) return rolMatch.nombre;

    // Si no hay coincidencia pero el usuario tiene un identificador tipo 'operator' o 'admin',
    // devolver una etiqueta amigable basada en el id/nombre proporcionado.
    final fallback = roleId.trim().toLowerCase();
    if (fallback.isEmpty) return 'Sin rol';
    if (fallback.contains('oper')) return 'Operador';
    if (fallback.contains('admin')) return 'Administrador';
    // Capitalizar la primera letra como último recurso
    return '${roleId[0].toUpperCase()}${roleId.substring(1)}';
  }

  /// Muestra un diálogo de confirmación antes de cerrar sesión
  void _mostrarConfirmacionCerrarSesion() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2E2E2E) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
              widget.onLogout(); // Ejecutar el logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Color getRoleColor(String roleId, bool isDark) {
    final rol = roles.firstWhere(
      (r) => r.id == roleId || r.nombre.toLowerCase() == roleId.toLowerCase(),
      orElse: () => Rol(
        id: '',
        nombre: 'Sin rol',
        descripcion: '',
        permisos: [],
        fechaCreacion: DateTime.now(),
      ),
    );

    // Determinar nombre a usar (fallback a roleId si no existe documento)
    String nombreToCheck;
    if (rol.id.isNotEmpty) {
      nombreToCheck = rol.nombre.toLowerCase();
    } else {
      nombreToCheck = roleId.toLowerCase();
    }

    if (nombreToCheck.contains('admin') ||
        nombreToCheck.contains('administr')) {
      return isDark ? Colors.redAccent : Colors.red;
    }
    if (nombreToCheck.contains('oper') ||
        nombreToCheck.contains('operator') ||
        nombreToCheck.contains('operador')) {
      return isDark ? Colors.blueAccent : Colors.blue;
    }
    return isDark ? Colors.grey.shade400 : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (usuario == null) {
      // Mostrar indicador de carga o mensaje si no hay usuario en memoria
      return Scaffold(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Mostrar iniciales usando nombre + apellido cuando estén disponibles
    final initials =
        ((usuario!.nombre.isNotEmpty ? usuario!.nombre[0] : '') +
                (usuario!.apellido.isNotEmpty ? usuario!.apellido[0] : ''))
            .toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
        elevation: 0,
        title: Text(
          "Perfil",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              // Esto se puede conectar luego con tu provider o theme manager
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==================== CABECERA ====================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: isDark
                        ? Colors.orange.shade700
                        : Colors.orange.shade400,
                    // Usar ruta de avatar si existe
                    backgroundImage: (() {
                      final avatarPath = usuario!.avatar;
                      if (avatarPath != null && avatarPath.isNotEmpty) {
                        return FileImage(File(avatarPath));
                      }
                      return null;
                    })(),
                    child: (() {
                      final avatarPath = usuario!.avatar;
                      return (avatarPath != null && avatarPath.isNotEmpty)
                          ? null
                          : Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                    })(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${usuario!.nombre} ${usuario!.apellido}'.trim(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    usuario!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(
                      getRoleLabel(
                        usuario!.roles.isNotEmpty ? usuario!.roles.first : '',
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: getRoleColor(
                      usuario!.roles.isNotEmpty ? usuario!.roles.first : '',
                      isDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    variant: ButtonVariant.secondary,
                    onPressed: () async {
                      // Ir a pantalla de edición y recargar si retorna usuario
                      final current = AuthService.usuarioActual;
                      if (current == null) return;
                      final updated = await Navigator.of(context)
                          .push<Usuario?>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(usuario: current),
                            ),
                          );
                      if (updated != null) {
                        // actualizar UI
                        setState(() {
                          usuario = updated;
                        });
                      }
                    },
                    child: const Text(
                      "Editar Perfil",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==================== INFORMACIÓN ====================
            _buildInfoCard(
              context,
              isDark,
              title: "Fecha de registro",
              value:
                  "${usuario!.fechaRegistro.day}/${usuario!.fechaRegistro.month}/${usuario!.fechaRegistro.year}",
              icon: Icons.calendar_today,
            ),
            _buildInfoCard(
              context,
              isDark,
              title: "Teléfono",
              value: usuario!.telefono,
              icon: Icons.phone,
            ),
            _buildInfoCard(
              context,
              isDark,
              title: "Estado",
              value: usuario!.activo ? "Activo" : "Inactivo",
              icon: usuario!.activo ? Icons.check_circle : Icons.cancel,
            ),
            _buildInfoCard(
              context,
              isDark,
              title: "Roles asignados",
              value: usuario!.roles.length.toString(),
              icon: Icons.security,
            ),

            const SizedBox(height: 30),

            // ==================== BOTÓN CERRAR SESIÓN ====================
            CustomButton(
              variant: ButtonVariant.danger,
              size: ButtonSize.full,
              onPressed: _mostrarConfirmacionCerrarSesion,
              child: const Text(
                "Cerrar Sesión",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.orange.shade300 : Colors.orange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
