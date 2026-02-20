import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/falla_predicha.dart';
import '../models/mantenimiento_recordatorio.dart';
import '../models/estado_maquinaria.dart';

/// Servicio para enviar notificaciones de mantenimiento predictivo
class NotificacionesMantenimientoService {
  static final NotificacionesMantenimientoService _instance = NotificacionesMantenimientoService._internal();
  factory NotificacionesMantenimientoService() => _instance;
  NotificacionesMantenimientoService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  /// Inicializa el servicio de notificaciones
  Future<void> inicializar() async {
    if (_inicializado) return;

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

    await _notifications.initialize(initSettings);
    _inicializado = true;
  }

  /// Notifica sobre estado urgente de una máquina
  Future<void> notificarEstadoUrgente(String maquinariaNombre, EstadoMaquinaria estado) async {
    await inicializar();

    final androidDetails = AndroidNotificationDetails(
      'mantenimiento_urgente',
      'Mantenimiento Urgente',
      channelDescription: 'Alertas de mantenimiento urgente',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF0000),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '🚨 Estado Urgente: $maquinariaNombre',
      'Estado: ${estado.estadoGeneral} - Score de Salud: ${estado.scoreSalud.toStringAsFixed(0)}%',
      details,
    );
  }

  /// Notifica sobre una falla predicha
  Future<void> notificarFallaPredicha(String maquinariaNombre, FallaPredicha falla) async {
    await inicializar();

    final severidad = falla.severidad == 'critica' ? '🚨 CRÍTICA' : 
                     falla.severidad == 'alta' ? '⚠️ ALTA' : 
                     '📋 MEDIA';

    final androidDetails = AndroidNotificationDetails(
      'fallas_predichas',
      'Fallas Predichas',
      channelDescription: 'Notificaciones de fallas predichas por ML',
      importance: falla.severidad == 'critica' ? Importance.max : Importance.high,
      priority: falla.severidad == 'critica' ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      color: falla.severidad == 'critica' ? const Color(0xFFFF0000) : const Color(0xFFFFA500),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000 + falla.probabilidad.round(),
      '$severidad - $maquinariaNombre',
      '${falla.nombreFalla}: ${falla.probabilidad.toStringAsFixed(0)}% de probabilidad',
      details,
    );
  }

  /// Notifica sobre recordatorios de mantenimiento urgentes
  Future<void> notificarRecordatorioUrgente(String maquinariaNombre, MantenimientoRecordatorio recordatorio) async {
    await inicializar();

    final tipo = recordatorio.tipoMantenimiento == 'aceite' ? '🛢️ Cambio de Aceite' :
                 recordatorio.tipoMantenimiento == 'filtro' ? '🔧 Cambio de Filtros' :
                 recordatorio.tipoMantenimiento == 'revision_general' ? '🔍 Revisión General' :
                 '⚙️ Revisión Mayor';

    final androidDetails = AndroidNotificationDetails(
      'recordatorios_mantenimiento',
      'Recordatorios de Mantenimiento',
      channelDescription: 'Notificaciones de mantenimientos programados',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFFA500),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000 + recordatorio.horasRestantes,
      '$tipo - $maquinariaNombre',
      'Faltan ${recordatorio.horasRestantes} horas (${recordatorio.descripcion})',
      details,
    );
  }

  /// Programa notificaciones periódicas para recordatorios
  Future<void> programarNotificacionesRecordatorios(
    List<MantenimientoRecordatorio> recordatorios,
  ) async {
    await inicializar();

    for (var recordatorio in recordatorios) {
      if (recordatorio.urgente && recordatorio.fechaEstimada != null) {
        final diferencia = recordatorio.fechaEstimada!.difference(DateTime.now());
        if (diferencia.inDays >= 0 && diferencia.inDays <= 7) {
          // Programar notificación para el día estimado
          await _notificacionesRecordatorioProgramado(
            recordatorio,
            diferencia,
          );
        }
      }
    }
  }

  Future<void> _notificacionesRecordatorioProgramado(
    MantenimientoRecordatorio recordatorio,
    Duration diferencia,
  ) async {
    // Implementar programación de notificaciones futuras si es necesario
    // Por ahora, solo notificamos inmediatamente si es urgente
  }
}

