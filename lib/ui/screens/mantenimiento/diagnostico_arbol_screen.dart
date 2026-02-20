import 'package:flutter/material.dart';
import '../../../models/arbol_decisiones.dart';
import '../../../models/maquinaria.dart';
import '../../../services/diagnostico_arbol_service.dart';

/// Pantalla que muestra el diagnóstico completo usando árbol de decisiones
/// Muestra sistemas -> componentes -> síntomas -> soluciones de forma jerárquica
class DiagnosticoArbolScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const DiagnosticoArbolScreen({
    super.key,
    required this.maquinaria,
  });

  @override
  State<DiagnosticoArbolScreen> createState() => _DiagnosticoArbolScreenState();
}

class _DiagnosticoArbolScreenState extends State<DiagnosticoArbolScreen> {
  final DiagnosticoArbolService _diagnosticoService = DiagnosticoArbolService();
  DiagnosticoCompleto? _diagnostico;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDiagnostico();
  }

  Future<void> _cargarDiagnostico() async {
    setState(() => _loading = true);
    try {
      final diagnostico = await _diagnosticoService.diagnosticarMaquina(widget.maquinaria);
      setState(() {
        _diagnostico = diagnostico;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar diagnóstico: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Diagnóstico: ${widget.maquinaria.nombre}'),
        backgroundColor: Colors.yellow.shade600,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _diagnostico == null
              ? const Center(child: Text('No se pudo generar el diagnóstico'))
              : RefreshIndicator(
                  onRefresh: _cargarDiagnostico,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResumenGeneral(isDark),
                        const SizedBox(height: 20),
                        _buildSistemas(isDark),
                        const SizedBox(height: 20),
                        _buildRecomendacionesGlobales(isDark),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumenGeneral(bool isDark) {
    final diagnostico = _diagnostico!;
    final colorRiesgo = _obtenerColorRiesgo(diagnostico.nivelRiesgoGeneral);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorRiesgo, colorRiesgo.withOpacity(0.7)],
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
                Icon(Icons.assessment, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnóstico General',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.maquinaria.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricaCard(
                  'Score de Riesgo',
                  '${diagnostico.scoreRiesgoGeneral.toStringAsFixed(1)}%',
                  Icons.warning,
                  Colors.white,
                ),
                _buildMetricaCard(
                  'Nivel de Riesgo',
                  diagnostico.nivelRiesgoGeneral.toUpperCase(),
                  Icons.trending_up,
                  Colors.white,
                ),
                _buildMetricaCard(
                  'Sistemas Evaluados',
                  diagnostico.sistemas.isEmpty ? '0' : '${diagnostico.sistemas.length}',
                  Icons.settings,
                  Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSistemas(bool isDark) {
    final sistemas = _diagnostico!.sistemas;

    if (sistemas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  '✅ Todos los sistemas están en buen estado',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diagnóstico por Sistemas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        if (sistemas.isEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay sistemas con problemas detectados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para obtener un diagnóstico detallado, registre parámetros de la máquina en la pestaña "Parámetros".',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...sistemas.map((sistema) => _buildSistemaCard(sistema, isDark)),
      ],
    );
  }

  Widget _buildSistemaCard(DiagnosticoSistema sistema, bool isDark) {
    final colorSistema = _obtenerColorRiesgo(sistema.nivelRiesgo);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorSistema.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _obtenerIconoSistema(sistema.sistemaId),
            color: colorSistema,
            size: 28,
          ),
        ),
        title: Text(
          sistema.sistemaNombre,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorSistema,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sistema.nivelRiesgo.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Riesgo: ${sistema.scoreRiesgo.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorSistema,
                  ),
                ),
              ],
            ),
            if (sistema.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                sistema.descripcion!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        children: sistema.componentes.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '✅ Este sistema no presenta problemas',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ]
            : sistema.componentes.map((componente) => _buildComponenteCard(componente, isDark)).toList(),
      ),
    );
  }

  Widget _buildComponenteCard(DiagnosticoComponente componente, bool isDark) {
    final colorComponente = _obtenerColorRiesgo(componente.nivelRiesgo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorComponente.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.build_circle,
            color: colorComponente,
            size: 20,
          ),
        ),
        title: Text(
          componente.componenteNombre,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorComponente,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Prioridad ${componente.prioridad}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${componente.scoreRiesgo.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorComponente,
              ),
            ),
          ],
        ),
        children: [
          if (componente.descripcion != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                componente.descripcion!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
          if (componente.sintomas.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Síntomas Detectados:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...componente.sintomas.map((sintoma) => _buildSintomaCard(sintoma, isDark)),
          ],
          if (componente.solucion != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Solución Recomendada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    componente.solucion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (componente.accionesRecomendadas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Acciones a Realizar:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...componente.accionesRecomendadas.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSintomaCard(DiagnosticoSintoma sintoma, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sintoma.presente
            ? Colors.orange.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sintoma.presente
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            sintoma.presente ? Icons.warning : Icons.check_circle,
            color: sintoma.presente ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sintoma.sintomaNombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                if (sintoma.descripcion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sintoma.descripcion!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sintoma.presente
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${sintoma.probabilidad.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: sintoma.presente ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacionesGlobales(bool isDark) {
    final recomendaciones = _diagnostico!.recomendacionesGlobales;

    if (recomendaciones.isEmpty) return const SizedBox.shrink();

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
                const Icon(Icons.recommend, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Recomendaciones Globales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recomendaciones.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _obtenerColorRiesgo(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'critico':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'medio':
        return Colors.yellow;
      case 'bajo':
        return Colors.blue;
      case 'optimo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _obtenerIconoSistema(String sistemaId) {
    switch (sistemaId) {
      case 'sistema_motor':
        return Icons.precision_manufacturing;
      case 'sistema_hidraulico':
        return Icons.water_drop;
      case 'sistema_transmision':
        return Icons.settings;
      case 'sistema_frenos':
        return Icons.stop_circle;
      case 'sistema_tren_rodaje':
        return Icons.track_changes;
      case 'sistema_general':
        return Icons.build;
      default:
        return Icons.settings;
    }
  }
}

