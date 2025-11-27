import 'dart:convert'; // 🔥 Necesario para codificar/decodificar
import 'dart:io';

import 'dart:typed_data'; // 🔥 Para manejar los bytes
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'historial_screen.dart'; 

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  User? user;
  Map<String, dynamic>? userData;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (user != null) {
      final doc = await _db.collection('usuarios').doc(user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data();
        });
      }
    }
  }

  // 📸 FUNCIÓN: TOMA FOTO -> CODIFICA A BASE64 -> GUARDA EN FIRESTORE
  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    
    // Seleccionar origen
    final XFile? image = await showDialog<XFile?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambiar foto de perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Tomar foto"),
              onTap: () async {
                // maxWidth: 800 asegura que la imagen no pese más de 1MB (Límite de Firestore)
                // pero mantiene una calidad visual HD para celulares.
                final img = await picker.pickImage(
                  source: ImageSource.camera, 
                  maxWidth: 800, 
                  imageQuality: 80 
                );
                Navigator.pop(ctx, img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galería"),
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.gallery, 
                  maxWidth: 800, 
                  imageQuality: 80
                );
                Navigator.pop(ctx, img);
              },
            ),
          ],
        ),
      ),
    );

    if (image == null) return;

    setState(() => _uploading = true);

    try {
      // 1. Convertir imagen a BYTES
      Uint8List imageBytes = await image.readAsBytes();

      // 2. CODIFICAR: Convertir Bytes a String (Base64)
      String base64String = base64Encode(imageBytes);

      // 3. GUARDAR: Escribir esa cadena gigante en Firestore directamente
      // Usamos el campo 'foto_base64' para diferenciarlo
      await _db.collection('usuarios').doc(user!.uid).update({
        'foto_base64': base64String,
      });
      
      // 4. Recargar datos para mostrar la imagen nueva
      await _cargarDatosUsuario();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Foto actualizada correctamente!")),
        );
      }
    } catch (e) {
      debugPrint("Error guardando foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error al guardar: Asegúrate que la foto no sea muy pesada.")),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // 🖼️ WIDGET AUXILIAR PARA DECODIFICAR Y MOSTRAR
  ImageProvider? _obtenerImagenProvider() {
    if (userData == null) return null;

    // A. Intentar usar la imagen Base64 (Nueva forma)
    if (userData!.containsKey('foto_base64') && userData!['foto_base64'] != null) {
      try {
        String base64String = userData!['foto_base64'];
        // DECODIFICAR
        Uint8List bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        print("Error decodificando imagen: $e");
      }
    }

    // B. Si no hay Base64, intentar usar URL antigua (Firebase Storage)
    if (userData!.containsKey('foto') && userData!['foto'] != null) {
      return NetworkImage(userData!['foto']);
    }

    // C. Si no hay nada, retorna null (se mostrará el icono por defecto)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String nombre = userData!['nombre'] ?? 'Usuario';
    final String email = userData!['email'] ?? user?.email ?? '';
    final String rol = userData!['rol'] ?? 'Cliente';
    
    // Obtenemos la imagen procesada
    final ImageProvider? imagenPerfil = _obtenerImagenProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: const Color(0xFF6487E4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // CABECERA AZUL CON FOTO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF6487E4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          // AQUÍ SE MUESTRA LA IMAGEN DECODIFICADA
                          backgroundImage: imagenPerfil,
                          child: imagenPerfil == null 
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploading ? null : _cambiarFoto,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: _uploading 
                                ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.camera_alt, color: Color(0xFF6487E4)),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rol.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // OPCIONES DEL PERFIL
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _perfilItem(
                    icon: Icons.shopping_bag_outlined, 
                    titulo: "Mis Pedidos", 
                    subtitulo: "Ver historial de compras",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialScreen()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Funcionalidad de historial pendiente")));
                    }
                  ),
                  _perfilItem(
                    icon: Icons.location_on_outlined, 
                    titulo: "Direcciones", 
                    subtitulo: "Administrar direcciones de entrega",
                    onTap: () {}
                  ),
                  _perfilItem(
                    icon: Icons.settings_outlined, 
                    titulo: "Configuración", 
                    subtitulo: "Privacidad y seguridad",
                    onTap: () {}
                  ),
                  const Divider(),
                  _perfilItem(
                    icon: Icons.help_outline, 
                    titulo: "Ayuda y Soporte", 
                    subtitulo: "Contactar con atención al cliente",
                    onTap: () {}
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfilItem({required IconData icon, required String titulo, required String subtitulo, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6487E4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6487E4)),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}