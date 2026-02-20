import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';

class ControlPDFGenerator {
  static final pdf.PdfColor _blackSteel = _hex('#1B1B1B');
  static final pdf.PdfColor _darkGrey = _hex('#2E2E2E');
  static final pdf.PdfColor _midGrey = _hex('#3A3A3A');
  static final pdf.PdfColor _catYellow = _hex('#FFCD11');
  static final pdf.PdfColor _softYellow = _hex('#FFD74D');
  static final pdf.PdfColor _lightText = _hex('#E5E5E5');
  static final pdf.PdfColor _darkGreyRow = _hex('#383838');

  /// Genera un PDF según el tipo de reporte
  Future<File> generar(
    String tipo,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    switch (tipo) {
      case 'inventario':
        return buildInventarioPdf(data, context);
      case 'alquileres':
        return buildAlquileresPdf(data, context);
      case 'mantenimiento':
        return buildMantenimientoPdf(data, context);
      case 'usuarios':
        return buildUsuariosPdf(data, context);
      default:
        return _buildGenericPdf(data, title: 'Reporte', context: context);
    }
  }

  // 📦 INVENTARIO
  Future<File> buildInventarioPdf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final doc = pw.Document();

    // Cabecera y contenido en la misma página
    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => pw.Container(
          color: _blackSteel,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TRACTOGER',
                    style: pw.TextStyle(
                      color: _catYellow,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _softYellow,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'INVENTARIO',
                      style: pw.TextStyle(
                        color: pdf.PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'REPORTE DE INVENTARIO',
                style: pw.TextStyle(
                  color: pdf.PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                _subtitleFromData(data),
                style: pw.TextStyle(color: _lightText, fontSize: 12),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                height: 2,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [_softYellow, _catYellow],
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              // Resumen (en la misma página)
              if (data['resumen'] != null) ...[
                _sectionTitle('Resumen General'),
                pw.SizedBox(height: 12),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: _darkGrey,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: _softYellow, width: 0.7),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: _midGrey,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total equipos',
                              style: pw.TextStyle(
                                color: _lightText,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              _num(data['resumen']?['total']),
                              style: pw.TextStyle(
                                color: pdf.PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: _midGrey,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Disponibles',
                              style: pw.TextStyle(
                                color: _lightText,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              _num(data['resumen']?['disponibles']),
                              style: pw.TextStyle(
                                color: pdf.PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: _midGrey,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'En Mantenimiento',
                              style: pw.TextStyle(
                                color: _lightText,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              _num(data['resumen']?['mantenimiento']),
                              style: pw.TextStyle(
                                color: pdf.PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Alquilados',
                              style: pw.TextStyle(
                                color: _lightText,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              _num(data['resumen']?['alquilados']),
                              style: pw.TextStyle(
                                color: pdf.PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
              ],
              // Información de detalle (continuará en siguiente página si es necesario)
              _sectionTitle('Detalle de Equipos'),
              pw.SizedBox(height: 8),
              pw.Text(
                'Total de equipos: ${(data['items'] as List<dynamic>? ?? []).length}',
                style: pw.TextStyle(
                  color: _lightText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Detalle en página separada
    final items = (data['items'] as List<dynamic>? ?? []);
    if (items.isNotEmpty) {
      _addTable(
        doc,
        title: 'Detalle de Equipos',
        headers: const [
          'Código',
          'Nombre',
          'Categoría',
          'Estado',
          'Ubicación',
          'Horómetro',
          'Ingreso',
        ],
        data: items
            .map<List<String>>(
              (e) => [
                '${e['codigo'] ?? '-'}',
                '${e['nombre'] ?? '-'}',
                '${e['categoria'] ?? '-'}',
                '${e['estado'] ?? '-'}',
                '${e['ubicacion'] ?? '-'}',
                '${e['horometro'] ?? 0}',
                '${e['ingreso'] ?? '-'}',
              ],
            )
            .toList(),
      );
    } else {
      _addEmptyMessage(doc, 'No hay equipos registrados en el inventario');
    }

    // Guarda el archivo PDF generado
    final pdfFile = await _save(doc, fileName: _fileName('inventario'));

    // Abre el archivo generado automáticamente
    await OpenFilex.open(pdfFile.path);

    // Notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte de Inventario generado: ${pdfFile.path}'),
        backgroundColor: Colors.green,
      ),
    );

    return pdfFile;
  }

  // 💰 ALQUILERES
  Future<File> buildAlquileresPdf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final doc = pw.Document();

    _addHeaderCover(
      doc,
      title: 'REPORTE DE ALQUILERES',
      subtitle: _subtitleFromData(data),
      chip: 'Alquileres',
    );

    // Resumen (solo si hay datos)
    if (data['resumen'] != null) {
      final rows = <MapEntry<String, String>>[
        _kv('Total contratos', _num(data['resumen']?['total'])),
        _kv('Entregados', _num(data['resumen']?['entregados'])),
        _kv('Devueltos', _num(data['resumen']?['devueltos'])),
        _kv('Pendientes', _num(data['resumen']?['pendientes'])),
      ];
      // Agregar cancelados si existe
      if (data['resumen']?['cancelados'] != null) {
        rows.add(_kv('Cancelados', _num(data['resumen']?['cancelados'])));
      }
      _addSummarySection(
        doc,
        title: 'Resumen General',
        rows: rows,
      );
    }

    final items = (data['items'] as List<dynamic>? ?? []);
    if (items.isNotEmpty) {
      _addTable(
        doc,
        title: 'Contratos de Alquiler',
        headers: const [
          'Cliente',
          'Equipo',
          'Monto (USD)',
          'Estado',
          'Fecha Inicio',
          'Fecha Fin',
        ],
        data: items
            .map<List<String>>(
              (e) => [
                '${e['cliente'] ?? '-'}',
                '${e['equipo'] ?? '-'}',
                _money(e['monto'] ?? 0),
                '${e['estado'] ?? '-'}',
                '${e['fechaInicio'] ?? '-'}',
                '${e['fechaFin'] ?? '-'}',
              ],
            )
            .toList(),
      );
    } else {
      _addEmptyMessage(doc, 'No hay contratos de alquiler registrados');
    }

    // Guardamos el archivo y lo abrimos
    final pdfFile = await _save(doc, fileName: _fileName('alquileres'));

    // Abrir el archivo generado automáticamente
    await OpenFilex.open(pdfFile.path);

    // Notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte de Alquileres generado: ${pdfFile.path}'),
        backgroundColor: Colors.green,
      ),
    );

    return pdfFile;
  }

  // 🔧 MANTENIMIENTO
  Future<File> buildMantenimientoPdf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final doc = pw.Document();

    _addHeaderCover(
      doc,
      title: 'REPORTE DE MANTENIMIENTO',
      subtitle: _subtitleFromData(data),
      chip: 'Mantenimiento',
    );

    // Resumen (solo si hay datos)
    if (data['resumen'] != null) {
      _addSummarySection(
        doc,
        title: 'Resumen General',
        rows: [
          _kv('Total registros', _num(data['resumen']?['total'])),
          _kv('Completados', _num(data['resumen']?['completados'])),
          _kv('Pendientes', _num(data['resumen']?['pendientes'])),
          _kv('En Progreso', _num(data['resumen']?['en_progreso'])),
        ],
      );
    }

    final items = (data['items'] as List<dynamic>? ?? []);
    if (items.isNotEmpty) {
      _addTable(
        doc,
        title: 'Registros de Mantenimiento',
        headers: const ['Equipo', 'Tipo', 'Costo (USD)', 'Fecha', 'Estado'],
        data: items
            .map<List<String>>(
              (e) => [
                '${e['equipo'] ?? '-'}',
                '${e['tipo'] ?? '-'}',
                _money(e['costo'] ?? 0),
                '${e['fecha'] ?? '-'}',
                '${e['estado'] ?? '-'}',
              ],
            )
            .toList(),
      );
    } else {
      _addEmptyMessage(doc, 'No hay registros de mantenimiento');
    }

    // Guardamos el archivo y lo abrimos
    final pdfFile = await _save(doc, fileName: _fileName('mantenimiento'));

    // Abrir el archivo generado automáticamente
    await OpenFilex.open(pdfFile.path);

    // Notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte de Mantenimiento generado: ${pdfFile.path}'),
        backgroundColor: Colors.green,
      ),
    );

    return pdfFile;
  }

  // 👤 USUARIOS
  Future<File> buildUsuariosPdf(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final doc = pw.Document();

    _addHeaderCover(
      doc,
      title: 'REPORTE DE USUARIOS',
      subtitle: _subtitleFromData(data),
      chip: 'Usuarios',
    );

    // Resumen de usuarios
    if (data['resumen'] != null) {
      _addSummarySection(
        doc,
        title: 'Resumen de Usuarios',
        rows: [
          _kv('Total usuarios', _num(data['resumen']?['total'])),
          _kv('Usuarios activos', _num(data['resumen']?['activos'])),
          _kv('Usuarios inactivos', _num(data['resumen']?['inactivos'])),
        ],
      );
    }

    final items = (data['items'] as List<dynamic>? ?? []);
    if (items.isNotEmpty) {
      _addTable(
        doc,
        title: 'Usuarios Registrados',
        headers: const ['Nombre', 'Rol', 'Correo', 'Teléfono', 'Estado', 'Registro'],
        data: items
            .map<List<String>>(
              (e) => [
                '${e['nombre'] ?? '-'}',
                '${e['rol'] ?? '-'}',
                '${e['correo'] ?? '-'}',
                '${e['telefono'] ?? '-'}',
                '${e['estado'] ?? '-'}',
                '${e['fechaRegistro'] ?? '-'}',
              ],
            )
            .toList(),
      );
    } else {
      _addEmptyMessage(doc, 'No hay usuarios registrados');
    }

    // Guardamos el archivo y lo abrimos
    final pdfFile = await _save(doc, fileName: _fileName('usuarios'));

    // Abrir el archivo generado automáticamente
    await OpenFilex.open(pdfFile.path);

    // Notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte de Usuarios generado: ${pdfFile.path}'),
        backgroundColor: Colors.green,
      ),
    );

    return pdfFile;
  }

  // 📄 GENÉRICO
  Future<File> _buildGenericPdf(
    Map<String, dynamic> data, {
    required String title,
    required BuildContext context,
  }) async {
    final doc = pw.Document();

    _addHeaderCover(
      doc,
      title: title.toUpperCase(),
      subtitle: _subtitleFromData(data),
      chip: 'Reporte',
    );

    _addTable(
      doc,
      title: 'Datos Generales',
      headers: const ['Clave', 'Valor'],
      data: data.entries
          .where((e) => e.value is! List && e.value is! Map)
          .map<List<String>>((e) => ['${e.key}', '${e.value}'])
          .toList(),
    );

    return _save(doc, fileName: _fileName('reporte'));
  }

  // ===============================
  // 🔹 COMPONENTES DE CONSTRUCCIÓN
  // ===============================

  void _addHeaderCover(
    pw.Document doc, {
    required String title,
    required String subtitle,
    required String chip,
  }) {
    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => pw.Container(
          color: _blackSteel,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TRACTOGER',
                    style: pw.TextStyle(
                      color: _catYellow,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _softYellow,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      chip.toUpperCase(),
                      style: pw.TextStyle(
                        color: pdf.PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: pdf.PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                subtitle,
                style: pw.TextStyle(color: _lightText, fontSize: 12),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                height: 2,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [_softYellow, _catYellow],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSummarySection(
    pw.Document doc, {
    required String title,
    required List<MapEntry<String, String>> rows,
  }) {
    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => pw.Container(
          color: _blackSteel,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle(title),
              pw.SizedBox(height: 12),
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: _darkGrey,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: _softYellow, width: 0.7),
                ),
                child: pw.Column(
                  children: rows
                      .map(
                        (kv) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                color: _midGrey,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                kv.key,
                                style: pw.TextStyle(
                                  color: _lightText,
                                  fontSize: 12,
                                ),
                              ),
                              pw.Text(
                                kv.value,
                                style: pw.TextStyle(
                                  color: pdf.PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTable(
    pw.Document doc, {
    required String title,
    required List<String> headers,
    required List<List<String>> data,
  }) {
    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => pw.Container(
          color: _blackSteel,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle(title),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerDecoration: pw.BoxDecoration(color: _midGrey),
                headerStyle: pw.TextStyle(
                  color: _softYellow,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: pw.TextStyle(
                  color: pdf.PdfColors.white,
                  fontSize: 9,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerHeight: 26,
                cellHeight: 22,
                oddRowDecoration: pw.BoxDecoration(color: _darkGreyRow),
                data: <List<String>>[headers, ...data],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Total filas: ${data.length}',
                style: pw.TextStyle(color: _lightText, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================
  // 🔹 HELPERS UTILITARIOS
  // ======================

  pw.Widget _sectionTitle(String text) => pw.Row(
    children: [
      pw.Container(
        width: 6,
        height: 18,
        decoration: pw.BoxDecoration(
          color: _catYellow,
          borderRadius: pw.BorderRadius.circular(2),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(
        text,
        style: pw.TextStyle(
          color: pdf.PdfColors.white,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );

  static pdf.PdfColor _hex(String hex) {
    final clean = hex.replaceAll('#', '');
    final r = int.parse(clean.substring(0, 2), radix: 16);
    final g = int.parse(clean.substring(2, 4), radix: 16);
    final b = int.parse(clean.substring(4, 6), radix: 16);
    return pdf.PdfColor.fromInt(0xFF000000 | (r << 16) | (g << 8) | b);
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _money(dynamic v) {
    final n = (v is num) ? v.toDouble() : 0.0;
    return '\$${n.toStringAsFixed(2)}';
  }

  static String _num(dynamic v) {
    if (v == null) return '0';
    if (v is num) {
      return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
    }
    if (v is String) return v;
    return '0';
  }

  static MapEntry<String, String> _kv(String k, dynamic v) => MapEntry(k, '$v');

  static String _fileName(String base) =>
      '${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';

  Future<File> _save(pw.Document doc, {required String fileName}) async {
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return file;
  }

  String _subtitleFromData(Map<String, dynamic> data) {
    final empresa = data['empresa'] ?? 'Tracktoger';
    final fecha = data['fecha'] is DateTime
        ? _fmtDate(data['fecha'])
        : _fmtDate(DateTime.now());
    final filtro = data['filtro'] != null ? ' • Filtro: ${data['filtro']}' : '';
    return '$empresa • $fecha$filtro';
  }

  /// Agrega un mensaje cuando no hay datos
  void _addEmptyMessage(pw.Document doc, String message) {
    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => pw.Container(
          color: _blackSteel,
          padding: const pw.EdgeInsets.all(28),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 64,
                  height: 64,
                  decoration: pw.BoxDecoration(
                    color: _midGrey,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'ℹ',
                      style: pw.TextStyle(
                        color: _lightText,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  message,
                  style: pw.TextStyle(
                    color: _lightText,
                    fontSize: 16,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
