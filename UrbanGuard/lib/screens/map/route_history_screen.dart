import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RouteHistoryScreen extends StatefulWidget {
  final int usuarioId;
  RouteHistoryScreen({required this.usuarioId});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  List<dynamic> rutas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRutas();
  }

  void _loadRutas() async {
    final resp = await ApiService().getRutas(widget.usuarioId);
    setState(() {
      rutas = resp ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial de Rutas')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: rutas.length,
        itemBuilder: (context, i) {
          final r = rutas[i];
          return ListTile(
            title: Text('Ruta ${r['id']}'),
            subtitle: Text(
                'Origen: (${r['origen_lat']}, ${r['origen_lng']})\nDestino: (${r['destino_lat']}, ${r['destino_lng']})'),
          );
        },
      ),
    );
  }
}