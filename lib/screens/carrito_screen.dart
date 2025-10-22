import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _carrito = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  /// 🔹 Cargar los productos del carrito en tiempo real (Firestore)
  void _cargarCarrito() {
    _db.collection('carrito').snapshots().listen((snapshot) {
      final temp = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "nombre": data["nombre"] ?? "Producto",
          "precio": (data["precio"] ?? 0).toDouble(),
          "cantidad": (data["cantidad"] ?? 1),
          "imagen": data["imagen"] ?? "lib/assets/productos/product.png",
        };
      }).toList();

      setState(() {
        _carrito = temp;
        _loading = false;
      });
    });
  }

  /// 🔹 Actualizar cantidad de producto
  Future<void> _actualizarCantidad(String id, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      await _eliminarProducto(id);
    } else {
      await _db.collection('carrito').doc(id).update({"cantidad": nuevaCantidad});
    }
  }

  /// 🔹 Eliminar un producto del carrito
  Future<void> _eliminarProducto(String id) async {
    await _db.collection('carrito').doc(id).delete();
  }

  /// 🔹 Calcular total
  double get _total => _carrito.fold(
      0, (sum, p) => sum + (p["precio"] as double) * (p["cantidad"] as int));

  /// 🔹 Vaciar carrito al comprar
  Future<void> _finalizarCompra() async {
    final carritoRef = _db.collection('carrito');
    final snapshot = await carritoRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compra realizada correctamente 🧾"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6487E4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mi Carrito"),
        backgroundColor: const Color(0xFF6487E4),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _carrito.isEmpty
              ? const Center(
                  child: Text(
                    "Tu carrito está vacío 🛒",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _carrito.length,
                        itemBuilder: (context, i) {
                          final item = _carrito[i];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  item["imagen"],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              title: Text(
                                item["nombre"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    "S/. ${item["precio"].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        color: Color(0xFF6487E4),
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _actualizarCantidad(
                                            item["id"],
                                            (item["cantidad"] as int) - 1),
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        item["cantidad"].toString(),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        onPressed: () => _actualizarCantidad(
                                            item["id"],
                                            (item["cantidad"] as int) + 1),
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        color: const Color(0xFF6487E4),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _eliminarProducto(item["id"]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    /// 🔹 Total y botón de compra
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "S/. ${_total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF6487E4),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed:
                                _carrito.isEmpty ? null : _finalizarCompra,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text("Finalizar compra"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6487E4),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
