import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final int usuarioId;
  EmergencyContactsScreen({required this.usuarioId});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<dynamic> contactos = [];
  bool isLoading = true;
  int? selectedContactId;

  @override
  void initState() {
    super.initState();
    _loadContactos();
  }

  void _loadContactos() async {
    setState(() { isLoading = true; });
    final resp = await ApiService().getContactos(widget.usuarioId);
    setState(() {
      contactos = resp ?? [];
      isLoading = false;
      selectedContactId = null;
    });
  }

  void _showAddOrEditDialog({Map<String, dynamic>? contacto}) {
    final nombreCtrl = TextEditingController(text: contacto?['nombre'] ?? '');
    final telefonoCtrl = TextEditingController(text: contacto?['telefono'] ?? '');
    final isEdit = contacto != null;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(isEdit ? 'Modificar Contacto' : 'Agregar Contacto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: telefonoCtrl,
                  decoration: InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorMsg!,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Atrás'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  final telefono = telefonoCtrl.text.trim();
                  if (nombre.isEmpty || telefono.isEmpty) {
                    setStateDialog(() {
                      errorMsg = 'Debe completar todos los campos obligatorios.';
                    });
                    return;
                  }
                  if (isEdit) {
                    await ApiService().modificarContacto(contacto!['id'], {
                      'nombre': nombre,
                      'telefono': telefono,
                    });
                  } else {
                    await ApiService().agregarContacto({
                      'usuario_id': widget.usuarioId,
                      'nombre': nombre,
                      'telefono': telefono,
                    });
                  }
                  Navigator.pop(context);
                  _loadContactos();
                },
                child: Text(isEdit ? 'Modificar' : 'Agregar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _eliminarContacto() async {
    final contacto = contactos.firstWhere((c) => c['id'] == selectedContactId, orElse: () => null);
    if (contacto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleccione un contacto')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Contacto'),
        content: Text('¿Seguro que quiere eliminar este contacto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService().eliminarContacto(contacto['id']);
      _loadContactos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contactos de Emergencia'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Agregar',
            onPressed: () => _showAddOrEditDialog(),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Modificar',
            onPressed: selectedContactId == null
                ? () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Seleccione un contacto')),
            )
                : () {
              final contacto = contactos.firstWhere((c) => c['id'] == selectedContactId);
              _showAddOrEditDialog(contacto: contacto);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Eliminar',
            onPressed: _eliminarContacto,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : contactos.isEmpty
          ? Center(child: Text('No tienes contactos de emergencia.'))
          : ListView.builder(
        itemCount: contactos.length,
        itemBuilder: (context, i) {
          final c = contactos[i];
          final isSelected = c['id'] == selectedContactId;
          return ListTile(
            title: Text(c['nombre']),
            subtitle: Text(c['telefono']),
            selected: isSelected,
            selectedTileColor: Colors.blue[50],
            onTap: () {
              setState(() {
                selectedContactId = isSelected ? null : c['id'];
              });
            },
          );
        },
      ),
    );
  }
}