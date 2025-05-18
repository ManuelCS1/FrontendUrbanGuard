import 'package:flutter/material.dart';

class GlossaryScreen extends StatefulWidget {
  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final List<Map<String, String>> terms = [
    {
      'term': 'Zona de riesgo',
      'definition': 'Área geográfica identificada con alta incidencia de delitos o peligros para el usuario.'
    },
    {
      'term': 'Ruta segura',
      'definition': 'Trayecto recomendado por la aplicación que minimiza la exposición a zonas de riesgo.'
    },
    {
      'term': 'Incidente',
      'definition': 'Evento reportado por un usuario relacionado con delitos o situaciones de peligro.'
    },
    {
      'term': 'Reporte de incidente',
      'definition': 'Funcionalidad que permite al usuario informar sobre un hecho delictivo o situación peligrosa.'
    },
    {
      'term': 'Calificación de ruta',
      'definition': 'Valoración que el usuario otorga a una ruta recorrida, basada en su experiencia de seguridad.'
    },
    {
      'term': 'Contacto de emergencia',
      'definition': 'Persona registrada por el usuario para ser notificada o contactada en caso de emergencia.'
    },
    {
      'term': 'Consejo de seguridad',
      'definition': 'Recomendación o tip brindado por la aplicación para mejorar la seguridad personal.'
    },
    {
      'term': 'Mapa de calor',
      'definition': 'Visualización gráfica que muestra la concentración de incidentes en diferentes zonas.'
    },
    {
      'term': 'Simulación de caminata',
      'definition': 'Función que permite al usuario ensayar un recorrido para evaluar su seguridad.'
    },
    {
      'term': 'Predicción de delitos',
      'definition': 'Estimación basada en datos históricos sobre la probabilidad de ocurrencia de delitos en una zona.'
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredTerms = [];
  String? notFoundMessage;

  @override
  void initState() {
    super.initState();
    filteredTerms = List.from(terms);
  }

  void _showDefinition(BuildContext context, String term, String definition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(term),
        content: Text(definition),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _searchTerm() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredTerms = List.from(terms);
        notFoundMessage = null;
      });
      return;
    }
    final results = terms.where((t) => t['term']!.toLowerCase().contains(query)).toList();
    setState(() {
      filteredTerms = results;
      notFoundMessage = results.isEmpty ? 'El término no está disponible en el glosario.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Glosario de Seguridad')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar término...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchTerm(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchTerm,
                  tooltip: 'Buscar',
                ),
              ],
            ),
          ),
          if (notFoundMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                notFoundMessage!,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredTerms.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final t = filteredTerms[index];
                return ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue),
                  title: Text(t['term']!, style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _showDefinition(context, t['term']!, t['definition']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}