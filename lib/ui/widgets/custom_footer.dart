import 'package:flutter/material.dart';

enum TabItem {
  inicio,
  dashboard,
  inventario,
  alquileres,
  mantenimiento,
  perfil,
}

class CustomFooter extends StatelessWidget {
  final TabItem activeTab;
  final ValueChanged<TabItem> onTabChange;
  final bool esAdmin;

  const CustomFooter({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.esAdmin,
  });

  /// Obtiene las tabs disponibles según el rol del usuario
  List<TabItem> _getTabsDisponibles() {
    if (esAdmin) {
      // Admin puede ver todas las tabs
      return TabItem.values;
    } else {
      // Operador solo puede ver: Inventario, Mantenimiento, Perfil
      return [
        TabItem.inventario,
        TabItem.mantenimiento,
        TabItem.perfil,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final double footerHeight = MediaQuery.of(context).size.height * 0.085;
    final tabsDisponibles = _getTabsDisponibles();

    return SafeArea(
      top: false,
      child: Container(
        height: footerHeight.clamp(55, 75),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF101010), Color(0xFF1C1C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: const Border(
            top: BorderSide(color: Color(0xFFFFCD11), width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: tabsDisponibles.map((tab) {
            final bool isActive = tab == activeTab;
            final iconData = _getIconData(tab);
            final label = _getLabel(tab);

            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChange(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFFFFCD11), Color(0xFFFFCD11)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isActive ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, -1),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconData,
                        size: 26,
                        color: isActive
                            ? Colors.black
                            : const Color(0xFF9FA4AA),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? Colors.black
                              : const Color(0xFF9FA4AA),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getIconData(TabItem tab) {
    switch (tab) {
      case TabItem.inicio:
        return Icons.home_rounded;
      case TabItem.dashboard:
        return Icons.bar_chart_rounded;
      case TabItem.inventario:
        return Icons.inventory_2_rounded;
      case TabItem.alquileres:
        return Icons.calendar_month_rounded;
      case TabItem.mantenimiento:
        return Icons.build_rounded;
      case TabItem.perfil:
        return Icons.person_rounded;
    }
  }

  String _getLabel(TabItem tab) {
    switch (tab) {
      case TabItem.inicio:
        return "Inicio";
      case TabItem.dashboard:
        return "Dashboard";
      case TabItem.inventario:
        return "Inventario";
      case TabItem.alquileres:
        return "Alquileres";
      case TabItem.mantenimiento:
        return "Mantenimiento";
      case TabItem.perfil:
        return "Perfil";
    }
  }
}
