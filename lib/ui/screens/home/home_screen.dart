import 'package:flutter/material.dart';
import 'package:tracktoger/ui/widgets/custom_footer.dart';
import 'package:tracktoger/ui/screens/home/pages/home_page.dart';
import 'package:tracktoger/ui/screens/dashboard/dashboard_screen.dart';
import 'package:tracktoger/ui/screens/inventario/inventario_screen.dart';
import 'package:tracktoger/ui/screens/alquileres/alquileres_screen.dart';
import 'package:tracktoger/ui/screens/perfil/perfil_sreen.dart';
import 'package:tracktoger/ui/screens/mantenimiento/mantenimiento_screen.dart';
import 'package:tracktoger/core/auth_service.dart';
import 'package:tracktoger/ui/screens/usuarios/usuario_screen.dart';
import 'package:tracktoger/models/usuario.dart';

class HomeScreen extends StatefulWidget {
  final String currentTab;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.currentTab,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Note: `TabItem` enum is defined in `custom_footer.dart` and reused here.

class _HomeScreenState extends State<HomeScreen> {
  late TabItem currentTab;
  bool _esAdmin = false;
  bool _loadingPermisos = true;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    currentTab = _mapStringToTab(widget.currentTab);
  }

  /// Verifica los permisos del usuario actual
  Future<void> _verificarPermisos() async {
    final esAdmin = await AuthService.esAdministrador();
    setState(() {
      _esAdmin = esAdmin;
      _loadingPermisos = false;
    });
    
    // Si el usuario es operador y está en una tab no permitida, redirigir
    if (!_esAdmin) {
      final tabActual = _mapStringToTab(widget.currentTab);
      if (tabActual == TabItem.inicio || 
          tabActual == TabItem.dashboard || 
          tabActual == TabItem.alquileres) {
        // Redirigir a inventario (primera tab permitida)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleTabChange(TabItem.inventario);
        });
      }
    }
  }

  TabItem _mapStringToTab(String tab) {
    switch (tab) {
      case 'dashboard':
        return TabItem.dashboard;
      case 'inventario':
        return TabItem.inventario;
      case 'alquileres':
        return TabItem.alquileres;
      case 'mantenimiento':
        return TabItem.mantenimiento;
      case 'perfil':
        return TabItem.perfil;
      case 'inicio':
      default:
        return TabItem.inicio;
    }
  }

  void handleTabChange(TabItem tab) {
    // Verificar permisos antes de cambiar de tab
    if (!_esAdmin) {
      // Operadores no pueden acceder a: inicio, dashboard, alquileres
      if (tab == TabItem.inicio || tab == TabItem.dashboard || tab == TabItem.alquileres) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para acceder a esta sección'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    setState(() => currentTab = tab);
    widget.onNavigate(tab.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B1B1B), Color(0xFF2E2E2E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildCurrentScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _loadingPermisos 
          ? null 
          : CustomFooter(
              activeTab: currentTab,
              onTabChange: handleTabChange,
              esAdmin: _esAdmin,
            ),
    );
  }

  Widget _buildCurrentScreen() {
    // Verificar permisos antes de mostrar la pantalla
    if (!_esAdmin) {
      if (currentTab == TabItem.inicio || 
          currentTab == TabItem.dashboard || 
          currentTab == TabItem.alquileres) {
        // Si es operador y está en una tab no permitida, mostrar mensaje
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Acceso Restringido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tienes permisos para acceder a esta sección',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    }
    
    switch (currentTab) {
      case TabItem.inicio:
        return HomePage(onNavigateToTab: handleTabChange);
      case TabItem.dashboard:
        return const DashboardScreen();
      case TabItem.inventario:
        return const InventarioScreen();
      case TabItem.alquileres:
        return const AlquileresScreen();
      case TabItem.mantenimiento:
        return const MantenimientoScreen();
      case TabItem.perfil:
        return PerfilScreen(onLogout: widget.onLogout);
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1B1B), Color(0xFF2E2E2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFFCD11), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCD11).withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícono o logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCD11),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: Colors.black,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TRACKTOGER",
                  style: TextStyle(
                    color: Color(0xFFFFCD11),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  _getHeaderSubtitle(),
                  style: const TextStyle(
                    color: Color(0xFFE5E5E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Botón Admin (solo visible para el admin) - Escucha cambios en el usuario
          ValueListenableBuilder<Usuario?>(
            valueListenable: AuthService.usuarioNotifier,
            builder: (context, usuario, _) {
              if (usuario == null) return const SizedBox.shrink();
              
              // Usar el usuario del notifier como key para forzar reconstrucción
              return FutureBuilder<bool>(
                future: AuthService.esAdministrador(),
                key: ValueKey(usuario.id + (usuario.roles.join(','))),
                builder: (context, snapshot) {
                  final esAdmin = snapshot.data ?? false;
                  if (!esAdmin) return const SizedBox.shrink();
                  
                  return InkWell(
                    onTap: () {
                      // Navegar a la pantalla de gestión de usuarios real
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UsuarioScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCD11),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Admin",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (currentTab) {
      case TabItem.inicio:
        return "Panel de Control Industrial";
      case TabItem.dashboard:
        return "Dashboard y Métricas";
      case TabItem.inventario:
        return "Gestión de Inventario";
      case TabItem.alquileres:
        return "Gestión de Alquileres";
      case TabItem.mantenimiento:
        return "Mantenimiento Predictivo";
      case TabItem.perfil:
        return "Perfil de Usuario";
    }
  }
}
