import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://bdurbanguard-api.onrender.com';

  // USUARIOS
  Future<Map<String, dynamic>?> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en registro: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String correo, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> recuperar(String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/recuperar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en recuperación: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPerfil(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/usuarios/$usuarioId'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }

  // RUTAS
  Future<Map<String, dynamic>?> guardarRuta(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rutas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al guardar ruta: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getRutas(int usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rutas/$usuarioId'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al obtener rutas: $e');
      return null;
    }
  }

  // CONTACTOS DE EMERGENCIA
  Future<List<dynamic>?> getContactos(int usuarioId) async {
    final resp = await http.get(Uri.parse('$baseUrl/contactos/$usuarioId'));
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }

  Future agregarContacto(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/contactos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  Future modificarContacto(int contactoId, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$baseUrl/contactos/$contactoId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  Future eliminarContacto(int contactoId) async {
    await http.delete(Uri.parse('$baseUrl/contactos/$contactoId'));
  }

  // CONSEJOS DE SEGURIDAD
  Future<Map<String, dynamic>?> agregarConsejo(String texto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/consejos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'texto': texto}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al agregar consejo: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getConsejos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/consejos'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al obtener consejos: $e');
      return null;
    }
  }

  // CALIFICACIONES DE RUTAS
  Future<Map<String, dynamic>?> calificarRuta(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calificaciones'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al calificar ruta: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getCalificaciones(int rutaId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/calificaciones/$rutaId'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al obtener calificaciones: $e');
      return null;
    }
  }

  // INCIDENTES
  Future<List<dynamic>?> getIncidentes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/incidentes'));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al obtener incidentes: $e');
      return null;
    }
  }

  // HEATMAP
  Future<List<dynamic>?> obtenerDatosMapaCalor() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/heatmap_data'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al obtener datos del mapa de calor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al conectar para mapa de calor: $e');
      return null;
    }
  }

  // PREDICCIÓN DE RIESGO
  Future<Map<String, dynamic>?> obtenerPrediccion(double latitud, double longitud, {int hora = -1}) async {
    try {
      final now = DateTime.now();
      final horaEnvio = hora == -1 ? now.hour : hora;

      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitud': latitud,
          'longitud': longitud,
          'hora': horaEnvio,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error en predicción: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al conectar para predicción: $e');
      return null;
    }
  }
  // RECUPERACIÓN Y CAMBIO DE CONTRASEÑA (NUEVO FLUJO)
  Future<Map<String, dynamic>?> verificarRecuperacion(String correo, String celular) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/recuperar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'celular': celular}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en verificación de recuperación: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> cambiarContrasena(String correo, String celular, String nuevaContrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/recuperar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'celular': celular, 'nueva_contrasena': nuevaContrasena}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      print('Error al cambiar contraseña: $e');
      return null;
    }
  }

  // REPORTES DE INCIDENTES
  Future<Map<String, dynamic>?> reportarIncidente(Map<String, dynamic> data) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/reportes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(resp.body);
    } catch (e) {
      print('Error al reportar incidente: $e');
      return null;
    }
  }

  Future<List<dynamic>?> obtenerReportes(int usuarioId) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/reportes/$usuarioId'));
      return jsonDecode(resp.body);
    } catch (e) {
      print('Error al obtener reportes: $e');
      return null;
    }
  }
}