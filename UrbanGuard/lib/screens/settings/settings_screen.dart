import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            child: Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Política de Privacidad'),
            onTap: () => _showDialog(
              'Política de Privacidad',
              'Aquí va el texto de la política de privacidad de la aplicación. Puedes personalizar este texto según tus necesidades legales.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Términos y Condiciones'),
            onTap: () => _showDialog(
              'Términos y Condiciones',
              'Aquí van los términos y condiciones de uso de la aplicación. Personaliza este texto según tus requerimientos.',
            ),
          ),
          SwitchListTile(
            secondary: Icon(Icons.notifications_active),
            title: Text('Notificaciones'),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
              _saveNotificationPreference(value);
            },
          ),
        ],
      ),
    );
  }
}