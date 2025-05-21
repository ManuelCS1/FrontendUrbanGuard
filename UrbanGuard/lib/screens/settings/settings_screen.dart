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
              '''Esta aplicación recopila y utiliza información personal únicamente con el fin de mejorar la experiencia del usuario y ofrecer las funcionalidades principales, como la geolocalización y la visualización de mapas.

Datos que recopilamos:
- Ubicación geográfica del dispositivo, solo cuando el usuario lo permite.
- Preferencias de configuración almacenadas localmente en el dispositivo.

Uso de la información:
- La ubicación se utiliza exclusivamente para mostrar la posición del usuario en el mapa y para funcionalidades relacionadas con la visualización de distritos.
- No compartimos información personal ni de ubicación con terceros.
- No almacenamos datos personales en servidores externos; toda la información se guarda localmente en el dispositivo.

Permisos:
- La app solicita acceso a la ubicación solo para brindar los servicios mencionados.
- El usuario puede revocar estos permisos en cualquier momento desde la configuración del dispositivo.

Cambios en la política:
- Nos reservamos el derecho de modificar esta política de privacidad. Cualquier cambio será notificado a través de la aplicación.

Si tienes dudas o consultas sobre nuestra política de privacidad, puedes contactarnos a través del correo de soporte disponible en la aplicación.
''',
            ),
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Términos y Condiciones'),
            onTap: () => _showDialog(
              'Términos y Condiciones',
              '''Al utilizar esta aplicación, aceptas los siguientes términos y condiciones:

1. Uso de la aplicación:
Esta app está destinada a facilitar la visualización de mapas y la ubicación dentro de la provincia de Ilo. El usuario es responsable de utilizar la información proporcionada de manera adecuada.

2. Permisos y datos:
La app solicita permisos de ubicación para ofrecer sus funcionalidades principales. El usuario puede aceptar o rechazar estos permisos en cualquier momento.

3. Propiedad intelectual:
Todos los contenidos, mapas y diseños de la aplicación son propiedad de los desarrolladores o de sus respectivos titulares y están protegidos por las leyes de propiedad intelectual.

4. Limitación de responsabilidad:
La información mostrada en la app es referencial y puede no ser exacta o estar actualizada. No nos hacemos responsables por el uso indebido de la información ni por daños derivados del uso de la aplicación.

5. Modificaciones:
Nos reservamos el derecho de modificar estos términos y condiciones en cualquier momento. Los cambios serán notificados a través de la aplicación.

Si tienes preguntas sobre estos términos, puedes contactarnos mediante el correo de soporte disponible en la app.
''',
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