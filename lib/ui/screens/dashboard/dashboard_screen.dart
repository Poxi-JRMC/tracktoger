import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tracktoger/controllers/control_maquinaria.dart';
import 'package:tracktoger/controllers/control_alquiler.dart';
import 'package:tracktoger/controllers/control_cliente.dart';
import 'package:tracktoger/controllers/control_mantenimiento.dart';
import 'package:tracktoger/controllers/control_pdf_generator.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/models/categoria.dart';
import 'package:tracktoger/models/usuario.dart';
import 'package:tracktoger/models/maquinaria.dart';
import 'package:tracktoger/models/alquiler.dart';
import 'package:tracktoger/models/registro_mantenimiento.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> kpiCards = [];
  Map<String, dynamic> usuariosStats = {};
  bool isLoading = true;
  final ControlUsuario _controlUsuario = ControlUsuario();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Caché para optimizar rendimiento
  Map<String, dynamic>? _cachedStats;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadDashboardData();
  }

  /// Inicializa las notificaciones locales
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Solicitar permisos en Android 13+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    // Usar caché si está disponible y no está expirado
    if (!forceRefresh && 
        _cachedStats != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      setState(() {
        usuariosStats = _cachedStats!['usuariosStats'] ?? {};
        kpiCards = List<Map<String, dynamic>>.from(_cachedStats!['kpiCards'] ?? []);
        isLoading = false;
      });
      return;
    }

    try {
      // Carga secuencial para no saturar Atlas M0 (evita "connection reset" al cambiar tabs)
      final maquinariaStats = await ControlMaquinaria().obtenerEstadisticasMaquinaria();
      final alquileresStats = await ControlAlquiler().obtenerEstadisticasAlquileres();
      final mantenimientoStats = await ControlMantenimiento().obtenerEstadisticasMantenimiento();
      final usuariosStatsData = await _controlUsuario.obtenerEstadisticasUsuarios();

      setState(() {
        usuariosStats = usuariosStatsData;
        kpiCards = [
          {
            "title": "Usuarios Activos",
            "value": "${usuariosStatsData['activos'] ?? 0}",
            "subtitle": "de ${usuariosStatsData['total'] ?? 0} total",
            "change": "+${usuariosStatsData['nuevosUsuarios'] ?? 0} nuevos",
            "trendUp": true,
            "color": const Color(0xFF4FC3F7),
            "icon": Icons.people_rounded,
          },
          {
            "title": "Disponibilidad Total",
            "value": "${maquinariaStats['porcentajeDisponibilidad'] ?? 0}%",
            "subtitle": "${maquinariaStats['disponibles'] ?? 0} disponibles",
            "change": "+2.1%",
            "trendUp": true,
            "color": const Color(0xFFFFD74D),
            "icon": Icons.precision_manufacturing_rounded,
          },
          {
            "title": "Rentabilidad",
            "value":
                "Bs ${ (alquileresStats['totalMonto'] ?? 0).toStringAsFixed(0)}",
            "subtitle": "Ingresos totales (Bs)",
            "change": "+${alquileresStats['entregados'] ?? 0} activos",
            "trendUp": true,
            "color": const Color(0xFF43A047),
            "icon": Icons.attach_money_rounded,
          },
          {
            "title": "Alertas Activas",
            "value": "${mantenimientoStats['alertasActivas'] ?? 0}",
            "subtitle": "Mantenimiento",
            "change": "-8%",
            "trendUp": false,
            "color": const Color(0xFFD32F2F),
            "icon": Icons.warning_amber_rounded,
          },
        ];
        isLoading = false;
        
        // Actualizar caché
        _cachedStats = {
          'usuariosStats': usuariosStatsData,
          'kpiCards': kpiCards,
        };
        _lastCacheUpdate = DateTime.now();
      });
    } catch (e) {
      print('Error cargando datos del dashboard: $e');
      setState(() => isLoading = false);
    }
  }

  /// Muestra un diálogo para seleccionar el período del reporte
  Future<String?> _mostrarSelectorPeriodo() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          'Seleccionar Período',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPeriodoOption('semanal', 'Semanal', 'Últimos 7 días'),
            const SizedBox(height: 8),
            _buildPeriodoOption('mensual', 'Mensual', 'Último mes'),
            const SizedBox(height: 8),
            _buildPeriodoOption('anual', 'Anual', 'Último año'),
            const SizedBox(height: 8),
            _buildPeriodoOption('todo', 'Todo', 'Histórico completo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoOption(String valor, String titulo, String descripcion) {
    return InkWell(
      onTap: () => Navigator.pop(context, valor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCD11).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _getPeriodoIcon(valor),
              color: const Color(0xFFFFCD11),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade600,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPeriodoIcon(String periodo) {
    switch (periodo) {
      case 'semanal':
        return Icons.calendar_view_week;
      case 'mensual':
        return Icons.calendar_month;
      case 'anual':
        return Icons.calendar_today;
      case 'todo':
        return Icons.history;
      default:
        return Icons.calendar_today;
    }
  }

  /// Calcula las fechas de inicio y fin según el período seleccionado
  Map<String, DateTime?> _calcularFechasPeriodo(String periodo) {
    final ahora = DateTime.now();
    DateTime? fechaInicio;
    DateTime? fechaFin = ahora;

    switch (periodo) {
      case 'semanal':
        fechaInicio = ahora.subtract(const Duration(days: 7));
        break;
      case 'mensual':
        fechaInicio = DateTime(ahora.year, ahora.month - 1, ahora.day);
        break;
      case 'anual':
        fechaInicio = DateTime(ahora.year - 1, ahora.month, ahora.day);
        break;
      case 'todo':
        fechaInicio = null; // Sin límite
        fechaFin = null; // Sin límite
        break;
    }

    return {
      'inicio': fechaInicio,
      'fin': fechaFin,
    };
  }

  Future<void> _exportReport(String tipo) async {
    try {
      // Mostrar selector de período
      final periodoSeleccionado = await _mostrarSelectorPeriodo();
      if (periodoSeleccionado == null) {
        return; // Usuario canceló
      }

      // Calcular fechas según el período
      final fechas = _calcularFechasPeriodo(periodoSeleccionado);
      final fechaInicio = fechas['inicio'];
      final fechaFin = fechas['fin'];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generando reporte ${periodoSeleccionado}...'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      final generator = ControlPDFGenerator();
      Map<String, dynamic> data = {};

      // Obtener datos reales según el tipo
      switch (tipo.toLowerCase()) {
        case 'usuarios':
          final usuarios = await _controlUsuario.consultarTodosUsuarios();
          final roles = await _controlUsuario.consultarTodosRoles();
          
          // Filtrar usuarios por período (fecha de registro)
          List<Usuario> usuariosFiltrados;
          if (fechaInicio != null) {
            final inicio = fechaInicio;
            final fin = fechaFin;
            usuariosFiltrados = usuarios.where((u) {
              if (fin != null) {
                return u.fechaRegistro.isAfter(inicio) && 
                       u.fechaRegistro.isBefore(fin);
              }
              return u.fechaRegistro.isAfter(inicio);
            }).toList();
          } else {
            usuariosFiltrados = usuarios;
          }
          
          data = {
            'empresa': 'Tracktoger',
            'fecha': DateTime.now(),
            'filtro': _obtenerTextoFiltro(periodoSeleccionado, 'usuarios'),
            'resumen': {
              'total': usuariosFiltrados.length,
              'activos': usuariosFiltrados.where((u) => u.activo).length,
              'inactivos': usuariosFiltrados.where((u) => !u.activo).length,
            },
            'items': usuariosFiltrados.map((u) {
              // Obtener nombre del rol (buscar el rol Operador si no se encuentra)
              String nombreRol = 'Operador'; // Por defecto Operador
              if (u.roles.isNotEmpty) {
                try {
                  final rol = roles.firstWhere((r) => r.id == u.roles.first);
                  nombreRol = rol.nombre.isNotEmpty ? rol.nombre : 'Operador';
                } catch (_) {
                  // Si no se encuentra el rol, buscar uno que contenga "operador"
                  try {
                    final rolOperador = roles.firstWhere(
                      (r) => r.nombre.toLowerCase().contains('operador'),
                    );
                    nombreRol = rolOperador.nombre;
                  } catch (_) {
                    nombreRol = 'Operador';
                  }
                }
              }
              
              return {
                'nombre': '${u.nombre} ${u.apellido}'.trim(),
                'rol': nombreRol,
                'correo': u.email,
                'telefono': u.telefono,
                'estado': u.activo ? 'Activo' : 'Inactivo',
                'fechaRegistro': u.fechaRegistro.toString().split(' ')[0],
              };
            }).toList(),
          };
          break;
        case 'inventario':
          final todasMaquinarias = await ControlMaquinaria().consultarTodasMaquinarias();
          final categorias = await ControlMaquinaria().consultarTodasCategorias();
          
          // Filtrar maquinaria por período (fecha de adquisición)
          List<Maquinaria> maquinaria;
          if (fechaInicio != null) {
            final inicio = fechaInicio;
            final fin = fechaFin;
            maquinaria = todasMaquinarias.where((m) {
              if (fin != null) {
                return m.fechaAdquisicion.isAfter(inicio) && 
                       m.fechaAdquisicion.isBefore(fin);
              }
              return m.fechaAdquisicion.isAfter(inicio);
            }).toList();
          } else {
            maquinaria = todasMaquinarias;
          }
          
          // Recalcular estadísticas con datos filtrados
          final stats = {
            'total': maquinaria.length,
            'disponibles': maquinaria.where((m) => m.estado == 'disponible').length,
            'mantenimiento': maquinaria.where((m) => m.estado == 'mantenimiento').length,
            'alquiladas': maquinaria.where((m) => m.estado == 'alquilado').length,
          };
          
          data = {
            'empresa': 'Tracktoger',
            'fecha': DateTime.now(),
            'filtro': _obtenerTextoFiltro(periodoSeleccionado, 'inventario'),
            'resumen': {
              'total': stats['total'] ?? 0,
              'disponibles': stats['disponibles'] ?? 0,
              'mantenimiento': stats['mantenimiento'] ?? 0,
              'alquilados': stats['alquiladas'] ?? 0,
            },
            'items': maquinaria.map((m) {
              String categoriaNombre = 'Sin categoría';
              try {
                final cat = categorias.firstWhere((c) => c.id == m.categoriaId);
                categoriaNombre = cat.nombre;
              } catch (_) {}
              
              return {
                'codigo': m.numeroSerie,
                'nombre': m.nombre,
                'categoria': categoriaNombre,
                'estado': m.estado,
                'ubicacion': m.ubicacion ?? '-',
                'horometro': m.horasUso,
                'ingreso': m.fechaAdquisicion.toString().split(' ')[0],
              };
            }).toList(),
          };
          break;
        case 'alquileres':
          final controlAlquiler = ControlAlquiler();
          final controlCliente = ControlCliente();
          final controlMaquinaria = ControlMaquinaria();
          final todosAlquileres = await controlAlquiler.consultarTodosAlquileres();
          final clientes = await controlCliente.consultarTodosClientes();
          final maquinarias = await controlMaquinaria.consultarTodasMaquinarias();
          
          // Filtrar alquileres por período (fecha de registro)
          List<Alquiler> alquileres;
          if (fechaInicio != null) {
            final inicio = fechaInicio;
            final fin = fechaFin;
            alquileres = todosAlquileres.where((a) {
              if (fin != null) {
                return a.fechaRegistro.isAfter(inicio) && 
                       a.fechaRegistro.isBefore(fin);
              }
              return a.fechaRegistro.isAfter(inicio);
            }).toList();
          } else {
            alquileres = todosAlquileres;
          }
          
          data = {
            'empresa': 'Tracktoger',
            'fecha': DateTime.now(),
            'filtro': _obtenerTextoFiltro(periodoSeleccionado, 'alquileres'),
            'resumen': {
              'total': alquileres.length,
              'entregados': alquileres.where((a) => a.estado == 'entregada').length,
              'devueltos': alquileres.where((a) => a.estado == 'devuelta').length,
              'pendientes': alquileres.where((a) => a.estado == 'pendiente_entrega').length,
              'cancelados': alquileres.where((a) => a.estado == 'cancelado').length,
            },
            'items': alquileres.map((a) {
              String clienteNombre = 'Cliente desconocido';
              try {
                final cli = clientes.firstWhere((cl) => cl.id == a.clienteId);
                clienteNombre = cli.nombreCompleto;
              } catch (_) {}
              
              String nombreMaquina = 'Máquina desconocida';
              try {
                final maq = maquinarias.firstWhere((m) => m.id == a.maquinariaId);
                nombreMaquina = maq.nombre;
              } catch (_) {}
              
              return {
                'cliente': clienteNombre,
                'equipo': nombreMaquina,
                'monto': a.monto,
                'estado': a.estado,
                'fechaInicio': a.fechaInicio.toString().split(' ')[0],
                'fechaFin': a.fechaFin.toString().split(' ')[0],
              };
            }).toList(),
          };
          break;
        case 'mantenimiento':
          final controlMantenimiento = ControlMantenimiento();
          final todosRegistros = await controlMantenimiento.consultarTodosRegistrosMantenimiento();
          final maquinarias = await ControlMaquinaria().consultarTodasMaquinarias();
          
          // Filtrar registros por período (fecha de creación)
          List<RegistroMantenimiento> registros;
          if (fechaInicio != null) {
            final inicio = fechaInicio;
            final fin = fechaFin;
            registros = todosRegistros.where((r) {
              if (fin != null) {
                return r.fechaCreacion.isAfter(inicio) && 
                       r.fechaCreacion.isBefore(fin);
              }
              return r.fechaCreacion.isAfter(inicio);
            }).toList();
          } else {
            registros = todosRegistros;
          }
          
          data = {
            'empresa': 'Tracktoger',
            'fecha': DateTime.now(),
            'filtro': _obtenerTextoFiltro(periodoSeleccionado, 'mantenimiento'),
            'resumen': {
              'total': registros.length,
              'completados': registros.where((r) => r.estado == 'completado').length,
              'pendientes': registros.where((r) => r.estado == 'pendiente').length,
              'en_progreso': registros.where((r) => r.estado == 'en_progreso').length,
            },
            'items': registros.map((r) {
              String nombreMaquina = 'Máquina desconocida';
              try {
                final maq = maquinarias.firstWhere((m) => m.id == r.idMaquinaria);
                nombreMaquina = maq.nombre;
              } catch (_) {}
              
              return {
                'equipo': nombreMaquina,
                'tipo': r.tipoMantenimiento,
                'costo': r.costoTotal,
                'fecha': r.fechaProgramada.toString().split(' ')[0],
                'estado': r.estado,
                'prioridad': '-',
                'descripcion': r.descripcionTrabajo,
              };
            }).toList(),
          };
          break;
        default:
          data = {
            'empresa': 'Tracktoger',
            'fecha': DateTime.now(),
            'items': [],
          };
      }

      final pdfFile = await generator.generar(tipo.toLowerCase(), data, context);

      // Descargar el PDF a la carpeta Downloads
      await _downloadPdf(pdfFile, tipo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reporte de $tipo descargado correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error al generar reporte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar reporte: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Muestra una notificación del sistema cuando se descarga un PDF
  Future<void> _showDownloadNotification(String tipo, String fileName) async {
    const androidDetails = AndroidNotificationDetails(
      'pdf_downloads',
      'Descargas de PDF',
      channelDescription: 'Notificaciones cuando se descargan reportes PDF',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '✅ PDF Descargado',
      'Reporte de $tipo guardado: $fileName',
      details,
    );
  }

  /// Descarga el PDF a la carpeta Downloads
  Future<void> _downloadPdf(File pdfFile, String tipo) async {
    try {
      // Solicitar permisos de almacenamiento
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Intentar con el nuevo permiso de Android 11+
          await Permission.manageExternalStorage.request();
        }
      }

      // Obtener directorio de descargas
      Directory? downloadDir;
      if (Platform.isAndroid) {
        // Para Android, usar el directorio de descargas
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          downloadDir = Directory('${externalDir.path.split('/Android')[0]}/Download');
          if (!await downloadDir.exists()) {
            downloadDir = await getApplicationDocumentsDirectory();
          }
        } else {
          downloadDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        final downloadsDir = await getDownloadsDirectory();
        downloadDir = downloadsDir ?? await getApplicationDocumentsDirectory();
      }

      // Crear nombre de archivo con timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'reporte_${tipo}_$timestamp.pdf';
      final destinationFile = File('${downloadDir.path}/$fileName');

      // Copiar archivo a descargas
      await pdfFile.copy(destinationFile.path);

      print('✅ PDF descargado en: ${destinationFile.path}');

      // Mostrar notificación del sistema
      await _showDownloadNotification(tipo, fileName);
    } catch (e) {
      print('⚠️ Error al descargar PDF: $e');
      // No lanzar error, solo loguear - el archivo ya se generó y se puede abrir
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          'Exportar Reportes',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exportTile("Inventario", Icons.inventory_2_rounded, Colors.amber),
            _exportTile("Alquileres", Icons.description_rounded, Colors.green),
            _exportTile("Mantenimiento", Icons.build_rounded, Colors.orange),
            _exportTile("Usuarios", Icons.people_alt_rounded, Colors.blue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cerrar",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportTile(String tipo, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        "Reporte de $tipo",
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        "Formato PDF/Excel",
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(context);
        _exportReport(tipo.toLowerCase());
      },
    );
  }

  // 🎨 Paleta de diseño Caterpillar Tech
  final Color colorFondo = const Color(0xFF1B1B1B);
  final Color colorPanel = const Color(0xFF2E2E2E);
  final Color colorBorde = const Color(0xFFFFD74D);
  final Color colorTexto = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 25),
            _buildExportButton(),
            const SizedBox(height: 25),
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.yellow),
                  )
                : Column(
                    children: [
                      _buildKPICards(),
                      const SizedBox(height: 25),
                      _buildUsuariosSection(),
                      const SizedBox(height: 25),
                      _buildChartsSection(),
                    ],
                  ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 🧭 Header del Dashboard
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorPanel,
        border: Border.all(color: colorBorde, width: 1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.dashboard_customize_rounded,
            color: Colors.yellow,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Panel de Control Industrial",
                style: TextStyle(
                  color: colorTexto,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "TractoG · Supervisión general del sistema",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📦 Botón Exportar Reportes
  Widget _buildExportButton() {
    return InkWell(
      onTap: _showExportDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorBorde.withOpacity(0.6), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorBorde.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.yellow,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Exportar Reportes PDF / Excel",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.yellow,
            ),
          ],
        ),
      ),
    );
  }

  // 📊 Tarjetas KPI
  Widget _buildKPICards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpiCards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final kpi = kpiCards[index];
        return Container(
          decoration: BoxDecoration(
            color: colorPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (kpi["color"] as Color).withOpacity(0.5),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(kpi["icon"], color: kpi["color"], size: 20),
                  Icon(
                    kpi["trendUp"] ? Icons.trending_up : Icons.trending_down,
                    color: kpi["trendUp"] ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  kpi["value"] ?? "-",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kpi["title"],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (kpi["subtitle"] != null) ...[
                const SizedBox(height: 2),
                Text(
                  kpi["subtitle"],
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                kpi["change"],
                style: TextStyle(
                  color: kpi["trendUp"] ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // 👥 Sección de usuarios
  Widget _buildUsuariosSection() {
    if (usuariosStats.isEmpty) return const SizedBox.shrink();

    final usuariosPorRol = usuariosStats['usuariosPorRol'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorPanel,
        border: Border.all(color: colorBorde.withOpacity(0.6), width: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  color: colorBorde,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estadísticas de Usuarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Usuarios',
                  '${usuariosStats['total'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Activos',
                  '${usuariosStats['activos'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Nuevos (30d)',
                  '${usuariosStats['nuevosUsuarios'] ?? 0}',
                  Icons.person_add,
                  Colors.orange,
                ),
              ),
            ],
          ),
          if (usuariosPorRol.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Usuarios por Rol',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...usuariosPorRol.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorBorde.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: colorPanel.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 📈 Sección de gráficos
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartBox("Disponibilidad Mensual", _buildBarChart()),
        const SizedBox(height: 20),
        _chartBox("Distribución de Equipos", _buildPieChart()),
        const SizedBox(height: 20),
        _chartBox("Ingresos Trimestrales", _buildLineChart()),
      ],
    );
  }

  Widget _chartBox(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorPanel,
        border: Border.all(color: colorBorde.withOpacity(0.6), width: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Usar datos reales del estado
    final maquinariaStats = kpiCards.isNotEmpty 
        ? (kpiCards.firstWhere(
            (kpi) => kpi["title"] == "Disponibilidad Total",
            orElse: () => {},
          )["subtitle"] as String?)?.split(" ").first ?? "0"
        : "0";
    
    final disponibles = int.tryParse(maquinariaStats) ?? 0;
    final total = usuariosStats['total'] ?? 1;
    final porcentajeDisponible = total > 0 ? (disponibles / total * 100).round() : 0;
    final porcentajeMantenimiento = 100 - porcentajeDisponible;
    
    // Obtener últimos 4 meses
    final ahora = DateTime.now();
    final meses = [
      {"mes": _getMesNombre(ahora.subtract(const Duration(days: 90))), "disponible": porcentajeDisponible, "mantenimiento": porcentajeMantenimiento},
      {"mes": _getMesNombre(ahora.subtract(const Duration(days: 60))), "disponible": porcentajeDisponible, "mantenimiento": porcentajeMantenimiento},
      {"mes": _getMesNombre(ahora.subtract(const Duration(days: 30))), "disponible": porcentajeDisponible, "mantenimiento": porcentajeMantenimiento},
      {"mes": _getMesNombre(ahora), "disponible": porcentajeDisponible, "mantenimiento": porcentajeMantenimiento},
    ];
    
    final data = meses;
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.map((e) {
            final disponible = (e["disponible"] ?? 0) as int;
            final mantenimiento = (e["mantenimiento"] ?? 0) as int;
            return BarChartGroupData(
              x: data.indexOf(e),
              barRods: [
                BarChartRodData(
                  toY: disponible.toDouble(),
                  color: Colors.greenAccent,
                  width: 10,
                ),
                BarChartRodData(
                  toY: mantenimiento.toDouble(),
                  color: Colors.orangeAccent,
                  width: 10,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    // Cargar datos reales de categorías
    return FutureBuilder<Map<String, int>>(
      future: _obtenerDistribucionCategorias(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        final distribucion = snapshot.data!;
        final total = distribucion.values.fold<int>(0, (sum, val) => sum + val);
        if (total == 0) {
          return const SizedBox(height: 200, child: Center(child: Text("No hay datos", style: TextStyle(color: Colors.white))));
        }
        
        final colors = [Colors.blueAccent, Colors.orangeAccent, Colors.tealAccent, Colors.grey, Colors.purpleAccent, Colors.redAccent];
        int colorIndex = 0;
        
        final data = distribucion.entries.map((e) {
          final percentage = (e.value / total * 100).round();
          return {
            "label": e.key,
            "value": percentage,
            "color": colors[colorIndex++ % colors.length],
          };
        }).toList();
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data
              .map(
                (e) {
                  final value = (e["value"] ?? 0) as int;
                  return PieChartSectionData(
                    value: value.toDouble(),
                    title: "$value%",
                    color: e["color"] as Color,
                    radius: 55,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  );
                },
              )
              .toList(),
          centerSpaceRadius: 35,
          sectionsSpace: 2,
        ),
      ),
    );
      },
    );
  }

  Widget _buildLineChart() {
    // Cargar datos reales de ingresos trimestrales
    return FutureBuilder<List<Map<String, double>>>(
      future: _obtenerIngresosTrimestrales(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        final data = snapshot.data!;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .map(
                    (e) {
                      final x = e["x"] ?? 0.0;
                      final y = e["y"] ?? 0.0;
                      return FlSpot(x, y);
                    },
                  )
                  .toList(),
              isCurved: true,
              color: Colors.amber,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  String _getMesNombre(DateTime fecha) {
    final meses = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
    return meses[fecha.month - 1];
  }

  Future<Map<String, int>> _obtenerDistribucionCategorias() async {
    try {
      final maquinarias = await ControlMaquinaria().consultarTodasMaquinarias();
      final categorias = await ControlMaquinaria().consultarTodasCategorias();
      
      final distribucion = <String, int>{};
      for (var maq in maquinarias) {
        final categoria = categorias.firstWhere(
          (c) => c.id == maq.categoriaId,
          orElse: () => categorias.isNotEmpty 
              ? categorias.first 
              : Categoria(
                  id: '', 
                  nombre: 'Sin categoría',
                  descripcion: 'Sin descripción',
                  fechaCreacion: DateTime.now(),
                ),
        );
        distribucion[categoria.nombre] = (distribucion[categoria.nombre] ?? 0) + 1;
      }
      
      return distribucion;
    } catch (e) {
      print('Error obteniendo distribución: $e');
      return {};
    }
  }

  Future<List<Map<String, double>>> _obtenerIngresosTrimestrales() async {
    try {
      final alquileres = await ControlAlquiler().consultarTodosAlquileres();
      final ahora = DateTime.now();
      
      // Agrupar por trimestre (últimos 4 trimestres)
      final trimestres = <int, double>{};
      
      for (var alq in alquileres) {
        final mesesDesdeInicio = (ahora.difference(alq.fechaInicio).inDays / 30).floor();
        final trimestre = (mesesDesdeInicio / 3).floor();
        
        if (trimestre >= 0 && trimestre < 4) {
          trimestres[trimestre] = (trimestres[trimestre] ?? 0.0) + alq.monto;
        }
      }
      
      // Convertir a lista ordenada
      final data = <Map<String, double>>[];
      for (int i = 0; i < 4; i++) {
        data.add({
          "x": i.toDouble(),
          "y": (trimestres[i] ?? 0.0) / 1000.0, // Dividir por 1000 para mejor visualización
        });
      }
      
      return data;
    } catch (e) {
      print('Error obteniendo ingresos: $e');
      return [
        {"x": 0.0, "y": 0.0},
        {"x": 1.0, "y": 0.0},
        {"x": 2.0, "y": 0.0},
        {"x": 3.0, "y": 0.0},
      ];
    }
  }

  /// Obtiene el texto del filtro según el período y tipo de reporte
  String _obtenerTextoFiltro(String periodo, String tipo) {
    String periodoTexto;
    switch (periodo) {
      case 'semanal':
        periodoTexto = 'Últimos 7 días';
        break;
      case 'mensual':
        periodoTexto = 'Último mes';
        break;
      case 'anual':
        periodoTexto = 'Último año';
        break;
      case 'todo':
        periodoTexto = 'Histórico completo';
        break;
      default:
        periodoTexto = 'Todo';
    }

    switch (tipo) {
      case 'usuarios':
        return periodo == 'todo' ? 'Todos los usuarios' : 'Usuarios - $periodoTexto';
      case 'inventario':
        return periodo == 'todo' ? 'Todo el inventario' : 'Inventario - $periodoTexto';
      case 'alquileres':
        return periodo == 'todo' ? 'Todos los alquileres' : 'Alquileres - $periodoTexto';
      case 'mantenimiento':
        return periodo == 'todo' ? 'Todos los registros' : 'Mantenimiento - $periodoTexto';
      default:
        return periodoTexto;
    }
  }
}
