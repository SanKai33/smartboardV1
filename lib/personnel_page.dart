import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
//import 'package:share/share.dart';

import 'package:smartboard/models/personnel.dart';

class PersonnelPage extends StatefulWidget {
  final String entrepriseId;

  PersonnelPage({required this.entrepriseId});

  @override
  _PersonnelPageState createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom ou prénom',
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchQuery = "";
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => _createNewAgent(context),
            child: Text('Nouvel Agent', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: Colors.black),
          ),
        ],
      ),
      body: PersonnelNettoyageWidget(
        entrepriseId: widget.entrepriseId,
        searchQuery: searchQuery,
      ),
    );
  }





  void _createNewAgent(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController firstNameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nouvel Agent'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Nom'),
                ),
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(hintText: 'Prénom'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(hintText: 'Numéro de téléphone'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Créer le compte'),
              onPressed: () {
                _addAgentToFirestore(nameController.text, firstNameController.text, phoneController.text, context);
              },
            ),
          ],
        );
      },
    );
  }

  void _addAgentToFirestore(String name, String firstName, String phone, BuildContext context) {
    String agentId = name + firstName[0].toLowerCase();

    FirebaseFirestore.instance.collection('personnel').add({
      'nom': name,
      'prenom': firstName,
      'telephone': phone,
      'entrepriseId': widget.entrepriseId,
      // Ajouter d'autres champs requis par le modèle Personnel si nécessaire
    }).then((value) {
      Navigator.of(context).pop(); // Ferme la boîte de dialogue de création
      _showSuccessDialog(context, agentId);
    }).catchError((error) {
      print("Erreur lors de l'ajout de l'agent: $error");
    });
  }

  void _showSuccessDialog(BuildContext context, String agentId) {
    final String message = "L'agent a été créé avec succès.\n"
        "Identifiant: $agentId\n"
        "Mot de passe par défaut: 123456";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Succès'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Partager'),
              onPressed: () {
                //Share.share(message);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class PersonnelNettoyageWidget extends StatelessWidget {
  final String entrepriseId;
  final String searchQuery;

  PersonnelNettoyageWidget({required this.entrepriseId, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('personnel')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erreur lors du chargement des agents.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<Personnel> listeAgents = snapshot.data!.docs.map((DocumentSnapshot document) {
          return Personnel.fromFirestore(document);
        }).toList();

        // Filtrage des agents en fonction de la requête de recherche
        if (searchQuery.isNotEmpty) {
          listeAgents = listeAgents.where((agent) {
            String searchLowercase = searchQuery.toLowerCase();
            return agent.nom.toLowerCase().contains(searchLowercase) ||
                agent.prenom.toLowerCase().contains(searchLowercase);
          }).toList();
        }

        return ListView(
          children: listeAgents.map((agent) => buildCard(context, agent)).toList(),
        );
      },
    );
  }

  Widget buildCard(BuildContext context, Personnel personnel) {
    return Card(
      child: InkWell(
        onTap: () => _showOptionsDialog(context, personnel),
        child: ListTile(
          title: Text('${personnel.nom} ${personnel.prenom}'),
          subtitle: Text('${personnel.telephone}'),
          trailing: Text(personnel.typeCompte, // Affiche la fonction de l'agent
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }




  void _showOptionsDialog(BuildContext context, Personnel personnel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options pour ${personnel.nom}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextButton(
                  child: Text('Modifier la fonction'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showEditRoleDialog(context, personnel);
                  },
                ),
                TextButton(
                  child: Text('Modifier le compte'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showEditAccountDialog(context, personnel);
                  },
                ),
                TextButton(
                  child: Text('Supprimer'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmationDialog(context, personnel);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditRoleDialog(BuildContext context, Personnel personnel) {
    String selectedRole = personnel.typeCompte; // Utilisez le rôle actuel comme valeur par défaut

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Utilisation de StatefulBuilder pour gérer l'état local du dialogue
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Modifier la Fonction'),
              content: DropdownButton<String>(
                value: selectedRole,
                onChanged: (String? newValue) {
                  setState(() { // Mise à jour de l'état local du dialogue
                    selectedRole = newValue!;
                  });
                },
                items: <String>['Agent Simple', 'Superviseur', 'Contrôleur']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Modifier'),
                  onPressed: () {
                    // Mettre à jour le rôle de l'agent dans Firestore
                    FirebaseFirestore.instance.collection('agents').doc(personnel.id).update({'typeCompte': selectedRole});
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAccountDialog(BuildContext context, Personnel personnel) {
    TextEditingController nomController = TextEditingController(text: personnel.nom);
    TextEditingController prenomController = TextEditingController(text: personnel.prenom);
    TextEditingController telephoneController = TextEditingController(text: personnel.telephone);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le Compte'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(controller: nomController, decoration: InputDecoration(hintText: 'Nom')),
                TextField(controller: prenomController, decoration: InputDecoration(hintText: 'Prénom')),
                TextField(controller: telephoneController, decoration: InputDecoration(hintText: 'Téléphone')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Modifier'),
              onPressed: () {
                // Mettre à jour les informations de l'agent dans Firestore
                FirebaseFirestore.instance.collection('agents').doc(personnel.id).update({
                  'nom': nomController.text,
                  'prenom': prenomController.text,
                  'telephone': telephoneController.text,
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Personnel personnel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la Suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer cet agent ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () {
                // Supprimer l'agent de Firestore
                FirebaseFirestore.instance.collection('agents').doc(personnel.id).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }




}