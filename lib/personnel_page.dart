import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/models/personnel.dart';
import 'models/client.dart';
import 'models/residence.dart';

class PersonnelPage extends StatefulWidget {
  final String entrepriseId;

  PersonnelPage({required this.entrepriseId});

  @override
  _PersonnelPageState createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  List<Personnel> personnelList = [];
  List<Personnel> filteredPersonnelList = [];
  List<Client> clientList = [];
  List<Client> filteredClientList = [];
  List<Residence> residences = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingPersonnel();
    _loadExistingClients();
    _loadResidences();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadResidences() async {
    var collection = FirebaseFirestore.instance
        .collection('residences')
        .where('entrepriseId', isEqualTo: widget.entrepriseId);
    var querySnapshot = await collection.get();
    var tempList = querySnapshot.docs
        .map((doc) => Residence.fromFirestore(doc))
        .toList();
    setState(() {
      residences = tempList;
    });
  }

  void _loadExistingPersonnel() async {
    var collection = FirebaseFirestore.instance
        .collection('personnel')
        .where('entrepriseId', isEqualTo: widget.entrepriseId);
    var querySnapshot = await collection.get();
    var tempList = querySnapshot.docs
        .map((doc) => Personnel.fromFirestore(doc))
        .toList();
    setState(() {
      personnelList = tempList;
      filteredPersonnelList = tempList;
    });
  }

  void _loadExistingClients() async {
    var collection = FirebaseFirestore.instance
        .collection('clients')
        .where('entrepriseId', isEqualTo: widget.entrepriseId);
    var querySnapshot = await collection.get();
    var tempList = querySnapshot.docs
        .map((doc) => Client.fromFirestore(doc))
        .toList();
    setState(() {
      clientList = tempList;
      filteredClientList = tempList;
    });
  }

  void _filterPersonnelAndClients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPersonnelList = personnelList;
        filteredClientList = clientList;
      } else {
        filteredPersonnelList = personnelList.where((personnel) =>
        personnel.nom.toLowerCase().contains(query.toLowerCase()) ||
            personnel.prenom.toLowerCase().contains(query.toLowerCase())).toList();
        filteredClientList = clientList.where((client) =>
        client.nom.toLowerCase().contains(query.toLowerCase()) ||
            client.prenom.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _movePersonnel(Personnel personnel, String newResidenceId) async {
    List<String> updatedResidences = List.from(personnel.residencesAffectees);
    if (!updatedResidences.contains(newResidenceId)) {
      updatedResidences.add(newResidenceId);
    }

    await FirebaseFirestore.instance
        .collection('personnel')
        .doc(personnel.id)
        .update({'residencesAffectees': updatedResidences});
    setState(() {
      personnel.residencesAffectees = updatedResidences;
      _filterPersonnelAndClients(searchController.text);
    });
  }

  void _moveClient(Client client, String newResidenceId) async {
    List<String> updatedResidences = List.from(client.residencesAffectees);
    if (!updatedResidences.contains(newResidenceId)) {
      updatedResidences.add(newResidenceId);
    }

    await FirebaseFirestore.instance
        .collection('clients')
        .doc(client.id)
        .update({'residencesAffectees': updatedResidences});
    setState(() {
      client.residencesAffectees = updatedResidences;
      _filterPersonnelAndClients(searchController.text);
    });
  }

  Future<void> _updatePersonnel(Personnel personnel) async {
    await FirebaseFirestore.instance
        .collection('personnel')
        .doc(personnel.id)
        .update(personnel.toMap());
  }

  Future<void> _updateClient(Client client) async {
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(client.id)
        .update(client.toMap());
  }

  Future<void> _deletePersonnelFromResidence(Personnel personnel, String residenceId) async {
    List<String> updatedResidences = List.from(personnel.residencesAffectees);
    updatedResidences.remove(residenceId);

    await FirebaseFirestore.instance
        .collection('personnel')
        .doc(personnel.id)
        .update({'residencesAffectees': updatedResidences});
    setState(() {
      personnel.residencesAffectees = updatedResidences;
      _filterPersonnelAndClients(searchController.text);
    });
  }

  Future<void> _deleteClientFromResidence(Client client, String residenceId) async {
    List<String> updatedResidences = List.from(client.residencesAffectees);
    updatedResidences.remove(residenceId);

    await FirebaseFirestore.instance
        .collection('clients')
        .doc(client.id)
        .update({'residencesAffectees': updatedResidences});
    setState(() {
      client.residencesAffectees = updatedResidences;
      _filterPersonnelAndClients(searchController.text);
    });
  }

  void _showAddPersonnelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un nouveau compte'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: Text('Créer un agent'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showNewAgentDialog();
                  },
                ),
                ListTile(
                  title: Text('Créer un client'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showNewClientDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNewAgentDialog() {
    final _nomController = TextEditingController();
    final _prenomController = TextEditingController();
    final _telephoneController = TextEditingController();
    final _emailController = TextEditingController();
    bool estSuperviseur = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un nouvel agent'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                        controller: _nomController,
                        decoration: InputDecoration(hintText: "Nom")),
                    TextField(
                        controller: _prenomController,
                        decoration: InputDecoration(hintText: "Prénom")),
                    TextField(
                        controller: _telephoneController,
                        decoration: InputDecoration(hintText: "Téléphone")),
                    TextField(
                        controller: _emailController,
                        decoration: InputDecoration(hintText: "Email")),
                    CheckboxListTile(
                      title: Text("Superviseur"),
                      value: estSuperviseur,
                      onChanged: (bool? value) {
                        setState(() {
                          estSuperviseur = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
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
                  'agent',
                  estSuperviseur,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showNewClientDialog() {
    final _nomController = TextEditingController();
    final _prenomController = TextEditingController();
    final _telephoneController = TextEditingController();
    final _emailController = TextEditingController();
    bool estControleur = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un nouveau client'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                        controller: _nomController,
                        decoration: InputDecoration(hintText: "Nom")),
                    TextField(
                        controller: _prenomController,
                        decoration: InputDecoration(hintText: "Prénom")),
                    TextField(
                        controller: _telephoneController,
                        decoration: InputDecoration(hintText: "Téléphone")),
                    TextField(
                        controller: _emailController,
                        decoration: InputDecoration(hintText: "Email")),
                    CheckboxListTile(
                      title: Text("Contrôleur"),
                      value: estControleur,
                      onChanged: (bool? value) {
                        setState(() {
                          estControleur = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
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
                _addNewClient(
                  _nomController.text,
                  _prenomController.text,
                  _telephoneController.text,
                  _emailController.text,
                  estControleur,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewPersonnel(
      String nom, String prenom, String telephone, String email, String typeCompte, bool estSuperviseur) {
    String identifiant = nom.toLowerCase() + prenom[0].toLowerCase();
    String defaultPassword = "123456";
    Personnel newPersonnel = Personnel(
      id: '',
      identifiant: identifiant,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      typeCompte: typeCompte,
      estSuperviseur: estSuperviseur,
      residencesAffectees: [],
      entrepriseId: widget.entrepriseId,
    );

    FirebaseFirestore.instance
        .collection('personnel')
        .add(newPersonnel.toMap())
        .then((docRef) {
      newPersonnel.id = docRef.id;
      FirebaseFirestore.instance.collection('auth').add({
        'identifiant': identifiant,
        'password': defaultPassword,
      }).then((_) {
        setState(() {
          personnelList.add(newPersonnel);
          _filterPersonnelAndClients(searchController.text);
        });
        _showConfirmationDialog(nom, prenom, defaultPassword);
      });
    });
  }

  void _addNewClient(
      String nom, String prenom, String telephone, String email, bool estControleur) {
    Client newClient = Client(
      id: '',
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      entrepriseId: widget.entrepriseId,
      residencesAffectees: [],
      estControleur: estControleur,
    );

    FirebaseFirestore.instance
        .collection('clients')
        .add(newClient.toMap())
        .then((docRef) {
      newClient.id = docRef.id;
      setState(() {
        clientList.add(newClient);
        _filterPersonnelAndClients(searchController.text);
      });
      _showClientConfirmationDialog(nom, prenom);
    });
  }

  void _showConfirmationDialog(String nom, String prenom, String password) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Compte Créé'),
          content: Text(
              'Le compte de $nom $prenom a été créé avec succès. \nIdentifiant : ${nom.toLowerCase() + prenom[0].toLowerCase()} \nMot de passe : $password'),
          actions: <Widget>[
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

  void _showClientConfirmationDialog(String nom, String prenom) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Client Créé'),
          content: Text('Le client $nom $prenom a été créé avec succès.'),
          actions: <Widget>[
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

  Future<void> _confirmDeleteFromResidence(
      BuildContext context, dynamic person, String residenceId) async {
    String entityType = person is Personnel ? 'personnel' : 'client';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation de suppression'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Êtes-vous sûr de vouloir supprimer ce $entityType de la résidence sélectionnée ?'),
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
              child: Text('Confirmer'),
              onPressed: () {
                if (person is Personnel) {
                  _deletePersonnelFromResidence(person, residenceId);
                } else if (person is Client) {
                  _deleteClientFromResidence(person, residenceId);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditPersonnelDialog(Personnel personnel) {
    final _telephoneController = TextEditingController(text: personnel.telephone);
    final _emailController = TextEditingController(text: personnel.email);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier les informations de l\'agent'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _telephoneController,
                  decoration: InputDecoration(hintText: "Téléphone"),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: "Email"),
                ),
                TextButton(
                  child: Text('Changer rôle'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showRoleDialogPersonnel(personnel);
                  },
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
                setState(() {
                  personnel.telephone = _telephoneController.text;
                  personnel.email = _emailController.text;
                  _updatePersonnel(personnel);
                  Navigator.of(context).pop();
                  _showValidationDialog('Les informations de l\'agent ont été mises à jour.');
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditClientDialog(Client client) {
    final _telephoneController = TextEditingController(text: client.telephone);
    final _emailController = TextEditingController(text: client.email);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier les informations du client'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _telephoneController,
                  decoration: InputDecoration(hintText: "Téléphone"),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: "Email"),
                ),
                TextButton(
                  child: Text('Changer rôle'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showRoleDialogClient(client);
                  },
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
                setState(() {
                  client.telephone = _telephoneController.text;
                  client.email = _emailController.text;
                  _updateClient(client);
                  Navigator.of(context).pop();
                  _showValidationDialog('Les informations du client ont été mises à jour.');
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showRoleDialogPersonnel(Personnel personnel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer rôle de l\'agent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Superviseur', style: TextStyle(color: Colors.red)),
                onTap: () {
                  personnel.estSuperviseur = true;
                  _updatePersonnel(personnel).then((_) {
                    Navigator.of(context).pop();
                    _showValidationDialog('Le rôle de l\'agent a été mis à jour.');
                  });
                },
              ),
              ListTile(
                title: Text('Agent'),
                onTap: () {
                  personnel.estSuperviseur = false;
                  _updatePersonnel(personnel).then((_) {
                    Navigator.of(context).pop();
                    _showValidationDialog('Le rôle de l\'agent a été mis à jour.');
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoleDialogClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer rôle du client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Contrôleur'),
                onTap: () {
                  client.estControleur = true;
                  _updateClient(client).then((_) {
                    Navigator.of(context).pop();
                    _showValidationDialog('Le rôle du client a été mis à jour.');
                  });
                },
              ),
              ListTile(
                title: Text('Client'),
                onTap: () {
                  client.estControleur = false;
                  _updateClient(client).then((_) {
                    Navigator.of(context).pop();
                    _showValidationDialog('Le rôle du client a été mis à jour.');
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Validation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _filterPersonnelAndClients(searchController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personnel et Clients de l\'entreprise'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: _showAddPersonnelDialog,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Créer un compte',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Chercher',
                hintText: 'Chercher par nom ou prénom',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterPersonnelAndClients,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  _buildTable(
                    title: 'Personnel non affecté',
                    rows: _buildUnassignedPersonnelRows(),
                    showHeader: true,
                  ),
                  _buildTable(
                    title: 'Clients non affectés',
                    rows: _buildUnassignedClientRows(),
                    showHeader: true,
                  ),
                  ..._buildResidenceTables(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildUnassignedPersonnelRows() {
    List<DataRow> rows = [];

    var unassignedPersonnel = filteredPersonnelList.where((p) => p.residencesAffectees.isEmpty).toList();
    for (var item in unassignedPersonnel) {
      rows.add(DataRow(cells: [
        DataCell(Text(item.nom)),
        DataCell(Text(item.prenom)),
        DataCell(Text(item.telephone)),
        DataCell(Text(item.email)),
        DataCell(Text(
          item.estSuperviseur ? 'Superviseur' : 'Agent',
          style: TextStyle(color: item.estSuperviseur ? Colors.red : Colors.black),
        )),
        DataCell(TextButton(
          child: Text('Affecter Résidence'),
          onPressed: () async {
            String? selectedResidence = await _showResidenceDialog(context);
            if (selectedResidence != null) {
              _movePersonnel(item, selectedResidence);
            }
          },
        )),
        DataCell(Row(
          children: [
            TextButton(
              child: Text('Modifier'),
              onPressed: () {
                _showEditPersonnelDialog(item);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.black),
              onPressed: () {
                _confirmDeleteFromResidence(context, item, '');
              },
            ),
          ],
        )),
      ]));
    }

    return rows;
  }

  List<DataRow> _buildUnassignedClientRows() {
    List<DataRow> rows = [];

    var unassignedClients = filteredClientList.where((c) => c.residencesAffectees.isEmpty).toList();
    for (var item in unassignedClients) {
      rows.add(DataRow(cells: [
        DataCell(Text(item.nom)),
        DataCell(Text(item.prenom)),
        DataCell(Text(item.telephone)),
        DataCell(Text(item.email)),
        DataCell(Text(
          item.estControleur ? 'Contrôleur' : 'Client',
          style: TextStyle(color: item.estControleur ? Colors.red : Colors.black),
        )),
        DataCell(TextButton(
          child: Text('Affecter Résidence'),
          onPressed: () async {
            String? selectedResidence = await _showResidenceDialog(context);
            if (selectedResidence != null) {
              _moveClient(item, selectedResidence);
            }
          },
        )),
        DataCell(Row(
          children: [
            TextButton(
              child: Text('Modifier'),
              onPressed: () {
                _showEditClientDialog(item);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.black),
              onPressed: () {
                _confirmDeleteFromResidence(context, item, '');
              },
            ),
          ],
        )),
      ]));
    }

    return rows;
  }

  List<Widget> _buildResidenceTables() {
    List<Widget> residenceTables = [];

    for (var residence in residences) {
      var clientsInResidence = filteredClientList.where((c) => c.residencesAffectees.contains(residence.id)).toList();
      var personnelInResidence = filteredPersonnelList.where((p) => p.residencesAffectees.contains(residence.id)).toList();

      if (clientsInResidence.isNotEmpty || personnelInResidence.isNotEmpty) {
        residenceTables.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    residence.nom,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        );
        residenceTables.add(
          _buildTable(
            title: '',
            rows: _buildResidenceRows(residence),
            showHeader: true,
          ),
        );
      }
    }

    return residenceTables;
  }

  List<DataRow> _buildResidenceRows(Residence residence) {
    List<DataRow> rows = [];

    var clientsInResidence = filteredClientList.where((c) => c.residencesAffectees.contains(residence.id)).toList();
    clientsInResidence.sort((a, b) => a.nom.compareTo(b.nom)); // Sort clients by name
    for (var item in clientsInResidence) {
      rows.add(DataRow(
        color: MaterialStateColor.resolveWith((states) => Colors.lightBlue.shade100),
        cells: [
          DataCell(Text(item.nom)),
          DataCell(Text(item.prenom)),
          DataCell(Text(item.telephone)),
          DataCell(Text(item.email)),
          DataCell(Text(
            item.estControleur ? 'Contrôleur' : 'Client',
            style: TextStyle(color: item.estControleur ? Colors.red : Colors.black),
          )),
          DataCell(TextButton(
            child: Text('Affecter Résidence'),
            onPressed: () async {
              String? selectedResidence = await _showResidenceDialog(context);
              if (selectedResidence != null) {
                _moveClient(item, selectedResidence);
              }
            },
          )),
          DataCell(Row(
            children: [
              TextButton(
                child: Text('Modifier'),
                onPressed: () {
                  _showEditClientDialog(item);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.black),
                onPressed: () {
                  _confirmDeleteFromResidence(context, item, residence.id);
                },
              ),
            ],
          )),
        ],
      ));
    }

    var personnelInResidence = filteredPersonnelList.where((p) => p.residencesAffectees.contains(residence.id)).toList();
    personnelInResidence.sort((a, b) => a.nom.compareTo(b.nom)); // Sort personnel by name
    for (var item in personnelInResidence) {
      rows.add(DataRow(cells: [
        DataCell(Text(item.nom)),
        DataCell(Text(item.prenom)),
        DataCell(Text(item.telephone)),
        DataCell(Text(item.email)),
        DataCell(Text(
          item.estSuperviseur ? 'Superviseur' : 'Agent',
          style: TextStyle(color: item.estSuperviseur ? Colors.red : Colors.black),
        )),
        DataCell(TextButton(
          child: Text('Affecter Résidence'),
          onPressed: () async {
            String? selectedResidence = await _showResidenceDialog(context);
            if (selectedResidence != null) {
              _movePersonnel(item, selectedResidence);
            }
          },
        )),
        DataCell(Row(
          children: [
            TextButton(
              child: Text('Modifier'),
              onPressed: () {
                _showEditPersonnelDialog(item);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.black),
              onPressed: () {
                _confirmDeleteFromResidence(context, item, residence.id);
              },
            ),
          ],
        )),
      ]));
    }

    return rows;
  }

  Widget _buildTable({required String title, required List<DataRow> rows, required bool showHeader}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade300),
              columns: [
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Prénom')),
                DataColumn(label: Text('Téléphone')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Rôle')),
                DataColumn(label: Text('Résidence')),
                DataColumn(label: Text('Action')),
              ],
              rows: rows,
              dividerThickness: 2,
              border: TableBorder(
                top: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
                left: BorderSide(color: Colors.black),
                right: BorderSide(color: Colors.black),
                horizontalInside: BorderSide(color: Colors.black),
                verticalInside: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showResidenceDialog(BuildContext context) async {
    String? selectedResidenceId;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sélectionnez une résidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Aucune résidence'),
                onTap: () {
                  selectedResidenceId = '';
                  Navigator.of(context).pop(selectedResidenceId);
                },
              ),
              ...residences.map((residence) {
                return ListTile(
                  title: Text(residence.nom),
                  onTap: () {
                    selectedResidenceId = residence.id;
                    Navigator.of(context).pop(selectedResidenceId);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}