// lib/screens/historial_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot> _historialStream = const Stream.empty();

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  Future<void> _setupStream() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Usamos la subcolección 'historial' dentro de usuarios/{uid}
    final userHist = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('historial')
        .orderBy('fecha', descending: true)
        .snapshots();

    setState(() {
      _historialStream = userHist;
    });
  }

  // ✅ MEJORA 1: Soporte robusto para fechas (String, Timestamp, DateTime)
  String _formatDate(dynamic t) {
    if (t == null) return 'Sin fecha';
    DateTime? d;
    
    if (t is Timestamp) {
      d = t.toDate();
    } else if (t is String) {
      d = DateTime.tryParse(t); // Parsea el string guardado en checkout
    } else if (t is DateTime) {
      d = t;
    }

    if (d == null) return 'Fecha inválida';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // ✅ MEJORA 2: Función limpia para imágenes de Drive
  String _driveToDirect(String url) {
    if (url.isEmpty) return '';
    if (url.contains('/d/')) {
      return url.replaceAllMapped(RegExp(r'/d/([a-zA-Z0-9_-]+)'), (m) {
        return 'https://drive.google.com/uc?export=view&id=${m[1]}';
      }).replaceAll('drive.google.com/file/d/', 'drive.google.com/uc?export=view&id=');
    }
    return url;
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'procesando':
        return Colors.blue;
      case 'enviado':
        return Colors.purple;
      case 'entregado':
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Convierte el campo 'productos' a List<Map<String,dynamic>>
  List<Map<String, dynamic>> _normalizeProductos(dynamic raw) {
    final List<Map<String, dynamic>> lista = [];

    if (raw == null) return lista;

    // Caso 1: ya es una lista (lo más común ahora)
    if (raw is List) {
      for (var item in raw) {
        if (item is Map) {
          lista.add(Map<String, dynamic>.from(item));
        } else if (item is String) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map) {
              lista.add(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
        }
      }
      return lista;
    }

    // Caso 2: viene como String
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map) lista.add(Map<String, dynamic>.from(item));
          }
        } else if (decoded is Map) {
          lista.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
      return lista;
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de compras'),
        backgroundColor: const Color(0xFF6487E4),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: _historialStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes compras registradas',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final fecha = data['fecha'];
              final productosRaw = data['productos'];
              final productos = _normalizeProductos(productosRaw);
              final total = (data['total'] ?? 0).toDouble();
              final estado = (data['estado'] as String?) ?? 'Pendiente';
              final metodoPago = data['metodo_pago'] ?? 'Tarjeta';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _colorEstado(estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long, color: _colorEstado(estado)),
                  ),
                  title: Text(
                    _formatDate(fecha), 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'S/. ${total.toStringAsFixed(2)}', 
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorEstado(estado),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado.toUpperCase(), 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Productos (${productos.length})", 
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)
                      )
                    ),
                    const SizedBox(height: 10),
                    if (productos.isEmpty)
                      const Text('No hay detalle disponible.', style: TextStyle(color: Colors.black54))
                    else
                      ...productos.map((p) {
                        final nombre = p['nombre'] ?? p['title'] ?? 'Producto';
                        final cantidad = p['cantidad'] ?? p['qty'] ?? 1;
                        final precio = (p['precio'] ?? p['price'] ?? 0).toDouble();
                        String imagen = p['imagen'] ?? '';
                        
                        // Procesar imagen de Drive si es necesario
                        imagen = _driveToDirect(imagen);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // Imagen miniatura
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: imagen.isNotEmpty
                                  ? Image.network(
                                      imagen,
                                      width: 40, height: 40, fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => Container(
                                        width: 40, height: 40, color: Colors.grey[200], 
                                        child: const Icon(Icons.image, size: 20, color: Colors.grey)
                                      ),
                                    )
                                  : Container(
                                      width: 40, height: 40, color: Colors.grey[200], 
                                      child: const Icon(Icons.shopping_bag, size: 20, color: Colors.grey)
                                    ),
                              ),
                              const SizedBox(width: 12),
                              // Datos producto
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('x$cantidad', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('S/. ${precio.toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }),
                    
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Método de pago:", style: TextStyle(color: Colors.grey)),
                        Flexible(
                          child: Text(
                            metodoPago, 
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}