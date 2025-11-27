import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; // 🔥 IMPORTANTE: Gráficos
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0; // 0: Productos, 1: Pedidos, 2: Reportes
  final Color _primaryColor = const Color(0xFF6487E4);

  // Helper para imágenes de Drive
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

  // Helper para colores de estado
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'empaquetado': return Colors.blue;
      case 'en viaje': return Colors.purple;
      case 'entregado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fierros Cocharcas - Admin"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            backgroundColor: Colors.white,
            indicatorColor: _primaryColor.withOpacity(0.1),
            selectedLabelTextStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.store_mall_directory_outlined),
                selectedIcon: Icon(Icons.store),
                label: Text('Productos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined), // Cambié icono para reflejar gestión
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Pedidos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Reportes'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoProducto(),
              label: const Text("Nuevo Producto", style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildProductosView();
      case 1: return _buildPedidosView();
      case 2: return _buildReportesView();
      default: return const Center(child: Text("Seleccione una opción"));
    }
  }

  // ==========================================
  // 1. VISTA DE PRODUCTOS (Sin cambios mayores)
  // ==========================================
  Widget _buildProductosView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('productos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No hay productos."));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            String imgUrl = _driveToDirect(data['imagen'] ?? '');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: imgUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text(data['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("S/. ${data['precio']}", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _mostrarDialogoProducto(docId: id, nombre: data['nombre'], precio: data['precio'].toString(), img: data['imagen']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarProducto(id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 2. VISTA DE PEDIDOS (CON CAMBIO DE ESTADO) 🔥
  // ==========================================
  Widget _buildPedidosView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pedidos_general')
          //.orderBy('timestamp', descending: true) // Descomenta si tienes el índice
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No hay pedidos."));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id; // ID del documento para actualizar
            
            final total = (data['total'] ?? 0).toDouble();
            final fecha = data['fecha']?.toString().substring(0, 16) ?? '-';
            final estado = data['estado'] ?? 'Pendiente';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _colorEstado(estado).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_shipping, color: _colorEstado(estado)),
                ),
                title: Text("Cliente: ${data['email_cliente'] ?? 'Anónimo'}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$fecha • S/. ${total.toStringAsFixed(2)}"),
                    const SizedBox(height: 4),
                    // CHIP DE ESTADO ACTUAL
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _colorEstado(estado),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(estado.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Gestión del Pedido:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        
                        // 🔥 BOTONES PARA CAMBIAR ESTADO
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _botonEstado(id, "Pendiente", estado, Colors.orange),
                              const SizedBox(width: 8),
                              _botonEstado(id, "Empaquetado", estado, Colors.blue),
                              const SizedBox(width: 8),
                              _botonEstado(id, "En viaje", estado, Colors.purple),
                              const SizedBox(width: 8),
                              _botonEstado(id, "Entregado", estado, Colors.green),
                              const SizedBox(width: 8),
                              _botonEstado(id, "Cancelado", estado, Colors.red),
                            ],
                          ),
                        ),
                        
                        const Divider(height: 30),
                        const Text("Detalle Productos:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        if (data['productos'] != null)
                          ...(data['productos'] as List).map((p) => 
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text("• ${p['nombre']} (x${p['cantidad'] ?? 1})"),
                            )
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
    );
  }

  Widget _botonEstado(String docId, String titulo, String estadoActual, Color color) {
    bool isSelected = titulo.toLowerCase() == estadoActual.toLowerCase();
    return InkWell(
      onTap: () => _cambiarEstadoPedido(docId, titulo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          titulo,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. VISTA DE REPORTES (CON GRÁFICOS) 📊
  // ==========================================
  Widget _buildReportesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pedidos_general').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        
        // 1. Cálculos generales
        double ventasTotales = 0;
        int cantidadPedidos = docs.length;
        
        // 2. Datos para el gráfico (Ventas por día o simples barras de ejemplo)
        // Para simplificar, haremos un gráfico de los últimos 5 pedidos como ejemplo visual
        List<BarChartGroupData> barrasGrafico = [];
        
        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          double monto = (data['total'] ?? 0).toDouble();
          ventasTotales += monto;

          // Solo mostramos los últimos 7 en el gráfico para que no se sature
          if (i < 7) {
            barrasGrafico.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: monto,
                    color: _primaryColor,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              ),
            );
          }
        }

        double ticketPromedio = cantidadPedidos > 0 ? ventasTotales / cantidadPedidos : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Panel de Control", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // TARJETAS DE RESUMEN
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _reportCard("Ventas Totales", "S/. ${ventasTotales.toStringAsFixed(2)}", Icons.monetization_on, Colors.green),
                  _reportCard("Pedidos", "$cantidadPedidos", Icons.shopping_bag, Colors.orange),
                  _reportCard("Ticket Promedio", "S/. ${ticketPromedio.toStringAsFixed(2)}", Icons.analytics, Colors.purple),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // 🔥 GRÁFICO DE BARRAS (FL_CHART)
              const Text("Últimas Ventas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: docs.isEmpty 
                  ? const Center(child: Text("No hay datos para graficar"))
                  : BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text("P${value.toInt() + 1}", style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: barrasGrafico,
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  // ==========================================
  // LÓGICA DE ACTUALIZACIÓN DE ESTADOS (SINCRONIZADA POR ID) 🔥
  // ==========================================
  Future<void> _cambiarEstadoPedido(String docId, String nuevoEstado) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Actualizar copia del ADMIN
      await firestore
          .collection('pedidos_general')
          .doc(docId)
          .update({'estado': nuevoEstado});

      // 2. Buscar datos para sincronizar con el CLIENTE
      final doc = await firestore.collection('pedidos_general').doc(docId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final uidCliente = data?['uid_cliente'];
        final idPedidoUsuario = data?['id_pedido_usuario']; // ✅ Leemos el ID exacto

        // CASO A: Tenemos el ID exacto (Pedidos nuevos con el código corregido)
        if (uidCliente != null && idPedidoUsuario != null) {
          await firestore
              .collection('usuarios')
              .doc(uidCliente)
              .collection('historial')
              .doc(idPedidoUsuario) // Vamos directo al grano
              .update({'estado': nuevoEstado});
              
          debugPrint("✅ Sincronizado por ID directo.");
        } 
        // CASO B: Respaldo para pedidos viejos (Intento por fecha)
        else if (uidCliente != null) {
           final fechaPedido = data?['fecha'];
           final query = await firestore
              .collection('usuarios')
              .doc(uidCliente)
              .collection('historial')
              .where('fecha', isEqualTo: fechaPedido)
              .get();
           
           for (var d in query.docs) {
             await d.reference.update({'estado': nuevoEstado});
           }
           debugPrint("⚠️ Sincronizado por fecha (método antiguo).");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Estado actualizado a: $nuevoEstado"),
            backgroundColor: _colorEstado(nuevoEstado),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error actualizando: $e");
    }
  }

  // ... (Funciones _eliminarProducto y _mostrarDialogoProducto se mantienen igual que antes) ...
  
  void _eliminarProducto(String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("¿Eliminar producto?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
        TextButton(onPressed: () async {
           await FirebaseFirestore.instance.collection('productos').doc(id).delete();
           if(mounted) Navigator.pop(ctx);
        }, child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _mostrarDialogoProducto({String? docId, String? nombre, String? precio, String? img}) {
    final nombreCtrl = TextEditingController(text: nombre ?? '');
    final precioCtrl = TextEditingController(text: precio ?? '');
    final imagenCtrl = TextEditingController(text: img ?? '');
    final bool esEdicion = docId != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? "Editar Producto" : "Nuevo Producto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
            TextField(controller: imagenCtrl, decoration: const InputDecoration(labelText: "URL Imagen")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final double? precioVal = double.tryParse(precioCtrl.text);
              if (nombreCtrl.text.isNotEmpty && precioVal != null) {
                final data = {'nombre': nombreCtrl.text, 'precio': precioVal, 'imagen': imagenCtrl.text};
                if (esEdicion) {
                  await FirebaseFirestore.instance.collection('productos').doc(docId).update(data);
                } else {
                  await FirebaseFirestore.instance.collection('productos').add(data);
                }
                if(mounted) Navigator.pop(ctx);
              }
            },
            child: Text("Guardar"),
          )
        ],
      ),
    );
  }
}