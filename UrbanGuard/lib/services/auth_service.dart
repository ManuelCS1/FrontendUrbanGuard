import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> login(String correo, String contrasena) async {
    final result = await _api.login(correo, contrasena);
    return result;
  }

  Future<Map<String, dynamic>?> register(Map<String, dynamic> data) async {
    final result = await _api.register(data);
    return result;
  }

  // Nuevo método: verificar correo y celular
  Future<Map<String, dynamic>?> verificarRecuperacion(String correo, String celular) async {
    final result = await _api.verificarRecuperacion(correo, celular);
    return result;
  }

  // Nuevo método: cambiar contraseña
  Future<Map<String, dynamic>?> cambiarContrasena(String correo, String celular, String nuevaContrasena) async {
    final result = await _api.cambiarContrasena(correo, celular, nuevaContrasena);
    return result;
  }
}