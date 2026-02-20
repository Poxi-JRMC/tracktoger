import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracktoger/ui/screens/splash/splash_screen.dart'; // 👈 Cambia la ruta si tu Splash está en otra carpeta

class LogoAnimation extends StatefulWidget {
  const LogoAnimation({super.key});

  @override
  State<LogoAnimation> createState() => _LogoAnimationState();
}

class _LogoAnimationState extends State<LogoAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  late final AnimationController _sparkController;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();

    // 🎬 Controlador principal del logo
    _mainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<double>(begin: -40, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    // ✨ Vibración tipo chispa
    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // 🔘 Controlador de puntos secuenciales
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // ⏱️ Transición automática al SplashScreen
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SplashScreen(onComplete: () {})),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ⚙️ LOGO PRINCIPAL ANIMADO
              AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _sparkController,
                ]),
                builder: (context, child) {
                  final vibration =
                      sin(_sparkController.value * 2 * pi) * 2; // chispa ligera
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value + vibration),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Aro metálico externo
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFB8860B),
                                Color(0xFFFFD700),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),

                        // Engranaje central rotando
                        Transform.rotate(
                          angle: _mainController.value * 2 * pi,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.construction,
                              color: Colors.black,
                              size: 60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // 🟡 TÍTULO METÁLICO “TRACKTOGER”
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFFE866),
                    Color(0xFFFFD700),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  "TRACKTOGER",
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.yellow.withOpacity(0.5),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Subtítulo
              Text(
                "Gestión y mantenimiento inteligente",
                style: GoogleFonts.robotoCondensed(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),

              const SizedBox(height: 35),

              // 🔸 PUNTOS DE CARGA
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _dotController,
                    builder: (context, child) {
                      double progress = (_dotController.value * 3) % 3;
                      double opacity = (progress - i).abs() < 0.5
                          ? 1.0
                          : 0.3; // secuencia
                      double size = (progress - i).abs() < 0.5 ? 14 : 10;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(opacity),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFD700,
                              ).withOpacity(opacity),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
