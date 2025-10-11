import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool cargando = false;

  Future<void> registrar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => cargando = true);

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correoCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final ref = FirebaseDatabase.instance.ref('usuarios/${cred.user!.uid}');
      await ref.set({
        'nombre': nombreCtrl.text.trim(),
        'correo': correoCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        'uid': cred.user!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada correctamente 🎉')));
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error en el registro')));
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Crea una cuenta',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Completa los campos necesarios',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: correoCtrl,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obligatorio';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.length < 9 ? 'Número no válido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirmar contraseña'),
                    validator: (v) =>
                        v != passCtrl.text ? 'No coinciden' : null,
                  ),
                  const SizedBox(height: 20),
                  cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6487E4),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                          ),
                          onPressed: registrar,
                          child: const Text('REGISTRARSE',
                              style: TextStyle(color: Colors.white)),
                        ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: const Center(
                      child: Text.rich(
                        TextSpan(
                          text: '¿Ya tienes una cuenta? ',
                          children: [
                            TextSpan(
                              text: 'Acceder',
                              style: TextStyle(
                                  color: Color(0xFF6487E4),
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
