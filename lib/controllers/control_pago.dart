import 'package:mongo_dart/mongo_dart.dart';
import '../models/pago.dart';
import '../data/services/database_service.dart';

/// Controlador para la gestión de pagos
class ControlPago {
  final DatabaseService _dbService = DatabaseService();

  /// Registra un nuevo pago
  Future<Pago> registrarPago(Pago pago) async {
    String pagoId = pago.id;
    if (pagoId.isEmpty) {
      pagoId = ObjectId().toHexString();
    }

    final pagoToInsert = pago.copyWith(id: pagoId);
    await _dbService.insertarPago(pagoToInsert.toMap());
    print('✅ Pago registrado: $pagoId');
    return pagoToInsert;
  }

  /// Actualiza un pago existente
  Future<Pago> actualizarPago(Pago pago) async {
    await _dbService.actualizarPago(pago.toMap());
    return pago;
  }

  /// Obtiene un pago por su ID
  Future<Pago?> consultarPago(String id) async {
    return await _dbService.consultarPago(id);
  }

  /// Obtiene todos los pagos de un contrato
  Future<List<Pago>> consultarPagosPorContrato(String contratoId) async {
    return await _dbService.consultarPagosPorContrato(contratoId);
  }

  /// Elimina un pago
  Future<bool> eliminarPago(String id) async {
    await _dbService.eliminarPago(id);
    return true;
  }

  /// Calcula el monto total cancelado de un contrato
  Future<double> calcularMontoCancelado(String contratoId) async {
    final pagos = await consultarPagosPorContrato(contratoId);
    return pagos
        .where((p) => p.estado == 'confirmado')
        .fold<double>(0.0, (sum, p) => sum + p.monto);
  }
}

