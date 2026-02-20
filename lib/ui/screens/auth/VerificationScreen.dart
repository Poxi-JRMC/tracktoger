import 'package:flutter/material.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/data/services/email_service.dart'; // Asegúrate de tener la importación correcta
import 'package:tracktoger/models/usuario.dart';
import 'package:tracktoger/services/app_link_service.dart';

class VerificationScreen extends StatefulWidget {
  final String verificationCode; // Código de verificación esperado
  final String userEmail; // Correo del usuario
  final String userId; // ID del usuario en la BD

  const VerificationScreen({
    super.key,
    required this.verificationCode,
    required this.userEmail,
    required this.userId,
  });

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController codeController = TextEditingController();
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Configurar callback para recibir links de verificación
    AppLinkService().setVerificationCallback(_handleVerificationLink);
    
    // Verificar si hay un link inicial pendiente
    _checkInitialLink();
  }

  /// Verifica si hay un link inicial que abrió la app
  Future<void> _checkInitialLink() async {
    final initialLink = AppLinkService().getInitialLink();
    if (initialLink != null) {
      // Procesar el link después de un pequeño delay para asegurar que la UI esté lista
      Future.delayed(const Duration(milliseconds: 300), () {
        _processLink(initialLink);
      });
    }
  }

  /// Maneja links de verificación recibidos desde app_links
  void _handleVerificationLink(String email, String code) {
    // Verificar que el email coincida con el usuario actual
    if (email.toLowerCase() == widget.userEmail.toLowerCase()) {
      // Auto-completar el código y verificar
      codeController.text = code;
      handleVerificacion(code);
    } else {
      // Si el email no coincide, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace de verificación no corresponde a este usuario'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Procesa un link URI directamente
  void _processLink(Uri uri) {
    final queryParams = uri.queryParameters;
    final email = queryParams['email'];
    final code = queryParams['code'];
    
    if (email != null && code != null) {
      _handleVerificationLink(Uri.decodeComponent(email), code);
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  // Método que maneja la validación del código ingresado
  Future<void> handleVerificacion(String codigoIngresado) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      // Delegar la verificación a ControlUsuario para mantener la lógica en un único lugar
      final Usuario? usuarioVerificado = await ControlUsuario().verificarCodigo(
        widget.userEmail,
        codigoIngresado,
      );

      if (usuarioVerificado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario verificado correctamente')),
        );

        // Devolver el usuario verificado al push anterior
        Navigator.of(context).pop(usuarioVerificado);
      } else {
        setState(() {
          errorMessage = "Código de verificación incorrecto";
        });
      }
    } catch (e) {
      // Capturar cualquier excepción y mostrarla
      setState(() {
        errorMessage = 'Error durante la verificación: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // Método que simula la validación del código de verificación
  Future<bool> validarCodigoVerificacion(String codigoIngresado) async {
    // Esta función queda por compatibilidad; la verificación principal
    // se realiza vía ControlUsuario.verificarCodigo desde handleVerificacion.
    final usuario = await ControlUsuario().consultarUsuario(widget.userId);
    if (usuario != null) {
      return usuario.codigoVerificacion == codigoIngresado;
    }
    return false;
  }

  // Método para reenviar el código de verificación
  Future<void> reenviarCodigo() async {
    setState(() {
      loading = true;
    });

    try {
      // Enviar el código de verificación por correo al usuario
      await EmailService.sendVerificationEmail(
        widget.userEmail,
        widget.verificationCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código de verificación enviado nuevamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el código. Inténtalo de nuevo.'),
        ),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verificación de correo"),
        backgroundColor: const Color(0xFF1B1B1B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Introduce el código enviado a tu correo electrónico.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Código de verificación",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      handleVerificacion(codeController.text);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCD11),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Verificar"),
            ),
            const SizedBox(height: 20),
            // Botón para reenviar el código
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      reenviarCodigo(); // Llamar a la función de reenvío de código
                    },
              child: const Text(
                "Volver a enviar código",
                style: TextStyle(color: Color(0xFFFFCD11)),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF101010),
    );
  }
}
