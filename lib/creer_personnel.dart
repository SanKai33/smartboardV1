import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/personnel_model.dart';

class CreerPersonnelPage extends StatefulWidget {
  final String entrepriseId; // Ajoutez cette ligne pour définir entrepriseId

  // Assurez-vous que le constructeur de CreerPersonnelPage accepte entrepriseId
  CreerPersonnelPage({Key? key, required this.entrepriseId}) : super(key: key);

  @override
  _CreerPersonnelPageState createState() => _CreerPersonnelPageState();
}

class _CreerPersonnelPageState extends State<CreerPersonnelPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String typeCompte = 'personnel de nettoyage';
  bool estSuperviseur = false;
  String nom = '';
  String prenom = '';
  String email = '';
  String motDePasse = '123456'; // Mot de passe par défaut
  String residenceAffectee = '';
  List<String> listeResidences = [];
  bool isLoading = true;




  void _loadResidences(String entrepriseId) async {
    try {
      // Remplacer 'votre_entreprise_id' par l'ID de l'entreprise actuelle
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('entreprise')
          .doc(entrepriseId)
          .collection('residences')
          .get();

      List<String> residences = querySnapshot.docs.map((doc) => doc['nom'] as String).toList();
      print('Résidences chargées: $residences'); // Débogage : affiche les résidences chargées

      setState(() {
        listeResidences = residences;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des résidences: $e'); // Débogage : affiche les erreurs
      // Gérer l'erreur de chargement ici
    }
  }

  @override
  void initState() {
    super.initState();
    // Assurez-vous que l'ID de l'entreprise est passé à la fonction _loadResidences
    _loadResidences(widget.entrepriseId);
  }


  bool get isFormValid {
    if (typeCompte == 'personnel de nettoyage') {
      return nom.isNotEmpty && prenom.isNotEmpty && email.isNotEmpty;
    } else {
      return nom.isNotEmpty && prenom.isNotEmpty && email.isNotEmpty && residenceAffectee.isNotEmpty;
    }
  }

  void _enregistrerPersonnel() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez remplir tous les champs')));
      return;
    }

    // Ajoutez le champ entrepriseId dans les données du personnel
    Map<String, dynamic> personnelData = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'typeCompte': typeCompte,
      'estSuperviseur': estSuperviseur,
      'residenceAffectee': typeCompte == 'contrôle et réception' ? residenceAffectee : '',
      'entrepriseId': widget.entrepriseId, // Ajoutez cette ligne
      // 'motDePasse': motDePasse, // Enlever cette ligne si vous ne stockez pas les mots de passe en clair.
    };

    // Assurez-vous que vous enregistrez le personnel dans la collection 'entreprise/{entrepriseId}/personnel'
    try {
      await _firestore.collection('entreprise')
          .doc(widget.entrepriseId)
          .collection('personnel')
          .add(personnelData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Personnel enregistré avec succès')));
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement du personnel')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer Personnel'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: typeCompte,
              onChanged: (newValue) {
                setState(() {
                  typeCompte = newValue!;
                  residenceAffectee = '';
                });
              },
              items: ['personnel de nettoyage', 'contrôle et réception']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (typeCompte == 'personnel de nettoyage')
              CheckboxListTile(
                title: Text('Est Superviseur'),
                value: estSuperviseur,
                onChanged: (value) {
                  setState(() {
                    estSuperviseur = value!;
                  });
                },
              ),
            if (typeCompte == 'contrôle et réception')
              DropdownButtonFormField<String>(
                value: residenceAffectee.isEmpty ? null : residenceAffectee,
                onChanged: (newValue) {
                  setState(() {
                    residenceAffectee = newValue!;
                  });
                },
                items: listeResidences.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Résidence Affectée'),
              ),
            TextField(
              onChanged: (value) => setState(() => nom = value),
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              onChanged: (value) => setState(() => prenom = value),
              decoration: InputDecoration(labelText: 'Prénom'),
            ),
            TextField(
              onChanged: (value) => setState(() => email = value),
              decoration: InputDecoration(labelText: 'Email'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text('Mot de passe par défaut : '),
                  Text(motDePasse, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isFormValid ? _enregistrerPersonnel : null,
              child: Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).primaryColor,
                onPrimary: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
