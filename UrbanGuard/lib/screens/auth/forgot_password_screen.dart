import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _changeKey = GlobalKey<FormState>();
  String correo = '';
  String celular = '';
  String nuevaContrasena = '';
  String repetirContrasena = '';
  String? infoMsg;
  String? errorMsg;
  bool isLoading = false;
  bool puedeCambiar = false;

  void _verificarDatos() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; infoMsg = null; errorMsg = null; });

    final resp = await AuthService().verificarRecuperacion(correo, celular);
    setState(() { isLoading = false; });

    if (resp != null && resp['mensaje'] != null) {
      setState(() {
        infoMsg = resp['mensaje'];
        puedeCambiar = true;
      });
    } else {
      setState(() { errorMsg = resp?['error'] ?? 'Error desconocido'; });
    }
  }

  void _cambiarContrasena() async {
    if (!_changeKey.currentState!.validate()) return;
    setState(() { isLoading = true; infoMsg = null; errorMsg = null; });

    final resp = await AuthService().cambiarContrasena(correo, celular, nuevaContrasena);
    setState(() { isLoading = false; });

    if (resp != null && resp['mensaje'] != null) {
      setState(() {
        infoMsg = resp['mensaje'];
        puedeCambiar = false;
      });
      // Espera un momento para que el usuario vea el mensaje y luego redirige
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } else {
      setState(() { errorMsg = resp?['error'] ?? 'Error desconocido'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            if (!puedeCambiar)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Correo'),
                      onChanged: (v) => correo = v,
                      validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Celular'),
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => celular = v,
                      validator: (v) => v == null || v.length < 6 ? 'Celular inválido' : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : _verificarDatos,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Verificar datos'),
                    ),
                  ],
                ),
              ),
            if (puedeCambiar)
              Form(
                key: _changeKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Nueva contraseña'),
                      obscureText: true,
                      onChanged: (v) => nuevaContrasena = v,
                      validator: (v) => v == null || v.length < 2 ? 'Mínimo 3 caracteres' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Repetir nueva contraseña'),
                      obscureText: true,
                      onChanged: (v) => repetirContrasena = v,
                      validator: (v) => v != nuevaContrasena ? 'No coinciden' : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : _cambiarContrasena,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Cambiar contraseña'),
                    ),
                  ],
                ),
              ),
            if (infoMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(infoMsg!, style: TextStyle(color: Colors.green)),
              ),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}