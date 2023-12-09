
/**
class Personnel {
  String nom;
  String prenom;
  String email;
  bool estSuperviseur;
  String type;
  String? residenceAffectee;

  Personnel({
    required this.nom,
    required this.prenom,
    required this.email,
    this.estSuperviseur = false,
    required this.type,
    this.residenceAffectee,
  });
}

// Liste globale de personnel
List<Personnel> listePersonnel = [];
// Liste globale pour stocker le personnel de nettoyage
List<Personnel> listePersonnelNettoyage = [];

// Liste globale pour stocker le personnel de contrôle et réception
List<Personnel> listeControleReception = [];

void ajouterPersonnel(Personnel personnel) {
  if (personnel.type == 'personnel de nettoyage') {
    listePersonnelNettoyage.add(personnel);
  } else if (personnel.type == 'contrôle et réception') {
    listeControleReception.add(personnel);
  }
}**/
