import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/affectation_personnel.dart';
import 'package:smartboard/models/personnel.dart';

class PersonnelPage extends StatefulWidget {
  final String entrepriseId;

  PersonnelPage({required this.entrepriseId});

  @override
  _PersonnelPageState createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  bool _isAuthorized = false;
  List<Personnel> personnelList = [];

  @override
  void initState() {
    super.initState();
    _requestPassword();
  }

  void _requestPassword() async {
    TextEditingController passwordController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mot de passe Administrateur'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: 'Entrez le mot de passe'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Valider'),
              onPressed: () {
                if (passwordController.text == '2233') {
                  setState(() {
                    _isAuthorized = true;
                  });
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewPersonnelRow() {
    setState(() {
      personnelList.add(Personnel(
        id: '', // Laisser vide, Firestore générera un ID lors de l'enregistrement
        identifiant: '',
        nom: '',
        prenom: '',
        email: '',
        telephone: '',
        typeCompte: '',
        estSuperviseur: false,
        entrepriseId: widget.entrepriseId,
      ));
    });
  }

  void _updatePersonnelField(Personnel personnel, String field, String value) {
    FirebaseFirestore.instance.collection('personnel').doc(personnel.id).update({field: value});
    int index = personnelList.indexOf(personnel);
    if (index != -1) {
      setState(() {
        personnelList[index] = personnel.copyWith(field: value, id: '');
      });
    }
  }

  void _createNewPersonnel(Personnel personnel) {
    DocumentReference docRef = FirebaseFirestore.instance.collection('personnel').doc();
    personnel = personnel.copyWith(id: docRef.id, field: '');  // Mise à jour de l'ID
    docRef.set(personnel.toMap());
    int index = personnelList.indexOf(personnel);
    if (index != -1) {
      setState(() {
        personnelList[index] = personnel;
      });
    }
  }

  void _deletePersonnel(Personnel personnel) {
    FirebaseFirestore.instance.collection('personnel').doc(personnel.id).delete();
    setState(() {
      personnelList.removeWhere((element) => element.id == personnel.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Accès Restreint'),
        ),
        body: Center(child: Text('Vous n’êtes pas autorisé à voir cette page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Personnel de l\'entreprise'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewPersonnelRow,
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Prénom')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Téléphone')),
            DataColumn(label: Text('Actions')),
          ],
          rows: personnelList.map((personnel) {
            bool isNewRow = personnel.id.isEmpty;
            return DataRow(cells: [
              DataCell(TextField(
                controller: TextEditingController(text: personnel.nom),
                onSubmitted: (value) {
                  isNewRow
                      ? _createNewPersonnel(personnel.copyWith(nom: value, field: '', id: ''))
                      : _updatePersonnelField(personnel, 'nom', value);
                },
              )),
              DataCell(TextField(
                controller: TextEditingController(text: personnel.prenom),
                onSubmitted: (value) {
                  isNewRow
                      ? _createNewPersonnel(personnel.copyWith(prenom: value, field: '', id: ''))
                      : _updatePersonnelField(personnel, 'prenom', value);
                },
              )),
              DataCell(TextField(
                controller: TextEditingController(text: personnel.email),
                onSubmitted: (value) {
                  isNewRow
                      ? _createNewPersonnel(personnel.copyWith(email: value, field: '', id: ''))
                      : _updatePersonnelField(personnel, 'email', value);
                },
              )),
              DataCell(TextField(
                controller: TextEditingController(text: personnel.telephone),
                onSubmitted: (value) {
                  isNewRow
                      ? _createNewPersonnel(personnel.copyWith(telephone: value, field: '', id: ''))
                      : _updatePersonnelField(personnel, 'telephone', value);
                },
              )),
              DataCell(Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deletePersonnel(personnel),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}