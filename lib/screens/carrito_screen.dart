import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final db = FirebaseDatabase.instance.ref('carrito');
  List<Map<String, dynamic>> carrito = [];

  @override
  void initState() {
    super.initState();
    db.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          carrito = data.entries
              .map((e) => {
                    'id': e.key,
                    'nombre': e.value['nombre'],
                    'precio': e.value['precio'],
                    'imagen': e.value['imagen'],
                  })
              .toList();
        });
      } else {
        setState(() => carrito = []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double total = carrito.fold(
        0, (sum, item) => sum + double.parse(item['precio'].toString()));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6487E4),
        title: const Text('Mi Carrito'),
      ),
      body: carrito.isEmpty
          ? const Center(
              child: Text('Tu carrito está vacío 🛒',
                  style: TextStyle(fontSize: 18)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...carrito.map((item) => Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(item['imagen'],
                              width: 50,
                              errorBuilder: (context, error, stack) =>
                                  Image.asset('assets/default_product.png')),
                        ),
                        title: Text(item['nombre']),
                        subtitle: Text('S/. ${item['precio']}'),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => db.child(item['id']).remove(),
                        ),
                      ),
                    )),
                const Divider(),
                Text('Total: S/. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6487E4),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Compra realizada con éxito 🎉')));
                    db.remove();
                  },
                  child: const Text('Finalizar compra',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}
