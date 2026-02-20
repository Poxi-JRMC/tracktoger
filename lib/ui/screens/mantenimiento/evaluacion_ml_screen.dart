import 'package:flutter/material.dart';
import '../../../services/ml_evaluation_service.dart';
import '../../../controllers/control_maquinaria.dart';
import 'package:fl_chart/fl_chart.dart';

// Importar las clases que fueron movidas al nivel superior
export '../../../services/ml_evaluation_service.dart' show EvaluationResults, ConfusionMatrix, ROCCurve, ROCPoint;

/// Pantalla profesional para visualizar evaluación del modelo ML
/// Muestra métricas: Accuracy, Recall, Precision, F1-Score, ROC, AUC
class EvaluacionMLScreen extends StatefulWidget {
  const EvaluacionMLScreen({super.key});

  @override
  State<EvaluacionMLScreen> createState() => _EvaluacionMLScreenState();
}

class _EvaluacionMLScreenState extends State<EvaluacionMLScreen> {
  final MLEvaluationService _evaluationService = MLEvaluationService();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  
  EvaluationResults? _resultados;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _evaluarModelo();
  }

  Future<void> _evaluarModelo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final maquinarias = await _controlMaquinaria.consultarTodasMaquinarias();
      final resultados = await _evaluationService.evaluarModelo(
        maquinariasTest: maquinarias,
      );

      setState(() {
        _resultados = resultados;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al evaluar modelo: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Evaluación del Modelo ML'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _evaluarModelo,
            tooltip: 'Reevaluar modelo',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _evaluarModelo,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _resultados == null
                  ? const Center(child: Text('No hay resultados'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResumenEjecutivo(_resultados!, isDark),
                          const SizedBox(height: 24),
                          _buildMetricasPrincipales(_resultados!, isDark),
                          const SizedBox(height: 24),
                          _buildMatrizConfusion(_resultados!, isDark),
                          const SizedBox(height: 24),
                          _buildROCCurve(_resultados!, isDark),
                          const SizedBox(height: 24),
                          _buildMetricasPorClase(_resultados!, isDark),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildResumenEjecutivo(
    EvaluationResults resultados,
    bool isDark,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Resumen Ejecutivo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _evaluationService.obtenerResumenEjecutivo(resultados),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasPrincipales(
    EvaluationResults resultados,
    bool isDark,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas Principales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    'Accuracy',
                    resultados.accuracy,
                    Icons.check_circle,
                    Colors.green,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricaCard(
                    'Precision',
                    resultados.precision,
                    Icons.precision_manufacturing,
                    Colors.blue,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    'Recall',
                    resultados.recall,
                    Icons.search,
                    Colors.orange,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricaCard(
                    'F1-Score',
                    resultados.f1Score,
                    Icons.trending_up,
                    Colors.purple,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricaCard(
              'AUC (Area Under Curve)',
              resultados.auc,
              Icons.show_chart,
              Colors.red,
              isDark,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaCard(
    String label,
    double valor,
    IconData icon,
    Color color,
    bool isDark, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${(valor * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrizConfusion(
    EvaluationResults resultados,
    bool isDark,
  ) {
    final matrix = resultados.confusionMatrix;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matriz de Confusión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade300),
                  children: [
                    const TableCell(child: SizedBox()),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Predicción\nFalla', textAlign: TextAlign.center),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Predicción\nNo Falla', textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Real Falla'),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.withOpacity(0.3),
                        child: Text(
                          'TP: ${matrix.truePositives}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withOpacity(0.3),
                        child: Text(
                          'FN: ${matrix.falseNegatives}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Real No Falla'),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.orange.withOpacity(0.3),
                        child: Text(
                          'FP: ${matrix.falsePositives}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.withOpacity(0.3),
                        child: Text(
                          'TN: ${matrix.trueNegatives}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${matrix.total} muestras',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildROCCurve(
    EvaluationResults resultados,
    bool isDark,
  ) {
    final roc = resultados.rocCurve;

    if (roc.points.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Curva ROC (Receiver Operating Characteristic)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AUC: ${(roc.auc * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: roc.auc >= 0.8
                    ? Colors.green
                    : roc.auc >= 0.7
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 40,
                        showTitles: true,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 40,
                        showTitles: true,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: roc.points.map((p) => FlSpot(
                        p.falsePositiveRate,
                        p.truePositiveRate,
                      )).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Línea diagonal de referencia (clasificador aleatorio)
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 0),
                        const FlSpot(1, 1),
                      ],
                      isCurved: false,
                      color: Colors.grey,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                  minX: 0,
                  maxX: 1,
                  minY: 0,
                  maxY: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'FPR (False Positive Rate)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  'TPR (True Positive Rate / Recall)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasPorClase(
    EvaluationResults resultados,
    bool isDark,
  ) {
    if (resultados.perClassMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas por Tipo de Falla',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...resultados.perClassMetrics.entries.map((entry) {
              final tipo = entry.key.replaceAll('_accuracy', '').replaceAll('_count', '');
              final valor = entry.value;
              
              if (entry.key.endsWith('_count')) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tipo.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: valor,
                        child: Container(
                          decoration: BoxDecoration(
                            color: valor >= 0.8
                                ? Colors.green
                                : valor >= 0.6
                                    ? Colors.orange
                                    : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(valor * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

