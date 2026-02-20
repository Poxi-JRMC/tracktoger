import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracktoger/controllers/control_usuario.dart'; // Asegúrate de importar ControlUsuario
import 'package:tracktoger/models/usuario.dart'; // Asegúrate de importar el modelo de Usuario
// email_service no se usa aquí; el envío lo hace ControlUsuario
import 'VerificationScreen.dart'; // Pantalla para ingresar el código de verificación
import 'package:tracktoger/core/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onShowLogin;

  const RegisterScreen({
    Key? key,
    required this.onRegister,
    required this.onShowLogin,
  }) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool loading = false;
  bool obscurePass = true;

  // ⚙️ Rol por defecto = operador (automático)
  final String selectedRole = "operator";

  // Validación de contraseña
  bool get _tieneMinimo8Caracteres => passwordController.text.length >= 8;
  bool get _tieneMayuscula => passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _tieneMinuscula => passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _tieneNumero => passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _tieneCaracterEspecial => passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get _passwordEsValida =>
      _tieneMinimo8Caracteres &&
      _tieneMayuscula &&
      _tieneMinuscula &&
      _tieneNumero &&
      _tieneCaracterEspecial;

  bool get isFormValid =>
      nameController.text.isNotEmpty &&
      lastNameController.text.isNotEmpty &&
      emailController.text.isNotEmpty &&
      _passwordEsValida;

  // Ahora la generación y envío del código lo hace ControlUsuario (server-side flow)

  Future<void> handleRegister() async {
    HapticFeedback.lightImpact();

    // Validar contraseña antes de proceder
    if (!_passwordEsValida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña no cumple con los requisitos de seguridad'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Crear usuario a partir de los datos ingresados en el formulario
      final usuario = Usuario(
        id: '', // ID se genera en MongoDB automáticamente
        nombre: nameController.text,
        apellido: lastNameController.text.trim(),
        email: emailController.text,
        telefono: phoneController.text,
        fechaRegistro: DateTime.now(),
        activo: false, // Usuario no verificado aún
        roles: ['operator'], // Rol de usuario por defecto
        password: passwordController.text,
      );

      // Registrar usuario usando ControlUsuario (retorna código y id)
      final result = await ControlUsuario().registrarUsuario(usuario);
      String verificationCode = result['code'] ?? '';
      String userId = result['id'] ?? '';

      // Simular un pequeño retraso (por ejemplo, si estuvieras esperando respuesta de la DB)
      await Future.delayed(const Duration(seconds: 1));

      setState(() => loading = false);

      // Ir a la pantalla de verificación pasando email y id.
      // Esperamos el resultado: la VerificationScreen devolverá el Usuario verificado
      if (mounted) {
        final verifiedUser = await Navigator.push<Usuario?>(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              verificationCode: verificationCode,
              userEmail: usuario.email,
              userId: userId,
            ),
          ),
        );

        if (verifiedUser != null) {
          // Asegurar que AuthService tenga el usuario actual (por si ControlUsuario no lo hizo)
          AuthService.actualizarUsuario(verifiedUser);

          // Notificar que el usuario ya está listo para entrar
          widget.onRegister();
        }
      }
    } catch (e) {
      // Manejar errores
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E0E), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Color(0xFFFFCD11), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.engineering,
                    color: Color(0xFFFFCD11),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "TRACKTOGER",
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFCD11),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Crear nueva cuenta",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFFFCD11), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.badge,
                            color: Color(0xFFFFCD11),
                          ),
                          hintText: "Nombre",
                          hintStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFCD11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: lastNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFFFFCD11),
                          ),
                          hintText: "Apellido",
                          hintStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFCD11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFFFFCD11),
                          ),
                          hintText: "Número de teléfono",
                          hintStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFCD11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFFFFCD11),
                          ),
                          hintText: "tu@email.com",
                          hintStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFCD11),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFCD11),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePass,
                        onChanged: (_) => setState(() {}), // Actualizar UI en tiempo real
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFFFFCD11),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFFFFCD11),
                            ),
                            onPressed: () =>
                                setState(() => obscurePass = !obscurePass),
                          ),
                          hintText: "Contraseña",
                          hintStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _passwordEsValida || passwordController.text.isEmpty
                                  ? const Color(0xFFFFCD11)
                                  : Colors.red,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _passwordEsValida || passwordController.text.isEmpty
                                  ? const Color(0xFFFFCD11)
                                  : Colors.red,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Indicador de requisitos de contraseña
                      if (passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildPasswordRequirements(),
                      ],
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: isFormValid ? handleRegister : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCD11),
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: Colors.yellow.withOpacity(0.5),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "CREAR CUENTA",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: widget.onShowLogin,
                        child: const Text(
                          "¿Ya tienes cuenta? Inicia sesión",
                          style: TextStyle(
                            color: Color(0xFFFFCD11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget que muestra los requisitos de la contraseña con indicadores visuales
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _passwordEsValida ? Colors.green : const Color(0xFFFFCD11),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'Al menos 8 caracteres',
            _tieneMinimo8Caracteres,
          ),
          _buildRequirementItem(
            'Una letra mayúscula',
            _tieneMayuscula,
          ),
          _buildRequirementItem(
            'Una letra minúscula',
            _tieneMinuscula,
          ),
          _buildRequirementItem(
            'Un número',
            _tieneNumero,
          ),
          _buildRequirementItem(
            'Un carácter especial (!@#\$%^&*)',
            _tieneCaracterEspecial,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid ? Colors.green : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isValid ? Colors.green.shade300 : Colors.grey.shade400,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
