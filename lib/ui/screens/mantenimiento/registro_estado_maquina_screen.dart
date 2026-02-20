import 'package:flutter/material.dart';
import '../../../models/maquinaria.dart';
import '../../../controllers/control_mantenimiento.dart';
import '../../../models/analisis.dart';

/// Pantalla para registrar el estado inicial de una máquina
/// Permite registrar análisis y observaciones antes de hacer predicciones
class RegistroEstadoMaquinaScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const RegistroEstadoMaquinaScreen({
    super.key,
    required this.maquinaria,
  });

  @override
  State<RegistroEstadoMaquinaScreen> createState() => _RegistroEstadoMaquinaScreenState();
}

class _RegistroEstadoMaquinaScreenState extends State<RegistroEstadoMaquinaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  
  String _tipoAnalisis = 'temperatura';
  double _valorMedido = 0.0;
  double _valorLimite = 0.0;
  String _resultado = 'normal';
  String _observaciones = '';
  String _recomendaciones = '';
  
  final List<Map<String, dynamic>> _tiposAnalisis = [
    {'id': 'temperatura', 'nombre': 'Temperatura del Motor'},
    {'id': 'presion', 'nombre': 'Presión Hidráulica'},
    {'id': 'vibracion', 'nombre': 'Vibración'},
    {'id': 'aceite', 'nombre': 'Análisis de Aceite'},
    {'id': 'refrigerante', 'nombre': 'Nivel de Refrigerante'},
    {'id': 'filtros', 'nombre': 'Estado de Filtros'},
    {'id': 'estructura', 'nombre': 'Inspección Estructural'},
    {'id': 'frenos', 'nombre': 'Sistema de Frenos'},
    {'id': 'transmision', 'nombre': 'Transmisión'},
    {'id': 'hidraulico', 'nombre': 'Sistema Hidráulico'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Estado: ${widget.maquinaria.nombre}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              
              // Tipo de análisis
              Text(
                'Tipo de Análisis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoAnalisis,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                items: _tiposAnalisis.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo['id'] as String,
                    child: Text(tipo['nombre'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _tipoAnalisis = value!);
                },
              ),
              const SizedBox(height: 20),
              
              // Valor medido
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Valor Medido',
                  hintText: 'Ej: 85.5 (temperatura en °C, presión en PSI, etc.)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _valorMedido = double.tryParse(value) ?? 0.0;
                },
              ),
              const SizedBox(height: 16),
              
              // Valor límite
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Valor Límite (Máximo Permitido)',
                  hintText: 'Ej: 90.0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _valorLimite = double.tryParse(value) ?? 0.0;
                },
              ),
              const SizedBox(height: 20),
              
              // Resultado
              Text(
                'Resultado del Análisis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _resultado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'normal',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Normal'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'advertencia',
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Advertencia'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'critico',
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Crítico'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _resultado = value!);
                },
              ),
              const SizedBox(height: 20),
              
              // Observaciones
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  hintText: 'Describe lo que observaste en la inspección...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 4,
                onChanged: (value) => _observaciones = value,
              ),
              const SizedBox(height: 16),
              
              // Recomendaciones
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Recomendaciones',
                  hintText: 'Qué acciones recomiendas...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
                onChanged: (value) => _recomendaciones = value,
              ),
              const SizedBox(height: 32),
              
              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarAnalisis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar Análisis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarAnalisis() async {
    if (_formKey.currentState!.validate()) {
      try {
        final fechaRegistro = DateTime.now();
        final analisis = Analisis(
          id: 'analisis_${fechaRegistro.millisecondsSinceEpoch}',
          maquinariaId: widget.maquinaria.id,
          tipoAnalisis: _tipoAnalisis,
          fechaAnalisis: fechaRegistro,
          fechaRegistro: fechaRegistro,
          datosAnalisis: {
            'valorMedido': _valorMedido,
            'valorLimite': _valorLimite,
            'tipoAnalisis': _tipoAnalisis,
          },
          resultado: _resultado,
          valorMedido: _valorMedido,
          valorLimite: _valorLimite,
          observaciones: _observaciones.isEmpty ? null : _observaciones,
          recomendaciones: _recomendaciones.isEmpty ? null : _recomendaciones,
        );

        await _controlMantenimiento.registrarAnalisis(analisis);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Análisis registrado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retorna true para indicar que se guardó
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al guardar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

