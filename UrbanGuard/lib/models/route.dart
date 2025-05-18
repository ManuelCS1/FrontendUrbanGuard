class RouteModel {
  final int id;
  final int usuarioId;
  final double origenLat;
  final double origenLng;
  final double destinoLat;
  final double destinoLng;
  final int? calificacion;

  RouteModel({
    required this.id,
    required this.usuarioId,
    required this.origenLat,
    required this.origenLng,
    required this.destinoLat,
    required this.destinoLng,
    this.calificacion,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      usuarioId: json['usuario_id'],
      origenLat: json['origen_lat'],
      origenLng: json['origen_lng'],
      destinoLat: json['destino_lat'],
      destinoLng: json['destino_lng'],
      calificacion: json['calificacion'],
    );
  }
}