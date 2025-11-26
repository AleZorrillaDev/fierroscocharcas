import 'package:flutter/material.dart';
import 'addpago_screen.dart';

class CheckCompraScreen extends StatefulWidget {
  final double totalProductos;
  final double envio;
  final double recargo;

  const CheckCompraScreen({
    super.key,
    required this.totalProductos,
    required this.envio,
    this.recargo = 0.0,
  });

  @override
  State<CheckCompraScreen> createState() => _CheckCompraScreenState();
}

class _CheckCompraScreenState extends State<CheckCompraScreen> {
  bool envioPrioritario = false;

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
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card["numero"]!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card["nombre"]!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
                          child: Text("Delivery programado\n10:00 h - 10:15 h",
                              style: TextStyle(fontSize: 15)),
                        ),
                        TextButton(
                            onPressed: () {},
                            child: const Text("Cambiar",
                                style: TextStyle(color: Colors.blue)))
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
                            child: Text("Envío prioritario + S/ 2",
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
            onPressed: selectedIndex == -1
                ? null
                : () {
                    // Aquí procesas el pago
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == -1
                    ? Colors.grey
                    : const Color(0xFFEF2B53),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50))),
            child: Text(
              "Pagar  •  S/ ${totalFinal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
