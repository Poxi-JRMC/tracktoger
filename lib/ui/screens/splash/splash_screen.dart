import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _gearController;
  late final AnimationController _pistonController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // ⏳ Duración antes de pasar al login
    Future.delayed(const Duration(seconds: 5), widget.onComplete);

    // ⚙️ Rotación de engranaje
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 🧱 Movimiento del pistón (arriba / abajo)
    _pistonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 🌫️ Fade general
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _gearController.dispose();
    _pistonController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 🔶 Blueprint dorado de fondo
            CustomPaint(painter: _BlueprintPainter()),

            // 🌫️ Efecto polvo / energía
            Positioned(
              bottom: 0,
              child: Container(
                width: size.width,
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            // ⚙️ Logo animado central
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _gearController,
                  _pistonController,
                ]),
                builder: (context, _) {
                  double rotation = _gearController.value * 2 * pi;
                  double pistonOffset = sin(_pistonController.value * pi) * 15;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Aro metálico exterior
                      Container(
                        width: 180,
                        height: 180,
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
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),

                      // Engranaje girando
                      Transform.rotate(
                        angle: rotation,
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: _GearPainter(),
                        ),
                      ),

                      // Pistón móvil central
                      Transform.translate(
                        offset: Offset(0, pistonOffset),
                        child: Container(
                          width: 45,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.construction,
                            color: Colors.black,
                            size: 38,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 🟡 Texto principal
            Positioned(
              bottom: size.height * 0.28,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    "TRACKTOGER",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Color(0xFFFFD700), blurRadius: 20),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Preparando maquinaria inteligente...",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // 🔸 Puntos de carga inferiores
            Positioned(bottom: 60, left: 0, right: 0, child: _LoadingDots()),
          ],
        ),
      ),
    );
  }
}

// 🔩 Engranaje dinámico (dientes de acero dorado)
class _GearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final center = Offset(size.width / 2, size.height / 2);
    const teeth = 12;
    const innerRadius = 35.0;
    const outerRadius = 50.0;

    for (int i = 0; i < teeth; i++) {
      double angle = (2 * pi / teeth) * i;
      final p1 = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }

    canvas.drawCircle(center, 25, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 🟢 Puntos de carga animados
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double progress = (_controller.value * 3) % 3;
            double opacity = (progress - i).abs() < 0.5 ? 1.0 : 0.3;
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
                    color: const Color(0xFFFFD700).withOpacity(opacity),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

// 🔷 Líneas diagonales tipo blueprint
class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double i = -size.height; i < size.width * 2; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
