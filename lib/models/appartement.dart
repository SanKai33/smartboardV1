class Appartement {
  String id;
  String numero;
  String batiment;
  String typologie;
  int nombrePersonnes;
  String residenceId;
  int nombreLitsSimples;
  int nombreLitsDoubles;
  int nombreSallesDeBains;

  Appartement({
    required this.id,
    required this.numero,
    required this.batiment,
    required this.typologie,
    required this.nombrePersonnes,
    required this.residenceId,
    required this.nombreLitsSimples,
    required this.nombreLitsDoubles,
    required this.nombreSallesDeBains,
  });

  factory Appartement.fromMap(Map<String, dynamic> map, String id) {
    return Appartement(
      id: id,
      numero: map['numero'] ?? '',
      batiment: map['batiment'] ?? '',
      typologie: map['typologie'] ?? '',
      nombrePersonnes: map['nombrePersonnes'] ?? 0,
      residenceId: map['residenceId'] ?? '',
      nombreLitsSimples: map['nombreLitsSimples'] ?? 0,
      nombreLitsDoubles: map['nombreLitsDoubles'] ?? 0,
      nombreSallesDeBains: map['nombreSallesDeBains'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'batiment': batiment,
      'typologie': typologie,
      'nombrePersonnes': nombrePersonnes,
      'residenceId': residenceId,
      'nombreLitsSimples': nombreLitsSimples,
      'nombreLitsDoubles': nombreLitsDoubles,
      'nombreSallesDeBains': nombreSallesDeBains,
    };
  }
}