import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart'; // 🔥 1. IMPORTANTE: Importamos la configuración generada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 2. IMPORTANTE: Le decimos a Firebase qué opciones usar según la plataforma (Web/Android)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
    
    runApp(const FierrosCocharcasApp());
  } catch (e) {
    debugPrint('❌ Error al inicializar Firebase: $e');
    runApp(const FirebaseErrorApp());
  }
}

/// 🔹 App principal
class FierrosCocharcasApp extends StatelessWidget {
  const FierrosCocharcasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fierros Cocharcas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF6487E4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6487E4),
          secondary: const Color(0xFFF9F888),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// 🚨 App alternativa si Firebase falla al iniciar
class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.redAccent.shade100,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error_outline, color: Colors.white, size: 80),
                SizedBox(height: 16),
                Text(
                  'Error al conectar con Firebase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Verifica tu conexión o la configuración web',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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