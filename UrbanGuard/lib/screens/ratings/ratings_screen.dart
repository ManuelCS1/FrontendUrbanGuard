import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RatingsScreen extends StatefulWidget {
  final int rutaId;
  final int usuarioId;
  RatingsScreen({required this.rutaId, required this.usuarioId});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<dynamic> calificaciones = [];
  bool isLoading = true;
  int calificacion = 5;
  String comentario = '';

  @override
  void initState() {
    super.initState();
    _loadCalificaciones();
  }

  void _loadCalificaciones() async {
    final resp = await ApiService().getCalificaciones(widget.rutaId);
    setState(() {
      calificaciones = resp ?? [];
      isLoading = false;
    });
  }

  void _calificar() async {
    await ApiService().calificarRuta({
      'usuario_id': widget.usuarioId,
      'ruta_id': widget.rutaId,
      'calificacion': calificacion,
      'comentario': comentario,
    });
    comentario = '';
    _loadCalificaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calificaciones de Ruta')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: calificaciones.length,
              itemBuilder: (context, i) {
                final c = calificaciones[i];
                return ListTile(
                  title: Text('Calificación: ${c['calificacion']}'),
                  subtitle: Text(c['comentario'] ?? ''),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<int>(
                  value: calificacion,
                  items: List.generate(5, (i) => i + 1)
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text('$e estrellas'),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => calificacion = v!),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Comentario'),
                  onChanged: (v) => comentario = v,
                ),
                ElevatedButton(
                  onPressed: _calificar,
                  child: Text('Calificar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}