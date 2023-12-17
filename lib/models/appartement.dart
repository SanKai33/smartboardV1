class Appartement {
  String id;
  String numero;
  String batiment;
  String typologie;
  int nombrePersonnes;
  String residenceId;

  Appartement({
    required this.id,
    required this.numero,
    required this.batiment,
    required this.typologie,
    required this.nombrePersonnes,
    required this.residenceId,
  });

  factory Appartement.fromMap(Map<String, dynamic> map, String id) {
    return Appartement(
      id: id,
      numero: map['numero'] ?? '',
      batiment: map['batiment'] ?? '',
      typologie: map['typologie'] ?? '',
      nombrePersonnes: map['nombrePersonnes'] ?? 0,
      residenceId: map['residenceId'] ?? '',
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
    };
  }
}