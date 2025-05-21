import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location_pkg;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../routes/app_routes.dart';
import 'callao_polygon.dart';

/// Pantalla principal del mapa, integra Google Maps y todas las funciones de seguridad.
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // --- VARIABLES Y CONTROLADORES PRINCIPALES ---
  // ApiService para llamadas a la API de tu backend
  final ApiService apiService = ApiService();

  // Resultados de predicción de delitos para origen y destino
  Map<String, dynamic>? prediccionResultados;
  Map<String, dynamic>? prediccionResultadosDestino;

  // Controlador para el campo de búsqueda de direcciones
  final TextEditingController _searchController = TextEditingController();

  // Controlador del mapa de Google
  GoogleMapController? _mapController;

  // Timers para simulación de rutas y caminata
  Timer? _simulationTimer;
  Timer? _caminataTimer;

  // Estado de la simulación y rutas
  bool rutaEnProgreso = false;
  bool simulandoCaminata = false;
  int? usuarioId;

  //variable para guardar el estado inicial
  bool? _simulacionEmpezoEnZonaDeRiesgo;

  // Variables para la simulación de caminata
  List<LatLng> _rutaSimulada = [];
  int _pasoActual = 0;

  // Coordenadas de la polilínea de la ruta, marcadores, círculos de calor y polilíneas en el mapa
  List<LatLng> polylineCoordinates = [];
  Set<Marker> _markers = {};
  Set<Circle> _heatMapCircles = {};
  Set<Polyline> _mapPolylines = {};

  // API Key de Google Maps
  String apiKey = 'AIzaSyCdjMMG__X2Y2lm16pXWbMVSBEFCeQXV9g';

  // Instancia de Location para obtener la ubicación del usuario
  location_pkg.Location location = location_pkg.Location();

  // Predicciones de autocompletado de direcciones
  List<Map<String, dynamic>> predictions = [];

  // Destino seleccionado y ubicación actual
  LatLng? selectedDestination;
  LatLng? currentLocation;

  // Información de la zona de riesgo más cercana
  Map<String, dynamic>? zonaDeRiesgo;

  // Estado para saber si el usuario está dentro del Callao
  bool isInCallao = false;

  // Control para mostrar predicción de origen o destino
  bool showOriginPrediction = true;

  // Límites geográficos del Callao
  final LatLngBounds callaoBounds = LatLngBounds(
    southwest: LatLng(-12.125, -77.174),
    northeast: LatLng(-11.994, -77.027),
  );

  // Mapeo de tipos de círculos de calor
  Map<String, String> circleTypes = {};

  // --- CICLO DE VIDA DEL WIDGET ---
  @override
  void initState() {
    super.initState();
    _checkLocationPermissions(); // Solicita permisos de ubicación y obtiene la ubicación actual
    _fetchHeatMapData();         // Carga los datos del mapa de calor (zonas de riesgo)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtiene el usuarioId pasado por argumentos de navegación
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    usuarioId = args?['usuarioId'];
  }

  @override
  void dispose() {
    // Cancela timers al destruir el widget
    _simulationTimer?.cancel();
    _caminataTimer?.cancel();
    super.dispose();
  }

  // --- FUNCIONES DE SIMULACIÓN DE CAMINATA Y RUTAS SEGURAS ---

  /// Busca un punto seguro a cierta distancia de la ubicación actual, lejos de zonas de riesgo.
  LatLng _buscarPuntoSeguro({double distanciaMetros = 500}) {
    // Si no hay ubicación actual, retorna un punto por defecto
    if (currentLocation == null) return LatLng(-12.0540, -77.1219);

    double lat = currentLocation!.latitude;
    double lng = currentLocation!.longitude;
    double earthRadius = 6371000; // metros

    // Calcula un nuevo punto al norte
    double newLat = lat + (distanciaMetros / earthRadius) * (180 / pi);
    LatLng candidato = LatLng(newLat, lng);

    // Verifica que esté lejos de todas las zonas de riesgo
    bool lejos = true;
    for (var circle in _heatMapCircles) {
      double d = _calculateDistance(
          candidato.latitude, candidato.longitude,
          circle.center.latitude, circle.center.longitude
      );
      if (d < 100) { // Si está cerca de alguna zona de riesgo, no es válido
        lejos = false;
        break;
      }
    }
    // Si no está lejos, busca al sur
    if (!lejos) {
      newLat = lat - (distanciaMetros / earthRadius) * (180 / pi);
      candidato = LatLng(newLat, lng);
    }
    return candidato;
  }

  /// Inicia la simulación de una caminata desde la ubicación actual hacia un punto seguro o zona de riesgo.
  void _iniciarSimulacionCaminata() {
    if (_heatMapCircles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay zonas de riesgo cargadas.'))
      );
      return;
    }

    final origen = currentLocation ?? LatLng(-12.0540, -77.1219);
    LatLng destino;

    // Guarda el estado inicial de la alerta
    _simulacionEmpezoEnZonaDeRiesgo = zonaDeRiesgo != null;

    if (_simulacionEmpezoEnZonaDeRiesgo!) {
      // Si está en zona de riesgo, busca un punto seguro
      destino = _buscarPuntoSeguro(distanciaMetros: 600);
    } else {
      // Si está en zona segura, busca la zona de riesgo más cercana
      destino = _heatMapCircles.first.center;
    }

    _rutaSimulada = _generarRutaSimulada(origen, destino, pasos: 30);
    _pasoActual = 0;
    simulandoCaminata = true;

    _caminataTimer?.cancel();
    _caminataTimer = Timer.periodic(Duration(milliseconds: 700), (timer) {
      if (_pasoActual < _rutaSimulada.length) {
        currentLocation = _rutaSimulada[_pasoActual];
        _setMarker(currentLocation!, "Ubicación simulada", isCurrentLocation: true);
        _checkProximityToRiskZones();

        // Lógica de parada automática
        bool ahoraEnZonaDeRiesgo = zonaDeRiesgo != null;
        if (_simulacionEmpezoEnZonaDeRiesgo! && !ahoraEnZonaDeRiesgo) {
          // Empezó en zona de riesgo y ahora está fuera: detener simulación
          timer.cancel();
          setState(() {
            simulandoCaminata = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('¡Has salido de la zona de riesgo! Simulación finalizada.'))
          );
          return;
        } else if (!_simulacionEmpezoEnZonaDeRiesgo! && ahoraEnZonaDeRiesgo) {
          // Empezó fuera de zona de riesgo y ahora está dentro: detener simulación
          timer.cancel();
          setState(() {
            simulandoCaminata = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('¡Has entrado a una zona de riesgo! Simulación finalizada.'))
          );
          return;
        }

        setState(() {});
        _pasoActual++;
      } else {
        timer.cancel();
        setState(() {
          simulandoCaminata = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Caminata simulada finalizada.'))
        );
      }
    });
  }

  /// Genera una lista de puntos (LatLng) que simulan una ruta entre dos ubicaciones.
  List<LatLng> _generarRutaSimulada(LatLng origen, LatLng destino, {int pasos = 20}) {
    List<LatLng> ruta = [];
    for (int i = 0; i <= pasos; i++) {
      double lat = origen.latitude + (destino.latitude - origen.latitude) * i / pasos;
      double lng = origen.longitude + (destino.longitude - origen.longitude) * i / pasos;
      ruta.add(LatLng(lat, lng));
    }
    return ruta;
  }

  // --- FUNCIONES DE UBICACIÓN Y PERMISOS ---

  /// Solicita permisos de ubicación y obtiene la ubicación actual del usuario.
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled;
    location_pkg.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == location_pkg.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != location_pkg.PermissionStatus.granted) {
        return;
      }
    }

    _getCurrentLocation();
  }

  /// Obtiene la ubicación actual del usuario y actualiza el mapa.
  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await location_pkg.Location().getLocation();
      final latitude = locationData.latitude;
      final longitude = locationData.longitude;

      if (latitude != null && longitude != null) {
        currentLocation = LatLng(latitude, longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation!, 14),
        );
        _setMarker(currentLocation!, "Ubicación actual", isCurrentLocation: true);

        isInCallao = _isLocationInCallao(currentLocation!);

        // Si está en el Callao, obtiene la predicción de delitos para la ubicación actual
        if (isInCallao) {
          apiService.obtenerPrediccion(latitude, longitude).then((resultado) {
            setState(() {
              prediccionResultados = resultado;
            });
          });
        } else {
          setState(() {
            prediccionResultados = null;
          });
        }

        _checkProximityToRiskZones();
      }
    } catch (e) {
      print("Error al obtener la ubicación: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error al obtener la ubicación actual."),
      ));
    }
  }

  /// Verifica si una ubicación está dentro de los límites del Callao.
  bool _isLocationInCallao(LatLng location) {
    return callaoBounds.contains(location);
  }

  /// Verifica si una ruta pasa por el Callao.
  bool _doesRoutePassThroughCallao(List<LatLng> routePoints) {
    for (LatLng point in routePoints) {
      if (callaoBounds.contains(point)) {
        return true;
      }
    }
    return false;
  }

  // --- FUNCIONES DE MAPA DE CALOR (ZONAS DE RIESGO) ---

  /// Obtiene los datos del mapa de calor desde la API y crea los círculos de riesgo.
  Future<void> _fetchHeatMapData() async {
    try {
      final datosMapaCalor = await apiService.obtenerDatosMapaCalor();
      if (datosMapaCalor != null) {
        _createHeatMapCircles(datosMapaCalor);
      } else {
        print('Error al obtener los datos del mapa de calor');
      }
    } catch (e) {
      print('Error de conexión para obtener el mapa de calor: $e');
    }
  }

  /// Crea los círculos de calor en el mapa a partir de los datos recibidos.
  void _createHeatMapCircles(List<dynamic> data) {
    Set<Circle> circles = {};
    for (var item in data) {
      double? latitude = item['latitud'] is double ? item['latitud'] : double.tryParse(item['latitud'].toString());
      double? longitude = item['longitud'] is double ? item['longitud'] : double.tryParse(item['longitud'].toString());
      String? type = item['sub_tipo'];

      if (latitude != null && longitude != null && type != null) {
        Color color;

        // Asigna color según el tipo de delito
        switch (type.toLowerCase()) {
          case 'homicidio':
            color = Colors.red.withOpacity(0.5);
            break;
          case 'hurto':
            color = Colors.blue.withOpacity(0.5);
            break;
          case 'robo':
            color = Colors.yellow.withOpacity(0.5);
            break;
          case 'violacion':
            color = Colors.purple.withOpacity(0.5);
            break;
          default:
            color = Colors.grey.withOpacity(0.5);
        }

        final circleIdValue = '$latitude-$longitude';
        circles.add(
          Circle(
            circleId: CircleId(circleIdValue),
            center: LatLng(latitude, longitude),
            radius: 15,
            fillColor: color,
            strokeColor: Colors.transparent,
            strokeWidth: 1,
          ),
        );

        circleTypes[circleIdValue] = type;
      } else {
        print('Datos inválidos: latitud=$latitude, longitud=$longitude, tipo=$type');
      }
    }

    setState(() {
      _heatMapCircles = circles;
    });
  }

  // --- FUNCIONES DE ALERTA Y DETECCIÓN DE ZONAS DE RIESGO ---

  /// Verifica si la ubicación actual está cerca de alguna zona de riesgo y actualiza el estado.
  void _checkProximityToRiskZones() {
    if (currentLocation == null) {
      if (zonaDeRiesgo != null) {
        setState(() {
          zonaDeRiesgo = null;
        });
      }
      return;
    }

    Map<String, dynamic>? nuevaZonaDeRiesgo;
    for (var circle in _heatMapCircles) {
      double distance = _calculateDistance(
        currentLocation!.latitude,
        currentLocation!.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );

      if (distance <= 30) {
        nuevaZonaDeRiesgo = {
          'latitud': circle.center.latitude,
          'longitud': circle.center.longitude,
          'tipo': circleTypes[circle.circleId.value] ?? 'Desconocido',
          'distancia': distance.toStringAsFixed(2)
        };
        break;
      }
    }

    if (nuevaZonaDeRiesgo?.toString() != zonaDeRiesgo?.toString()) {
      setState(() {
        zonaDeRiesgo = nuevaZonaDeRiesgo;
      });
    }
  }

  /// Calcula la distancia entre dos puntos geográficos usando la fórmula de Haversine.
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371000;
    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) * cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  // --- LEYENDA DEL MAPA DE CALOR ---

  /// Muestra un diálogo con la leyenda de colores del mapa de calor.
  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Leyenda del Mapa de Calor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendRow(Colors.red.withOpacity(0.5), 'Homicidio'),
              _buildLegendRow(Colors.blue.withOpacity(0.5), 'Hurto'),
              _buildLegendRow(Colors.yellow.withOpacity(0.5), 'Robo'),
              _buildLegendRow(Colors.purple.withOpacity(0.5), 'Violación'),
              _buildLegendRow(Colors.grey.withOpacity(0.5), 'Otro'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          color: color,
        ),
        SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  // --- FUNCIONES DE MARCADORES Y POLILÍNEAS ---

  /// Coloca un marcador en el mapa, diferenciando si es la ubicación actual.
  void _setMarker(LatLng position, String title, {bool isCurrentLocation = false}) {
    final marker = Marker(
      markerId: isCurrentLocation ? MarkerId("current_location") : MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: isCurrentLocation
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
          : BitmapDescriptor.defaultMarker,
    );

    setState(() {
      if (isCurrentLocation) {
        _markers.add(marker);
      } else {
        _markers = _markers.where((m) => m.markerId.value == "current_location").toSet();
        _markers.add(marker);
      }
      polylineCoordinates.clear();
    });
  }

  // --- FUNCIONES DE RIESGO DE RUTA ---

  // Pesos para cada tipo de delito
  final Map<String, double> crimeWeights = {
    'homicidio': 1.0,
    'hurto': 0.3,
    'robo': 0.5,
    'violacion': 0.7,
    'otro': 0.2,
  };

  /// Calcula el puntaje de riesgo de una ruta según la cercanía a zonas de riesgo.
  double _calculateRouteRisk(List<LatLng> routePoints) {
    const double riskZoneRadius = 100;
    double totalRiskScore = 0.0;

    for (LatLng routePoint in routePoints) {
      for (Circle riskZone in _heatMapCircles) {
        double distance = _calculateDistance(
          routePoint.latitude,
          routePoint.longitude,
          riskZone.center.latitude,
          riskZone.center.longitude,
        );

        if (distance <= riskZoneRadius) {
          String crimeType = circleTypes[riskZone.circleId.value] ?? 'otro';
          double weight = crimeWeights[crimeType.toLowerCase()] ?? 0.2;
          totalRiskScore += weight;
        }
      }
    }

    return totalRiskScore;
  }

  // --- FUNCIONES DE AUTOCOMPLETADO Y SELECCIÓN DE DESTINO ---

  /// Actualiza las predicciones de autocompletado de direcciones según el texto ingresado.
  void _onSearchChanged(String query) async {
    if (query.isNotEmpty) {
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey',
      ));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          predictions = data['predictions'] ?? [];
        });
      } else {
        print('Error fetching autocomplete predictions: ${response.statusCode}');
      }
    } else {
      setState(() {
        predictions = [];
      });
    }
  }

  /// Cuando el usuario selecciona una predicción, obtiene la ubicación y la marca en el mapa.
  Future<void> _onPredictionTap(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];
    final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    ));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var location = data['result']['geometry']['location'];
      selectedDestination = LatLng(location['lat'], location['lng']);
      _mapPolylines.clear();
      polylineCoordinates.clear();
      _setMarker(selectedDestination!, "Destino");
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(selectedDestination!, 14));
      _checkDestinationPrediction();
      setState(() {
        predictions = [];
        _searchController.clear();
      });
    } else {
      print('Error fetching place details: ${response.statusCode}');
    }
  }

  /// Obtiene la predicción de delitos para el destino seleccionado.
  Future<void> _checkDestinationPrediction() async {
    if (selectedDestination != null && _isLocationInCallao(selectedDestination!)) {
      prediccionResultadosDestino = await apiService.obtenerPrediccion(
        selectedDestination!.latitude,
        selectedDestination!.longitude,
      );
      setState(() {});
    } else {
      prediccionResultadosDestino = null;
      setState(() {});
    }
  }

  // --- FUNCIONES DE RUTAS Y SIMULACIÓN DE RECORRIDO ---

  /// Obtiene la ruta entre origen y destino, calcula el riesgo y muestra opciones de simulación.
  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    _mapPolylines.clear();
    polylineCoordinates.clear();

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      List<LatLng> initialRoutePoints = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
      double initialRouteRisk = _calculateRouteRisk(initialRoutePoints);

      bool passesThroughCallao = _doesRoutePassThroughCallao(initialRoutePoints);

      // Si la ruta pasa por zonas de riesgo, busca una alternativa más segura
      if (passesThroughCallao && _isRouteNearRiskZones(initialRoutePoints)) {
        _mapPolylines.add(Polyline(
          polylineId: PolylineId('dangerous_route'),
          points: initialRoutePoints,
          color: Colors.red,
          width: 5,
        ));

        List<LatLng>? saferRoute = await _findMinimizedRiskRoute(origin, destination);
        if (saferRoute != null) {
          double saferRouteRisk = _calculateRouteRisk(saferRoute);

          _mapPolylines.add(Polyline(
            polylineId: PolylineId('safe_route'),
            points: saferRoute,
            color: Colors.blue,
            width: 5,
          ));

          // Muestra diálogo para elegir simulación de la ruta más segura
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Rutas disponibles'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Se han encontrado dos rutas posibles:'),
                  SizedBox(height: 8),
                  Text('Ruta original (roja): Riesgo ${initialRouteRisk.toStringAsFixed(2)}'),
                  Text('Ruta alternativa (azul): Riesgo ${saferRouteRisk.toStringAsFixed(2)}'),
                  SizedBox(height: 16),
                  Text('¿Deseas simular el recorrido de la ruta más segura?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simularRecorrido();
                  },
                  child: Text('Iniciar simulación'),
                ),
              ],
            ),
          );
        } else {
          // Si no hay ruta alternativa, solo muestra la original
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Advertencia de ruta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No se encontró una ruta alternativa más segura.'),
                  Text('Riesgo de la ruta: ${initialRouteRisk.toStringAsFixed(2)}'),
                  SizedBox(height: 16),
                  Text('¿Deseas simular el recorrido de esta ruta?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simularRecorrido();
                  },
                  child: Text('Iniciar simulación'),
                ),
              ],
            ),
          );
        }
      } else {
        // Si la ruta es segura, la muestra en azul
        _mapPolylines.add(Polyline(
          polylineId: PolylineId('safe_route'),
          points: initialRoutePoints,
          color: Colors.blue,
          width: 5,
        ));

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Ruta segura'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Se ha encontrado una ruta segura.'),
                Text('Riesgo de la ruta: ${initialRouteRisk.toStringAsFixed(2)}'),
                SizedBox(height: 16),
                Text('¿Deseas simular el recorrido?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _simularRecorrido();
                },
                child: Text('Iniciar simulación'),
              ),
            ],
          ),
        );
      }

      setState(() {});
    } else {
      print("Error en la respuesta de la API de Direcciones: ${data['status']}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No se encontró una ruta entre los puntos dados."),
      ));
    }
  }

  /// Verifica si la ruta pasa cerca de zonas de riesgo.
  bool _isRouteNearRiskZones(List<LatLng> routePoints) {
    const double riskZoneRadius = 50;
    int riskZoneCounter = 0;

    for (LatLng routePoint in routePoints) {
      for (Circle riskZone in _heatMapCircles) {
        double distance = _calculateDistance(
          routePoint.latitude,
          routePoint.longitude,
          riskZone.center.latitude,
          riskZone.center.longitude,
        );
        if (distance <= riskZoneRadius) {
          riskZoneCounter++;
          if (riskZoneCounter > 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Busca una ruta alternativa minimizando el paso por zonas de riesgo.
  Future<List<LatLng>?> _findMinimizedRiskRoute(LatLng origin, LatLng destination) async {
    const List<String> transportModes = ['driving', 'bicycling', 'walking'];
    List<LatLng>? bestRoute;
    int minRiskCount = double.maxFinite.toInt();

    for (String mode in transportModes) {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$mode&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        var route = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> routePoints = _decodePolyline(route);

        int riskCount = _countRiskZonesAlongRoute(routePoints);
        if (riskCount < minRiskCount) {
          minRiskCount = riskCount;
          bestRoute = routePoints;
        }
      }
    }

    return bestRoute;
  }

  /// Cuenta cuántas zonas de riesgo hay a lo largo de una ruta.
  int _countRiskZonesAlongRoute(List<LatLng> routePoints) {
    const double riskZoneRadius = 100;
    int riskZoneCounter = 0;

    for (LatLng routePoint in routePoints) {
      for (Circle riskZone in _heatMapCircles) {
        double distance = _calculateDistance(
          routePoint.latitude,
          routePoint.longitude,
          riskZone.center.latitude,
          riskZone.center.longitude,
        );
        if (distance <= riskZoneRadius) {
          riskZoneCounter++;
        }
      }
    }
    return riskZoneCounter;
  }

  /// Decodifica una polilínea de Google Maps a una lista de LatLng.
  List<LatLng> _decodePolyline(String poly) {
    List<LatLng> points = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // --- FUNCIONES DE GUARDADO Y CALIFICACIÓN DE RUTA ---

  /// Guarda la ruta recorrida en la base de datos y permite calificarla.
  Future<void> _guardarRuta() async {
    if (currentLocation != null && selectedDestination != null) {
      try {
        final response = await apiService.guardarRuta({
          'usuario_id': usuarioId,
          'origen_lat': currentLocation!.latitude,
          'origen_lng': currentLocation!.longitude,
          'destino_lat': selectedDestination!.latitude,
          'destino_lng': selectedDestination!.longitude,
        });

        if (response != null && response['mensaje'] == "Ruta guardada") {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('¡Has llegado a tu destino!'),
              content: Text('¿Deseas calificar esta ruta?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Después'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.ratings,
                      arguments: {
                        'rutaId': response['ruta_id'] ?? 1,
                        'usuarioId': 1,
                      },
                    );
                  },
                  child: Text('Calificar'),
                ),
              ],
            ),
          );

          setState(() {
            rutaEnProgreso = false;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la ruta: $e')),
        );
      }
    }
  }

  /// Simula el recorrido de la ruta y guarda la ruta al finalizar.
  void _simularRecorrido() {
    setState(() {
      rutaEnProgreso = true;
    });

    _simulationTimer = Timer(Duration(seconds: 10), () {
      _guardarRuta();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulando recorrido... Espera 10 segundos.')),
    );
  }

  // --- WIDGET PRINCIPAL (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Navegación con Google Maps"),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- BARRA DE BÚSQUEDA DE DIRECCIONES ---
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Buscar dirección",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.my_location),
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
              ),
              // --- LISTA DE PREDICCIONES DE AUTOCOMPLETADO ---
              if (predictions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: predictions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(predictions[index]['description']),
                        onTap: () => _onPredictionTap(predictions[index]),
                      );
                    },
                  ),
                ),
              // --- MAPA PRINCIPAL ---
              Expanded(
                flex: predictions.isEmpty ? 4 : 2,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentLocation ?? LatLng(-12.0540, -77.1219),
                    zoom: 12,
                  ),
                  onTap: (LatLng tappedPoint) {
                    selectedDestination = tappedPoint;
                    _setMarker(tappedPoint, "Destino seleccionado");
                    _mapController?.animateCamera(CameraUpdate.newLatLng(tappedPoint));
                    _checkDestinationPrediction();
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _getCurrentLocation();
                  },
                  markers: _markers,
                  circles: _heatMapCircles,
                  polylines: _mapPolylines,
                ),
              ),
              // --- BOTÓN PARA SIMULAR CAMINATA ---
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.directions_walk),
                  label: Text(simulandoCaminata ? "Caminata en curso..." : "Simular caminata"),
                  onPressed: simulandoCaminata ? null : _iniciarSimulacionCaminata,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ),
              // --- BOTÓN PARA OBTENER RUTA ENTRE ORIGEN Y DESTINO ---
              if (selectedDestination != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (currentLocation != null && selectedDestination != null) {
                        if (!isPointInCallao(selectedDestination!)) {
                          // Muestra advertencia, pero igual traza la ruta general
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Advertencia'),
                              content: Text('El destino está fuera del Callao. Por falta de información, fuera de esta zona no se detecterá una ruta segura'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Traza la ruta general al cerrar el mensaje
                                    _getRoute(currentLocation!, selectedDestination!);
                                  },
                                  child: Text('Entendido'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Destino dentro del Callao: intenta ambas rutas
                          _getRoute(currentLocation!, selectedDestination!);
                        }
                      }
                    },
                    child: Text("Obtener ruta"),
                  ),
                ),
              // --- PREDICCIÓN DE DELITOS EN ORIGEN Y DESTINO ---
              if (prediccionResultados != null || prediccionResultadosDestino != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showOriginPrediction = true;
                              });
                            },
                            child: Text("Ver Predicción de Origen"),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showOriginPrediction = false;
                              });
                            },
                            child: Text("Ver Predicción de Destino"),
                          ),
                        ],
                      ),
                      if (showOriginPrediction && prediccionResultados != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Predicción de Delitos (Origen):",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text("Homicidio: ${prediccionResultados!['homicidio'].toStringAsFixed(2)}%"),
                            Text("Hurto: ${prediccionResultados!['hurto'].toStringAsFixed(2)}%"),
                            Text("Robo: ${prediccionResultados!['robo'].toStringAsFixed(2)}%"),
                            Text("Violación: ${prediccionResultados!['violacion'].toStringAsFixed(2)}%"),
                          ],
                        ),
                      if (!showOriginPrediction && prediccionResultadosDestino != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Predicción de Delitos (Destino):",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text("Homicidio: ${prediccionResultadosDestino!['homicidio'].toStringAsFixed(2)}%"),
                            Text("Hurto: ${prediccionResultadosDestino!['hurto'].toStringAsFixed(2)}%"),
                            Text("Robo: ${prediccionResultadosDestino!['robo'].toStringAsFixed(2)}%"),
                            Text("Violación: ${prediccionResultadosDestino!['violacion'].toStringAsFixed(2)}%"),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
          // --- INDICADOR DE SIMULACIÓN DE RUTA EN PROGRESO ---
          if (rutaEnProgreso)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Simulando recorrido...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          // --- ALERTA DE ZONA DE RIESGO CERCANA ---
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: GestureDetector(
              onTap: () {
                if (zonaDeRiesgo != null) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Zona de Riesgo Cercana'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Esta cerca a una zona de peligro.'),
                            Text('Tipo de zona: ${zonaDeRiesgo!['tipo']}'),
                            Text('Distancia: ${zonaDeRiesgo!['distancia']} metros'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cerrar'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.all(8),
                color: zonaDeRiesgo != null ? Colors.red : Colors.green,
                child: Text(
                  zonaDeRiesgo != null ? '¡Cuidado!' : 'Alerta',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // --- BOTÓN FLOTANTE PARA MOSTRAR LA LEYENDA DEL MAPA DE CALOR ---
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 28,
            child: FloatingActionButton(
              onPressed: _showLegendDialog,
              child: Icon(Icons.info),
            ),
          ),
        ],
      ),
    );
  }
}