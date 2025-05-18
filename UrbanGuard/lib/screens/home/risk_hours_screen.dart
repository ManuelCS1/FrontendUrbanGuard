import 'package:flutter/material.dart';

class RiskHoursScreen extends StatelessWidget {
  // Horarios de ejemplo (puedes cambiar los datos)
  final List<Map<String, dynamic>> horarios = [
    {'hora': '18:00 - 20:00', 'riesgo': 32},
    {'hora': '20:00 - 22:00', 'riesgo': 28},
    {'hora': '16:00 - 18:00', 'riesgo': 18},
    {'hora': '22:00 - 00:00', 'riesgo': 12},
    {'hora': '14:00 - 16:00', 'riesgo': 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Horarios de Mayor Riesgo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evita desplazarte en estos horarios si es posible:',
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
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
                    title: Text(
                      item['hora'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['riesgo']}%',
                        style: TextStyle(
                          color: Colors.redAccent,
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