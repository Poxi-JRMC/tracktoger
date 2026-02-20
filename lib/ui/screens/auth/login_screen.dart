import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracktoger/controllers/control_usuario.dart';
import 'package:tracktoger/core/auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onShowRegister;

  const LoginScreen({
    Key? key,
    required this.onLogin,
    required this.onShowRegister,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool canLogin = false;
  bool rememberMe = false;
  bool obscurePass = true;

  @override
  void initState() {
    super.initState();
    emailController.addListener(checkInput);
    passwordController.addListener(checkInput);
    _cargarCredencialesGuardadas();
  }

  /// Carga las credenciales guardadas si "Recuérdame" estaba activo
  Future<void> _cargarCredencialesGuardadas() async {
    try {
      final credenciales = await AuthService.cargarCredenciales();
      if (credenciales['rememberMe'] == 'true' &&
          credenciales['email'] != null &&
          credenciales['password'] != null) {
        setState(() {
          emailController.text = credenciales['email']!;
          passwordController.text = credenciales['password']!;
          rememberMe = true;
          canLogin = true;
        });
        print('✅ Credenciales cargadas automáticamente');
      }
    } catch (e) {
      print('⚠️ Error al cargar credenciales: $e');
    }
  }

  void checkInput() {
    setState(() {
      canLogin =
          emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  Future<void> handleLogin() async {
    HapticFeedback.lightImpact();
    setState(() => loading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final usuario = await ControlUsuario().autenticarUsuario(email, password);
      if (usuario != null) {
        // Establecer usuario actual en el servicio de auth
        AuthService.actualizarUsuario(usuario);
        print(
          'LoginScreen: autenticación OK -> usuario=${usuario.email}, id=${usuario.id}',
        );

        // Guardar o eliminar credenciales según "Recuérdame"
        if (rememberMe) {
          await AuthService.guardarCredenciales(email, password);
          print('✅ Credenciales guardadas para próxima sesión');
        } else {
          await AuthService.eliminarCredenciales();
          print('✅ Credenciales no guardadas (Recuérdame desactivado)');
        }

        widget.onLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas o usuario no verificado'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
                // 🟡 Logo industrial
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
                    Icons.construction,
                    color: Color(0xFFFFCD11),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),

                // 🟡 Título
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
                  "Gestión y mantenimiento de maquinaria",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),

                // 🟢 Tarjeta de login
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
                      // 🟡 Campo email
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFFFFCD11),
                          ),
                          hintText: "Correo electrónico",
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

                      // 🟡 Campo contraseña con mostrar/ocultar
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePass,
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
                      const SizedBox(height: 10),

                      // 🔘 Recordarme + Olvidé contraseña
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                activeColor: const Color(0xFFFFCD11),
                                onChanged: (v) async {
                                  setState(() => rememberMe = v!);
                                  // Si se desactiva "Recuérdame", eliminar credenciales guardadas
                                  if (!v!) {
                                    await AuthService.eliminarCredenciales();
                                    print('✅ "Recuérdame" desactivado - credenciales eliminadas');
                                  }
                                },
                              ),
                              const Text(
                                "Recordarme",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    onBackToLogin: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(
                                color: Color(0xFFFFCD11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🟡 Botón Iniciar sesión
                      ElevatedButton(
                        onPressed: canLogin ? handleLogin : null,
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
                                "INICIAR SESIÓN",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),

                      // 🔹 Registrar cuenta
                      TextButton(
                        onPressed: widget.onShowRegister,
                        child: const Text(
                          "¿No tienes cuenta? Regístrate",
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
}
