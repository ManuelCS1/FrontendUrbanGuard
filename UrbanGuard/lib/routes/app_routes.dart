import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart' as login_screen;
import '../screens/auth/register_screen.dart' as register_screen;
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/map/report_incident_screen.dart';
import '../screens/map/route_history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/contacts/emergency_contacts_screen.dart';
import '../screens/home/risk_hours_screen.dart';
import '../screens/ratings/ratings_screen.dart';
import '../screens/map/report_history_screen.dart';
import '../screens/home/safe_hours_screen.dart';
import '../screens/home/glossary_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String map = '/map';
  static const String reportIncident = '/report_incident';
  static const String routeHistory = '/route_history';
  static const String settings = '/settings';
  static const String emergencyContacts = '/emergency_contacts';
  static const String riskHours = '/risk_hours';
  static const String ratings = '/ratings';
  static const String reportHistory = '/report_history';
  static const String safeHours = '/safe_hours';
  static const String glossary = '/glossary';

  static final routes = <String, WidgetBuilder>{
    login: (context) => login_screen.LoginScreen(),
    register: (context) => register_screen.RegisterScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    home: (context) => HomeScreen(),
    map: (context) => MapScreen(),
    safeHours: (context) => SafeHoursScreen(),
    glossary: (context) => GlossaryScreen(),

    ratings: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return Scaffold(body: Center(child: Text('Error: No hay argumentos')));
      }
      return RatingsScreen(
        rutaId: args['rutaId'],
        usuarioId: args['usuarioId'],
      );
    },

    reportHistory: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args == null || !args.containsKey('usuarioId')) {
        return Scaffold(
          body: Center(child: Text('Error: No se proporcionó usuarioId')),
        );
      }
      return ReportHistoryScreen(usuarioId: args['usuarioId']);
    },


    reportIncident: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args == null || !args.containsKey('usuarioId')) {
        return Scaffold(
          body: Center(child: Text('Error: No se proporcionó usuarioId')),
        );
      }
      return ReportIncidentScreen(usuarioId: args['usuarioId']);
    },
    settings: (context) => SettingsScreen(),
    riskHours: (context) => RiskHoursScreen(),

    profile: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args == null || args is! Map<String, dynamic> || !args.containsKey('usuarioId')) {
        return Scaffold(
          body: Center(child: Text('Error: No se proporcionó usuarioId')),
        );
      }
      return ProfileScreen(
        usuarioId: args['usuarioId'],
        nombre: args['nombre'] ?? '',
        correo: args['correo'] ?? '',
        celular: args['celular'] ?? '',
      );
    },
    routeHistory: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args == null || args is! Map<String, dynamic> || !args.containsKey('usuarioId')) {
        return Scaffold(
          body: Center(child: Text('Error: No se proporcionó usuarioId')),
        );
      }
      return RouteHistoryScreen(usuarioId: args['usuarioId']);
    },
    emergencyContacts: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args == null || args is! Map<String, dynamic> || !args.containsKey('usuarioId')) {
        return Scaffold(
          body: Center(child: Text('Error: No se proporcionó usuarioId')),
        );
      }
      return EmergencyContactsScreen(usuarioId: args['usuarioId']);
    },
  };
}