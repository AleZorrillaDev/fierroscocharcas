import 'package:flutter/material.dart';
import 'productos_screen.dart';
import 'carrito_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    ProductosScreen(),
    CarritoScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFF6487E4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: "Inicio"),
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined), label: "Productos"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), label: "Carrito"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Perfil"),
        ],
      ),
    );
  }
}

/// 📱 Vista principal de inicio
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Fierros Cocharcas"),
        backgroundColor: const Color(0xFF6487E4),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "¡Bienvenido!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Encuentra los mejores fierros, herramientas y materiales de construcción a precios competitivos.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // 🏷️ Banner principal
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.asset(
                    "lib/assets/banners/oferta1.png",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  ),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Ofertas especiales 🔧",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              blurRadius: 6,
                              color: Colors.black54,
                              offset: Offset(1, 1))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              "Marcas destacadas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 🧰 Marcas horizontales
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  marcaItem("lib/assets/marcas/stanley.png"),
                  marcaItem("lib/assets/marcas/cat.png"),
                  marcaItem("lib/assets/marcas/aceros.png"),
                  marcaItem("lib/assets/marcas/sider.png"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Productos populares 🔥",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 🧱 Productos destacados (solo muestra ejemplo visual)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, i) {
                final productos = [
                  {"nombre": "Taladro Stanley", "precio": "159.90"},
                  {"nombre": "Cincel Industrial", "precio": "39.90"},
                  {"nombre": "Disco de Corte CAT", "precio": "14.50"},
                  {"nombre": "Juego de Llaves", "precio": "120.00"},
                ];

                final p = productos[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
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
                              top: Radius.circular(12)),
                          child: Image.asset(
                            "lib/assets/productos/product.png",
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p["nombre"]!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "S/. ${p["precio"]}",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Componente para mostrar las marcas
  Widget marcaItem(String ruta) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(ruta, fit: BoxFit.contain),
          ),
        ),
      );
}
