class Rating {
  final int id;
  final int usuarioId;
  final int rutaId;
  final int calificacion;
  final String? comentario;

  Rating({
    required this.id,
    required this.usuarioId,
    required this.rutaId,
    required this.calificacion,
    this.comentario,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      usuarioId: json['usuario_id'],
      rutaId: json['ruta_id'],
      calificacion: json['calificacion'],
      comentario: json['comentario'],
    );
  }
}