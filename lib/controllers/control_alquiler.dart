import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import '../models/alquiler.dart';
import '../data/services/database_service.dart';
import 'control_cliente.dart';
import 'control_maquinaria.dart';
import '../utils/pdf/template/contrato_alquiler_template.dart';

/// Controlador para la gestión de alquileres
/// Maneja las operaciones CRUD de alquileres usando MongoDB
class ControlAlquiler {
  final DatabaseService _dbService = DatabaseService();
  final ControlCliente _controlCliente = ControlCliente();
  final ControlMaquinaria _controlMaquinaria = ControlMaquinaria();

  /// Registra un nuevo alquiler
  Future<Alquiler> registrarAlquiler(Alquiler alquiler) async {
    String alquilerId = alquiler.id;
    if (alquilerId.isEmpty) {
      alquilerId = ObjectId().toHexString();
    }

    // Validar que el cliente existe
    final cliente = await _controlCliente.consultarCliente(alquiler.clienteId);
    if (cliente == null) {
      throw Exception('Cliente no encontrado');
    }

    // Validar que la maquinaria existe y está disponible
    final maquinaria = await _controlMaquinaria.consultarMaquinaria(alquiler.maquinariaId);
    if (maquinaria == null) {
      throw Exception('Maquinaria no encontrada');
    }

    // Verificar que no haya conflictos de fechas con otros alquileres activos
    final alquileresActivos = await consultarTodosAlquileres(
      soloActivos: true,
      maquinariaId: alquiler.maquinariaId,
    );
    
    for (var alq in alquileresActivos) {
      if (alq.estado != 'devuelto' && alq.estado != 'cancelado') {
        // Verificar solapamiento de fechas
        if ((alquiler.fechaInicio.isBefore(alq.fechaFin) || alquiler.fechaInicio.isAtSameMomentAs(alq.fechaFin)) &&
            (alquiler.fechaFin.isAfter(alq.fechaInicio) || alquiler.fechaFin.isAtSameMomentAs(alq.fechaInicio))) {
          throw Exception('La maquinaria ya está alquilada en ese período');
        }
      }
    }

    // Actualizar estado de la maquinaria a "alquilado"
    await _controlMaquinaria.actualizarEstadoMaquinaria(alquiler.maquinariaId, 'alquilado');

    final alquilerToInsert = alquiler.copyWith(id: alquilerId);
    await _dbService.insertarAlquiler(alquilerToInsert.toMap());
    print('✅ Alquiler registrado en MongoDB: $alquilerId');
    return alquilerToInsert;
  }

  /// Actualiza un alquiler existente
  Future<Alquiler> actualizarAlquiler(Alquiler alquiler) async {
    final existente = await consultarAlquiler(alquiler.id);
    if (existente == null) {
      throw Exception('Alquiler no encontrado');
    }

    await _dbService.actualizarAlquiler(alquiler.toMap());
    return alquiler;
  }

  /// Obtiene un alquiler por su ID
  Future<Alquiler?> consultarAlquiler(String id) async {
    return await _dbService.consultarAlquiler(id);
  }

  /// Obtiene todos los alquileres
  Future<List<Alquiler>> consultarTodosAlquileres({
    bool soloActivos = true,
    String? clienteId,
    String? maquinariaId,
    String? estado,
  }) async {
    return await _dbService.consultarTodosAlquileres(
      soloActivos: soloActivos,
      clienteId: clienteId,
      maquinariaId: maquinariaId,
      estado: estado,
    );
  }

  /// Elimina un alquiler (desactiva)
  Future<bool> eliminarAlquiler(String id) async {
    final alquiler = await consultarAlquiler(id);
    if (alquiler != null && alquiler.estado != 'devuelto') {
      // Si el alquiler no está devuelto, cambiar estado de maquinaria a disponible
      await _controlMaquinaria.actualizarEstadoMaquinaria(alquiler.maquinariaId, 'disponible');
    }
    return await _dbService.eliminarAlquiler(id);
  }

  /// Registra la entrega de maquinaria (operador)
  /// Usa los mismos estados que el modelo `Alquiler`:
  /// 'pendiente_entrega' -> 'entregada'
  Future<Alquiler> registrarEntrega(String alquilerId, String proyecto) async {
    final alquiler = await consultarAlquiler(alquilerId);
    if (alquiler == null) {
      throw Exception('Alquiler no encontrado');
    }

    // El estado inicial definido en el modelo es 'pendiente_entrega'
    if (alquiler.estado != 'pendiente_entrega') {
      throw Exception('Solo se puede entregar un alquiler en estado pendiente de entrega');
    }

    final alquilerActualizado = alquiler.copyWith(
      estado: 'entregada',
      fechaEntrega: DateTime.now(),
      proyecto: proyecto.isNotEmpty ? proyecto : alquiler.proyecto,
    );

    await actualizarAlquiler(alquilerActualizado);
    return alquilerActualizado;
  }

  /// Registra la devolución de maquinaria (operador)
  /// Usa los mismos estados que el modelo `Alquiler`:
  /// 'entregada' -> 'devuelta'
  Future<Alquiler> registrarDevolucion(String alquilerId, int horasUsoReal) async {
    final alquiler = await consultarAlquiler(alquilerId);
    if (alquiler == null) {
      throw Exception('Alquiler no encontrado');
    }

    // Después de la entrega, el estado es 'entregada'
    if (alquiler.estado != 'entregada') {
      throw Exception('Solo se puede devolver un alquiler en estado entregada');
    }

    // Actualizar horas de uso de la maquinaria (sumamos las horas trabajadas en este contrato)
    final maquinaria = await _controlMaquinaria.consultarMaquinaria(alquiler.maquinariaId);
    if (maquinaria != null) {
      final nuevasHoras = (maquinaria.horasUso + horasUsoReal).toDouble();
      await _controlMaquinaria.actualizarHorasUso(alquiler.maquinariaId, nuevasHoras);
    }

    // Cambiar estado de maquinaria a disponible
    await _controlMaquinaria.actualizarEstadoMaquinaria(alquiler.maquinariaId, 'disponible');

    final alquilerActualizado = alquiler.copyWith(
      estado: 'devuelta',
      fechaDevolucion: DateTime.now(),
      horasUsoReal: horasUsoReal,
      proyectoFinalizado: true,
    );

    await actualizarAlquiler(alquilerActualizado);
    return alquilerActualizado;
  }

  /// Obtiene alquileres activos de una maquinaria
  Future<List<Alquiler>> consultarAlquileresActivosPorMaquinaria(String maquinariaId) async {
    final todos = await consultarTodosAlquileres(
      soloActivos: true,
      maquinariaId: maquinariaId,
    );
    // Se consideran "activos" todos los que NO están devueltos ni cancelados.
    // El estado correcto para devuelto en el modelo es 'devuelta'.
    return todos.where((a) =>
      a.estado != 'devuelta' && a.estado != 'cancelado'
    ).toList();
  }

  /// Verifica disponibilidad de maquinaria en un rango de fechas
  Future<bool> verificarDisponibilidad(String maquinariaId, DateTime fechaInicio, DateTime fechaFin) async {
    final alquileresActivos = await consultarAlquileresActivosPorMaquinaria(maquinariaId);
    
    for (var alq in alquileresActivos) {
      // Verificar solapamiento de fechas
      if ((fechaInicio.isBefore(alq.fechaFin) || fechaInicio.isAtSameMomentAs(alq.fechaFin)) &&
          (fechaFin.isAfter(alq.fechaInicio) || fechaFin.isAtSameMomentAs(alq.fechaInicio))) {
        return false; // No disponible
      }
    }
    return true; // Disponible
  }

  /// Obtiene estadísticas de alquileres
  Future<Map<String, dynamic>> obtenerEstadisticasAlquileres() async {
    final todos = await consultarTodosAlquileres();
    final total = todos.length;
    final pendientes = todos.where((a) => a.estado == 'pendiente_entrega').length;
    final entregados = todos.where((a) => a.estado == 'entregada').length;
    final devueltos = todos.where((a) => a.estado == 'devuelta').length;
    final cancelados = todos.where((a) => a.estado == 'cancelado').length;
    final totalMonto = todos.fold<double>(0.0, (sum, a) => sum + a.monto);

    return {
      'total': total,
      'pendientes': pendientes,
      'entregados': entregados,
      'devueltos': devueltos,
      'cancelados': cancelados,
      'totalMonto': totalMonto,
    };
  }

  /// Genera el PDF del contrato de alquiler
  Future<File> generarPdfContrato(
    String alquilerId,
    BuildContext context, {
    bool mostrarMonto = true,
  }) async {
    final alquiler = await consultarAlquiler(alquilerId);
    if (alquiler == null) {
      throw Exception('Alquiler no encontrado');
    }

    final cliente = await _controlCliente.consultarCliente(alquiler.clienteId);
    if (cliente == null) {
      throw Exception('Cliente no encontrado');
    }

    final maquinaria = await _controlMaquinaria.consultarMaquinaria(alquiler.maquinariaId);
    if (maquinaria == null) {
      throw Exception('Maquinaria no encontrada');
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) {
          return ContratoAlquilerTemplate.build(
            alquiler: alquiler,
            cliente: cliente,
            maquinaria: maquinaria,
            mostrarMonto: mostrarMonto,
          );
        },
      ),
    );

    // Guardar el PDF
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final fileName = 'contrato_alquiler_${alquiler.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // Abrir el archivo
    await OpenFilex.open(file.path);

    // Mostrar notificación
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contrato generado: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return file;
  }
}

