import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'historial_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _user = user;
          _userData = doc.data();
        });
      }
    }
  }

  void _cerrarSesion() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  Widget _buildInfoRow(String title, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6487E4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final data = _userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color(0xFF6487E4),
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- ENCABEZADO CON FOTO Y NOMBRE ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF6487E4),
                          child: Text(
                            user.email != null && user.email!.isNotEmpty
                                ? user.email![0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                                fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data?['nombre'] ?? 'Usuario',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- DATOS BÁSICOS ---
                  _buildInfoRow("Teléfono", data?['telefono']),
                  _buildInfoRow("Dirección", data?['direccion']),

                  const SizedBox(height: 20),

                  // --- OPCIONES DEL PERFIL ---
                  _buildMenuOption(
                    icon: Icons.history,
                    title: "Historial de compras",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistorialScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuOption(
                    icon: Icons.logout,
                    title: "Cerrar sesión",
                    onTap: _cerrarSesion,
                  ),
                ],
              ),
            ),
    );
  }
}
