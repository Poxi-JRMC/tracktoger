import 'dart:io';
import 'dart:convert';

/// Utilidades para manejo de imágenes
class ImageUtils {
  /// Convierte un archivo de imagen a base64
  static Future<String> imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Convierte base64 a File (para mostrar imágenes guardadas)
  static String base64ToImageUrl(String base64String) {
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Valida que el archivo sea una imagen válida
  static bool isValidImage(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Obtiene el tamaño del archivo en MB
  static Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }
}

