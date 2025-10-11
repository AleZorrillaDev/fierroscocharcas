import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nombreUsuario = '';
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _cargarNombre();
  }

  Future<void> _cargarNombre() async {
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref('usuarios/${user!.uid}');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() {
          nombreUsuario = snapshot.child('nombre').value.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6487E4),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 8),
            const Text('Fierros Cocharcas'),
          ],
        ),
        actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {},
            ),
            const SizedBox(width: 10),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- SALUDO ---
          Text(
            nombreUsuario.isEmpty
                ? 'Hola, Cliente 👋'
                : 'Hola, $nombreUsuario 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '¡Bienvenido de nuevo! Aprovecha las mejores ofertas del día.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // --- BANNER DE OFERTA ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F888),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.electrical_services, size: 45),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '¡Gran oferta en herramientas eléctricas! Hasta 50% de descuento en taladros, sierras y más.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // --- MARCAS ---
          const Text(
            'Marcas destacadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _marcaItem('assets/cat.png', 'CAT'),
                _marcaItem('assets/stanley.png', 'Stanley'),
                _marcaItem('assets/bosch.png', 'Bosch'),
                _marcaItem('assets/philips.png', 'Philips'),
                _marcaItem('assets/dewalt.png', 'DeWalt'),
              ],
            ),
          ),

          const SizedBox(height: 25),
          const Text(
            'Productos populares',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => _productoCard(
              nombre: 'Taladro Stanley Pro ${index + 1}',
              precio: 149.99 + index * 10,
              imagen: 'assets/product${index + 1}.png',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6487E4),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abrir chat de atención al cliente')),
          );
        },
        label: const Text('WhatsApp'),
        icon: const Icon(Icons.chat),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF6487E4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Órdenes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _marcaItem(String ruta, String nombre) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFF9F888),
            child: Image.asset(ruta, height: 30),
          ),
          const SizedBox(height: 5),
          Text(nombre, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _productoCard({
    required String nombre,
    required double precio,
    required String imagen,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Column(
        children: [
          Expanded(
            child: Image.asset(imagen, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('S/. ${precio.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
