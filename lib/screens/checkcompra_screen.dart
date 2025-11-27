import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Importante
import 'package:firebase_auth/firebase_auth.dart';     // 🔥 Importante
import 'addpago_screen.dart';

class CheckCompraScreen extends StatefulWidget {
  final double totalProductos;
  final double envio;
  final double recargo;
  
  // 🔥 Agregamos esto para guardar QUÉ se compró
  final List<Map<String, dynamic>> productos; 

  const CheckCompraScreen({
    super.key,
    required this.totalProductos,
    required this.envio,
    this.recargo = 0.0,
    required this.productos, // 🔥 Requerido
  });

  @override
  State<CheckCompraScreen> createState() => _CheckCompraScreenState();
}

class _CheckCompraScreenState extends State<CheckCompraScreen> {
  bool envioPrioritario = false;
  bool _isProcessing = false; // Para evitar doble clic al pagar

  // TARJETAS GUARDADAS (local temporal)
  List<Map<String, String>> tarjetas = [];

  int selectedIndex = -1;

  double get totalFinal {
    double extra = envioPrioritario ? 2.0 : 0.0;
    return widget.totalProductos + widget.envio + widget.recargo + extra;
  }

  void _agregarTarjeta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPagoScreen()),
    );

    if (result != null) {
      setState(() {
        tarjetas.add({
          "numero": result["cardNumber"],
          "fecha": result["expiry"],
          "nombre": result["name"]
        });
        selectedIndex = tarjetas.length - 1;
      });
    }
  }

  // --- LOGICA DE PAGO Y GUARDADO EN FIREBASE ---
  void _procesarPago() async {
    // 1. Validaciones básicas
    if (selectedIndex == -1) return;
    
    setState(() => _isProcessing = true); // Bloquear botón

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No hay usuario logueado"))
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // 2. Armar el objeto del pedido
      final tarjetaUsada = tarjetas[selectedIndex];
      
      Map<String, dynamic> datosPedido = {
        'total': totalFinal,
        'subtotal': widget.totalProductos,
        'envio': widget.envio + (envioPrioritario ? 2.0 : 0.0),
        'fecha': DateTime.now().toString(),
        'estado': 'Pendiente', // Pendiente, Enviado, Entregado
        'metodo_pago': 'Tarjeta terminada en ${tarjetaUsada["numero"]!.substring(tarjetaUsada["numero"]!.length - 4)}',
        'productos': widget.productos, // Lista de productos comprados
      };

      final _db = FirebaseFirestore.instance;

      // 3. PASO A: Guardar en el historial personal y CAPTURAR LA REFERENCIA (El ID)
      DocumentReference docRefUsuario = await _db.collection('usuarios')
          .doc(user.uid)
          .collection('historial')
          .add(datosPedido);

      // 🔥 Obtenemos el ID del documento que acabamos de crear
      String idPedidoUsuario = docRefUsuario.id; 

      // 4. PASO B: Guardar copia para el ADMIN incluyendo ese ID de referencia
      await _db.collection('pedidos_general').add({
        ...datosPedido, 
        'email_cliente': user.email, 
        'uid_cliente': user.uid,
        'id_pedido_usuario': idPedidoUsuario, // ✅ ESTA ES LA CLAVE PARA SINCRONIZAR
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Éxito y Salir
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("¡Compra Exitosa! 🎉"),
            content: const Text("Tu pedido ha sido registrado correctamente."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Cierra diálogo
                  // Regresa hasta la pantalla de inicio (borra historial de navegación)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("Aceptar"),
              )
            ],
          ),
        );
      }

    } catch (e) {
      print("Error al pagar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al procesar pago: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _tarjetaItem(int index) {
    final card = tarjetas[index];

    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color(0xFF4A5BD7)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: selectedIndex == index 
              ? Border.all(color: const Color(0xFF4A5BD7), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card, 
              color: selectedIndex == index ? Colors.white : Colors.black54, 
              size: 32
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card["numero"]!,
                    style: TextStyle(
                        color: selectedIndex == index ? Colors.white : Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card["nombre"]!,
                    style: TextStyle(
                      color: selectedIndex == index ? Colors.white70 : Colors.black54, 
                      fontSize: 14
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _bloque(String titulo, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Último paso"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================
            // MÉTODOS DE PAGO
            // ================================
            _bloque(
              "¿Cómo quieres pagar?",
              Column(
                children: [
                  if (tarjetas.isEmpty)
                     const Padding(
                       padding: EdgeInsets.all(8.0),
                       child: Text("No tienes tarjetas guardadas", style: TextStyle(color: Colors.grey)),
                     ),
                  ...List.generate(tarjetas.length, (i) => _tarjetaItem(i)),
                  const SizedBox(height: 10),

                  // AGREGAR TARJETA
                  GestureDetector(
                    onTap: _agregarTarjeta,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                          color: Colors.white),
                      child: Row(
                        children: const [
                          Icon(Icons.add, size: 30),
                          SizedBox(width: 12),
                          Text("Agregar tarjeta",
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================================
            // DATOS DE ENTREGA
            // ================================
            _bloque(
              "Datos de entrega",
              Column(
                children: [
                  // DELIVERY PROGRAMADO
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white),
                    child: Row(
                      children: [
                        const Icon(Icons.motorcycle_outlined),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text("Delivery estándar\nLlega en 24h",
                              style: TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ENVÍO PRIORITARIO
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white),
                    child: Row(
                      children: [
                        const Icon(Icons.electric_bike_outlined),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: Text("Envío prioritario + S/ 2.00",
                                style: TextStyle(fontSize: 15))),
                        Switch(
                          value: envioPrioritario,
                          activeTrackColor: Colors.black,
                          onChanged: (v) =>
                              setState(() => envioPrioritario = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================================
            // RESUMEN
            // ================================
            _bloque(
              "Resumen",
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Productos"),
                        Text("S/ ${widget.totalProductos.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Envío"),
                        Text("S/ ${widget.envio.toStringAsFixed(2)}"),
                      ],
                    ),

                    if (widget.recargo > 0)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Recargo"),
                              Text("S/ ${widget.recargo.toStringAsFixed(2)}"),
                            ],
                          ),
                        ],
                      ),

                    if (envioPrioritario)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Envío prioritario"),
                              Text("S/ 2.00"),
                            ],
                          ),
                        ],
                      ),
                    
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("S/ ${totalFinal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF2B53))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),

      // ================================
      // BOTÓN PAGAR
      // ================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: (selectedIndex == -1 || _isProcessing) 
                ? null 
                : _procesarPago, // 🔥 Llamamos a la función de Firebase
            style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == -1
                    ? Colors.grey
                    : const Color(0xFFEF2B53),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50))),
            child: _isProcessing 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  "Pagar  •  S/ ${totalFinal.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18),
                ),
          ),
        ),
      ),
    );
  }
}