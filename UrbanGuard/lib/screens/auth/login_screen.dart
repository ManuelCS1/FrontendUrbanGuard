import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String correo = '';
  String contrasena = '';
  String? errorMsg;
  bool isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; errorMsg = null; });

    final resp = await AuthService().login(correo, contrasena);
    setState(() { isLoading = false; });

    if (resp != null && resp['id'] != null) {
      Navigator.pushReplacementNamed(context, '/home', arguments: {
        'id': resp['id'],
        'nombre': resp['nombre'],
        'correo': resp['correo'],
        'celular': resp['celular'],
      });
    } else {
      setState(() { errorMsg = resp?['error'] ?? 'Error desconocido'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 20),
              // Logo centrado
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 200, // Ajusta este valor según el tamaño que desees
                ),
              ),
              SizedBox(height: 60), // Espacio entre el logo y los campos
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email), // Opcional: agrega un icono
                  border: OutlineInputBorder(), // Opcional: borde más visible
                ),
                onChanged: (v) => correo = v,
                validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              SizedBox(height: 16), // Espacio entre campos
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock), // Opcional: agrega un icono
                  border: OutlineInputBorder(), // Opcional: borde más visible
                ),
                obscureText: true,
                onChanged: (v) => contrasena = v,
                validator: (v) => v == null || v.length < 4 ? 'Mínimo 4 caracteres' : null,
              ),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), // Botón más alto
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Bordes redondeados
                  ),
                ),
                onPressed: isLoading ? null : _login,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Ingresar', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                child: Text('¿Olvidaste tu contraseña?'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}