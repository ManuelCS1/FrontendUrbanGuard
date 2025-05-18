import 'package:flutter/material.dart';

class RiskZoneLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 20, color: color),
        SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}