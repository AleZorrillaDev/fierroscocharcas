// lib/screens/carrito_screen.dart
import 'package:flutter/material.dart';
import 'checkcompra_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //bool _processing = false;

  Stream<QuerySnapshot> _carritoStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('carrito')
        .snapshots();
  }

  String _driveToDirect(String url) {
    if (url.isEmpty) return url;
    final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final m = reg.firstMatch(url);
    if (m != null && m.groupCount >= 1) {
      final id = m.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    }
    return url;
  }

  Future<void> _incrementar(String docId, int cantidad) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db
          .collection('usuarios')
          .doc(user.uid)
          .collection('carrito')
          .doc(docId)
          .update({
        'cantidad': cantidad + 1,
      });
    } catch (e) {
      debugPrint('Error incrementar: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No se pudo incrementar la cantidad'))),
        );
      }
    }
  }

  Future<void> _disminuir(String docId, int cantidad) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (cantidad > 1) {
        await _db
            .collection('usuarios')
            .doc(user.uid)
            .collection('carrito')
            .doc(docId)
            .update({'cantidad': cantidad - 1});
      } else {
        await _db
            .collection('usuarios')
            .doc(user.uid)
            .collection('carrito')
            .doc(docId)
            .delete();
      }
    } catch (e) {
      debugPrint('Error disminuir: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No se pudo actualizar la cantidad'))),
        );
      }
    }
  }

  Future<void> _eliminar(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db
          .collection('usuarios')
          .doc(user.uid)
          .collection('carrito')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Error eliminar: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No se pudo eliminar el producto'))),
        );
      }
    }
  }

  double _calcularTotalFromDocs(List<QueryDocumentSnapshot> docs) {
    double suma = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final precio = (data['precio'] ?? 0).toDouble();
      final cantidad = (data['cantidad'] ?? 1) as int;
      suma += precio * cantidad;
    }
    return suma;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Mi Carrito'),
            backgroundColor: const Color(0xFF6487E4)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Debes iniciar sesión para ver el carrito.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6487E4)),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: const Color(0xFF6487E4),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _carritoStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Carrito vacío → NO permitir pago
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tu carrito está vacío 🛒',
                      style:
                          TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Seguir comprando'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6487E4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final total = _calcularTotalFromDocs(docs);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    final nombre =
                        data['nombre'] ?? 'Producto';
                    final precio =
                        (data['precio'] ?? 0).toDouble();
                    final cantidad =
                        (data['cantidad'] ?? 1) as int;
                    final imagen =
                        (data['imagen'] ?? '') as String;

                    final imageUrl = imagen.isNotEmpty
                        ? _driveToDirect(imagen)
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons
                                          .image_not_supported,
                                          size: 40))
                              : Image.asset(
                                  'lib/assets/productos/product.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover),
                        ),
                        title: Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'S/. ${precio.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _disminuir(id, cantidad),
                              icon: const Icon(
                                  Icons.remove_circle_outline),
                              color: Colors.grey,
                            ),
                            Text(cantidad.toString(),
                                style:
                                    const TextStyle(fontSize: 16)),
                            IconButton(
                              onPressed: () =>
                                  _incrementar(id, cantidad),
                              icon: const Icon(
                                  Icons.add_circle_outline),
                              color: const Color(0xFF6487E4),
                            ),
                            IconButton(
                              onPressed: () => _eliminar(id),
                              icon: const Icon(
                                  Icons.delete_outline),
                              color: Colors.redAccent,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // TOTAL + IR A PAGO
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 6,
                          offset: const Offset(0, -2))
                    ]),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold)),
                          Text('S/. ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF6487E4),
                                  fontWeight:
                                      FontWeight.bold)),
                        ]),
                    const SizedBox(height: 12),

                    // 👉 BOTÓN que abre Checkout (CORRECTO)
                    ElevatedButton.icon(
                      onPressed: () {
                        // 1. Preparamos la lista de productos limpia para enviarla
                        final List<Map<String, dynamic>> listaParaEnviar = docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'id': doc.id,
                            'nombre': data['nombre'] ?? 'Producto',
                            'cantidad': data['cantidad'] ?? 1,
                            'precio': (data['precio'] ?? 0).toDouble(),
                            // Agregamos imagen por si quieres mostrarla en el resumen luego
                            'imagen': data['imagen'] ?? '', 
                          };
                        }).toList();

                        // 2. Navegamos pasando esa lista
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckCompraScreen(
                              totalProductos: total,
                              envio: 5.00,
                              recargo: 0.00,
                              productos: listaParaEnviar, // 🔥 AQUÍ ESTÁ LA CLAVE
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Continuar con el pago'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6487E4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label:
                          const Text('Seguir comprando'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
