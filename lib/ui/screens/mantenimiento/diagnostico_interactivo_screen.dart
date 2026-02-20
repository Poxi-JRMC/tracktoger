import 'package:flutter/material.dart';
import '../../../models/maquinaria.dart';
import '../../../services/diagnostico_arbol_service.dart';
import '../../../models/arbol_decisiones.dart';

/// Pantalla de diagnóstico interactivo
/// Pregunta al usuario sobre síntomas y lo guía hasta la solución
class DiagnosticoInteractivoScreen extends StatefulWidget {
  final Maquinaria maquinaria;

  const DiagnosticoInteractivoScreen({
    super.key,
    required this.maquinaria,
  });

  @override
  State<DiagnosticoInteractivoScreen> createState() => _DiagnosticoInteractivoScreenState();
}

class _DiagnosticoInteractivoScreenState extends State<DiagnosticoInteractivoScreen> {
  // Acceso temporal al método privado - en producción debería ser público
  DiagnosticoArbolService get _diagnosticoService => DiagnosticoArbolService();
  
  // Estado del diagnóstico interactivo
  NodoDecision? _nodoActual;
  List<String> _sintomasSeleccionados = [];
  List<Map<String, dynamic>> _historialPreguntas = [];
  String? _solucionFinal;
  List<String> _accionesRecomendadas = [];
  
  @override
  void initState() {
    super.initState();
    _iniciarDiagnostico();
  }

  void _iniciarDiagnostico() {
    // Empezar desde la raíz del árbol
    final arbol = _diagnosticoService.construirArbolDecisiones();
    _nodoActual = arbol;
    _cargarSiguientePregunta();
  }

  void _cargarSiguientePregunta() {
    if (_nodoActual == null) return;
    
    // Si estamos en la raíz, mostrar sistemas
    if (_nodoActual!.tipo == 'raiz') {
      // Mostrar lista de sistemas para seleccionar
      return;
    }
    
    // Si estamos en un sistema, mostrar componentes
    if (_nodoActual!.tipo == 'sistema') {
      // Mostrar componentes del sistema
      return;
    }
    
    // Si estamos en un componente, mostrar síntomas
    if (_nodoActual!.tipo == 'componente') {
      // Mostrar síntomas del componente
      return;
    }
    
    // Si llegamos a un síntoma, mostrar solución
    if (_nodoActual!.tipo == 'sintoma') {
      _solucionFinal = _nodoActual!.solucion;
      _accionesRecomendadas = _nodoActual!.accionesRecomendadas ?? [];
      _nodoActual = null; // Finalizar
    }
  }

  void _seleccionarSistema(String sistemaId) {
    final arbol = _diagnosticoService.construirArbolDecisiones();
    final sistema = _buscarNodo(arbol, sistemaId);
    
    if (sistema != null) {
      setState(() {
        _nodoActual = sistema;
        _historialPreguntas.add({
          'pregunta': '¿Qué sistema tiene problemas?',
          'respuesta': sistema.nombre,
        });
      });
    }
  }

  void _seleccionarComponente(String componenteId) {
    if (_nodoActual == null) return;
    
    final componente = _buscarNodo(_nodoActual!, componenteId);
    
    if (componente != null) {
      setState(() {
        _nodoActual = componente;
        _historialPreguntas.add({
          'pregunta': '¿Qué componente específico?',
          'respuesta': componente.nombre,
        });
      });
    }
  }

  void _seleccionarSintoma(String sintomaId, bool presente) {
    if (_nodoActual == null) return;
    
    final sintoma = _buscarNodo(_nodoActual!, sintomaId);
    
    if (sintoma != null && presente) {
      setState(() {
        _sintomasSeleccionados.add(sintoma.nombre);
        _solucionFinal = sintoma.solucion;
        _accionesRecomendadas = sintoma.accionesRecomendadas ?? [];
        _historialPreguntas.add({
          'pregunta': '¿Presenta este síntoma?',
          'respuesta': sintoma.nombre,
        });
        _nodoActual = null; // Finalizar diagnóstico
      });
    } else if (sintoma != null && !presente) {
      // Si el síntoma no está presente, continuar con otros síntomas
      setState(() {
        _historialPreguntas.add({
          'pregunta': '¿Presenta este síntoma?',
          'respuesta': 'No',
        });
      });
    }
  }

  NodoDecision? _buscarNodo(NodoDecision nodo, String id) {
    if (nodo.id == id) return nodo;
    
    for (var hijo in nodo.hijos) {
      final encontrado = _buscarNodo(hijo, id);
      if (encontrado != null) return encontrado;
    }
    
    return null;
  }

  void _reiniciarDiagnostico() {
    setState(() {
      _nodoActual = null;
      _sintomasSeleccionados = [];
      _historialPreguntas = [];
      _solucionFinal = null;
      _accionesRecomendadas = [];
    });
    _iniciarDiagnostico();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnóstico: ${widget.maquinaria.nombre}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reiniciarDiagnostico,
            tooltip: 'Reiniciar diagnóstico',
          ),
        ],
      ),
      body: _solucionFinal != null
          ? _buildSolucion(isDark)
          : _buildPreguntas(isDark),
    );
  }

  Widget _buildPreguntas(bool isDark) {
    if (_nodoActual == null) {
      // Mostrar sistemas disponibles
      final arbol = _diagnosticoService.construirArbolDecisiones();
      final sistemas = arbol.hijos.where((n) => n.tipo == 'sistema').toList();
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.blue.shade600, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        '¿Qué sistema tiene problemas?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...sistemas.map((sistema) => _buildBotonOpcion(
                    sistema.nombre,
                    sistema.descripcion ?? '',
                    () => _seleccionarSistema(sistema.id),
                    isDark,
                  )),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Mostrar opciones según el tipo de nodo actual
    if (_nodoActual!.tipo == 'sistema') {
      final componentes = _nodoActual!.hijos.where((n) => n.tipo == 'componente').toList();
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistorial(isDark),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, color: Colors.orange.shade600, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¿Qué componente específico?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...componentes.map((componente) => _buildBotonOpcion(
                    componente.nombre,
                    componente.descripcion ?? '',
                    () => _seleccionarComponente(componente.id),
                    isDark,
                  )),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    if (_nodoActual!.tipo == 'componente') {
      final sintomas = _nodoActual!.hijos.where((n) => n.tipo == 'sintoma').toList();
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistorial(isDark),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade600, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¿Qué síntomas presenta?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...sintomas.map((sintoma) => _buildBotonSintoma(
                    sintoma.nombre,
                    sintoma.descripcion ?? '',
                    sintoma.id,
                    isDark,
                  )),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return const Center(child: Text('Error: Estado no reconocido'));
  }

  Widget _buildBotonOpcion(String titulo, String descripcion, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward_ios, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      if (descripcion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          descripcion,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonSintoma(String titulo, String descripcion, String sintomaId, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildBotonOpcion(titulo, descripcion, () {}, isDark),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _seleccionarSintoma(sintomaId, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Sí'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _seleccionarSintoma(sintomaId, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial(bool isDark) {
    if (_historialPreguntas.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Respuestas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ..._historialPreguntas.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['pregunta'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          item['respuesta'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ],
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

  Widget _buildSolucion(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de solución
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'SOLUCIÓN ENCONTRADA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _solucionFinal ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Síntomas detectados
          if (_sintomasSeleccionados.isNotEmpty) ...[
            Text(
              'Síntomas Detectados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ..._sintomasSeleccionados.map((sintoma) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text(sintoma),
              ),
            )),
            const SizedBox(height: 20),
          ],
          
          // Acciones recomendadas
          if (_accionesRecomendadas.isNotEmpty) ...[
            Text(
              'Acciones Recomendadas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ..._accionesRecomendadas.asMap().entries.map((entry) {
              final index = entry.key;
              final accion = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade600,
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(accion),
                ),
              );
            }),
          ],
          
          const SizedBox(height: 32),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _reiniciarDiagnostico,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nuevo Diagnóstico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

