// lib/screens/productos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carrito_screen.dart';

enum SortOption { az, za, priceAsc, priceDesc }

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _search = '';
  SortOption? _sort;
  double? _minPrice;
  double? _maxPrice;

  /// Convierte enlaces de Google Drive a URL directa para mostrar imagen.
  String _driveToDirect(String? url) {
    if (url == null || url.isEmpty) return '';
    final reg = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = reg.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$id';
    }
    return url;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> producto) async {
    final user = _auth.currentUser;
    if (user == null) {
      // No mostramos SnackBar al agregar (requeriste silencio al añadir).
      return;
    }

    try {
      final carritoRef = _db.collection('usuarios').doc(user.uid).collection('carrito');

      QuerySnapshot existente;
      if (producto['id'] != null) {
        existente = await carritoRef.where('productoId', isEqualTo: producto['id']).limit(1).get();
      } else {
        existente = await carritoRef.where('nombre', isEqualTo: producto['nombre']).limit(1).get();
      }

      if (existente.docs.isNotEmpty) {
        final doc = existente.docs.first;
        final current = (doc['cantidad'] ?? 1) as int;
        await carritoRef.doc(doc.id).update({'cantidad': current + 1});
      } else {
        await carritoRef.add({
          'productoId': producto['id'] ?? null,
          'nombre': producto['nombre'],
          'precio': _toDouble(producto['precio']),
          'cantidad': 1,
          'imagen': producto['imagen'] ?? '',
        });
      }
    } catch (e) {
      debugPrint('Error agregando al carrito: $e');
    }
  }

  void _openFilterPriceModal() {
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(2) ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(2) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const ListTile(title: Text('Filtrar por precio', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              TextField(
                controller: minCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio mínimo (S/.)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio máximo (S/.)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final min = double.tryParse(minCtrl.text.replaceAll(',', '.'));
                          final max = double.tryParse(maxCtrl.text.replaceAll(',', '.'));
                          _minPrice = min;
                          _maxPrice = max;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6487E4)),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _applySortFilter(List<QueryDocumentSnapshot> docs) {
    final list = List<QueryDocumentSnapshot>.from(docs);

    // Filtrado por precio local
    if (_minPrice != null) {
      list.removeWhere((d) => _toDouble((d.data() as Map)['precio']) < _minPrice!);
    }
    if (_maxPrice != null) {
      list.removeWhere((d) => _toDouble((d.data() as Map)['precio']) > _maxPrice!);
    }

    // Filtrado por búsqueda
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list.retainWhere((d) {
        final data = d.data() as Map<String, dynamic>;
        final nombre = (data['nombre'] ?? '').toString().toLowerCase();
        return nombre.contains(q);
      });
    }

    // Ordenamiento
    list.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      final nameA = (da['nombre'] ?? '').toString().toLowerCase();
      final nameB = (db['nombre'] ?? '').toString().toLowerCase();
      final priceA = _toDouble(da['precio']);
      final priceB = _toDouble(db['precio']);

      switch (_sort) {
        case SortOption.az:
          return nameA.compareTo(nameB);
        case SortOption.za:
          return nameB.compareTo(nameA);
        case SortOption.priceAsc:
          return priceA.compareTo(priceB);
        case SortOption.priceDesc:
          return priceB.compareTo(priceA);
        default:
          return 0;
      }
    });

    return list;
  }

  Stream<QuerySnapshot> _carritoStreamForBadge() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('usuarios').doc(user.uid).collection('carrito').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: const Color(0xFF6487E4),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (value) {
              if (value == 'priceFilter') {
                _openFilterPriceModal();
                return;
              }
              setState(() {
                switch (value) {
                  case 'az':
                    _sort = SortOption.az;
                    break;
                  case 'za':
                    _sort = SortOption.za;
                    break;
                  case 'priceAsc':
                    _sort = SortOption.priceAsc;
                    break;
                  case 'priceDesc':
                    _sort = SortOption.priceDesc;
                    break;
                  default:
                    _sort = null;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(value: 'az', child: Text('A → Z')),
              const PopupMenuItem<String>(value: 'za', child: Text('Z → A')),
              const PopupMenuItem<String>(value: 'priceAsc', child: Text('Menor costo')),
              const PopupMenuItem<String>(value: 'priceDesc', child: Text('Mayor costo')),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'priceFilter',
                child: Row(children: const [
                  Icon(Icons.tune, size: 18),
                  SizedBox(width: 8),
                  Text('Filtrar por precio'),
                ]),
              ),
            ],
          ),

          // Badge del carrito (suma cantidades)
          StreamBuilder<QuerySnapshot>(
            stream: _carritoStreamForBadge(),
            builder: (context, snap) {
              int totalUnits = 0;
              if (snap.hasData) {
                totalUnits = snap.data!.docs.fold<int>(0, (sum, d) {
                  final data = d.data() as Map<String, dynamic>;
                  return sum + ((data['cantidad'] ?? 1) as int);
                });
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      final user = _auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para ver el carrito')));
                        return;
                      }
                      // Navegamos directamente a la pantalla del carrito
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CarritoScreen()));
                    },
                  ),
                  if (totalUnits > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$totalUnits', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Buscador simple
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          if (_minPrice != null || _maxPrice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: Text('Filtro: ${_minPrice != null ? 'desde S/. ${_minPrice!.toStringAsFixed(2)}' : ''} ${_maxPrice != null ? ' hasta S/. ${_maxPrice!.toStringAsFixed(2)}' : ''}')),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _minPrice = null;
                      _maxPrice = null;
                    }),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('productos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No hay productos disponibles.'));

                final docs = _applySortFilter(snapshot.data!.docs);

                if (docs.isEmpty) return const Center(child: Text('No hay productos que cumplan los filtros.'));

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.74),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final nombre = d['nombre'] ?? 'Producto';
                    final precio = _toDouble(d['precio']);
                    final imagenRaw = (d['imagen'] ?? '').toString();
                    final imageUrl = imagenRaw.isNotEmpty ? _driveToDirect(imagenRaw) : '';

                    final producto = {
                      'id': id,
                      'nombre': nombre,
                      'precio': precio,
                      'imagen': imagenRaw,
                    };

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Image.asset('lib/assets/productos/product.png', fit: BoxFit.cover))
                                  : Image.asset('lib/assets/productos/product.png', fit: BoxFit.cover),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('S/. ${precio.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF6487E4), fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _agregarAlCarrito(producto),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6487E4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    child: const Text('Agregar'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
