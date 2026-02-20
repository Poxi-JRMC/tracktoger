import 'package:mongo_dart/mongo_dart.dart';

/// Modelo de Alquiler para el sistema Tracktoger
/// Representa un contrato de alquiler de maquinaria
class Alquiler {
  final String id;
  final String clienteId; // ID del cliente
  final String maquinariaId; // ID de la maquinaria
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int horasAlquiler;
  final String tipoAlquiler; // 'horas' o 'meses'
  final double monto; // Solo visible para admin
  final double? montoAdelanto; // Pago adelantado (opcional)
  final double? montoCancelado; // Monto total cancelado hasta el momento
  final String? metodoPago; // 'qr', 'efectivo', 'transferencia', etc.
  final String? codigoQR; // Código QR para pagos (imagen en base64 o URL)
  final String? proyecto; // Proyecto al que se asigna la maquinaria
  final String? ubicacion; // Ubicación / lugar del proyecto
  final String estado; // 'pendiente_entrega', 'entregada', 'devuelta', 'cancelado'
  final String? observaciones;
  final DateTime fechaRegistro;
  final DateTime? fechaEntrega; // Fecha en que se entregó físicamente
  final DateTime? fechaDevolucion; // Fecha en que se devolvió
  final int? horasUsoReal; // Horas reales de uso registradas
  final Map<String, dynamic>? especificaciones; // Especificaciones del contrato
  final bool activo;
  final bool proyectoFinalizado; // Indica si el proyecto está finalizado

  Alquiler({
    required this.id,
    required this.clienteId,
    required this.maquinariaId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.horasAlquiler,
    this.tipoAlquiler = 'horas',
    required this.monto,
    this.montoAdelanto,
    this.montoCancelado,
    this.metodoPago,
    this.codigoQR,
    this.proyecto,
    this.ubicacion,
    this.estado = 'pendiente_entrega',
    this.observaciones,
    required this.fechaRegistro,
    this.fechaEntrega,
    this.fechaDevolucion,
    this.horasUsoReal,
    this.especificaciones,
    this.activo = true,
    this.proyectoFinalizado = false,
  });

  /// Convierte el objeto a Map para almacenamiento en MongoDB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'maquinariaId': maquinariaId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'horasAlquiler': horasAlquiler,
      'tipoAlquiler': tipoAlquiler,
      'monto': monto,
      'montoAdelanto': montoAdelanto,
      'montoCancelado': montoCancelado,
      'metodoPago': metodoPago,
      'codigoQR': codigoQR,
      'proyecto': proyecto,
      'ubicacion': ubicacion,
      'estado': estado,
      'observaciones': observaciones,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'fechaEntrega': fechaEntrega?.toIso8601String(),
      'fechaDevolucion': fechaDevolucion?.toIso8601String(),
      'horasUsoReal': horasUsoReal,
      'especificaciones': especificaciones,
      'activo': activo,
      'proyectoFinalizado': proyectoFinalizado,
    };
  }

  /// Crea un objeto Alquiler desde un Map de MongoDB
  factory Alquiler.fromMap(Map<String, dynamic> map) {
    // Manejar ID que puede venir como _id (ObjectId) o id (String)
    String id = '';
    if (map['_id'] != null) {
      final objectId = map['_id'];
      if (objectId is ObjectId) {
        id = objectId.toHexString();
      } else {
        String idStr = objectId.toString();
        if (idStr.startsWith('ObjectId(') && idStr.endsWith(')')) {
          id = idStr.substring(9, idStr.length - 2).replaceAll('"', '').replaceAll("'", '');
        } else {
          id = idStr;
        }
      }
    } else if (map['id'] != null) {
      id = map['id'].toString();
    }

    return Alquiler(
      id: id,
      clienteId: map['clienteId'] ?? '',
      maquinariaId: map['maquinariaId'] ?? '',
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.parse(map['fechaInicio'])
          : DateTime.now(),
      fechaFin: map['fechaFin'] != null
          ? DateTime.parse(map['fechaFin'])
          : DateTime.now(),
      horasAlquiler: map['horasAlquiler'] ?? 0,
      tipoAlquiler: map['tipoAlquiler'] ?? 'horas',
      monto: (map['monto'] ?? 0.0).toDouble(),
      montoAdelanto: map['montoAdelanto'] != null ? (map['montoAdelanto'] as num).toDouble() : null,
      montoCancelado: map['montoCancelado'] != null ? (map['montoCancelado'] as num).toDouble() : null,
      metodoPago: map['metodoPago'],
      codigoQR: map['codigoQR'],
      proyecto: map['proyecto'],
      ubicacion: map['ubicacion'],
      estado: map['estado'] ?? 'pendiente_entrega',
      observaciones: map['observaciones'],
      fechaRegistro: map['fechaRegistro'] != null
          ? DateTime.parse(map['fechaRegistro'])
          : DateTime.now(),
      fechaEntrega: map['fechaEntrega'] != null
          ? DateTime.parse(map['fechaEntrega'])
          : null,
      fechaDevolucion: map['fechaDevolucion'] != null
          ? DateTime.parse(map['fechaDevolucion'])
          : null,
      horasUsoReal: map['horasUsoReal'],
      especificaciones: map['especificaciones'] != null 
          ? Map<String, dynamic>.from(map['especificaciones']) 
          : null,
      activo: map['activo'] ?? true,
      proyectoFinalizado: map['proyectoFinalizado'] ?? false,
    );
  }

  /// Crea una copia del alquiler con campos modificados
  Alquiler copyWith({
    String? id,
    String? clienteId,
    String? maquinariaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? horasAlquiler,
    String? tipoAlquiler,
    double? monto,
    double? montoAdelanto,
    double? montoCancelado,
    String? metodoPago,
    String? codigoQR,
    String? proyecto,
    String? ubicacion,
    String? estado,
    String? observaciones,
    DateTime? fechaRegistro,
    DateTime? fechaEntrega,
    DateTime? fechaDevolucion,
    int? horasUsoReal,
    Map<String, dynamic>? especificaciones,
    bool? activo,
    bool? proyectoFinalizado,
  }) {
    return Alquiler(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      maquinariaId: maquinariaId ?? this.maquinariaId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      horasAlquiler: horasAlquiler ?? this.horasAlquiler,
      tipoAlquiler: tipoAlquiler ?? this.tipoAlquiler,
      monto: monto ?? this.monto,
      montoAdelanto: montoAdelanto ?? this.montoAdelanto,
      montoCancelado: montoCancelado ?? this.montoCancelado,
      metodoPago: metodoPago ?? this.metodoPago,
      codigoQR: codigoQR ?? this.codigoQR,
      proyecto: proyecto ?? this.proyecto,
      ubicacion: ubicacion ?? this.ubicacion,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      fechaDevolucion: fechaDevolucion ?? this.fechaDevolucion,
      horasUsoReal: horasUsoReal ?? this.horasUsoReal,
      especificaciones: especificaciones ?? this.especificaciones,
      activo: activo ?? this.activo,
      proyectoFinalizado: proyectoFinalizado ?? this.proyectoFinalizado,
    );
  }

  @override
  String toString() {
    return 'Alquiler(id: $id, clienteId: $clienteId, maquinariaId: $maquinariaId, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alquiler && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

