import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // 🔹 Controlador de animación
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 🔹 Fondo pasa de blanco → azul
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFF6487E4),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 🔹 Animación de aparición del logo
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // 🔹 Esperar antes de ir al Login
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Scaffold(
        backgroundColor: _colorAnimation.value,
        body: Center(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔹 Logo
                Image.asset(
                  'lib/assets/logo.png',
                  height: 140,
                ),
                const SizedBox(height: 30),
                // 🔹 Indicador de carga
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
