import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../models/maquinaria.dart';
import '../../../models/registro_mantenimiento.dart';
import '../../../controllers/control_mantenimiento.dart';
import '../../../controllers/control_maquinaria.dart';
import '../../../services/diagnostico_arbol_service.dart';
import '../../../services/ml_model_service.dart';
import '../../../config/mantenimiento_config.dart';
import 'diagnostico_arbol_screen.dart';
import 'diagnostico_interactivo_screen.dart';
import 'crear_registro_mantenimiento_screen.dart';
import 'registro_parametros_maquina_screen.dart';
import 'completar_mantenimiento_rapido_screen.dart';

/// Pantalla de detalles completos de una máquina en mantenimiento
/// Muestra toda la información, predicciones, análisis, y permite crear órdenes
class DetallesMaquinaMantenimientoScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const DetallesMaquinaMantenimientoScreen({
    super.key,
    required this.maquinaria,
  });

  @override
  State<DetallesMaquinaMantenimientoScreen> createState() => _DetallesMaquinaMantenimientoScreenState();
}

class _DetallesMaquinaMantenimientoScreenState extends State<DetallesMaquinaMantenimientoScreen> with WidgetsBindingObserver {
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();
  final DiagnosticoArbolService _diagnosticoService = DiagnosticoArbolService();
  final MLModelService _mlService = MLModelService();
  
  List<RegistroMantenimiento> _registrosMantenimiento = [];
  bool _loading = true;
  double? _probabilidadFallaML;
  int _diagnosticoKey = 0; // Key para forzar reconstrucción del diagnóstico
  Maquinaria? _maquinariaActualizada; // Guardar la máquina actualizada en el estado

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maquinariaActualizada = widget.maquinaria; // Inicializar con la máquina del widget
    _cargarDatos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Recargar datos cuando la app vuelve a primer plano
      _cargarDatos();
    }
  }

  // Getter para obtener la máquina actual (actualizada o la del widget)
  Maquinaria get _maquinaria => _maquinariaActualizada ?? widget.maquinaria;

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Recargar registros de mantenimiento
      final registros = await _controlMantenimiento.consultarRegistrosPorMaquinaria(widget.maquinaria.id);
      
      // IMPORTANTE: Recargar la máquina desde la base de datos para obtener los datos más actualizados
      // Esto asegura que las horas trabajadas se actualicen correctamente cuando se registran desde otra pantalla
      final controlMaquinaria = ControlMaquinaria();
      final maquinariaActualizada = await controlMaquinaria.consultarMaquinaria(widget.maquinaria.id);
      
      // Log para depuración
      if (maquinariaActualizada != null) {
        print('📊 Datos de máquina cargados:');
        print('   ID: ${maquinariaActualizada.id}');
        print('   Horas totales: ${maquinariaActualizada.horasUso}');
        print('   Horas desde mant. motor: ${maquinariaActualizada.horasDesdeUltimoMantenimientoMotor}');
        print('   Horas desde mant. hidráulico: ${maquinariaActualizada.horasDesdeUltimoMantenimientoHidraulico}');
        print('   Fecha último mantenimiento: ${maquinariaActualizada.fechaUltimoMantenimiento}');
      } else {
        print('⚠️ No se encontró la máquina actualizada');
      }
      
      // Calcular probabilidad de falla con ML (esto también recarga los análisis)
      final probabilidad = await _calcularProbabilidadFallaML();
      
      if (mounted) {
        setState(() {
          _registrosMantenimiento = registros;
          _probabilidadFallaML = probabilidad;
          _diagnosticoKey++; // Incrementar key para forzar reconstrucción del diagnóstico
          // Actualizar la máquina si se encontró - ESTO ES CRÍTICO para mostrar las horas actualizadas
          if (maquinariaActualizada != null) {
            _maquinariaActualizada = maquinariaActualizada; // Guardar la máquina actualizada
            print('✅ Máquina actualizada en el estado');
          } else {
            print('⚠️ No se encontró la máquina actualizada');
          }
        });
      }
    } catch (e) {
      print('❌ Error al cargar datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<double?> _calcularProbabilidadFallaML() async {
    try {
      // Usar la máquina actualizada del estado, no la del widget
      final maquinariaParaAnalisis = _maquinaria;
      
      // Obtener análisis recientes para usar datos reales
      final analisisRecientes = await _controlMantenimiento.consultarAnalisisPorMaquinaria(maquinariaParaAnalisis.id);
      final ahora = DateTime.now();
      
      // PRIORIZAR análisis de los últimos 7 días (más recientes)
      final analisisUltimos7Dias = analisisRecientes.where((a) => 
        ahora.difference(a.fechaAnalisis).inDays <= 7
      ).toList();
      
      // SIEMPRE usar solo análisis de últimos 7 días para contar alertas
      // Esto asegura sincronización con el diagnóstico
      final analisisParaAlertas = analisisUltimos7Dias;
      
      // Contar alertas críticas y medias SOLO de los análisis recientes (últimos 7 días)
      final alertasCriticas30d = analisisParaAlertas.where((a) => a.resultado == 'critico').length;
      final alertasMedias30d = analisisParaAlertas.where((a) => a.resultado == 'advertencia').length;
      
      // Si NO hay análisis recientes, retornar probabilidad baja (0-30%)
      // No usar el dataset porque puede dar valores altos incorrectos
      if (analisisUltimos7Dias.isEmpty) {
        print('⚠️ No hay análisis recientes, retornando probabilidad conservadora (20%)');
        return 0.2; // 20% de riesgo cuando no hay datos
      }
      
      // Para extraer valores de parámetros, usar SOLO análisis de últimos 7 días
      // Esto asegura sincronización con el diagnóstico
      final analisisParaValores = analisisUltimos7Dias;
      
      // Ordenar análisis por fecha (más reciente primero) para tomar el último valor de cada parámetro
      analisisParaValores.sort((a, b) => b.fechaAnalisis.compareTo(a.fechaAnalisis));
      
      // NO usar el dataset CSV como fallback - solo usar valores reales de análisis
      // Si no hay valores reales, usar valores conservadores (óptimos)

      // Valores por defecto CONSERVADORES (normales/óptimos) cuando no hay datos reales
      // Estos valores representan una máquina en estado normal/óptimo
      // NO usar el dataset porque puede tener valores que generan riesgo alto
      // Rango temp_refrigerante_motor: 70-130, óptimo ~85°C
      double tempRefrigeranteMotor = 85.0;
      // Rango temp_aceite_motor: 70-150, óptimo ~90°C
      double tempAceiteMotor = 90.0;
      // Rango presion_aceite_motor: 0.8-6.0, óptimo ~4.0 bar
      double presionAceiteMotor = 4.0;
      // Rango temp_aceite_hidraulico: 30-110, óptimo ~55°C
      double tempAceiteHidraulico = 55.0;
      // Rango presion_linea_hidraulica: 100-420, óptimo ~250 bar
      double presionLineaHidraulica = 250.0;
      // Rango nivel_aceite_motor: 0-1 (fracción), óptimo ~0.9 (90%)
      double nivelAceiteMotor = 0.9;
      // Rango nivel_aceite_hidraulico: 0-1 (fracción), óptimo ~0.9 (90%)
      double nivelAceiteHidraulico = 0.9;
      
      // Mapas para rastrear si ya encontramos el valor más reciente de cada parámetro
      final parametrosEncontrados = <String, bool>{};
      
      // Buscar valores en análisis recientes (tomar el MÁS RECIENTE de cada tipo)
      // Iterar desde el más reciente (ya está ordenado)
      for (var analisis in analisisParaValores) {
        final datos = analisis.datosAnalisis;
        final parametro = datos['parametro']?.toString() ?? '';
        final sistema = datos['sistema']?.toString() ?? '';
        
        // Usar valorMedido del análisis si está disponible, sino del map
        final valor = analisis.valorMedido ?? (datos['valorMedido'] != null 
            ? (datos['valorMedido'] as num).toDouble() 
            : null);
        
        if (valor == null || parametro.isEmpty) continue;
        
        // Mapear parámetros del formulario a features del ML
        // Sistema: refrigeracion, parámetro: temperatura_refrigerante
        if (sistema == 'refrigeracion' && parametro == 'temperatura_refrigerante' && 
            parametrosEncontrados['temp_refrigerante'] != true) {
          tempRefrigeranteMotor = valor; // Ya está en °C
          parametrosEncontrados['temp_refrigerante'] = true;
        }
        // Sistema: motor, parámetro: temperatura
        else if (sistema == 'motor' && parametro == 'temperatura' && 
                 parametrosEncontrados['temp_aceite_motor'] != true) {
          tempAceiteMotor = valor; // Ya está en °C
          parametrosEncontrados['temp_aceite_motor'] = true;
        }
        // Sistema: motor, parámetro: presion_aceite (PSI -> bar: 1 PSI = 0.0689476 bar)
        else if (sistema == 'motor' && parametro == 'presion_aceite' && 
                 parametrosEncontrados['presion_aceite_motor'] != true) {
          presionAceiteMotor = valor * 0.0689476; // Convertir PSI a bar
          parametrosEncontrados['presion_aceite_motor'] = true;
        }
        // Sistema: motor, parámetro: nivel_aceite (% -> fracción: 0-100 -> 0-1)
        else if (sistema == 'motor' && parametro == 'nivel_aceite' && 
                 parametrosEncontrados['nivel_aceite_motor'] != true) {
          nivelAceiteMotor = valor / 100.0; // Convertir porcentaje a fracción (0-1)
          parametrosEncontrados['nivel_aceite_motor'] = true;
        }
        // Sistema: hidraulico, parámetro: temperatura_fluido
        else if (sistema == 'hidraulico' && parametro == 'temperatura_fluido' && 
                 parametrosEncontrados['temp_aceite_hidraulico'] != true) {
          tempAceiteHidraulico = valor; // Ya está en °C
          parametrosEncontrados['temp_aceite_hidraulico'] = true;
        }
        // Sistema: hidraulico, parámetro: presion_hidraulica (PSI -> bar)
        else if (sistema == 'hidraulico' && parametro == 'presion_hidraulica' && 
                 parametrosEncontrados['presion_linea_hidraulico'] != true) {
          presionLineaHidraulica = valor * 0.0689476; // Convertir PSI a bar
          parametrosEncontrados['presion_linea_hidraulico'] = true;
        }
        // Sistema: hidraulico, parámetro: nivel_fluido (% -> fracción)
        else if (sistema == 'hidraulico' && parametro == 'nivel_fluido' && 
                 parametrosEncontrados['nivel_aceite_hidraulico'] != true) {
          nivelAceiteHidraulico = valor / 100.0; // Convertir porcentaje a fracción (0-1)
          parametrosEncontrados['nivel_aceite_hidraulico'] = true;
        }
      }
      
      // Debug: imprimir valores que se van a usar
      print('📊 Valores para ML:');
      print('   tempRefrigeranteMotor: $tempRefrigeranteMotor°C');
      print('   tempAceiteMotor: $tempAceiteMotor°C');
      print('   presionAceiteMotor: $presionAceiteMotor bar');
      print('   tempAceiteHidraulico: $tempAceiteHidraulico°C');
      print('   presionLineaHidraulica: $presionLineaHidraulica bar');
      print('   nivelAceiteMotor: $nivelAceiteMotor (fracción)');
      print('   nivelAceiteHidraulico: $nivelAceiteHidraulico (fracción)');
      print('   alertasCriticas30d: $alertasCriticas30d');
      print('   alertasMedias30d: $alertasMedias30d');

      // Preparar features con datos reales de análisis cuando están disponibles
      final features = _mlService.prepararFeatures(
        horasUsoTotal: maquinariaParaAnalisis.horasUso.toDouble(),
        horasDesdeUltimoMantenimiento: maquinariaParaAnalisis.horasDesdeUltimoMantenimientoMotor,
        tempRefrigeranteMotor: tempRefrigeranteMotor,
        tempAceiteMotor: tempAceiteMotor,
        presionAceiteMotor: presionAceiteMotor,
        tempAceiteHidraulico: tempAceiteHidraulico,
        presionLineaHidraulica: presionLineaHidraulica,
        nivelAceiteMotor: nivelAceiteMotor,
        nivelAceiteHidraulico: nivelAceiteHidraulico,
        // Rango diferencial_presion_filtro_aceite: 0-240, óptimo ~20 kPa (filtros limpios)
        diferencialPresionFiltroAceite: 20.0,
        // Rango diferencial_presion_filtro_hidraulico: 0-240, óptimo ~20 kPa (filtros limpios)
        diferencialPresionFiltroHidraulico: 20.0,
        // Rango porcentaje_tiempo_ralenti: 0-1, óptimo ~0.3 (30% - uso eficiente)
        porcentajeTiempoRalenti: 0.3,
        // Rango promedio_horas_diarias_uso: 0-20, óptimo ~8 horas (uso normal)
        promedioHorasDiariasUso: 8.0,
        alertasCriticas30d: alertasCriticas30d, // Usar análisis reales
        alertasMedias30d: alertasMedias30d, // Usar análisis reales
      );

      final probabilidad = await _mlService.predecir(features);
      return probabilidad;
    } catch (e) {
      print('Error al calcular probabilidad ML: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.maquinaria.nombre),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarDatos(); // Forzar recarga manual
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  _buildInfoBasica(isDark),
                  const SizedBox(height: 16),
                  
                  // Horas trabajadas y recomendaciones
                  _buildHorasTrabajadas(isDark),
                  const SizedBox(height: 16),
                  
                  // Riesgo ML
                  if (_probabilidadFallaML != null) ...[
                    _buildRiesgoML(isDark),
                    const SizedBox(height: 16),
                  ],
                  
                  // Estado general
                  _buildEstadoGeneral(isDark),
                  const SizedBox(height: 16),
                  
                  // Botones de acción
                  _buildBotonesAccion(isDark),
                  const SizedBox(height: 16),
                  
                  // Registros de mantenimiento
                  _buildRegistrosMantenimiento(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoBasica(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.construction, color: Colors.blue.shade600, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.maquinaria.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Horómetro: ${widget.maquinaria.horasUso} horas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Modelo', widget.maquinaria.modelo, isDark),
                ),
                Expanded(
                  child: _buildInfoItem('Marca', widget.maquinaria.marca, isDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoItem('Estado', widget.maquinaria.estado, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildHorasTrabajadas(bool isDark) {
    // Usar la máquina actualizada del estado
    final maquinaria = _maquinaria;
    
    // Calcular horas restantes para diferentes tipos de mantenimiento
    final horasRestantesMotor = MantenimientoConfig.calcularHorasRestantesAceiteMotor(
      maquinaria.horasDesdeUltimoMantenimientoMotor,
    );
    final horasRestantesHidraulico = MantenimientoConfig.calcularHorasRestantesAceiteHidraulico(
      maquinaria.horasDesdeUltimoMantenimientoHidraulico,
    );
    final horasRestantesFiltros = MantenimientoConfig.calcularHorasRestantesFiltros(
      maquinaria.horasDesdeUltimoMantenimientoMotor, // Usar motor como referencia
    );
    
    // Calcular información de último registro
    final ultimoMes = _obtenerMesTexto(maquinaria.fechaUltimoMantenimiento);
    
    // Calcular horas trabajadas desde último mantenimiento
    // Usar el máximo entre motor e hidráulico para mostrar el total trabajado
    final horasTrabajadasDesdeUltimoMantenimiento = 
        maquinaria.horasDesdeUltimoMantenimientoMotor > maquinaria.horasDesdeUltimoMantenimientoHidraulico
            ? maquinaria.horasDesdeUltimoMantenimientoMotor
            : maquinaria.horasDesdeUltimoMantenimientoHidraulico;
    
    print('   Horas trabajadas calculadas: $horasTrabajadasDesdeUltimoMantenimiento');
    print('   Horas restantes motor: ${MantenimientoConfig.calcularHorasRestantesAceiteMotor(maquinaria.horasDesdeUltimoMantenimientoMotor)}');
    print('   Horas restantes hidráulico: ${MantenimientoConfig.calcularHorasRestantesAceiteHidraulico(maquinaria.horasDesdeUltimoMantenimientoHidraulico)}');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Horas Trabajadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Información de último registro y horas trabajadas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Último mantenimiento: $ultimoMes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.work_outline, size: 16, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Horas trabajadas: ${horasTrabajadasDesdeUltimoMantenimiento.toStringAsFixed(1)} horas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Información detallada de horas
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Horómetro Total',
                    '${maquinaria.horasUso} hrs',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Desde Mant. Motor',
                    '${maquinaria.horasDesdeUltimoMantenimientoMotor.toStringAsFixed(1)} hrs',
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Desde Mant. Hidráulico',
              '${maquinaria.horasDesdeUltimoMantenimientoHidraulico.toStringAsFixed(1)} hrs',
              isDark,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.build_circle, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recomendaciones de Mantenimiento:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Cambio de aceite de motor (250 horas)
            Builder(
              builder: (context) {
                final completado = _estaMantenimientoCompletado('aceite motor');
                // Si está completado, mostrar mensaje diferente
                final mensaje = completado 
                    ? '🛢️ Cambio de aceite de motor completado recientemente'
                    : '🛢️ ${MantenimientoConfig.obtenerMensajeAceiteMotor(horasRestantesMotor)}';
                return _buildRecomendacionItem(
                  mensaje,
                  _obtenerColorRecomendacion(horasRestantesMotor, 50.0, completado: completado),
                  mostrarCheck: completado,
                  onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                    'aceite motor',
                    'Cambio de aceite de motor',
                    'motor',
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            
            // Cambio de aceite hidráulico (500 horas)
            Builder(
              builder: (context) {
                final completado = _estaMantenimientoCompletado('aceite hidráulico');
                final mensaje = completado 
                    ? '⚙️ Cambio de aceite hidráulico completado recientemente'
                    : '⚙️ ${MantenimientoConfig.obtenerMensajeAceiteHidraulico(horasRestantesHidraulico)}';
                return _buildRecomendacionItem(
                  mensaje,
                  _obtenerColorRecomendacion(horasRestantesHidraulico, 100.0, completado: completado),
                  mostrarCheck: completado,
                  onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                    'aceite hidráulico',
                    'Cambio de aceite hidráulico',
                    'hidraulico',
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            
            // Cambio de filtros (300 horas)
            Builder(
              builder: (context) {
                final completado = _estaMantenimientoCompletado('filtro');
                final mensaje = completado 
                    ? '🔧 Cambio de filtros completado recientemente'
                    : '🔧 ${MantenimientoConfig.obtenerMensajeFiltros(horasRestantesFiltros)}';
                return _buildRecomendacionItem(
                  mensaje,
                  _obtenerColorRecomendacion(horasRestantesFiltros, 50.0, completado: completado),
                  mostrarCheck: completado,
                  onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                    'filtro',
                    'Cambio de filtros',
                    'ambos',
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            
            // Agregar/rellenar aceite de motor (cada 100 horas)
            Builder(
              builder: (context) {
                final horasDesdeVerificacionMotor = maquinaria.horasDesdeUltimoMantenimientoMotor % 100;
                final horasRestantesVerificacionMotor = 100 - horasDesdeVerificacionMotor;
                final completado = _estaMantenimientoCompletado('agregar aceite motor');
                final mensaje = completado 
                    ? '➕ Verificación de aceite de motor completada recientemente'
                    : '➕ ${MantenimientoConfig.obtenerMensajeAgregarAceiteMotor(maquinaria.horasDesdeUltimoMantenimientoMotor)}';
                return Column(
                  children: [
                    _buildRecomendacionItem(
                      mensaje,
                      _obtenerColorRecomendacion(horasRestantesVerificacionMotor, 20.0, completado: completado),
                      mostrarCheck: completado,
                      onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                        'agregar aceite motor',
                        'Agregar/rellenar aceite de motor',
                        'motor',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            
            // Agregar/rellenar aceite hidráulico (cada 200 horas)
            Builder(
              builder: (context) {
                final horasDesdeVerificacionHidraulico = maquinaria.horasDesdeUltimoMantenimientoHidraulico % 200;
                final horasRestantesVerificacionHidraulico = 200 - horasDesdeVerificacionHidraulico;
                final completado = _estaMantenimientoCompletado('agregar aceite hidráulico');
                final mensaje = completado 
                    ? '➕ Verificación de aceite hidráulico completada recientemente'
                    : '➕ ${MantenimientoConfig.obtenerMensajeAgregarAceiteHidraulico(maquinaria.horasDesdeUltimoMantenimientoHidraulico)}';
                return Column(
                  children: [
                    _buildRecomendacionItem(
                      mensaje,
                      _obtenerColorRecomendacion(horasRestantesVerificacionHidraulico, 40.0, completado: completado),
                      mostrarCheck: completado,
                      onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                        'agregar aceite hidráulico',
                        'Agregar/rellenar aceite hidráulico',
                        'hidraulico',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            
            // Revisión general (1000 horas)
            Builder(
              builder: (context) {
                final horasRestantesRevision = MantenimientoConfig.UMBRAL_REVISION_GENERAL_HORAS - maquinaria.horasDesdeUltimoMantenimientoMotor;
                final completado = _estaMantenimientoCompletado('revisión general');
                final mensaje = completado 
                    ? '🔍 Revisión general completada recientemente'
                    : '🔍 ${MantenimientoConfig.obtenerMensajeRevisionGeneral(maquinaria.horasDesdeUltimoMantenimientoMotor)}';
                return Column(
                  children: [
                    _buildRecomendacionItem(
                      mensaje,
                      _obtenerColorRecomendacion(horasRestantesRevision, 200.0, completado: completado),
                      mostrarCheck: completado,
                      onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                        'revisión general',
                        'Revisión general',
                        'ambos',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            
            // Mantenimiento mayor (5000 horas)
            if (maquinaria.horasDesdeUltimoMantenimientoMotor >= 4500)
              Builder(
                builder: (context) {
                  final horasRestantesMayor = MantenimientoConfig.UMBRAL_MANTENIMIENTO_MAYOR_HORAS - maquinaria.horasDesdeUltimoMantenimientoMotor;
                  final completado = _estaMantenimientoCompletado('mantenimiento mayor');
                  final mensaje = completado 
                      ? '🔨 Mantenimiento mayor completado recientemente'
                      : '🔨 ${MantenimientoConfig.obtenerMensajeMantenimientoMayor(maquinaria.horasDesdeUltimoMantenimientoMotor)}';
                  return _buildRecomendacionItem(
                    mensaje,
                    _obtenerColorRecomendacion(horasRestantesMayor, 500.0, completado: completado),
                    mostrarCheck: completado,
                    onCompletar: completado ? null : () => _completarMantenimientoDesdeRecomendacion(
                      'mantenimiento mayor',
                      'Mantenimiento mayor',
                      'ambos',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  String _obtenerMesTexto(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  /// Función helper para determinar el color según horas trabajadas
  /// Rojo: Vencido (horasRestantes <= 0)
  /// Amarillo/Naranja: Cerca del límite (horasRestantes <= umbralUrgente)
  /// Verde: Falta mucho (horasRestantes > umbralUrgente)
  /// Gris: Completado (mantenimiento ya realizado)
  Color _obtenerColorRecomendacion(double horasRestantes, double umbralUrgente, {bool completado = false}) {
    if (completado) {
      return Colors.grey; // Completado - Gris
    } else if (horasRestantes <= 0) {
      return Colors.red; // Vencido - Rojo
    } else if (horasRestantes <= umbralUrgente) {
      return Colors.orange; // Cerca - Amarillo/Naranja
    } else {
      return Colors.green; // Falta mucho - Verde
    }
  }

  /// Verifica si un tipo de mantenimiento está completado recientemente
  /// Verifica TANTO el registro de mantenimiento COMO las horas trabajadas Y la fecha
  /// Retorna true si:
  /// 1. Hay un registro completado en los últimos 30 días Y las horas están en 0, O
  /// 2. Las horas están en 0 Y la fecha de último mantenimiento es reciente (< 30 días)
  /// Esto asegura coherencia entre registro, horas y fecha
  bool _estaMantenimientoCompletado(String tipoMantenimiento) {
    final ahora = DateTime.now();
    final maquinaria = _maquinaria;
    
    // Verificar si hay un registro completado reciente
    final tieneRegistroReciente = _registrosMantenimiento.any((registro) =>
        registro.idMaquinaria == widget.maquinaria.id &&
        registro.estado == 'completado' &&
        registro.fechaRealizacion != null &&
        ahora.difference(registro.fechaRealizacion!).inDays <= 30 &&
        registro.descripcionTrabajo.toLowerCase().contains(tipoMantenimiento.toLowerCase()));
    
    // Verificar si la fecha de último mantenimiento es reciente (< 30 días)
    final fechaMantenimientoReciente = ahora.difference(maquinaria.fechaUltimoMantenimiento).inDays <= 30;
    
    // Verificar las horas trabajadas según el tipo de mantenimiento
    bool horasEnCero = false;
    final tipoLower = tipoMantenimiento.toLowerCase();
    
    if (tipoLower.contains('motor') && !tipoLower.contains('hidráulico') && !tipoLower.contains('hidraulico')) {
      // Mantenimiento de motor: verificar horas de motor
      horasEnCero = maquinaria.horasDesdeUltimoMantenimientoMotor < 10.0;
    } else if (tipoLower.contains('hidráulico') || tipoLower.contains('hidraulico')) {
      // Mantenimiento hidráulico: verificar horas de hidráulico
      horasEnCero = maquinaria.horasDesdeUltimoMantenimientoHidraulico < 10.0;
    } else if (tipoLower.contains('filtro')) {
      // Filtros: verificar que al menos uno esté en 0 (o ambos)
      horasEnCero = maquinaria.horasDesdeUltimoMantenimientoMotor < 10.0 || 
                    maquinaria.horasDesdeUltimoMantenimientoHidraulico < 10.0;
    } else {
      // Otros (revisión general, mantenimiento mayor): verificar ambos
      horasEnCero = maquinaria.horasDesdeUltimoMantenimientoMotor < 10.0 && 
                    maquinaria.horasDesdeUltimoMantenimientoHidraulico < 10.0;
    }
    
    // El mantenimiento está completado si:
    // 1. Hay registro reciente Y horas en 0, O
    // 2. Horas en 0 Y fecha de mantenimiento es reciente (asegura que no es un error de datos antiguos)
    return (tieneRegistroReciente && horasEnCero) || (horasEnCero && fechaMantenimientoReciente);
  }

  /// Completa un mantenimiento desde una recomendación
  /// Abre una pantalla para agregar costo y detalle
  Future<void> _completarMantenimientoDesdeRecomendacion(
    String tipoMantenimiento,
    String descripcionTrabajo,
    String tipoReset, // 'motor', 'hidraulico', 'ambos'
  ) async {
    if (!mounted) return;
    
    // Abrir pantalla para agregar costo y detalle
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompletarMantenimientoRapidoScreen(
          maquinaria: _maquinaria,
          tipoMantenimiento: tipoMantenimiento,
          descripcionTrabajo: descripcionTrabajo,
          tipoReset: tipoReset,
        ),
      ),
    );
    
    // Si el mantenimiento se completó exitosamente, recargar datos
    if (resultado == true && mounted) {
      await _cargarDatos();
    }
  }

  Widget _buildRecomendacionItem(
    String mensaje,
    Color color, {
    bool mostrarCheck = false,
    VoidCallback? onCompletar,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (mostrarCheck)
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
          else
            Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                fontSize: 13,
                color: Color.lerp(color, Colors.black, 0.3) ?? color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Botón para completar mantenimiento (solo si no está completado)
          if (!mostrarCheck && onCompletar != null)
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 24),
              onPressed: onCompletar,
              tooltip: 'Marcar como completado',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildRiesgoML(bool isDark) {
    if (_probabilidadFallaML == null) return const SizedBox.shrink();

    final probabilidad = _probabilidadFallaML!;
    final porcentaje = (probabilidad * 100).toStringAsFixed(1);
    
    String nivelRiesgo;
    Color colorRiesgo;
    
    if (probabilidad < 0.4) {
      nivelRiesgo = 'BAJO';
      colorRiesgo = Colors.green;
    } else if (probabilidad < 0.6) {
      nivelRiesgo = 'MEDIO';
      colorRiesgo = Colors.yellow.shade700;
    } else if (probabilidad < 0.8) {
      nivelRiesgo = 'ALTO';
      colorRiesgo = Colors.orange;
    } else {
      nivelRiesgo = 'MUY ALTO';
      colorRiesgo = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorRiesgo.withOpacity(0.1),
              colorRiesgo.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorRiesgo, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: colorRiesgo, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Riesgo ML',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Probabilidad de Riesgo',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$porcentaje %',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorRiesgo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basado en modelo ML',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorRiesgo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    nivelRiesgo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoGeneral(bool isDark) {
    return FutureBuilder(
      key: ValueKey(_diagnosticoKey), // Key para forzar reconstrucción cuando cambie
      future: _diagnosticoService.diagnosticarMaquina(widget.maquinaria),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final diagnostico = snapshot.data!;
        final colorEstado = _obtenerColorEstado(diagnostico.nivelRiesgoGeneral);
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorEstado.withOpacity(0.1),
                  colorEstado.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorEstado, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorEstado,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _obtenerIconoEstado(diagnostico.nivelRiesgoGeneral),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTADO GENERAL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorEstado,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diagnostico.nivelRiesgoGeneral == 'sin_datos' 
                                ? 'SIN DATOS' 
                                : diagnostico.nivelRiesgoGeneral == 'optimo'
                                    ? 'ÓPTIMO'
                                    : diagnostico.nivelRiesgoGeneral.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      diagnostico.nivelRiesgoGeneral == 'sin_datos' 
                          ? 'N/A' 
                          : diagnostico.nivelRiesgoGeneral == 'optimo'
                              ? '100%'
                              : '${(100 - diagnostico.scoreRiesgoGeneral).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorEstado,
                      ),
                    ),
                  ],
                ),
                if (diagnostico.recomendacionesGlobales.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...diagnostico.recomendacionesGlobales.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: colorEstado),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotonesAccion(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistroParametrosMaquinaScreen(maquinaria: widget.maquinaria),
                    ),
                  );
                  // Recargar datos después de registrar parámetros
                  if (result == true) {
                    _cargarDatos();
                  }
                },
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Registrar Parámetros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiagnosticoInteractivoScreen(maquinaria: widget.maquinaria),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Diagnóstico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiagnosticoArbolScreen(maquinaria: widget.maquinaria),
                    ),
                  );
                },
                icon: const Icon(Icons.account_tree),
                label: const Text('Análisis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Métodos de análisis removidos - usar solo registros de mantenimiento

  Widget _buildRegistrosMantenimiento(bool isDark) {
    return Card(
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
                const Expanded(
                  child: Text(
                    'R. Mantenimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrearRegistroMantenimientoScreen(maquinaria: widget.maquinaria),
                        ),
                      );
                      if (resultado == true) {
                        _cargarDatos();
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_registrosMantenimiento.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No hay registros de mantenimiento',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ..._registrosMantenimiento.map((registro) => _buildItemRegistro(registro, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRegistro(RegistroMantenimiento registro, bool isDark) {
    final color = registro.estado == 'completado' 
        ? Colors.green 
        : registro.estado == 'en_progreso' 
            ? Colors.blue 
            : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  registro.tipoMantenimiento.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  registro.estado.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            registro.descripcionTrabajo,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          if (registro.costoTotal > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Costo: \$${registro.costoTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'critico':
      case 'urgente_reparacion':
        return Colors.red;
      case 'alto':
      case 'malo':
        return Colors.orange;
      case 'medio':
      case 'regular':
        return Colors.yellow.shade700;
      case 'bajo':
        return Colors.blue;
      case 'optimo':
      case 'bueno':
        return Colors.green;
      case 'sin_datos':
        return Colors.grey;
      default:
        return Colors.grey; // Para estados desconocidos, usar gris en lugar de verde
    }
  }

  IconData _obtenerIconoEstado(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'critico':
      case 'urgente_reparacion':
        return Icons.error;
      case 'alto':
      case 'malo':
        return Icons.warning;
      case 'medio':
      case 'regular':
        return Icons.info;
      case 'optimo':
      case 'bueno':
        return Icons.check_circle;
      case 'sin_datos':
        return Icons.info_outline;
      default:
        return Icons.help_outline; // Para estados desconocidos
    }
  }

}

