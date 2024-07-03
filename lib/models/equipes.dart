class Equipe {
  String nom;
  List<String> appartementIds;
  List<String> personnelIds;

  Equipe({
    required this.nom,
    required this.appartementIds,
    required this.personnelIds,
  });

  factory Equipe.fromMap(Map<String, dynamic> map) {
    return Equipe(
      nom: map['nom'] ?? '',
      appartementIds: map['appartementIds'] != null ? List<String>.from(map['appartementIds']) : [],
      personnelIds: map['personnelIds'] != null ? List<String>.from(map['personnelIds']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'appartementIds': appartementIds,
      'personnelIds': personnelIds,
    };
  }
}