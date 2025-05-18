import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  final int usuarioId;
  const ReportIncidentScreen({super.key, required this.usuarioId});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController latCtrl = TextEditingController();
  final TextEditingController lngCtrl = TextEditingController();
  final ApiService api = ApiService();

  final List<String> tipos = ['homicidio', 'robo', 'hurto', 'violacion'];
  String? tipoSel;
  bool enviando = false;
  String? errorMsg;

  void _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { enviando = true; errorMsg = null; });

    final resp = await api.reportarIncidente({
      'usuario_id': widget.usuarioId,
      'tipo_incidente': tipoSel,
      'latitud': latCtrl.text.trim(),
      'longitud': lngCtrl.text.trim(),
      'descripcion': descCtrl.text.trim(),
    });

    setState(() { enviando = false; });

    if (resp != null && resp['mensaje'] != null) {
      if (mounted) Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(resp['mensaje'])));
    } else {
      setState(() { errorMsg = resp?['error'] ?? 'Error desconocido'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de incidente'),
                items: tipos.map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())),
                ).toList(),
                value: tipoSel,
                onChanged: (v) => setState(() => tipoSel = v),
                validator: (v) => v == null ? 'Seleccione un tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: latCtrl,
                decoration: const InputDecoration(labelText: 'Latitud'),
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Ingrese la latitud' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitud'),
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Ingrese la longitud' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 4,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Ingrese una descripción' : null,
              ),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: enviando ? null : _enviar,
                child: enviando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reportar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}