import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PdfHelpers {
  /// Guarda bytes en un archivo y devuelve la ruta.
  static Future<String> savePdf(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Abre el archivo nativo (Android/iOS/desktop). En web usa el visor de printing.
  static Future<void> openOrShare(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } else {
      final path = await savePdf(bytes, filename);
      await OpenFilex.open(path);
    }
  }
}
