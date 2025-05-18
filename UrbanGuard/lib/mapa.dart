import 'package:frontendappmovil/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as location_pkg;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? prediccionResultados;
  Map<String, dynamic>? prediccionResultadosDestino;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  List<LatLng> polylineCoordinates = [];
  Set<Marker> _markers = {};
  Set<Circle> _heatMapCircles = {};
  Set<Polyline> _mapPolylines = {};
  String apiKey = 'AIzaSyAljprSFUDcX57Z-rsSTwEYZWLhHYddsio';
  location_pkg.Location location = location_pkg.Location();
  List<Map<String, dynamic>> predictions = [];
  LatLng? selectedDestination;
  LatLng? currentLocation;
  Map<String, dynamic>? zonaDeRiesgo;
  bool isInCallao = false;
  bool showOriginPrediction = true; // Controla qué vista mostrar


  final LatLngBounds callaoBounds = LatLngBounds(
    southwest: LatLng(-12.125, -77.174),
    northeast: LatLng(-11.994, -77.027),
  );

  Map<String, String> circleTypes = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _fetchHeatMapData();
  }

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

  bool _isLocationInCallao(LatLng location) {
    return callaoBounds.contains(location);
  }

  bool _doesRoutePassThroughCallao(List<LatLng> routePoints) {
    for (LatLng point in routePoints) {
      if (callaoBounds.contains(point)) {
        return true;
      }
    }
    return false;
  }

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

  void _createHeatMapCircles(List<dynamic> data) {
    Set<Circle> circles = {};
    for (var item in data) {
      double? latitude = item['latitud'] is double ? item['latitud'] : double.tryParse(item['latitud'].toString());
      double? longitude = item['longitud'] is double ? item['longitud'] : double.tryParse(item['longitud'].toString());
      String? type = item['sub_tipo'];

      if (latitude != null && longitude != null && type != null) {
        Color color;

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

  void _checkProximityToRiskZones() {
    if (currentLocation == null || !isInCallao) return;

    for (var circle in _heatMapCircles) {
      double distance = _calculateDistance(
        currentLocation!.latitude,
        currentLocation!.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );

      if (distance <= 50) {
        setState(() {
          zonaDeRiesgo = {
            'latitud': circle.center.latitude,
            'longitud': circle.center.longitude,
            'tipo': circleTypes[circle.circleId.value] ?? 'Desconocido',
            'distancia': distance.toStringAsFixed(2)
          };
        });
        break;
      } else {
        setState(() {
          zonaDeRiesgo = null;
        });
      }
    }
  }

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
        _markers = _markers.where((m) => m.markerId.value ==
            "current_location").toSet();
        _markers.add(marker);
      }
      polylineCoordinates.clear();
    });
  }

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
                    _checkDestinationPrediction(); // Check prediction when setting destination
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
              if (selectedDestination != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (currentLocation != null && selectedDestination != null) {
                        _getRoute(currentLocation!, selectedDestination!);
                      }
                    },
                    child: Text("Obtener indicaciones"),
                  ),
                ),
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
      _checkDestinationPrediction(); // Call to check destination prediction
    } else {
      print('Error fetching place details: ${response.statusCode}');
    }
  }

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
  final Map<String, double> crimeWeights = {
    'homicidio': 1.0,
    'hurto': 0.3,
    'robo': 0.5,
    'violacion': 0.7,
    'otro': 0.2,
  };

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

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Ruta alternativa segura recomendada.\nRiesgo original: ${initialRouteRisk.toStringAsFixed(2)}\nRiesgo alternativo: ${saferRouteRisk.toStringAsFixed(2)}"),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("No se encontró una ruta segura. Se recomienda pasar con precaución.\nRiesgo de la ruta: ${initialRouteRisk.toStringAsFixed(2)}"),
          ));
        }
      } else {
        _mapPolylines.add(Polyline(
          polylineId: PolylineId('safe_route'),
          points: initialRoutePoints,
          color: Colors.blue,
          width: 5,
        ));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ruta segura encontrada.\nRiesgo de la ruta: ${initialRouteRisk.toStringAsFixed(2)}"),
        ));
      }

      setState(() {});
    } else {
      print("Error en la respuesta de la API de Direcciones: ${data['status']}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No se encontró una ruta entre los puntos dados."),
      ));
    }
  }

  void _addPolyline(String id, List<LatLng> points, Color color) {
    setState(() {
      _mapPolylines.add(Polyline(
        polylineId: PolylineId(id),
        points: points,
        color: color,
        width: 5,
      ));
    });
  }

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
}

