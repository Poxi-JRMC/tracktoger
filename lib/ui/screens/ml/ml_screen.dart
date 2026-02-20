import 'package:flutter/material.dart';

class MLAlert {
  final String id;
  final String equipment;
  final String riskLevel;
  final int riskScore;
  final String estimatedDate;
  final String description;
  final String category;
  final String recommendation;

  MLAlert({
    required this.id,
    required this.equipment,
    required this.riskLevel,
    required this.riskScore,
    required this.estimatedDate,
    required this.description,
    required this.category,
    required this.recommendation,
  });
}

class MLScreen extends StatelessWidget {
  MLScreen({super.key});

  final List<MLAlert> mlAlerts = [
    MLAlert(
      id: "1",
      equipment: "Excavadora CAT 320D",
      riskLevel: "high",
      riskScore: 85,
      estimatedDate: "2025-08-30",
      description: "Desgaste del sistema hidráulico detectado",
      category: "Hidráulico",
      recommendation: "Inspección inmediata del sistema hidráulico",
    ),
    MLAlert(
      id: "2",
      equipment: "Grúa Liebherr LTM 1050",
      riskLevel: "medium",
      riskScore: 62,
      estimatedDate: "2025-09-15",
      description: "Patrón anormal en la transmisión",
      category: "Transmisión",
      recommendation: "Programar mantenimiento preventivo",
    ),
    MLAlert(
      id: "3",
      equipment: "Compactadora Dynapac CA512",
      riskLevel: "low",
      riskScore: 34,
      estimatedDate: "2025-10-02",
      description: "Leve incremento en temperatura del motor",
      category: "Motor",
      recommendation: "Monitoreo continuo por 2 semanas",
    ),
    MLAlert(
      id: "4",
      equipment: "Camión Volvo FH16",
      riskLevel: "high",
      riskScore: 78,
      estimatedDate: "2025-09-05",
      description: "Degradación del sistema de frenos",
      category: "Frenos",
      recommendation: "Reemplazo urgente de pastillas de freno",
    ),
    MLAlert(
      id: "5",
      equipment: "Cargadora Caterpillar 950M",
      riskLevel: "medium",
      riskScore: 55,
      estimatedDate: "2025-09-20",
      description: "Vibración excesiva en el tren de rodaje",
      category: "Tren de rodaje",
      recommendation: "Inspección de componentes de rodaje",
    ),
  ];

  Color getRiskColor(String level) {
    switch (level) {
      case "high":
        return Colors.red.shade100;
      case "medium":
        return Colors.yellow.shade100;
      case "low":
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String getRiskLabel(String level) {
    switch (level) {
      case "high":
        return "Crítico";
      case "medium":
        return "Medio";
      case "low":
        return "Bajo";
      default:
        return "Desconocido";
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticalAlerts = mlAlerts.where((a) => a.riskLevel == "high").length;
    final totalAlerts = mlAlerts.length;
    final avgRiskScore =
        (mlAlerts.fold<int>(0, (sum, a) => sum + a.riskScore) / totalAlerts)
            .round();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)], // Navy → Blue
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "ML Insights",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Análisis predictivo y alertas inteligentes",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        "Críticas",
                        criticalAlerts.toString(),
                        Colors.red,
                      ),
                      _buildStatCard(
                        "Total",
                        totalAlerts.toString(),
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "Riesgo Prom.",
                        "$avgRiskScore%",
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI Insight card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                "Insight Semanal",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D1B2A),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "El modelo ML predice un aumento del 15% en mantenimientos preventivos esta semana. "
                            "Se recomienda priorizar equipos con score >70.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Alerts List
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Alertas Generadas",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D1B2A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Column(
                    children: mlAlerts.map((alert) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.equipment,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D1B2A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          alert.description,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getRiskColor(alert.riskLevel),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      getRiskLabel(alert.riskLevel),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Info details
                              _buildInfoRow(
                                "Score de Riesgo:",
                                "${alert.riskScore}%",
                              ),
                              _buildInfoRow("Categoría:", alert.category),
                              _buildInfoRow(
                                "Fecha estimada:",
                                "${DateTime.parse(alert.estimatedDate).day}/"
                                    "${DateTime.parse(alert.estimatedDate).month}/"
                                    "${DateTime.parse(alert.estimatedDate).year}",
                              ),

                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.build,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Recomendación:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D1B2A),
                                            ),
                                          ),
                                          Text(
                                            alert.recommendation,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
    );
  }
}
