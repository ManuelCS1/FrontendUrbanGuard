import 'package:flutter/material.dart';
// Importa tu LoginScreen aquí
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final int usuarioId;
  final String nombre;
  final String correo;
  final String celular;

  ProfileScreen({
    required this.usuarioId,
    required this.nombre,
    required this.correo,
    required this.celular,
  });

  void _logout(BuildContext context) {
    // Aquí puedes limpiar datos de sesión si es necesario
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24),
              Text(
                nombre,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Divider(thickness: 1, height: 32),
              ListTile(
                leading: Icon(Icons.email, color: Colors.blueGrey),
                title: Text('Correo'),
                subtitle: Text(correo),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.blueGrey),
                title: Text('Celular'),
                subtitle: Text(celular),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: Icon(Icons.logout),
                label: Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}