import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/models/personnel.dart';

class PersonnelPage extends StatefulWidget {
  final String entrepriseId;

  PersonnelPage({required this.entrepriseId});

  @override
  _PersonnelPageState createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  List<Personnel> personnelList = [];

  @override
  void initState() {
    super.initState();
    _loadExistingPersonnel();
  }

  void _loadExistingPersonnel() async {
    var collection = FirebaseFirestore.instance.collection('personnel').where('entrepriseId', isEqualTo: widget.entrepriseId);
    var querySnapshot = await collection.get();
    for (var doc in querySnapshot.docs) {
      setState(() {
        personnelList.add(Personnel.fromFirestore(doc));
      });
    }
  }

  void _showAddPersonnelDialog() {
    final _nomController = TextEditingController();
    final _prenomController = TextEditingController();
    final _telephoneController = TextEditingController();
    final _emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un nouvel agent'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(controller: _nomController, decoration: InputDecoration(hintText: "Nom")),
                TextField(controller: _prenomController, decoration: InputDecoration(hintText: "Prénom")),
                TextField(controller: _telephoneController, decoration: InputDecoration(hintText: "Téléphone")),
                TextField(controller: _emailController, decoration: InputDecoration(hintText: "Email")),
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
                _addNewPersonnel(
                  _nomController.text,
                  _prenomController.text,
                  _telephoneController.text,
                  _emailController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewPersonnel(String nom, String prenom, String telephone, String email) {
    String identifiant = nom.toLowerCase() + prenom[0].toLowerCase();
    Personnel newPersonnel = Personnel(
      id: '',
      identifiant: identifiant,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      typeCompte: 'Standard', // Ajustez selon votre logique
      estSuperviseur: false,
      entrepriseId: widget.entrepriseId,
    );
    FirebaseFirestore.instance.collection('personnel').add(newPersonnel.toMap());
    setState(() {
      personnelList.add(newPersonnel);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personnel de l\'entreprise'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddPersonnelDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: personnelList.length,
        itemBuilder: (context, index) {
          Personnel personnel = personnelList[index];
          return ListTile(
            title: Text(personnel.nom + " " + personnel.prenom),
            subtitle: Text(personnel.telephone),
            // Ajoutez d'autres informations ici si nécessaire
          );
        },
      ),
    );
  }
}