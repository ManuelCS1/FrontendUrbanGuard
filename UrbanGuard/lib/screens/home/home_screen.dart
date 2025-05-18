import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../advice/advice_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Mostrar el consejo después de que la pantalla se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarConsejoDiario(context);
    });
  }

  void _mostrarConsejoDiario(BuildContext context) {
    final consejoAleatorio = AdviceScreen.obtenerConsejoAleatorio(); // Llama al método estático

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('Consejo de Seguridad'),
        content: Text(consejoAleatorio), // Muestra el consejo aleatorio
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final usuarioId = args?['id'];
    final nombre = args?['nombre'] ?? '';
    final correo = args?['correo'] ?? '';
    final celular = args?['celular'] ?? '';

    // Argumentos para pasar a las otras pantallas
    final userArgs = {
      'usuarioId': usuarioId,
      'nombre': nombre,
      'correo': correo,
      'celular': celular,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('UrbanGuard'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile, arguments: userArgs),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Mapa de Zonas de Riesgo'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.map, arguments: userArgs),
          ),
          ListTile(
            leading: Icon(Icons.report),
            title: Text('Reportar Incidente'),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.reportIncident,
              arguments: userArgs,
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Historial de Reportes de Incidentes'),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.reportHistory,
              arguments: userArgs,
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text('Glosario de Seguridad'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.glossary),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Historial de Rutas'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.routeHistory, arguments: userArgs),
          ),
          ListTile(
            leading: Icon(Icons.contacts),
            title: Text('Contactos de Emergencia'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts, arguments: userArgs),
          ),
          ListTile(
            leading: Icon(Icons.access_time_filled, color: Colors.red),
            title: Text('Horarios de Mayor Incidencia Delictiva'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.riskHours),
          ),
          ListTile(
            leading: Icon(Icons.access_time_filled, color: Colors.green),
            title: Text('Horarios de Menor Riesgo'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.safeHours),
          ),
          // --- NUEVO BOTÓN DE CONSEJO DE SEGURIDAD ---
          ListTile(
            leading: Icon(Icons.lightbulb, color: Colors.amber),
            title: Text('Consejo de seguridad'),
            onTap: () => _mostrarConsejoDiario(context),
          ),
        ],
      ),
    );
  }
}