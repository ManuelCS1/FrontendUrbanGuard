class User {
  final int id;
  final String nombre;
  final String correo;
  final String celular;

  User({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.celular
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      celular: json['celular'] ?? '',
    );
  }
}