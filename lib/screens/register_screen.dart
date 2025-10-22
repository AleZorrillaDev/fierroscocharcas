import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _numero = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 🔹 Guardar datos en Cloud Firestore (en lugar de Realtime Database)
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nombre.text.trim(),
        'email': _email.text.trim(),
        'numero': _numero.text.trim(),
        'rol': 'cliente',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Correo ya registrado.',
        'weak-password' => 'Contraseña débil.',
        'invalid-email' => 'Correo inválido.',
        _ => 'Error al registrar usuario.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('lib/assets/logo.png', height: 100),
                const SizedBox(height: 20),
                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6487E4),
                  ),
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: _nombre,
                  decoration: _input('Nombre completo', Icons.person_outline),
                  validator: (v) =>
                      v!.isEmpty ? 'Ingrese su nombre completo' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: _input('Correo electrónico', Icons.email_outlined),
                  validator: (v) => v!.isEmpty
                      ? 'Ingrese su correo'
                      : (!v.contains('@')
                          ? 'Correo inválido'
                          : null),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numero,
                  keyboardType: TextInputType.phone,
                  decoration: _input('Número de celular', Icons.phone_android),
                  validator: (v) =>
                      v!.length < 9 ? 'Número no válido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: _input('Contraseña', Icons.lock_outline),
                  validator: (v) =>
                      v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6487E4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'REGISTRARSE',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: '¿Ya tienes una cuenta? ',
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: 'Acceder',
                          style: TextStyle(
                            color: Color(0xFF6487E4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}
