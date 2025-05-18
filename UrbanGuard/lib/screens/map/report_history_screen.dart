import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ReportHistoryScreen extends StatelessWidget {
  final int usuarioId;
  const ReportHistoryScreen({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Reportes')),
      body: FutureBuilder<List<dynamic>?>(
        future: ApiService().obtenerReportes(usuarioId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data == null) {
            return const Center(child: Text('No se pudo cargar el historial.'));
          }
          final lista = snap.data!;
          if (lista.isEmpty) {
            return const Center(child: Text('No tienes reportes registrados.'));
          }
          return ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final r = lista[i];
              return ListTile(
                leading: const Icon(Icons.report),
                title: Text(r['tipo_incidente'].toString().toUpperCase()),
                subtitle: Text(r['descripcion']),
                trailing: Text(r['fecha'].toString().substring(0, 10)),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(r['tipo_incidente'].toString().toUpperCase()),
                    content: Text(
                      'Descripción: ${r['descripcion']}\n'
                          'Latitud: ${r['latitud']}\n'
                          'Longitud: ${r['longitud']}\n'
                          'Fecha: ${r['fecha']}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}