import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'productos_screen.dart';
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
            icon: Icon(Icons.home_filled),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: "Productos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

/// 📱 VISTA PRINCIPAL (HomeTab)
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Variables de Mapa
  Position? _posicionActual;
  bool _loadingLocation = true;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  
  // Variables de la Tienda
  LatLng? _ubicacionTienda;
  String _nombreTienda = "Cargando tienda...";

  // Distancia y Ruta
  double? _distanciaKm;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosTienda(); // Nueva función híbrida (Firebase + Respaldo)
    _iniciarSeguimientoGPS();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ✅ 1. CARGA INTELIGENTE (Firebase o Respaldo)
  Future<void> _cargarDatosTienda() async {
    try {
      debugPrint("🔍 Buscando tienda en Firestore...");
      
      // Intentamos leer el documento exacto de tu imagen
      final doc = await FirebaseFirestore.instance
          .collection('ubicacion_tienda')
          .doc('tienda_principal')
          .get();

      if (doc.exists) {
        debugPrint("✅ Tienda encontrada en Firebase");
        final data = doc.data()!;
        final double lat = double.parse(data['lat'].toString());
        final double lng = double.parse(data['lng'].toString());
        final String nombre = data['nombre'] ?? "Fierros Cocharcas";

        _actualizarDatosTienda(LatLng(lat, lng), nombre);
      } else {
        debugPrint("⚠️ No existe el documento en Firebase. Usando respaldo.");
        _usarUbicacionRespaldo();
      }
    } catch (e) {
      debugPrint("❌ Error de conexión con Firebase: $e. Usando respaldo.");
      _usarUbicacionRespaldo();
    }
  }

  // Si Firebase falla, usamos estas coordenadas fijas (Huancayo aprox, según tu imagen)
  void _usarUbicacionRespaldo() {
    // 📍 COORDENADAS DE RESPALDO (Cámbialas si sabes las exactas)
    // He puesto unas coordenadas de Huancayo como ejemplo
    const fallbackLocation = LatLng(-12.1058637,-75.1874083); 
    _actualizarDatosTienda(fallbackLocation, "Fierros Cocharcas (Local)");
  }

  void _actualizarDatosTienda(LatLng ubicacion, String nombre) {
    if (mounted) {
      setState(() {
        _ubicacionTienda = ubicacion;
        _nombreTienda = nombre;
      });
      _actualizarMapaCalculos();
    }
  }

  // 2. GPS EN TIEMPO REAL
  Future<void> _iniciarSeguimientoGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Opcional: Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStream = Geolocator.getPositionStream(locationSettings: settings).listen((Position pos) {
      if (mounted) {
        setState(() {
          _posicionActual = pos;
          _loadingLocation = false;
        });
        _actualizarMapaCalculos();
      }
    });
  }

  // 3. Cálculos de Ruta y Distancia
  void _actualizarMapaCalculos() {
    if (_posicionActual != null && _ubicacionTienda != null) {
      final distanceMeters = Geolocator.distanceBetween(
        _posicionActual!.latitude,
        _posicionActual!.longitude,
        _ubicacionTienda!.latitude,
        _ubicacionTienda!.longitude,
      );

      final nuevaRuta = Polyline(
        polylineId: const PolylineId("ruta_tienda"),
        points: [
          LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
          _ubicacionTienda!
        ],
        color: const Color(0xFF6487E4), 
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );

      setState(() {
        _distanciaKm = distanceMeters / 1000.0;
        _polylines = {nuevaRuta};
      });

      // Intentamos centrar el mapa automáticamente si ya cargó el controlador
      if (_mapController != null) {
         Opcional: _verTodoElMapa(); // Descomenta si quieres auto-zoom agresivo
      }
    }
  }

  // 4. FUNCIONES DE MAPA
  void _verTodoElMapa() {
    if (_posicionActual == null || _ubicacionTienda == null || _mapController == null) return;

    final double minLat = _posicionActual!.latitude < _ubicacionTienda!.latitude ? _posicionActual!.latitude : _ubicacionTienda!.latitude;
    final double maxLat = _posicionActual!.latitude > _ubicacionTienda!.latitude ? _posicionActual!.latitude : _ubicacionTienda!.latitude;
    final double minLng = _posicionActual!.longitude < _ubicacionTienda!.longitude ? _posicionActual!.longitude : _ubicacionTienda!.longitude;
    final double maxLng = _posicionActual!.longitude > _ubicacionTienda!.longitude ? _posicionActual!.longitude : _ubicacionTienda!.longitude;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
    } catch (e) {
      debugPrint("Error animando mapa: $e");
    }
  }

  Future<void> _alejarMapa() async {
    final controller = _mapController;
    if (controller != null) {
      await controller.animateCamera(CameraUpdate.zoomOut());
    }
  }

  Future<void> _abrirGoogleMaps() async {
    if (_ubicacionTienda == null) return;
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${_ubicacionTienda!.latitude},${_ubicacionTienda!.longitude}");
    try {
      if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir el mapa';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al abrir mapa")));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_posicionActual != null && _ubicacionTienda != null) {
      Future.delayed(const Duration(milliseconds: 500), _verTodoElMapa);
    }
  }

  // Widget del Mapa
  Widget _buildMapPreview() {
    if (_loadingLocation && _posicionActual == null) {
      return Container(
        height: 350, 
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[200]), 
        child: const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Buscando señal GPS..."),
          ],
        ))
      );
    }

    final initial = _posicionActual != null 
        ? LatLng(_posicionActual!.latitude, _posicionActual!.longitude) 
        : const LatLng(-12.1058637,-75.1874083); // Coordenada por defecto

    Set<Marker> misMarcadores = {};
    if (_posicionActual != null) {
      misMarcadores.add(Marker(
        markerId: const MarkerId('usuario'), 
        position: LatLng(_posicionActual!.latitude, _posicionActual!.longitude), 
        infoWindow: const InfoWindow(title: 'Tú estás aquí'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
      ));
    }
    if (_ubicacionTienda != null) {
      misMarcadores.add(Marker(
        markerId: const MarkerId('tienda'), 
        position: _ubicacionTienda!, 
        infoWindow: InfoWindow(title: _nombreTienda),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 350, 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: initial, zoom: 14),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  markers: misMarcadores,
                  polylines: _polylines,
                ),
                
                // Botones Flotantes
                Positioned(
                  right: 10, 
                  bottom: 10,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "btnAlejar",
                        backgroundColor: Colors.white,
                        mini: true,
                        onPressed: _alejarMapa, 
                        child: const Icon(Icons.remove, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "btnCentrar",
                        backgroundColor: const Color(0xFF6487E4),
                        mini: true,
                        onPressed: _verTodoElMapa, 
                        child: const Icon(Icons.center_focus_strong, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_ubicacionTienda != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _abrirGoogleMaps,
              icon: const Icon(Icons.directions),
              label: const Text("Ir con Google Maps"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
      ],
    );
  }

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
              "Todo en ferretería y construcción.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Banner
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
                          Colors.black.withValues(alpha: 0.4),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Mi ubicación y tienda",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // DISTANCIA
            if (_distanciaKm != null)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.place, color: Color(0xFF6487E4)),
                    const SizedBox(width: 8),
                    Text(
                      _distanciaKm! < 1 
                          ? "A solo ${(_distanciaKm! * 1000).toInt()} m" 
                          : "Distancia: ${_distanciaKm!.toStringAsFixed(2)} km",
                      style: const TextStyle(
                        color: Color(0xFF1565C0), 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                  ],
                ),
              )
            else
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Row(
                   children: [
                     const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                     const SizedBox(width: 10),
                     const Text("Localizando...", style: TextStyle(color: Colors.grey)),
                   ],
                 ),
               ),

            _buildMapPreview(),

            const SizedBox(height: 20),

            const Text(
              "Marcas destacadas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

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
                            top: Radius.circular(12),
                          ),
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
                              style:
                                  const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}