class Contact {
  final int id;
  final int usuarioId;
  final String nombre;
  final String telefono;

  Contact({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.telefono,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      usuarioId: json['usuario_id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
    );
  }
}