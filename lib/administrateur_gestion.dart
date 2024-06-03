import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'models/entreprise.dart';
import 'models/personnel.dart'; // Assurez-vous que le chemin d'accès au modèle Entreprise est correct

class AdministrateurGestion extends StatefulWidget {
  @override
  _AdministrateurGestionState createState() => _AdministrateurGestionState();
}

class _AdministrateurGestionState extends State<AdministrateurGestion> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Entreprise>> _loadEntreprises() {
    return _firestore.collection('entreprises')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Entreprise.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Stream<List<Personnel>> _loadPersonnel(String entrepriseId) {
    return _firestore.collection('personnel')
        .where('entrepriseId', isEqualTo: entrepriseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Personnel.fromFirestore(doc))
        .toList());
  }

  void _showOptionsDialog(Entreprise entreprise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options pour ${entreprise.nom}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Accéder au compte'),
                onTap: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                  _navigateToHomePage(entreprise.id); // Naviguer vers la page d'accueil de l'entreprise
                },
              ),
              ListTile(
                title: Text('Supprimer le compte'),
                onTap: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue des options
                  _showDeleteConfirmationDialog(entreprise); // Afficher la confirmation de suppression
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Entreprise entreprise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${entreprise.nom}? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue de confirmation
              },
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () {
                _deleteEntreprise(entreprise.id); // Procéder à la suppression
                Navigator.of(context).pop(); // Fermer la boîte de dialogue de confirmation
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteEntreprise(String id) {
    _firestore.collection('entreprises').doc(id).delete();
  }

  void _navigateToHomePage(String entrepriseId) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => HomePage(entrepriseId: entrepriseId),
    ));
  }

  void _showAddEntrepriseDialog() {
    TextEditingController nomController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController telephoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer une nouvelle entreprise'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(hintText: "Nom de l'entreprise"),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(hintText: "Email"),
                ),
                TextField(
                  controller: telephoneController,
                  decoration: InputDecoration(hintText: "Téléphone"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Enregistrer'),
              onPressed: () {
                _addEntreprise(nomController.text, emailController.text, telephoneController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addEntreprise(String nom, String email, String telephone) {
    Map<String, dynamic> data = {
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'password': 'smartboard2233'  // Utilisation du mot de passe par défaut "smartboard2233"
    };
    _firestore.collection('entreprises').add(data);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Entreprises et Personnels'),
        backgroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddEntrepriseDialog,
          )
        ],
      ),
      body: StreamBuilder<List<Entreprise>>(
        stream: _loadEntreprises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement des données'));
          }
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.map((entreprise) => ExpansionTile(
                title: Text(entreprise.nom),
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showOptionsDialog(entreprise),
                ),
                children: [
                  StreamBuilder<List<Personnel>>(
                    stream: _loadPersonnel(entreprise.id),
                    builder: (context, snapshotPersonnel) {
                      if (snapshotPersonnel.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshotPersonnel.hasError) {
                        return ListTile(title: Text('Erreur lors du chargement des agents'));
                      }
                      if (snapshotPersonnel.hasData && snapshotPersonnel.data!.isNotEmpty) {
                        return Column(
                          children: snapshotPersonnel.data!.map((agent) => Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(agent.nom + ' ' + agent.prenom),
                              subtitle: Text('Email: ${agent.email ?? 'Non disponible'}'),
                              onTap: () {
                                // Logique pour gérer le tap sur un agent
                              },
                            ),
                          )).toList(),
                        );
                      } else {
                        return ListTile(title: Text('Aucun agent trouvé pour cette entreprise'));
                      }
                    },
                  )
                ],
              )).toList(),
            );
          } else {
            return Center(child: Text('Aucune entreprise trouvée'));
          }
        },
      ),
    );
  }
}

