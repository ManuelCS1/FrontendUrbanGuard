class Advice {
  final int id;
  final String texto;

  Advice({required this.id, required this.texto});

  factory Advice.fromJson(Map<String, dynamic> json) {
    return Advice(
      id: json['id'],
      texto: json['texto'],
    );
  }
}