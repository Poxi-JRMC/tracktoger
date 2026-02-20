import 'package:flutter/material.dart';
import '../../../models/gasto_operativo.dart';
import '../../../models/maquinaria.dart';
import '../../../models/usuario.dart';
import '../../../controllers/control_gasto_operativo.dart';
import '../../../controllers/control_usuario.dart';

/// Pantalla para ver el historial completo de gastos operativos de una maquinaria
class HistorialGastosScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const HistorialGastosScreen({super.key, required this.maquinaria});

  @override
  State<HistorialGastosScreen> createState() => _HistorialGastosScreenState();
}

class _HistorialGastosScreenState extends State<HistorialGastosScreen> {
  final ControlGastoOperativo _controlGasto = ControlGastoOperativo();
  final ControlUsuario _controlUsuario = ControlUsuario();
  
  List<GastoOperativo> _gastos = [];
  Map<String, Usuario> _operadores = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    try {
      final gastos = await _controlGasto.consultarGastosPorMaquinaria(
        widget.maquinaria.id,
      );

      // Cargar información de operadores
      final operadoresMap = <String, Usuario>{};
      for (var gasto in gastos) {
        if (!operadoresMap.containsKey(gasto.operadorId)) {
          final operador = await _controlUsuario.consultarUsuario(gasto.operadorId);
          if (operador != null) {
            operadoresMap[gasto.operadorId] = operador;
          }
        }
      }

      setState(() {
        _gastos = gastos;
        _operadores = operadoresMap;
      });
    } catch (e) {
      _mostrarError('Error al cargar gastos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _formatearFechaHora(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Color _obtenerColorTipoGasto(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pasajes':
        return Colors.blue;
      case 'comida':
        return Colors.green;
      case 'transporte':
        return Colors.orange;
      case 'combustible':
        return Colors.red;
      case 'peaje':
        return Colors.purple;
      case 'hospedaje':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalGastos = _gastos.fold<double>(0.0, (sum, g) => sum + g.monto);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Gastos'),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Total Gastos',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${totalGastos.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                      Column(
                        children: [
                          Text(
                            'Registros',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_gastos.length}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Lista de gastos
                Expanded(
                  child: _gastos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay gastos registrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _gastos.length,
                          itemBuilder: (context, index) {
                            final gasto = _gastos[index];
                            final operador = _operadores[gasto.operadorId];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _obtenerColorTipoGasto(gasto.tipoGasto).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.receipt,
                                                color: _obtenerColorTipoGasto(gasto.tipoGasto),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  gasto.tipoGasto.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                                  ),
                                                ),
                                                if (operador != null)
                                                  Text(
                                                    '${operador.nombre} ${operador.apellido}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '\$${gasto.monto.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (gasto.descripcion != null && gasto.descripcion!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        gasto.descripcion!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatearFecha(gasto.fecha),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Registrado: ${_formatearFechaHora(gasto.fechaRegistro)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

