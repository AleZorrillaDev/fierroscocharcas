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

  String _formatDate(dynamic t) {
    if (t == null) return 'Sin fecha';
    DateTime d;
    if (t is Timestamp) {
      d = t.toDate();
    } else if (t is DateTime) {
      d = t;
    } else {
      return 'Sin fecha';
    }
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
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

    // Caso 1: ya es una lista
    if (raw is List) {
      for (var item in raw) {
        if (item is Map) {
          lista.add(Map<String, dynamic>.from(item));
        } else if (item is String) {
          // intenta parsear JSON por elemento
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map) {
              lista.add(Map<String, dynamic>.from(decoded));
            } else if (decoded is List) {
              for (var e in decoded) {
                if (e is Map) lista.add(Map<String, dynamic>.from(e));
              }
            }
          } catch (_) {
            // si no se puede parsear, ignoramos
          }
        }
      }
      return lista;
    }

    // Caso 2: viene como String (posible JSON)
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
      } catch (_) {
        // no es JSON válido -> intentar parse simple: no hacemos nada y devolvemos lista vacía
      }
      return lista;
    }

    // Caso 3: viene como Map (un solo producto)
    if (raw is Map) {
      lista.add(Map<String, dynamic>.from(raw));
      return lista;
    }

    // Fallback: vacío
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de compras'),
        backgroundColor: const Color(0xFF6487E4),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historialStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes compras registradas',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final fecha = data['fecha'];
              final productosRaw = data['productos'];
              final productos = _normalizeProductos(productosRaw);
              final total = (data['total'] ?? 0).toDouble();
              final estado = (data['estado'] as String?) ?? 'pendiente';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: Icon(Icons.receipt_long, color: _colorEstado(estado)),
                  title: Text('Compra · ${_formatDate(fecha)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Text('S/. ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(width: 8),
                      Chip(label: Text(estado.toUpperCase(), style: const TextStyle(color: Colors.white)), backgroundColor: _colorEstado(estado)),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (productos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('No hay detalle de productos disponible.', style: TextStyle(color: Colors.black54)),
                      )
                    else
                      ...productos.map((p) {
                        final nombre = p['nombre'] ?? p['title'] ?? 'Producto';
                        final cantidad = p['cantidad'] ?? p['qty'] ?? 1;
                        final precio = (p['precio'] ?? p['price'] ?? 0).toDouble();
                        final imagen = p['imagen'] as String?;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: imagen != null && imagen.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    // si es Drive, se verá si es directa; si no, deja que falle al cargar
                                    imagen.contains('/d/') ? imagen.replaceAllMapped(RegExp(r'/d/([a-zA-Z0-9_-]+)'), (m) => 'uc?export=view&id=${m[1]}').replaceFirst('drive.google.com/uc?export=view&id=', 'https://drive.google.com/uc?export=view&id=') : imagen,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                  ),
                                )
                              : null,
                          title: Text(nombre),
                          subtitle: Text('Cantidad: $cantidad'),
                          trailing: Text('S/. ${precio.toStringAsFixed(2)}'),
                        );
                      }).toList(),
                    const SizedBox(height: 8),
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
