class RiskZone {
  final double latitud;
  final double longitud;
  final String subTipo;

  RiskZone({
    required this.latitud,
    required this.longitud,
    required this.subTipo,
  });

  factory RiskZone.fromJson(Map<String, dynamic> json) {
    return RiskZone(
      latitud: json['latitud'] is double ? json['latitud'] : double.parse(json['latitud'].toString()),
      longitud: json['longitud'] is double ? json['longitud'] : double.parse(json['longitud'].toString()),
      subTipo: json['sub_tipo'] ?? '',
    );
  }
}