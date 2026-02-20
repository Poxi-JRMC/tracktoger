import '../models/arbol_decisiones.dart';
import '../models/maquinaria.dart';
import '../controllers/control_mantenimiento.dart';
import '../controllers/control_alquiler.dart';

/// Servicio para diagnóstico basado en árbol de decisiones
/// Evalúa máquinas por sistemas y componentes de forma jerárquica
class DiagnosticoArbolService {
  final ControlMantenimiento _controlMantenimiento = ControlMantenimiento();
  final ControlAlquiler _controlAlquiler = ControlAlquiler();

  /// Árbol de decisiones predefinido
  /// Público para uso en diagnóstico interactivo
  NodoDecision construirArbolDecisiones() {
    return NodoDecision(
      id: 'raiz',
      nombre: 'Diagnóstico General',
      tipo: 'raiz',
      hijos: [
        // SISTEMA: MOTOR
        NodoDecision(
          id: 'sistema_motor',
          nombre: 'Sistema Motor',
          tipo: 'sistema',
          descripcion: 'Evaluación del motor y componentes relacionados',
          hijos: [
            NodoDecision(
              id: 'componente_aceite_motor',
              nombre: 'Aceite del Motor',
              tipo: 'componente',
              descripcion: 'Estado del aceite y sistema de lubricación',
              criterios: {'horasUso': {'operator': '>', 'value': 0}},
              hijos: [
                NodoDecision(
                  id: 'sintoma_aceite_bajo',
                  nombre: 'Nivel de aceite bajo',
                  tipo: 'sintoma',
                  criterios: {'horasUso': {'operator': '>', 'value': 250}},
                  solucion: 'Verificar y rellenar aceite del motor',
                  accionesRecomendadas: [
                    'Verificar nivel de aceite',
                    'Revisar posibles fugas',
                    'Cambiar aceite si es necesario',
                  ],
                  prioridad: 4,
                ),
                NodoDecision(
                  id: 'sintoma_aceite_contaminado',
                  nombre: 'Aceite contaminado',
                  tipo: 'sintoma',
                  criterios: {'horasUso': {'operator': '>', 'value': 500}},
                  solucion: 'Cambio de aceite y filtro requerido',
                  accionesRecomendadas: [
                    'Drenar aceite usado',
                    'Reemplazar filtro de aceite',
                    'Agregar aceite nuevo según especificaciones',
                  ],
                  prioridad: 5,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_refrigeracion',
              nombre: 'Sistema de Refrigeración',
              tipo: 'componente',
              descripcion: 'Radiador, mangueras y líquido refrigerante',
              hijos: [
                NodoDecision(
                  id: 'sintoma_sobrecalentamiento',
                  nombre: 'Sobrecalentamiento',
                  tipo: 'sintoma',
                  criterios: {'analisisCriticos': {'operator': '>', 'value': 0}},
                  solucion: 'Revisar sistema de refrigeración completo',
                  accionesRecomendadas: [
                    'Verificar nivel de refrigerante',
                    'Inspeccionar mangueras y conexiones',
                    'Limpiar radiador si es necesario',
                    'Revisar termostato',
                  ],
                  prioridad: 5,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_filtros',
              nombre: 'Filtros',
              tipo: 'componente',
              descripcion: 'Filtros de aire, combustible y aceite',
              hijos: [
                NodoDecision(
                  id: 'sintoma_filtros_sucios',
                  nombre: 'Filtros sucios o obstruidos',
                  tipo: 'sintoma',
                  criterios: {'horasUso': {'operator': '>', 'value': 500}},
                  solucion: 'Reemplazo de filtros necesario',
                  accionesRecomendadas: [
                    'Reemplazar filtro de aire',
                    'Reemplazar filtro de combustible',
                    'Reemplazar filtro de aceite',
                  ],
                  prioridad: 3,
                ),
              ],
            ),
          ],
        ),
        // SISTEMA: HIDRÁULICO
        NodoDecision(
          id: 'sistema_hidraulico',
          nombre: 'Sistema Hidráulico',
          tipo: 'sistema',
          descripcion: 'Bombas, cilindros, mangueras y fluidos hidráulicos',
          hijos: [
            NodoDecision(
              id: 'componente_bomba_hidraulica',
              nombre: 'Bomba Hidráulica',
              tipo: 'componente',
              descripcion: 'Bomba principal del sistema hidráulico',
              hijos: [
                NodoDecision(
                  id: 'sintoma_presion_baja',
                  nombre: 'Presión hidráulica baja',
                  tipo: 'sintoma',
                  criterios: {'analisisAdvertencia': {'operator': '>', 'value': 2}},
                  solucion: 'Revisar y reparar bomba hidráulica',
                  accionesRecomendadas: [
                    'Medir presión del sistema',
                    'Verificar filtros hidráulicos',
                    'Inspeccionar bomba por desgaste',
                    'Revisar válvulas de alivio',
                  ],
                  prioridad: 4,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_mangueras',
              nombre: 'Mangueras y Conexiones',
              tipo: 'componente',
              descripcion: 'Mangueras, conexiones y sellos hidráulicos',
              hijos: [
                NodoDecision(
                  id: 'sintoma_fugas_hidraulicas',
                  nombre: 'Fugas de fluido hidráulico',
                  tipo: 'sintoma',
                  // REQUIERE análisis de advertencia real
                  criterios: {'analisisAdvertencia': {'operator': '>', 'value': 0}},
                  solucion: 'Reparar o reemplazar mangueras con fugas',
                  accionesRecomendadas: [
                    'Inspeccionar todas las mangueras',
                    'Identificar puntos de fuga',
                    'Reemplazar mangueras dañadas',
                    'Verificar conexiones y sellos',
                  ],
                  prioridad: 4,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_fluido_hidraulico',
              nombre: 'Fluido Hidráulico',
              tipo: 'componente',
              descripcion: 'Estado y nivel del fluido hidráulico',
              hijos: [
                NodoDecision(
                  id: 'sintoma_fluido_contaminado',
                  nombre: 'Fluido hidráulico contaminado',
                  tipo: 'sintoma',
                  criterios: {'horasUso': {'operator': '>', 'value': 1000}},
                  solucion: 'Cambio de fluido hidráulico requerido',
                  accionesRecomendadas: [
                    'Drenar fluido usado',
                    'Limpiar sistema',
                    'Reemplazar filtros hidráulicos',
                    'Agregar fluido nuevo',
                  ],
                  prioridad: 3,
                ),
              ],
            ),
          ],
        ),
        // SISTEMA: TRANSMISIÓN
        NodoDecision(
          id: 'sistema_transmision',
          nombre: 'Sistema de Transmisión',
          tipo: 'sistema',
          descripcion: 'Transmisión, embrague y componentes relacionados',
          hijos: [
            NodoDecision(
              id: 'componente_transmision',
              nombre: 'Transmisión',
              tipo: 'componente',
              descripcion: 'Caja de cambios y engranajes',
              hijos: [
                NodoDecision(
                  id: 'sintoma_desgaste_transmision',
                  nombre: 'Desgaste de transmisión',
                  tipo: 'sintoma',
                  // REQUIERE análisis crítico O horas muy altas
                  criterios: {
                    'horasUso': {'operator': '>', 'value': 2500},
                    'analisisCriticos': {'operator': '>=', 'value': 0}, // Opcional
                  },
                  solucion: 'Revisión y mantenimiento de transmisión',
                  accionesRecomendadas: [
                    'Cambiar aceite de transmisión',
                    'Inspeccionar engranajes',
                    'Verificar nivel de aceite',
                    'Revisar filtros de transmisión',
                  ],
                  prioridad: 4,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_embrague',
              nombre: 'Embrague',
              tipo: 'componente',
              descripcion: 'Sistema de embrague',
              hijos: [
                NodoDecision(
                  id: 'sintoma_embrague_desgastado',
                  nombre: 'Embrague desgastado',
                  tipo: 'sintoma',
                  criterios: {'horasUso': {'operator': '>', 'value': 2000}},
                  solucion: 'Revisar y reemplazar embrague si es necesario',
                  accionesRecomendadas: [
                    'Verificar desgaste del embrague',
                    'Ajustar si es posible',
                    'Reemplazar si está muy desgastado',
                  ],
                  prioridad: 3,
                ),
              ],
            ),
          ],
        ),
        // SISTEMA: FRENOS
        NodoDecision(
          id: 'sistema_frenos',
          nombre: 'Sistema de Frenos',
          tipo: 'sistema',
          descripcion: 'Frenos, pastillas, discos y sistema hidráulico',
          hijos: [
            NodoDecision(
              id: 'componente_pastillas',
              nombre: 'Pastillas de Freno',
              tipo: 'componente',
              descripcion: 'Pastillas y discos de freno',
              hijos: [
                NodoDecision(
                  id: 'sintoma_pastillas_desgastadas',
                  nombre: 'Pastillas de freno desgastadas',
                  tipo: 'sintoma',
                  // REQUIERE análisis O horas muy altas
                  criterios: {
                    'horasUso': {'operator': '>', 'value': 1500},
                    'analisisAdvertencia': {'operator': '>=', 'value': 0}, // Opcional
                  },
                  solucion: 'Reemplazar pastillas de freno',
                  accionesRecomendadas: [
                    'Inspeccionar pastillas',
                    'Verificar discos',
                    'Reemplazar pastillas si es necesario',
                    'Revisar sistema hidráulico de frenos',
                  ],
                  prioridad: 4,
                ),
              ],
            ),
          ],
        ),
        // SISTEMA: TREN DE RODAJE
        NodoDecision(
          id: 'sistema_tren_rodaje',
          nombre: 'Tren de Rodaje',
          tipo: 'sistema',
          descripcion: 'Orugas, rodillos, ruedas y componentes de movimiento',
          hijos: [
            NodoDecision(
              id: 'componente_orugas',
              nombre: 'Orugas',
              tipo: 'componente',
              descripcion: 'Orugas y eslabones',
              hijos: [
                NodoDecision(
                  id: 'sintoma_orugas_desgastadas',
                  nombre: 'Orugas desgastadas',
                  tipo: 'sintoma',
                  criterios: {'horasUso': {'operator': '>', 'value': 2000}},
                  solucion: 'Inspeccionar y reemplazar orugas si es necesario',
                  accionesRecomendadas: [
                    'Medir desgaste de orugas',
                    'Verificar tensión',
                    'Reemplazar si el desgaste es excesivo',
                  ],
                  prioridad: 3,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_rodillos',
              nombre: 'Rodillos y Ruedas',
              tipo: 'componente',
              descripcion: 'Rodillos de apoyo y ruedas',
              hijos: [
                NodoDecision(
                  id: 'sintoma_rodillos_desgastados',
                  nombre: 'Rodillos desgastados',
                  tipo: 'sintoma',
                  // REQUIERE análisis O horas muy altas
                  criterios: {
                    'horasUso': {'operator': '>', 'value': 2500},
                    'analisisAdvertencia': {'operator': '>=', 'value': 0}, // Opcional
                  },
                  solucion: 'Revisar y reemplazar rodillos desgastados',
                  accionesRecomendadas: [
                    'Inspeccionar todos los rodillos',
                    'Verificar sellos',
                    'Reemplazar rodillos dañados',
                  ],
                  prioridad: 3,
                ),
              ],
            ),
          ],
        ),
        // SISTEMA: GENERAL
        NodoDecision(
          id: 'sistema_general',
          nombre: 'Problemas Generales',
          tipo: 'sistema',
          descripcion: 'Problemas generales y mantenimiento preventivo',
          hijos: [
            NodoDecision(
              id: 'componente_lubricacion',
              nombre: 'Lubricación General',
              tipo: 'componente',
              descripcion: 'Puntos de lubricación y engrasado',
              hijos: [
                NodoDecision(
                  id: 'sintoma_lubricacion_insuficiente',
                  nombre: 'Lubricación insuficiente',
                  tipo: 'sintoma',
                  criterios: {'diasDesdeUltimoMantenimiento': {'operator': '>', 'value': 90}},
                  solucion: 'Engrasar todos los puntos de lubricación',
                  accionesRecomendadas: [
                    'Engrasar puntos de lubricación',
                    'Verificar niveles de fluidos',
                    'Limpiar puntos de engrase',
                  ],
                  prioridad: 2,
                ),
              ],
            ),
            NodoDecision(
              id: 'componente_estructura',
              nombre: 'Estructura y Chasis',
              tipo: 'componente',
              descripcion: 'Estructura, chasis y componentes estructurales',
              hijos: [
                NodoDecision(
                  id: 'sintoma_grietas_estructura',
                  nombre: 'Grietas o daños estructurales',
                  tipo: 'sintoma',
                  criterios: {'analisisCriticos': {'operator': '>', 'value': 1}},
                  solucion: 'Inspección estructural completa requerida',
                  accionesRecomendadas: [
                    'Inspección visual completa',
                    'Revisar soldaduras',
                    'Evaluar daños estructurales',
                    'Reparar según sea necesario',
                  ],
                  prioridad: 5,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Genera diagnóstico completo para una máquina
  /// SOLO muestra problemas si hay EVIDENCIA REAL (análisis, alertas, órdenes)
  Future<DiagnosticoCompleto> diagnosticarMaquina(Maquinaria maquinaria) async {
    // Recopilar todos los datos necesarios
    final datosMaquina = await _recopilarDatosMaquina(maquinaria);
    
    // Verificar si hay evidencia real de problemas
    final tieneAnalisisCriticos = (datosMaquina['analisisCriticos'] ?? 0) > 0;
    final tieneAnalisisAdvertencia = (datosMaquina['analisisAdvertencia'] ?? 0) > 0;
    final tieneEvidenciaReal = tieneAnalisisCriticos || tieneAnalisisAdvertencia;
    final tieneAnalisisRecientes = datosMaquina['tieneAnalisisRecientes'] ?? false;
    
    // Obtener árbol de decisiones
    final arbol = construirArbolDecisiones();
    
    // Evaluar sistemas
    final diagnosticosSistemas = <DiagnosticoSistema>[];
    
    // Si hay análisis recientes pero todos son normales, retornar estado ÓPTIMO
    if (tieneAnalisisRecientes && !tieneEvidenciaReal) {
      return DiagnosticoCompleto(
        maquinariaId: maquinaria.id,
        maquinariaNombre: maquinaria.nombre,
        fechaDiagnostico: DateTime.now(),
        scoreRiesgoGeneral: 0.0,
        nivelRiesgoGeneral: 'optimo', // Estado ÓPTIMO cuando todos los parámetros son normales
        sistemas: [], // Lista vacía cuando no hay problemas
        recomendacionesGlobales: [
          '✅ Todos los parámetros están dentro de los rangos normales.',
          '✅ La máquina está en estado óptimo. Continúe con el mantenimiento preventivo regular.',
        ],
        datosEvaluados: datosMaquina,
      );
    }
    
    // Si no hay análisis recientes ni evidencia real, retornar SIN DATOS
    if (!tieneEvidenciaReal && !tieneAnalisisRecientes) {
      return DiagnosticoCompleto(
        maquinariaId: maquinaria.id,
        maquinariaNombre: maquinaria.nombre,
        fechaDiagnostico: DateTime.now(),
        scoreRiesgoGeneral: 0.0,
        nivelRiesgoGeneral: 'sin_datos',
        sistemas: [], // Lista vacía cuando no hay datos
        recomendacionesGlobales: [
          '💡 No hay datos de análisis recientes.',
          '💡 Para un diagnóstico más preciso, registre análisis de mantenimiento en la pestaña "Parámetros".',
        ],
        datosEvaluados: datosMaquina,
      );
    }
    
    // Solo evaluar sistemas si hay evidencia real
    for (var sistemaNodo in arbol.hijos) {
      if (sistemaNodo.tipo == 'sistema') {
        final diagnosticoSistema = await _evaluarSistema(sistemaNodo, datosMaquina);
        // Solo agregar si tiene componentes con problemas
        if (diagnosticoSistema != null && diagnosticoSistema.componentes.isNotEmpty) {
          diagnosticosSistemas.add(diagnosticoSistema);
        }
      }
    }
    
    // Calcular score general
    // Si no hay evidencia real (análisis, alertas), el score debe ser 0
    final scoreGeneral = tieneEvidenciaReal && diagnosticosSistemas.isNotEmpty
        ? diagnosticosSistemas.map((s) => s.scoreRiesgo).reduce((a, b) => a + b) / diagnosticosSistemas.length
        : 0.0;
    
    final nivelGeneral = tieneEvidenciaReal ? _calcularNivelRiesgo(scoreGeneral) : 'optimo';
    
    // Generar recomendaciones globales
    final recomendacionesGlobales = _generarRecomendacionesGlobales(diagnosticosSistemas, tieneEvidenciaReal);
    
    return DiagnosticoCompleto(
      maquinariaId: maquinaria.id,
      maquinariaNombre: maquinaria.nombre,
      fechaDiagnostico: DateTime.now(),
      scoreRiesgoGeneral: scoreGeneral,
      nivelRiesgoGeneral: nivelGeneral,
      sistemas: diagnosticosSistemas,
      recomendacionesGlobales: recomendacionesGlobales,
      datosEvaluados: datosMaquina,
    );
  }

  /// Evalúa un sistema específico
  Future<DiagnosticoSistema?> _evaluarSistema(
    NodoDecision sistemaNodo,
    Map<String, dynamic> datosMaquina,
  ) async {
    if (!sistemaNodo.evaluar(datosMaquina)) return null;
    
    final componentes = <DiagnosticoComponente>[];
    final problemasGenerales = <String>[];
    final recomendacionesGenerales = <String>[];
    
    // Evaluar componentes del sistema
    for (var componenteNodo in sistemaNodo.hijos) {
      if (componenteNodo.tipo == 'componente') {
        final diagnosticoComponente = await _evaluarComponente(componenteNodo, datosMaquina);
        if (diagnosticoComponente != null) {
          componentes.add(diagnosticoComponente);
        }
      }
    }
    
    // Calcular score del sistema
    final scoreSistema = componentes.isNotEmpty
        ? componentes.map((c) => c.scoreRiesgo).reduce((a, b) => a + b) / componentes.length
        : 0.0;
    
    final nivelSistema = _calcularNivelRiesgo(scoreSistema);
    
    return DiagnosticoSistema(
      sistemaId: sistemaNodo.id,
      sistemaNombre: sistemaNodo.nombre,
      descripcion: sistemaNodo.descripcion,
      scoreRiesgo: scoreSistema,
      nivelRiesgo: nivelSistema,
      componentes: componentes,
      problemasGenerales: problemasGenerales,
      recomendacionesGenerales: recomendacionesGenerales,
    );
  }

  /// Evalúa un componente específico
  /// USA VALORES REALES de parámetros registrados para calcular el score
  Future<DiagnosticoComponente?> _evaluarComponente(
    NodoDecision componenteNodo,
    Map<String, dynamic> datosMaquina,
  ) async {
    if (!componenteNodo.evaluar(datosMaquina)) return null;
    
    final sintomas = <DiagnosticoSintoma>[];
    double scoreComponente = 0.0;
    int maxPrioridad = 0;
    String? solucionFinal;
    final accionesFinales = <String>[];
    
    // Obtener valores reales de parámetros (no usado directamente, pero se accede a través de analisisRecientes)
    final tieneAnalisisRecientes = datosMaquina['tieneAnalisisRecientes'] ?? false;
    final analisisRecientes = (datosMaquina['analisisRecientes'] as List?) ?? [];
    
    // Verificar si hay evidencia real de problemas (solo de análisis recientes)
    final tieneAnalisisCriticos = (datosMaquina['analisisCriticos'] ?? 0) > 0;
    final tieneAnalisisAdvertencia = (datosMaquina['analisisAdvertencia'] ?? 0) > 0;
    final tieneEvidenciaReal = tieneAnalisisCriticos || tieneAnalisisAdvertencia;
    
    // Si hay análisis recientes pero todos son normales, NO mostrar problemas
    if (tieneAnalisisRecientes && !tieneEvidenciaReal) {
      return null; // Todos los análisis recientes son normales, no hay problemas
    }
    
    // Evaluar síntomas del componente
    for (var sintomaNodo in componenteNodo.hijos) {
      if (sintomaNodo.tipo == 'sintoma') {
        // Verificar si el síntoma requiere evidencia real
        final requiereEvidenciaReal = sintomaNodo.criterios.containsKey('analisisCriticos') || 
                                     sintomaNodo.criterios.containsKey('analisisAdvertencia');
        
        // Si requiere evidencia real y no la hay, saltar este síntoma
        if (requiereEvidenciaReal && !tieneEvidenciaReal) {
          continue;
        }
        
        final presente = sintomaNodo.evaluar(datosMaquina);
        
        if (presente) {
          // Calcular probabilidad basada en valores reales de parámetros
          double probabilidad = 0.0;
          
          // Mapeo de parámetros a sistemas/componentes (según IDs usados en registro_parametros_maquina_screen.dart)
          final parametroMap = {
            // Sistema Motor
            'temperatura': 'componente_refrigeracion', // Temperatura del Motor
            'presion_aceite': 'componente_aceite_motor', // Presión de Aceite
            'nivel_aceite': 'componente_aceite_motor', // Nivel de Aceite
            'consumo_combustible': 'componente_aceite_motor', // Consumo de Combustible
            // Sistema Hidráulico
            'presion_hidraulica': 'componente_bomba_hidraulica', // Presión Hidráulica
            'nivel_fluido': 'componente_bomba_hidraulica', // Nivel de Fluido Hidráulico
            'temperatura_fluido': 'componente_bomba_hidraulica', // Temperatura del Fluido
            'fugas': 'componente_mangueras', // Fugas Detectadas
            // Sistema Transmisión
            'temperatura_transmision': 'componente_transmision', // Temperatura de Transmisión
            'nivel_aceite_transmision': 'componente_transmision', // Nivel de Aceite de Transmisión
            'ruidos': 'componente_transmision', // Ruidos Anormales
            // Sistema Frenos
            'presion_frenos': 'componente_pastillas', // Presión de Frenos
            'desgaste_pastillas': 'componente_pastillas', // Desgaste de Pastillas
            'temperatura_discos': 'componente_pastillas', // Temperatura de Discos
            // Sistema Refrigeración
            'temperatura_refrigerante': 'componente_refrigeracion', // Temperatura del Refrigerante
            'nivel_refrigerante': 'componente_refrigeracion', // Nivel de Refrigerante
            'presion_sistema': 'componente_refrigeracion', // Presión del Sistema
            // Filtros
            'filtro_aire': 'componente_filtros', // Estado Filtro de Aire
            'filtro_combustible': 'componente_filtros', // Estado Filtro de Combustible
            'filtro_aceite': 'componente_filtros', // Estado Filtro de Aceite
            // Estructura
            'grietas': 'componente_estructura', // Grietas Detectadas
            'corrosion': 'componente_estructura', // Corrosión
            'soldaduras': 'componente_estructura', // Estado de Soldaduras
          };
          
          // Buscar si hay valores de parámetros relacionados con este componente
          bool tieneValorParametro = false;
          double? valorParametro;
          double? valorLimite;
          
          for (var analisis in analisisRecientes) {
            if (analisis.datosAnalisis.isNotEmpty) {
              final datos = analisis.datosAnalisis;
              final parametro = datos['parametro']?.toString() ?? '';
              final sistema = datos['sistema']?.toString() ?? '';
              
              // Verificar si este parámetro pertenece a este componente
              final componenteRelacionado = parametroMap[parametro];
              if (componenteRelacionado == componenteNodo.id || 
                  (sistema == 'sistema_frenos' && componenteNodo.id == 'componente_pastillas')) {
                valorParametro = datos['valorMedido'] is num ? (datos['valorMedido'] as num).toDouble() : null;
                valorLimite = datos['valorLimite'] is num ? (datos['valorLimite'] as num).toDouble() : null;
                if (valorParametro != null) {
                  tieneValorParametro = true;
                  break; // Usar el más reciente
                }
              }
            }
          }
          
          // Calcular probabilidad basada en valores reales
          if (tieneValorParametro && valorParametro != null && valorLimite != null) {
            // Calcular desviación del valor límite
            final desviacion = (valorParametro / valorLimite).abs();
            
            if (desviacion > 1.2) {
              // Crítico: más del 20% sobre el límite
              probabilidad = 85.0 + (sintomaNodo.prioridad ?? 3) * 5.0;
            } else if (desviacion > 1.0) {
              // Advertencia: sobre el límite pero menos del 20%
              probabilidad = 60.0 + (sintomaNodo.prioridad ?? 3) * 5.0;
            } else if (desviacion > 0.8) {
              // Normal pero cerca del límite
              probabilidad = 30.0 + (sintomaNodo.prioridad ?? 2) * 3.0;
            } else {
              // Normal, no mostrar este síntoma
              continue;
            }
          } else if (tieneEvidenciaReal) {
            // Si hay evidencia real pero no valores específicos, usar conteo de análisis
            if (tieneAnalisisCriticos) {
              probabilidad = 85.0 + (sintomaNodo.prioridad ?? 3) * 5.0;
            } else if (tieneAnalisisAdvertencia) {
              probabilidad = 60.0 + (sintomaNodo.prioridad ?? 3) * 5.0;
            }
          } else {
            // Sin evidencia real, SOLO mostrar mantenimiento preventivo basado en horas
            final tieneHorasAltas = (datosMaquina['horasUso'] ?? 0) > 1000;
            final esMantenimientoPreventivo = sintomaNodo.criterios.containsKey('horasUso') ||
                                             sintomaNodo.criterios.containsKey('diasDesdeUltimoMantenimiento');
            
            if (esMantenimientoPreventivo && tieneHorasAltas) {
              probabilidad = 35.0 + (sintomaNodo.prioridad ?? 2) * 3.0;
            } else {
              continue;
            }
          }
          
          final diagnosticoSintoma = DiagnosticoSintoma(
            sintomaId: sintomaNodo.id,
            sintomaNombre: sintomaNodo.nombre,
            descripcion: sintomaNodo.descripcion,
            presente: true,
            probabilidad: probabilidad.clamp(0.0, 100.0),
            datosRelacionados: sintomaNodo.criterios,
          );
          
          sintomas.add(diagnosticoSintoma);
          
          // Actualizar score y prioridad
          scoreComponente += probabilidad;
          if ((sintomaNodo.prioridad ?? 0) > maxPrioridad) {
            maxPrioridad = sintomaNodo.prioridad ?? 0;
            solucionFinal = sintomaNodo.solucion;
            accionesFinales.clear();
            accionesFinales.addAll(sintomaNodo.accionesRecomendadas ?? []);
          }
        }
      }
    }
    
    // Si no hay síntomas, el componente está bien
    if (sintomas.isEmpty) {
      return null; // No mostrar componentes sin problemas
    }
    
    scoreComponente = sintomas.isNotEmpty ? scoreComponente / sintomas.length : 0.0;
    final nivelComponente = _calcularNivelRiesgo(scoreComponente);
    
    return DiagnosticoComponente(
      componenteId: componenteNodo.id,
      componenteNombre: componenteNodo.nombre,
      descripcion: componenteNodo.descripcion,
      scoreRiesgo: scoreComponente,
      nivelRiesgo: nivelComponente,
      sintomas: sintomas,
      solucion: solucionFinal,
      accionesRecomendadas: accionesFinales,
      prioridad: maxPrioridad,
    );
  }

  /// Recopila todos los datos necesarios para el diagnóstico
  Future<Map<String, dynamic>> _recopilarDatosMaquina(Maquinaria maquinaria) async {
    // Datos básicos de la máquina
    final horasUso = maquinaria.horasUso;
    final estado = maquinaria.estado;
    final diasDesdeUltimoMantenimiento = DateTime.now()
        .difference(maquinaria.fechaUltimoMantenimiento).inDays;
    
    // Análisis históricos - PRIORIZAR últimos 7 días
    final todosAnalisis = await _controlMantenimiento.consultarAnalisisPorMaquinaria(maquinaria.id);
    final ahora = DateTime.now();
    
    // Separar análisis recientes (últimos 7 días) de antiguos
    final analisisRecientes = todosAnalisis.where((a) => 
      ahora.difference(a.fechaAnalisis).inDays <= 7
    ).toList();
    
    // SIEMPRE usar solo análisis recientes (últimos 7 días) para evaluar
    // Si no hay análisis recientes, no hay evidencia real
    final analisisParaEvaluar = analisisRecientes;
    
    // Contar análisis críticos y advertencia SOLO de los análisis recientes (últimos 7 días)
    final analisisCriticos = analisisParaEvaluar.where((a) => a.resultado == 'critico').length;
    final analisisAdvertencia = analisisParaEvaluar.where((a) => a.resultado == 'advertencia').length;
    
    // Extraer valores reales de parámetros del análisis más reciente (priorizar últimos 7 días)
    final analisisMasReciente = analisisParaEvaluar.isNotEmpty 
        ? analisisParaEvaluar.reduce((a, b) => a.fechaAnalisis.isAfter(b.fechaAnalisis) ? a : b)
        : null;
    
    // Extraer todos los valores de parámetros de los análisis recientes
    final valoresParametros = <String, double>{};
    if (analisisMasReciente != null && analisisMasReciente.datosAnalisis.isNotEmpty) {
      // Extraer valores del análisis más reciente
      final datos = analisisMasReciente.datosAnalisis;
      if (datos.containsKey('valorMedido')) {
        final valorMedido = datos['valorMedido'];
        if (valorMedido is num) {
          final parametro = datos['parametro']?.toString() ?? '';
          valoresParametros[parametro] = valorMedido.toDouble();
        }
      }
    }
    
    // También buscar valores específicos por sistema/parámetro en todos los análisis recientes
    for (var analisis in analisisParaEvaluar) {
      if (analisis.datosAnalisis.isNotEmpty) {
        final datos = analisis.datosAnalisis;
        final parametro = datos['parametro']?.toString() ?? '';
        final valorMedido = datos['valorMedido'];
        
        if (valorMedido is num && parametro.isNotEmpty) {
          // Usar el valor más reciente para cada parámetro
          final key = parametro;
          if (!valoresParametros.containsKey(key) || 
              analisis.fechaAnalisis.isAfter(analisisMasReciente?.fechaAnalisis ?? DateTime(1970))) {
            valoresParametros[key] = valorMedido.toDouble();
          }
        }
      }
    }
    
    // Órdenes de trabajo
    final ordenes = await _controlMantenimiento.consultarOrdenesPorMaquinaria(maquinaria.id);
    final ordenesCompletadas = ordenes.where((o) => o.estado == 'completada').length;
    
    // Alquileres históricos
    final alquileres = await _controlAlquiler.consultarTodosAlquileres(
      soloActivos: false,
      maquinariaId: maquinaria.id,
    );
    final totalHorasHistoricas = alquileres
        .where((a) => a.horasUsoReal != null)
        .fold<int>(0, (sum, a) => sum + (a.horasUsoReal ?? 0));
    
    final horasTotales = horasUso + totalHorasHistoricas;
    
    return {
      'horasUso': horasUso,
      'horasTotales': horasTotales,
      'estado': estado,
      'diasDesdeUltimoMantenimiento': diasDesdeUltimoMantenimiento,
      'analisisCriticos': analisisCriticos,
      'analisisAdvertencia': analisisAdvertencia,
      'ordenesCompletadas': ordenesCompletadas,
      'totalHorasHistoricas': totalHorasHistoricas,
      'valoresParametros': valoresParametros, // Valores reales de parámetros
      'tieneAnalisisRecientes': analisisRecientes.isNotEmpty, // Flag para saber si hay datos recientes
      'analisisRecientes': analisisRecientes, // Lista de análisis recientes
    };
  }

  /// Calcula el nivel de riesgo basado en el score
  String _calcularNivelRiesgo(double score) {
    if (score >= 80) return 'critico';
    if (score >= 60) return 'alto';
    if (score >= 40) return 'medio';
    if (score >= 20) return 'bajo';
    return 'optimo';
  }

  /// Genera recomendaciones globales basadas en todos los sistemas
  List<String> _generarRecomendacionesGlobales(List<DiagnosticoSistema> sistemas, bool tieneEvidenciaReal) {
    final recomendaciones = <String>[];
    
    if (!tieneEvidenciaReal && sistemas.isEmpty) {
      recomendaciones.add('✅ No se detectaron problemas. La máquina está en buen estado.');
      recomendaciones.add('💡 Para un diagnóstico más preciso, registre análisis de mantenimiento en la pestaña "Análisis".');
      return recomendaciones;
    }
    
    final sistemasCriticos = sistemas.where((s) => s.nivelRiesgo == 'critico').length;
    final sistemasAltos = sistemas.where((s) => s.nivelRiesgo == 'alto').length;
    
    if (sistemasCriticos > 0) {
      recomendaciones.add('⚠️ Se detectaron $sistemasCriticos sistema(s) con riesgo crítico. Se recomienda revisión inmediata.');
    }
    
    if (sistemasAltos > 0) {
      recomendaciones.add('🔧 Se detectaron $sistemasAltos sistema(s) con riesgo alto. Planificar mantenimiento preventivo.');
    }
    
    final sistemasConProblemas = sistemas.where((s) => s.componentes.isNotEmpty).length;
    if (sistemasConProblemas > 0) {
      recomendaciones.add('📋 Se identificaron problemas en $sistemasConProblemas sistema(s). Revisar diagnósticos detallados.');
    }
    
    if (tieneEvidenciaReal) {
      recomendaciones.add('📊 Diagnóstico basado en análisis y datos reales registrados.');
    } else {
      recomendaciones.add('⏰ Diagnóstico preventivo basado en horas de uso. Registre análisis para mayor precisión.');
    }
    
    if (recomendaciones.isEmpty) {
      recomendaciones.add('✅ Todos los sistemas están en buen estado. Continuar con mantenimiento preventivo regular.');
    }
    
    return recomendaciones;
  }
}

