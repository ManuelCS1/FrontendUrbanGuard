class Incident {
  final double latitud;
  final double longitud;
  final String subTipo;

  Incident({
    required this.latitud,
    required this.longitud,
    required this.subTipo,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      latitud: json['latitud'] is double ? json['latitud'] : double.parse(json['latitud'].toString()),
      longitud: json['longitud'] is double ? json['longitud'] : double.parse(json['longitud'].toString()),
      subTipo: json['sub_tipo'] ?? '',
    );
  }
}