import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class UsuariosTemplate {
  static pw.Widget build(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>? ?? [];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '👤 Reporte de Usuarios del Sistema',
          style: pw.TextStyle(
            color: PdfColors.amberAccent,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Listado de usuarios registrados, roles y correos de acceso.',
          style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: const ['Nombre', 'Rol', 'Correo', 'Teléfono', 'Estado'],
          data: items.map((e) {
            return [
              '${e['nombre'] ?? '-'}',
              '${e['rol'] ?? '-'}',
              '${e['correo'] ?? '-'}',
              '${e['telefono'] ?? '-'}',
              '${e['estado'] ?? '-'}',
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            color: PdfColors.amberAccent,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.5),
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Usuarios registrados: ${items.length}',
          style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
        ),
      ],
    );
  }
}
