import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  /// 🔹 Convierte un enlace de Google Drive al formato de visualización directa
  String _convertirEnlaceDrive(String url) {
    final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    }
    return url;
  }

  /// 🔹 Carga productos desde Firestore
  void _cargarProductos() {
    _db.collection('productos').snapshots().listen((snapshot) {
      final temp = snapshot.docs.map((doc) {
        final value = doc.data();
        return {
          "id": doc.id,
          "nombre": value["nombre"] ?? "Producto",
          "precio": (value["precio"] ?? 0).toDouble(),
          "descripcion": value["descripcion"] ?? "",
          "imagen": _convertirEnlaceDrive(value["imagen"] ?? ""),
        };
      }).toList();

      setState(() {
        _productos = temp;
        _loading = false;
      });
    });
  }

  /// 🔹 Agrega productos al carrito (evita duplicados)
  Future<void> _agregarAlCarrito(Map<String, dynamic> producto) async {
    try {
      final carritoRef = _db.collection('carrito');
      final existente = await carritoRef
          .where("nombre", isEqualTo: producto["nombre"])
          .limit(1)
          .get();

      if (existente.docs.isNotEmpty) {
        final doc = existente.docs.first;
        final cantidadActual = (doc["cantidad"] ?? 1) as int;
        await doc.reference.update({"cantidad": cantidadActual + 1});
      } else {
        await carritoRef.add({
          "nombre": producto["nombre"],
          "precio": producto["precio"],
          "cantidad": 1,
          "imagen": producto["imagen"],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${producto["nombre"]} agregado al carrito."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF6487E4),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al agregar al carrito: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al agregar al carrito."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo de Productos"),
        backgroundColor: const Color(0xFF6487E4),
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      backgroundColor: Colors.grey[100],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? const Center(
                  child: Text(
                    "No hay productos disponibles.",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    itemCount: _productos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.74,
                    ),
                    itemBuilder: (context, i) {
                      final p = _productos[i];
                      return GestureDetector(
                        onTap: () => _mostrarDetalle(context, p),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14)),
                                  child: Image.network(
                                    p["imagen"],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p["nombre"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "S/. ${p["precio"].toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          color: Color(0xFF6487E4),
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _agregarAlCarrito(p),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6487E4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                        ),
                                        child: const Text("Agregar",
                                            style: TextStyle(fontSize: 14)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  /// 🔹 Muestra modal con detalle del producto
  void _mostrarDetalle(BuildContext context, Map<String, dynamic> producto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  producto["imagen"],
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 80),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                producto["nombre"],
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "S/. ${producto["precio"].toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6487E4),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                producto["descripcion"],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _agregarAlCarrito(producto);
                  },
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text("Agregar al carrito"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6487E4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
