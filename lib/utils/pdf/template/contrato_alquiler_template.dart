import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import '../../../models/alquiler.dart';
import '../../../models/cliente.dart';
import '../../../models/maquinaria.dart';

class ContratoAlquilerTemplate {
  // Datos de la empresa
  static String get nombreEmpresa => 'Raul Juan Mamani';
  static String get numeroIdentidad => '12345678'; // Número de identidad aleatorio
  static String get direccionEmpresa => 'Av. Principal 123, Ciudad';
  static String get telefonoEmpresa => '+51 999 999 999';
  static String get emailEmpresa => 'contacto@rauljuanmamani.com';

  static pw.Widget build({
    required Alquiler alquiler,
    required Cliente cliente,
    required Maquinaria maquinaria,
    bool mostrarMonto = true,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Encabezado profesional
          _buildHeader(),
          pw.SizedBox(height: 30),
          
          // Título del contrato
          pw.Center(
            child: pw.Text(
              'CONTRATO DE ALQUILER DE MAQUINARIA PESADA',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: pdf.PdfColors.black,
                letterSpacing: 1.2,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'N° ${alquiler.id.substring(0, 8).toUpperCase()}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: pdf.PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Preámbulo
          pw.Paragraph(
            text: 'Por medio del presente documento, ${nombreEmpresa}, identificado con DNI N° $numeroIdentidad, '
            'en adelante denominado "EL ARRENDADOR", y ${cliente.nombreCompleto}, '
            '${cliente.documentoIdentidad != null ? "identificado con DNI N° ${cliente.documentoIdentidad}, " : ""}'
            'en adelante denominado "EL ARRENDATARIO", acuerdan celebrar el presente contrato de alquiler '
            'de maquinaria pesada, sujeto a las siguientes cláusulas y condiciones:',
            style: const pw.TextStyle(fontSize: 11, height: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 30),
          
          // Cláusula 1: Datos de las partes
          _buildClausula(
            'CLÁUSULA PRIMERA: DATOS DE LAS PARTES',
            [
              _buildSubsection('A) EL ARRENDADOR:', [
                _buildRow('Nombre:', nombreEmpresa),
                _buildRow('DNI:', numeroIdentidad),
                _buildRow('Dirección:', direccionEmpresa),
                _buildRow('Teléfono:', telefonoEmpresa),
                _buildRow('Email:', emailEmpresa),
              ]),
              pw.SizedBox(height: 10),
              _buildSubsection('B) EL ARRENDATARIO:', [
                _buildRow('Nombre:', cliente.nombreCompleto),
                if (cliente.documentoIdentidad != null)
                  _buildRow('DNI:', cliente.documentoIdentidad!),
                _buildRow('Email:', cliente.email),
                _buildRow('Teléfono:', cliente.telefono),
                if (cliente.direccion != null)
                  _buildRow('Dirección:', cliente.direccion!),
                if (cliente.empresa != null)
                  _buildRow('Empresa:', cliente.empresa!),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Cláusula 2: Objeto del contrato
          _buildClausula(
            'CLÁUSULA SEGUNDA: OBJETO DEL CONTRATO',
            [
              pw.Text(
                'EL ARRENDADOR se obliga a entregar en alquiler a EL ARRENDATARIO la siguiente maquinaria pesada:',
                style: const pw.TextStyle(fontSize: 11, height: 1.5),
              ),
              pw.SizedBox(height: 10),
              _buildSubsection('DATOS DE LA MAQUINARIA:', [
                _buildRow('Nombre:', maquinaria.nombre),
                if (maquinaria.apodo != null)
                  _buildRow('Apodo:', maquinaria.apodo!),
                _buildRow('Marca:', maquinaria.marca),
                _buildRow('Modelo:', maquinaria.modelo),
                _buildRow('Número de Serie:', maquinaria.numeroSerie),
                if (maquinaria.ubicacion != null)
                  _buildRow('Ubicación:', maquinaria.ubicacion!),
              ]),
              if (maquinaria.especificaciones.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Especificaciones Técnicas:',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                ...maquinaria.especificaciones.entries.map((entry) {
                  return _buildRow(
                    entry.key.replaceAll('_', ' ').toUpperCase() + ':',
                    entry.value.toString(),
                  );
                }).toList(),
              ],
              if (alquiler.especificaciones != null && alquiler.especificaciones!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Especificaciones del Contrato:',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                ...alquiler.especificaciones!.entries.map((entry) {
                  return _buildRow(
                    entry.key.replaceAll('_', ' ').toUpperCase() + ':',
                    entry.value.toString(),
                  );
                }).toList(),
              ],
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Cláusula 3: Términos del alquiler
          _buildClausula(
            'CLÁUSULA TERCERA: TÉRMINOS DEL ALQUILER',
            [
              _buildRow('Fecha de Inicio:', _formatDate(alquiler.fechaInicio)),
              _buildRow('Fecha de Fin:', _formatDate(alquiler.fechaFin)),
              _buildRow(
                'Duración:',
                alquiler.tipoAlquiler == 'horas'
                    ? '${alquiler.horasAlquiler} horas'
                    : '${alquiler.horasAlquiler} meses',
              ),
              _buildRow(
                'Tipo de Alquiler:',
                alquiler.tipoAlquiler == 'horas' ? 'Por Horas' : 'Por Meses',
              ),
              if (alquiler.proyecto != null)
                _buildRow('Proyecto:', alquiler.proyecto!),
              if (alquiler.ubicacion != null)
                _buildRow('Ubicación del Proyecto:', alquiler.ubicacion!),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Cláusula 4: Monto y forma de pago
          if (mostrarMonto)
            _buildClausula(
              'CLÁUSULA CUARTA: MONTO Y FORMA DE PAGO',
              [
                _buildRow('Monto Total del Alquiler:', '\$${alquiler.monto.toStringAsFixed(2)}'),
                if (alquiler.montoAdelanto != null)
                  _buildRow('Monto Adelantado:', '\$${alquiler.montoAdelanto!.toStringAsFixed(2)}'),
                if (alquiler.montoCancelado != null) ...[
                  _buildRow('Monto Total Cancelado:', '\$${alquiler.montoCancelado!.toStringAsFixed(2)}'),
                  _buildRow(
                    'Monto a Deuda:',
                    '\$${(alquiler.monto - alquiler.montoCancelado!).toStringAsFixed(2)}',
                  ),
                ] else if (alquiler.montoAdelanto != null) ...[
                  _buildRow(
                    'Saldo Pendiente:',
                    '\$${(alquiler.monto - alquiler.montoAdelanto!).toStringAsFixed(2)}',
                  ),
                ],
                if (alquiler.metodoPago != null) ...[
                  pw.SizedBox(height: 8),
                  _buildRow(
                    'Método de Pago:',
                    alquiler.metodoPago == 'qr'
                        ? 'QR'
                        : alquiler.metodoPago == 'efectivo'
                            ? 'Efectivo'
                            : alquiler.metodoPago == 'transferencia'
                                ? 'Transferencia'
                                : alquiler.metodoPago == 'tarjeta'
                                    ? 'Tarjeta'
                                    : alquiler.metodoPago!.toUpperCase(),
                  ),
                ],
                pw.SizedBox(height: 10),
                if (alquiler.montoCancelado != null && alquiler.montoCancelado! >= alquiler.monto) ...[
                  pw.Paragraph(
                    text: 'EL ARRENDATARIO ha cancelado el monto total del alquiler. El contrato está completamente pagado.',
                    style: pw.TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: pw.FontWeight.bold,
                      color: pdf.PdfColors.green700,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ] else if (alquiler.montoCancelado != null && alquiler.montoCancelado! > 0) ...[
                  pw.Paragraph(
                    text: 'EL ARRENDATARIO ha cancelado un monto de \$${alquiler.montoCancelado!.toStringAsFixed(2)}. '
                    'El saldo pendiente de \$${(alquiler.monto - alquiler.montoCancelado!).toStringAsFixed(2)} '
                    'deberá ser cancelado según los términos acordados.',
                    style: const pw.TextStyle(fontSize: 11, height: 1.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                ] else if (alquiler.montoAdelanto != null) ...[
                  pw.Paragraph(
                    text: 'EL ARRENDATARIO ha realizado un pago adelantado de \$${alquiler.montoAdelanto!.toStringAsFixed(2)}. '
                    'El saldo pendiente deberá ser cancelado según los términos acordados.',
                    style: const pw.TextStyle(fontSize: 11, height: 1.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                ] else ...[
                  pw.Paragraph(
                    text: 'EL ARRENDATARIO se compromete a cancelar el monto total de \$${alquiler.monto.toStringAsFixed(2)} '
                    'según los términos acordados entre las partes.',
                    style: const pw.TextStyle(fontSize: 11, height: 1.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ],
            ),
          if (mostrarMonto) pw.SizedBox(height: 20),
          
          // Cláusula 5: Observaciones
          if (alquiler.observaciones != null && alquiler.observaciones!.isNotEmpty) ...[
              _buildClausula(
              'CLÁUSULA QUINTA: OBSERVACIONES Y CONDICIONES ESPECIALES',
              [
                pw.Paragraph(
                  text: alquiler.observaciones!,
                  style: const pw.TextStyle(fontSize: 11, height: 1.5),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
          
          // Cláusula final
          _buildClausula(
            'CLÁUSULA FINAL',
            [
              pw.Paragraph(
                text: 'Las partes declaran haber leído y entendido todas las cláusulas del presente contrato, '
                'y se comprometen a cumplir con todas las obligaciones establecidas. '
                'Este contrato tiene carácter legal y es válido desde la fecha de firma.',
                style: const pw.TextStyle(fontSize: 11, height: 1.5),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Fecha de Registro: ${_formatDate(alquiler.fechaRegistro)}',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
          
          pw.SizedBox(height: 40),
          
          // Firmas
          _buildFirmas(cliente),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pdf.PdfColors.black, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                nombreEmpresa.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'DNI: $numeroIdentidad',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                direccionEmpresa,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Tel: $telefonoEmpresa | Email: $emailEmpresa',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClausula(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pdf.PdfColors.grey700, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildSubsection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...children,
      ],
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFirmas(Cliente cliente) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pdf.PdfColors.black, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'FIRMAS DE LAS PARTES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: pdf.PdfColors.black, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'FIRMA DEL CLIENTE\n(ARRENDATARIO)',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        cliente.nombreCompleto,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    if (cliente.documentoIdentidad != null)
                      pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'DNI: ${cliente.documentoIdentidad}',
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: pdf.PdfColors.black, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'FIRMA DEL ARRENDADOR',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        nombreEmpresa,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'DNI: $numeroIdentidad',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: pdf.PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Paragraph(
              text: 'Este documento es válido para efectos legales y comerciales. '
              'Las firmas aquí consignadas confirman la aceptación de todas las cláusulas del presente contrato.',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: pdf.PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${meses[date.month - 1]} de ${date.year}';
  }
}
