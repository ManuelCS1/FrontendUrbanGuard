import 'dart:math';
import 'package:flutter/material.dart';

class AdviceScreen extends StatefulWidget {
  @override
  State<AdviceScreen> createState() => _AdviceScreenState();

  // Método estático para obtener un consejo aleatorio
  static String obtenerConsejoAleatorio() {
    final random = Random();
    return _AdviceScreenState.consejos[random.nextInt(_AdviceScreenState.consejos.length)];
  }
}

class _AdviceScreenState extends State<AdviceScreen> {
  static final List<String> consejos = [
    'Siempre camina por rutas bien iluminadas y transitadas.',
    'Usa la aplicación para mantenerte informado sobre zonas seguras y de riesgo.',
    'Mantén tus pertenencias personales cerca y seguras.',
    'Reporta cualquier incidente sospechoso a las autoridades.',
    'Usa aplicaciones que te indiquen zonas de riesgo en tiempo real.',
    'Comparte tu ubicación con un contacto de confianza cuando salgas.',
    'Evita transitar solo por la noche en zonas desconocidas.',
    'Aprende y sigue consejos de seguridad personal.',
    'Mantente alerta a tu entorno y evita distracciones.',
    'Usa rutas seguras recomendadas por la aplicación.',
    'Configura alertas para recibir notificaciones de zonas peligrosas.',
    'Participa reportando incidentes para ayudar a la comunidad.',
    'Ten a mano números de emergencia y contactos confiables.',
    'No aceptes ayuda de desconocidos en la calle.',
    'Cambia tus rutas habituales para evitar patrones predecibles.',
    'Usa transporte seguro y autorizado.',
    'Mantén tu teléfono cargado y con saldo para emergencias.',
    'Evita mostrar objetos de valor en público.',
    'Aprende técnicas básicas de defensa personal.',
    'Mantente informado sobre la seguridad en tu zona.',
  ];

  String consejoActual = '';

  @override
  void initState() {
    super.initState();
    _seleccionarConsejoAleatorio();
  }

  void _seleccionarConsejoAleatorio() {
    final random = Random();
    setState(() {
      consejoActual = consejos[random.nextInt(consejos.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consejo de Seguridad'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            consejoActual,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}