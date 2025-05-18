import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '';
  String correo = '';
  String celular = '';
  String contrasena = '';
  String? errorMsg;
  bool isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; errorMsg = null; });

    final data = {
      'nombre': nombre,
      'correo': correo,
      'celular': celular,
      'contrasena': contrasena,
    };

    final resp = await AuthService().register(data);
    setState(() { isLoading = false; });

    if (resp != null && resp['mensaje'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro exitoso, ahora inicia sesión.')),
      );
      Navigator.pop(context);
    } else {
      setState(() { errorMsg = resp?['error'] ?? 'Error desconocido'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre'),
                onChanged: (v) => nombre = v,
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Correo'),
                onChanged: (v) => correo = v,
                validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Celular'),
                onChanged: (v) => celular = v,
                validator: (v) => v == null || v.length < 8 ? 'Celular inválido' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onChanged: (v) => contrasena = v,
                validator: (v) => v == null || v.length < 2 ? 'Mínimo 3 caracteres' : null,
              ),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _register,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}