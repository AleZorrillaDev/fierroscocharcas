import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<Map<String, dynamic>?> _obtenerDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color(0xFF6487E4),
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _obtenerDatosUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          final nombre = data?['nombre'] ?? 'Usuario';
          final correo = data?['email'] ?? user?.email ?? '';
          final numero = data?['numero'] ?? '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: "avatarPerfil",
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: const AssetImage("lib/assets/marcas/cat.png"),
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(correo, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text('Teléfono: $numero',
                    style: const TextStyle(color: Colors.black54)),

                const SizedBox(height: 40),

                _opcionPerfil(
                  context,
                  Icons.person_outline,
                  "Editar perfil",
                  "Función aún no disponible",
                ),
                const SizedBox(height: 10),
                _opcionPerfil(
                  context,
                  Icons.settings_outlined,
                  "Configuraciones",
                  "Próximamente: ajustes de cuenta",
                ),
                const SizedBox(height: 10),
                _opcionPerfil(
                  context,
                  Icons.help_outline,
                  "Centro de ayuda",
                  "Próximamente soporte técnico.",
                ),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Cerrar sesión"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _opcionPerfil(BuildContext context, IconData icon, String texto, String mensaje) {
    return InkWell(
      onTap: () => _mensajeSnack(context, mensaje),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6487E4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _mensajeSnack(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6487E4),
      ),
    );
  }
}
