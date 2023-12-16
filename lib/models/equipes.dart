class Equipe {
  String nom;
  List<String> appartementIds;

  Equipe({required this.nom, required this.appartementIds, required List<dynamic> appartements});

  factory Equipe.fromMap(Map<String, dynamic> map) {
    return Equipe(
      nom: map['nom'] ?? '',
      appartementIds: List<String>.from(map['appartementIds'] as List<dynamic> ?? []), appartements: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'appartementIds': appartementIds,
    };
  }
}
