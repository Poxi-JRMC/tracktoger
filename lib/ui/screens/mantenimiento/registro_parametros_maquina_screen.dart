import 'package:flutter/material.dart';
import '../../../models/maquinaria.dart';
import '../../../controllers/control_mantenimiento.dart';
import '../../../models/analisis.dart';

/// Pantalla para registrar parámetros completos de una máquina
/// Pregunta sobre todos los sistemas para determinar el estado
class RegistroParametrosMaquinaScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const RegistroParametrosMaquinaScreen({
    super.key,
    required this.maquinaria,
  });

  @override
  State<RegistroParametrosMaquinaScreen> createState() => _RegistroParametrosMaquinaScreenState();
}

class _RegistroParametrosMaquinaScreenState extends State<RegistroParametrosMaquinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  
  // Controllers para cada sistema
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _resultados = {};
  bool _loading = false; // Estado de carga para evitar múltiples clics
  
  // Lista de sistemas y sus parámetros
  final List<Map<String, dynamic>> _sistemas = [
    {
      'id': 'motor',
      'nombre': 'Sistema Motor',
      'parametros': [
        {'id': 'temperatura', 'nombre': 'Temperatura del Motor (°C)', 'limite': 90.0},
        {'id': 'presion_aceite', 'nombre': 'Presión de Aceite (PSI)', 'limite': 40.0},
        {'id': 'nivel_aceite', 'nombre': 'Nivel de Aceite', 'limite': 100.0},
        {'id': 'consumo_combustible', 'nombre': 'Consumo de Combustible (L/h)', 'limite': 25.0},
      ],
    },
    {
      'id': 'hidraulico',
      'nombre': 'Sistema Hidráulico',
      'parametros': [
        {'id': 'presion_hidraulica', 'nombre': 'Presión Hidráulica (PSI)', 'limite': 3000.0},
        {'id': 'nivel_fluido', 'nombre': 'Nivel de Fluido Hidráulico (%)', 'limite': 80.0},
        {'id': 'temperatura_fluido', 'nombre': 'Temperatura del Fluido (°C)', 'limite': 70.0},
        {'id': 'fugas', 'nombre': 'Fugas Detectadas', 'limite': 0.0},
      ],
    },
    {
      'id': 'transmision',
      'nombre': 'Sistema de Transmisión',
      'parametros': [
        {'id': 'temperatura_transmision', 'nombre': 'Temperatura de Transmisión (°C)', 'limite': 100.0},
        {'id': 'nivel_aceite_transmision', 'nombre': 'Nivel de Aceite de Transmisión (%)', 'limite': 80.0},
        {'id': 'ruidos', 'nombre': 'Ruidos Anormales (0-10)', 'limite': 3.0},
      ],
    },
    {
      'id': 'frenos',
      'nombre': 'Sistema de Frenos',
      'parametros': [
        {'id': 'presion_frenos', 'nombre': 'Presión de Frenos (PSI)', 'limite': 1200.0},
        {'id': 'desgaste_pastillas', 'nombre': 'Desgaste de Pastillas (%)', 'limite': 30.0},
        {'id': 'temperatura_discos', 'nombre': 'Temperatura de Discos (°C)', 'limite': 200.0},
      ],
    },
    {
      'id': 'refrigeracion',
      'nombre': 'Sistema de Refrigeración',
      'parametros': [
        {'id': 'temperatura_refrigerante', 'nombre': 'Temperatura del Refrigerante (°C)', 'limite': 95.0},
        {'id': 'nivel_refrigerante', 'nombre': 'Nivel de Refrigerante (%)', 'limite': 80.0},
        {'id': 'presion_sistema', 'nombre': 'Presión del Sistema (PSI)', 'limite': 15.0},
      ],
    },
    {
      'id': 'filtros',
      'nombre': 'Filtros',
      'parametros': [
        {'id': 'filtro_aire', 'nombre': 'Estado Filtro de Aire (0-100%)', 'limite': 50.0},
        {'id': 'filtro_combustible', 'nombre': 'Estado Filtro de Combustible (0-100%)', 'limite': 50.0},
        {'id': 'filtro_aceite', 'nombre': 'Estado Filtro de Aceite (0-100%)', 'limite': 50.0},
      ],
    },
    {
      'id': 'estructura',
      'nombre': 'Estructura y Chasis',
      'parametros': [
        {'id': 'grietas', 'nombre': 'Grietas Detectadas', 'limite': 0.0},
        {'id': 'corrosion', 'nombre': 'Corrosión (%)', 'limite': 10.0},
        {'id': 'soldaduras', 'nombre': 'Estado de Soldaduras (0-10)', 'limite': 7.0},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar controllers y resultados
    for (var sistema in _sistemas) {
      for (var parametro in sistema['parametros']) {
        final id = '${sistema['id']}_${parametro['id']}';
        _controllers[id] = TextEditingController();
        _resultados[id] = 'normal';
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _evaluarParametro(String sistemaId, String parametroId, double valor, double limite) {
    final id = '${sistemaId}_${parametroId}';
    String resultado;
    
    if (valor > limite * 1.2) {
      resultado = 'critico';
    } else if (valor > limite) {
      resultado = 'advertencia';
    } else {
      resultado = 'normal';
    }
    
    setState(() {
      _resultados[id] = resultado;
    });
  }

  Future<void> _guardarParametros() async {
    if (_formKey.currentState!.validate()) {
      // Evitar múltiples clics mientras se está guardando
      if (_loading) return;
      
      setState(() => _loading = true);
      
      try {
        // ELIMINAR TODOS los análisis anteriores de esta máquina antes de registrar nuevos
        // Esto asegura que el análisis refleje solo los valores más recientes
        final eliminados = await _controlMantenimiento.eliminarTodosAnalisis(
          widget.maquinaria.id,
        );
        if (eliminados > 0) {
          print('🗑️ Eliminados TODOS los $eliminados análisis anteriores para reemplazarlos con nuevos parámetros');
        }
        
        final fechaRegistro = DateTime.now();
        int analisisCriticos = 0;
        int analisisAdvertencia = 0;
        
        // Registrar análisis para cada parámetro
        for (var sistema in _sistemas) {
          for (var parametro in sistema['parametros']) {
            final id = '${sistema['id']}_${parametro['id']}';
            final controller = _controllers[id];
            final valorTexto = controller?.text;
            
            if (valorTexto != null && valorTexto.isNotEmpty) {
              final valor = double.tryParse(valorTexto) ?? 0.0;
              final limite = parametro['limite'] as double;
              
              _evaluarParametro(sistema['id'], parametro['id'], valor, limite);
              final resultado = _resultados[id] ?? 'normal';
              
              if (resultado == 'critico') analisisCriticos++;
              if (resultado == 'advertencia') analisisAdvertencia++;
              
              final analisis = Analisis(
                id: 'analisis_${fechaRegistro.millisecondsSinceEpoch}_$id',
                maquinariaId: widget.maquinaria.id,
                tipoAnalisis: '${sistema['nombre']} - ${parametro['nombre']}',
                fechaAnalisis: fechaRegistro,
                fechaRegistro: fechaRegistro,
                datosAnalisis: {
                  'sistema': sistema['id'],
                  'parametro': parametro['id'],
                  'valorMedido': valor,
                  'valorLimite': limite,
                },
                resultado: resultado,
                valorMedido: valor,
                valorLimite: limite,
                observaciones: 'Registro de parámetros del sistema ${sistema['nombre']}',
                recomendaciones: resultado == 'critico' 
                    ? 'Revisión inmediata requerida'
                    : resultado == 'advertencia'
                        ? 'Monitorear y programar mantenimiento'
                        : 'Parámetro dentro de rango normal',
              );
              
              await _controlMantenimiento.registrarAnalisis(analisis);
            }
          }
        }
        
        // Limpiar todos los campos después de guardar exitosamente
        for (var controller in _controllers.values) {
          controller.clear();
        }
        _resultados.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                analisisCriticos == 0 && analisisAdvertencia == 0
                    ? '✅ Parámetros registrados correctamente. Estado actualizado.'
                    : '✅ Parámetros registrados: $analisisCriticos críticos, $analisisAdvertencia advertencias',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: analisisCriticos > 0 ? Colors.red : (analisisAdvertencia > 0 ? Colors.orange : Colors.green),
              duration: const Duration(seconds: 3),
            ),
          );
          // Esperar un momento antes de cerrar para que el usuario vea el mensaje
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Asegurar que el estado de carga se resetee siempre
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Parámetros: ${widget.maquinaria.nombre}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información de la máquina
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.construction, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.maquinaria.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.maquinaria.horasUso} horas de uso',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Formulario por sistema
            ..._sistemas.map((sistema) => _buildSistemaCard(sistema, isDark)),
            
            const SizedBox(height: 32),
            
            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _guardarParametros,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade600,
                ),
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Guardando...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Text(
                        'Guardar Todos los Parámetros',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSistemaCard(Map<String, dynamic> sistema, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          _obtenerIconoSistema(sistema['id']),
          color: Colors.blue.shade600,
          size: 28,
        ),
        title: Text(
          sistema['nombre'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: (sistema['parametros'] as List).map<Widget>((parametro) {
                final id = '${sistema['id']}_${parametro['id']}';
                final controller = _controllers[id]!;
                final resultado = _resultados[id] ?? 'normal';
                final color = resultado == 'critico' 
                    ? Colors.red 
                    : resultado == 'advertencia' 
                        ? Colors.orange 
                        : Colors.green;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              parametro['nombre'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (resultado != 'normal')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                resultado.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Ej: ${parametro['limite']}',
                          labelText: 'Valor Medido',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          suffixText: _obtenerUnidad(parametro['id']),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final valor = double.tryParse(value) ?? 0.0;
                            final limite = parametro['limite'] as double;
                            _evaluarParametro(sistema['id'], parametro['id'], valor, limite);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese un valor';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Límite máximo: ${parametro['limite']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
    );
  }

  IconData _obtenerIconoSistema(String sistemaId) {
    switch (sistemaId) {
      case 'motor':
        return Icons.speed;
      case 'hidraulico':
        return Icons.water_drop;
      case 'transmision':
        return Icons.settings;
      case 'frenos':
        return Icons.stop_circle;
      case 'refrigeracion':
        return Icons.ac_unit;
      case 'filtros':
        return Icons.filter_alt;
      case 'estructura':
        return Icons.build;
      default:
        return Icons.construction;
    }
  }

  String _obtenerUnidad(String parametroId) {
    if (parametroId.contains('temperatura')) return '°C';
    if (parametroId.contains('presion')) return 'PSI';
    if (parametroId.contains('nivel') || parametroId.contains('consumo')) return '%';
    if (parametroId.contains('fugas') || parametroId.contains('grietas')) return 'cantidad';
    return '';
  }
}

