import 'package:flutter/material.dart';

class SafeHoursScreen extends StatelessWidget {
  // Horarios de ejemplo con menor incidencia (puedes cambiar los datos)
  final List<Map<String, dynamic>> horarios = [
    {'hora': '06:00 - 08:00', 'riesgo': 2},
    {'hora': '08:00 - 10:00', 'riesgo': 3},
    {'hora': '10:00 - 12:00', 'riesgo': 4},
    {'hora': '12:00 - 14:00', 'riesgo': 5},
    {'hora': '00:00 - 06:00', 'riesgo': 6},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Horarios de Menor Riesgo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estos son los horarios más seguros para desplazarte:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: horarios.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final item = horarios[index];
                  return ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green, size: 32),
                    title: Text(
                      item['hora'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['riesgo']}%',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Estos porcentajes son informativos y pueden variar según la zona.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}