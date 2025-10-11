import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final db = FirebaseDatabase.instance.ref('productos');
  List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    final snapshot = await db.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        productos = data.entries
            .map((e) => {
                  'id': e.key,
                  'nombre': e.value['nombre'],
                  'precio': e.value['precio'],
                  'imagen': e.value['imagen'],
                })
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6487E4),
        title: const Text('Productos'),
      ),
      body: productos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final p = productos[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: Image.network(
                            p['imagen'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                Image.asset('assets/default_product.png'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(p['nombre'],
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      Text('S/. ${p['precio']}',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6487E4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          FirebaseDatabase.instance.ref('carrito').push().set({
                            'nombre': p['nombre'],
                            'precio': p['precio'],
                            'imagen': p['imagen'],
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${p['nombre']} agregado al carrito 🛒')));
                        },
                        child: const Text('Agregar',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
