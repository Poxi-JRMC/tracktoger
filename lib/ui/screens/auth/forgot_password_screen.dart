import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/services/app_link_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const ForgotPasswordScreen({Key? key, required this.onBackToLogin})
    : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool showCodeInput = false;
  bool obscurePass = true;
  bool obscureConfirm = true;
  String? currentEmail;

  @override
  void initState() {
    super.initState();
    // Configurar callback para recibir links de recuperación de contraseña
    AppLinkService().setPasswordResetCallback(_handlePasswordResetLink);
    
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

  /// Maneja links de recuperación de contraseña recibidos desde app_links
  void _handlePasswordResetLink(String email, String code) {
    // Verificar que el email coincida con el email ingresado (si ya se ingresó)
    if (currentEmail != null && email.toLowerCase() == currentEmail!.toLowerCase()) {
      // Auto-completar el código y mostrar campos de contraseña
      codeController.text = code;
      if (!showCodeInput) {
        setState(() {
          showCodeInput = true;
        });
      }
      // Mostrar mensaje informativo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de recuperación detectado. Completa tu nueva contraseña.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (currentEmail == null) {
      // Si no se ha ingresado email, establecerlo y mostrar campos
      setState(() {
        emailController.text = email;
        currentEmail = email.toLowerCase();
        codeController.text = code;
        showCodeInput = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de recuperación detectado. Completa tu nueva contraseña.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Si el email no coincide, mostrar mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace de recuperación no corresponde al email ingresado'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
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
      _handlePasswordResetLink(Uri.decodeComponent(email), code);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Paso 1: Enviar código de verificación al email
  Future<void> _enviarCodigoRecuperacion() async {
    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      _mostrarError('Por favor ingresa tu correo electrónico');
      return;
    }

    // Validar formato de email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _mostrarError('Por favor ingresa un correo electrónico válido');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => loading = true);
    try {
      final emailNormalized = email.toLowerCase();

      // Llamar al controlador para enviar código
      await ControlUsuario().enviarCodigoRecuperacion(emailNormalized);

      currentEmail = emailNormalized;
      setState(() => showCodeInput = true);

      _mostrarExito('Código de verificación enviado a $emailNormalized');
    } catch (e) {
      String mensajeError = 'Error al enviar código';
      if (e.toString().contains('No existe usuario')) {
        mensajeError = 'No existe un usuario registrado con ese correo electrónico';
      } else if (e.toString().contains('Error al enviar correo')) {
        mensajeError = 'Error al enviar el correo. Por favor intenta más tarde.';
      } else {
        mensajeError = 'Error: $e';
      }
      _mostrarError(mensajeError);
    } finally {
      setState(() => loading = false);
    }
  }

  /// Paso 2: Verificar código y permitir cambiar contraseña
  Future<void> _verificarCodigoYCambiarPassword() async {
    if (codeController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa el código de verificación');
      return;
    }

    if (passwordController.text.isEmpty) {
      _mostrarError('Por favor ingresa la nueva contraseña');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }

    if (passwordController.text.length < 8) {
      _mostrarError('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    // Validar que la contraseña tenga al menos una letra y un número
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)');
    if (!passwordRegex.hasMatch(passwordController.text)) {
      _mostrarError('La contraseña debe contener al menos una letra y un número');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => loading = true);
    try {
      final code = codeController.text.trim();
      final newPassword = passwordController.text;

      // Llamar al controlador para recuperar contraseña
      await ControlUsuario().recuperarPassword(
        currentEmail!,
        code,
        newPassword,
      );

      _mostrarExito('Contraseña actualizada correctamente');

      // Volver a login después de 1.5 segundos
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onBackToLogin();
      });
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => widget.onBackToLogin(),
        ),
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              showCodeInput
                  ? 'Ingresa el código y tu nueva contraseña'
                  : 'Ingresa tu correo para recibir el código de recuperación',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Campo de Email
            if (!showCodeInput)
              _buildEmailField()
            else ...[
              // Código de verificación
              _buildCodeField(),
              const SizedBox(height: 16),
              // Nueva contraseña
              _buildPasswordField(),
              const SizedBox(height: 16),
              // Confirmar contraseña
              _buildConfirmPasswordField(),
            ],

            const SizedBox(height: 32),

            // Botón de acción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : (showCodeInput
                          ? () => _verificarCodigoYCambiarPassword()
                          : () => _enviarCodigoRecuperacion()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCD11),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : Text(
                        showCodeInput ? 'Cambiar Contraseña' : 'Enviar Código',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            if (showCodeInput) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            showCodeInput = false;
                            codeController.clear();
                            passwordController.clear();
                            confirmPasswordController.clear();
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFCD11)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Usar otro email',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFFCD11),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      enabled: !loading,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'correo@ejemplo.com',
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: const Icon(Icons.email, color: Color(0xFFFFCD11)),
        filled: true,
        fillColor: const Color(0xFF2E2E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCD11)),
        ),
      ),
    );
  }

  Widget _buildCodeField() {
    return TextField(
      controller: codeController,
      enabled: !loading,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCD11)),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF2E2E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCD11)),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      enabled: !loading,
      obscureText: obscurePass,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Nueva contraseña',
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCD11)),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePass ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFFFFCD11),
          ),
          onPressed: () => setState(() => obscurePass = !obscurePass),
        ),
        filled: true,
        fillColor: const Color(0xFF2E2E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCD11)),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: confirmPasswordController,
      enabled: !loading,
      obscureText: obscureConfirm,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Confirmar contraseña',
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCD11)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureConfirm ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFFFFCD11),
          ),
          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
        ),
        filled: true,
        fillColor: const Color(0xFF2E2E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCD11)),
        ),
      ),
    );
  }
}
