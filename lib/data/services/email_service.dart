import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailService {
  static String? get _apiKey => dotenv.env['SENDGRID_API_KEY'];
  static String get _fromEmail => dotenv.env['SENDGRID_FROM_EMAIL'] ?? 'noreply@tracktoger.com';

  // Método para enviar el correo con el código de verificación
  static Future<void> sendVerificationEmail(
    String toEmail,
    String verificationCode,
  ) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      print('⚠️ SENDGRID_API_KEY no configurada en .env - no se puede enviar correo');
      throw Exception('SendGrid no configurado. Añade SENDGRID_API_KEY al .env');
    }
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'personalizations': [
        {
          'to': [
            {'email': toEmail},
          ],
          'subject': 'Verificación de correo - Tracktoger',
        },
      ],
      'from': {'email': _fromEmail},
      'content': [
        {
          'type': 'text/html',
          'value': '''
            <html>
              <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                  <div style="text-align: center; margin-bottom: 30px;">
                    <h1 style="color: #FFCD11; margin: 0;">TRACKTOGER</h1>
                    <p style="color: #666; margin: 5px 0;">Gestión Industrial</p>
                  </div>
                  
                  <h2 style="color: #333; margin-top: 0;">Verificación de Correo Electrónico</h2>
                  
                  <p style="color: #666; line-height: 1.6;">
                    ¡Bienvenido a Tracktoger! Para completar tu registro y activar tu cuenta, utiliza el siguiente código de verificación:
                  </p>
                  
                  <div style="background-color: #FFCD11; color: #000; padding: 20px; border-radius: 8px; text-align: center; margin: 30px 0;">
                    <h1 style="margin: 0; font-size: 32px; letter-spacing: 5px; font-weight: bold;">$verificationCode</h1>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="tracktoger://verify?email=${Uri.encodeComponent(toEmail)}&code=$verificationCode" 
                       style="display: inline-block; background-color: #FFCD11; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
                      Verificar en la App
                    </a>
                  </div>
                  
                  <p style="color: #666; line-height: 1.6; text-align: center; font-size: 12px;">
                    O copia el código manualmente si el botón no funciona
                  </p>
                  
                  <p style="color: #666; line-height: 1.6;">
                    Este código es válido por 30 minutos. Si no solicitaste este registro, ignora este correo.
                  </p>
                  
                  <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <p style="color: #666; margin: 0; font-size: 14px;">
                      <strong>¿Necesitas ayuda?</strong><br>
                      Si tienes problemas para verificar tu cuenta, contacta con nuestro equipo de soporte.
                    </p>
                  </div>
                  
                  <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
                  
                  <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                    © ${DateTime.now().year} Tracktoger. Todos los derechos reservados.
                  </p>
                </div>
              </body>
            </html>
          ''',
        },
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 202) {
        print('✅ Correo de verificación enviado a $toEmail');
      } else {
        print('❌ Error al enviar el correo: ${response.statusCode} - ${response.body}');
        throw Exception('Error al enviar correo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al conectar con SendGrid: $e');
      rethrow;
    }
  }

  // Método específico para enviar código de recuperación de contraseña
  static Future<void> sendPasswordRecoveryEmail(
    String toEmail,
    String recoveryCode,
  ) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      print('⚠️ SENDGRID_API_KEY no configurada - no se puede enviar correo');
      throw Exception('SendGrid no configurado. Añade SENDGRID_API_KEY al .env');
    }
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'personalizations': [
        {
          'to': [
            {'email': toEmail},
          ],
          'subject': 'Recuperación de contraseña - Tracktoger',
        },
      ],
      'from': {'email': _fromEmail},
      'content': [
        {
          'type': 'text/html',
          'value': '''
            <html>
              <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
                <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                  <div style="text-align: center; margin-bottom: 30px;">
                    <h1 style="color: #FFCD11; margin: 0;">TRACKTOGER</h1>
                    <p style="color: #666; margin: 5px 0;">Gestión Industrial</p>
                  </div>
                  
                  <h2 style="color: #333; margin-top: 0;">Recuperación de Contraseña</h2>
                  
                  <p style="color: #666; line-height: 1.6;">
                    Has solicitado recuperar tu contraseña. Utiliza el siguiente código para restablecerla:
                  </p>
                  
                  <div style="background-color: #FFCD11; color: #000; padding: 20px; border-radius: 8px; text-align: center; margin: 30px 0;">
                    <h1 style="margin: 0; font-size: 32px; letter-spacing: 5px; font-weight: bold;">$recoveryCode</h1>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="tracktoger://reset-password?email=${Uri.encodeComponent(toEmail)}&code=$recoveryCode" 
                       style="display: inline-block; background-color: #FFCD11; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
                      Restablecer en la App
                    </a>
                  </div>
                  
                  <p style="color: #666; line-height: 1.6; text-align: center; font-size: 12px;">
                    O copia el código manualmente si el botón no funciona
                  </p>
                  
                  <p style="color: #666; line-height: 1.6;">
                    Este código es válido por 30 minutos. Si no solicitaste este cambio, ignora este correo.
                  </p>
                  
                  <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
                  
                  <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
                    © ${DateTime.now().year} Tracktoger. Todos los derechos reservados.
                  </p>
                </div>
              </body>
            </html>
          ''',
        },
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 202) {
        print('✅ Correo de recuperación enviado a $toEmail');
      } else {
        print('❌ Error al enviar correo de recuperación: ${response.statusCode} - ${response.body}');
        throw Exception('Error al enviar correo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al conectar con SendGrid: $e');
      rethrow;
    }
  }
}
