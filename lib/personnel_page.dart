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