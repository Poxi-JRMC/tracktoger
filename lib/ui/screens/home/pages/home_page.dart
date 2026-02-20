import 'package:flutter/material.dart';
import 'package:tracktoger/ui/widgets/custom_footer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tracktoger/controllers/control_maquinaria.dart';
import 'package:tracktoger/controllers/control_alquiler.dart';
import 'package:tracktoger/controllers/control_mantenimiento.dart';
import 'package:tracktoger/controllers/control_gasto_operativo.dart';

class HomePage extends StatefulWidget {
  final Function(TabItem) onNavigateToTab;

  const HomePage({super.key, required this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Ajuste automático del childAspectRatio según ancho
    final aspectRatio = screenWidth < 380
        ? 2.0
        : screenWidth < 450
        ? 2.3
        : 2.6;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: const Color(0xFF1B1B1B),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRevenueChart(),
              const SizedBox(height: 20),
              _buildGlobalStats(aspectRatio),
              const SizedBox(height: 25),
              _buildModulesGrid(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // 📈 Análisis Financiero
  Widget _buildRevenueChart() {
    final chartColors = {
      "Ingresos": const Color.fromARGB(255, 255, 230, 3),
      "Gastos": const Color.fromARGB(255, 0, 255, 255),
      "Mantenimiento": const Color.fromARGB(255, 228, 114, 7),
      "Ganancia": const Color.fromARGB(255, 30, 207, 39),
    };

    return FutureBuilder<Map<String, double>>(
      future: _obtenerDatosFinancieros(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD74D), width: 0.8),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD74D)),
            ),
          );
        }

        final chartData = snapshot.data!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD74D), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Análisis Financiero",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                      borderData: FlBorderData(show: false),

                      sections: chartData.entries.map((e) {
                        final color = chartColors[e.key]!;
                        final value = e.value;
                        final total = chartData.values.reduce((a, b) => a + b);
                        final percentage = (value / total * 100)
                            .toStringAsFixed(1);

                        return PieChartSectionData(
                          color: color,
                          value: value,
                          title: "$percentage%",
                          radius: 70,
                          titleStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chartData.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: chartColors[e.key],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${e.key}: \$${e.value.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Future<Map<String, double>> _obtenerDatosFinancieros() async {
    try {
      final alquileresStats = await ControlAlquiler().obtenerEstadisticasAlquileres();
      final gastosStats = await ControlGastoOperativo().obtenerEstadisticasGastos();
      final mantenimientoStats = await ControlMantenimiento().obtenerEstadisticasMantenimiento();
      
      final ingresos = (alquileresStats['totalMonto'] ?? 0.0).toDouble();
      final gastos = (gastosStats['totalMonto'] ?? 0.0).toDouble();
      final mantenimiento = (mantenimientoStats['costoTotal'] ?? 0.0).toDouble();
      final ganancia = ingresos - gastos - mantenimiento;
      
      return {
        "Ingresos": ingresos > 0 ? ingresos : 0.0,
        "Gastos": gastos > 0 ? gastos : 0.0,
        "Mantenimiento": mantenimiento > 0 ? mantenimiento : 0.0,
        "Ganancia": ganancia > 0 ? ganancia : 0.0,
      };
    } catch (e) {
      print('Error obteniendo datos financieros: $e');
      return {
        "Ingresos": 0.0,
        "Gastos": 0.0,
        "Mantenimiento": 0.0,
        "Ganancia": 0.0,
      };
    }
  }

  // 📋 Resumen Global del Sistema
  Widget _buildGlobalStats(double aspectRatio) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _obtenerEstadisticasGlobales(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD74D), width: 0.8),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD74D)),
            ),
          );
        }

        final stats = snapshot.data!;
        final cards = [
          {
            "label": "Total Maquinaria",
            "value": "${stats['totalMaquinaria'] ?? 0}",
            "icon": Icons.construction,
            "color": const Color(0xFFFFD74D),
          },
          {
            "label": "Disponibles",
            "value": "${stats['disponibles'] ?? 0}",
            "icon": Icons.check_circle,
            "color": const Color(0xFF43A047),
          },
          {
            "label": "Contratos Activos",
            "value": "${stats['contratosActivos'] ?? 0}",
            "icon": Icons.description,
            "color": const Color(0xFF4FC3F7),
          },
          {
            "label": "Alertas Activas",
            "value": "${stats['alertasActivas'] ?? 0}",
            "icon": Icons.warning_amber_rounded,
            "color": const Color(0xFFD32F2F),
          },
        ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD74D), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📋 Resumen Global del Sistema",
            style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.0, // ← AQUÍ es donde ajustamos el alto/ancho
            children: cards.map((card) {
              final String label = card["label"] as String;
              final String value = card["value"].toString();
              final Color color = card["color"] as Color;
              final IconData icon = card["icon"] as IconData;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.6), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            label,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE5E5E5),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
      },
    );
  }

  Future<Map<String, dynamic>> _obtenerEstadisticasGlobales() async {
    try {
      final maquinariaStats = await ControlMaquinaria().obtenerEstadisticasMaquinaria();
      final alquileresStats = await ControlAlquiler().obtenerEstadisticasAlquileres();
      final mantenimientoStats = await ControlMantenimiento().obtenerEstadisticasMantenimiento();
      
      return {
        'totalMaquinaria': maquinariaStats['total'] ?? 0,
        'disponibles': maquinariaStats['disponibles'] ?? 0,
        'contratosActivos': alquileresStats['entregados'] ?? 0,
        'alertasActivas': mantenimientoStats['alertasActivas'] ?? 0,
      };
    } catch (e) {
      print('Error obteniendo estadísticas globales: $e');
      return {
        'totalMaquinaria': 0,
        'disponibles': 0,
        'contratosActivos': 0,
        'alertasActivas': 0,
      };
    }
  }

  // ⚙️ Módulos Principales
  Widget _buildModulesGrid() {
    final modules = [
      {
        "title": "Dashboard",
        "subtitle": "Métricas y KPIs",
        "icon": Icons.bar_chart_rounded,
        "color": const Color(0xFF4FC3F7),
        "tab": TabItem.dashboard,
      },
      {
        "title": "Inventario",
        "subtitle": "Gestión de equipos",
        "icon": Icons.inventory_2_rounded,
        "color": const Color(0xFF43A047),
        "tab": TabItem.inventario,
      },
      {
        "title": "Alquileres",
        "subtitle": "Contratos activos",
        "icon": Icons.calendar_month_rounded,
        "color": const Color(0xFFFFB74D),
        "tab": TabItem.alquileres,
      },
      {
        "title": "Mantenimiento",
        "subtitle": "Servicios técnicos",
        "icon": Icons.build_rounded,
        "color": const Color(0xFFD32F2F),
        "tab": TabItem.mantenimiento,
      },
      {
        "title": "Perfil",
        "subtitle": "Configuración y usuario",
        "icon": Icons.person_rounded,
        "color": const Color(0xFF64B5F6),
        "tab": TabItem.perfil,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD74D), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🧭 Módulos Principales",
            style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: modules.map((m) {
              return InkWell(
                onTap: () => widget.onNavigateToTab(m["tab"] as TabItem),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (m["color"] as Color).withOpacity(0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        m["icon"] as IconData,
                        color: m["color"] as Color,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        m["title"] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m["subtitle"] as String,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
