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
  List<Personnel> displayedPersonnelList = [];
  TextEditingController searchController = TextEditingController();
  List<Residence> residences = [];

  @override
  void initState() {
    super.initState();
    _loadExistingPersonnel();
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

  Stream<List<Personnel>> _personnelStream() {
    return FirebaseFirestore.instance
        .collection('personnel')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Personnel.fromFirestore(doc))
        .toList());
  }

  Stream<List<Residence>> _residencesStream() {
    return FirebaseFirestore.instance
        .collection('residences')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Residence.fromFirestore(doc))
        .toList());
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
      displayedPersonnelList = tempList;
    });
  }

  void _filterPersonnel(String query) {
    setState(() {
      displayedPersonnelList = query.isEmpty
          ? personnelList
          : personnelList
          .where((personnel) =>
      personnel.nom.toLowerCase().contains(query.toLowerCase()) ||
          personnel.prenom
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showAddPersonnelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un nouveau'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: Text('Ajouter un agent'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showNewAgentDialog();
                  },
                ),
                ListTile(
                  title: Text('Ajouter un client'),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un nouvel agent'),
          content: SingleChildScrollView(
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
                  'agent',
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
    String? selectedResidenceId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un nouveau client'),
          content: SingleChildScrollView(
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
                DropdownButton<String>(
                  value: selectedResidenceId,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedResidenceId = newValue;
                    });
                  },
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Aucune résidence'),
                    ),
                    ...residences.map<DropdownMenuItem<String>>(
                            (Residence residence) {
                          return DropdownMenuItem<String>(
                            value: residence.id,
                            child: Text(residence.nom),
                          );
                        }).toList(),
                  ],
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
                _addNewClient(
                  _nomController.text,
                  _prenomController.text,
                  _telephoneController.text,
                  _emailController.text,
                  selectedResidenceId,
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
      String nom, String prenom, String telephone, String email, String typeCompte) {
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
      estSuperviseur: false,
      entrepriseId: widget.entrepriseId,
      estControleur: false,
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
          _filterPersonnel(searchController.text);
        });
        _showConfirmationDialog(nom, prenom, defaultPassword);
      });
    });
  }

  void _addNewClient(
      String nom, String prenom, String telephone, String email, String? residenceId) {
    Client newClient = Client(
      id: '',
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      entrepriseId: widget.entrepriseId,
      residenceId: residenceId,
    );

    FirebaseFirestore.instance
        .collection('clients')
        .add(newClient.toMap())
        .then((docRef) {
      newClient.id = docRef.id;
      if (residenceId != null) {
        FirebaseFirestore.instance.collection('residences').doc(residenceId).update({
          'personnelIds': FieldValue.arrayUnion([newClient.id])
        });
      }
      setState(() {
        _filterPersonnel(searchController.text);
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

  void _showPersonnelOptionsDialog(Personnel personnel) {
    final _nomController = TextEditingController(text: personnel.nom);
    final _prenomController = TextEditingController(text: personnel.prenom);
    final _telephoneController =
    TextEditingController(text: personnel.telephone);
    final _emailController = TextEditingController(text: personnel.email);
    bool estSuperviseur = personnel.estSuperviseur;
    bool estControleur = personnel.estControleur;
    String? selectedResidenceId = personnel.residenceAffectee;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Options pour ${personnel.nom} ${personnel.prenom}'),
              content: SingleChildScrollView(
                child: Column(
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
                    SwitchListTile(
                      title: Text('Est Superviseur'),
                      value: estSuperviseur,
                      onChanged: (bool value) {
                        setState(() => estSuperviseur = value);
                      },
                    ),
                    SwitchListTile(
                      title: Text('Est Contrôleur'),
                      value: estControleur,
                      onChanged: (bool value) {
                        setState(() => estControleur = value);
                      },
                    ),
                    DropdownButton<String>(
                      value: selectedResidenceId,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedResidenceId = newValue;
                        });
                      },
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('Aucune résidence'),
                        ),
                        ...residences.map<DropdownMenuItem<String>>(
                                (Residence residence) {
                              return DropdownMenuItem<String>(
                                value: residence.id,
                                child: Text(residence.nom),
                              );
                            }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Enregistrer'),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('personnel')
                        .doc(personnel.id)
                        .update({
                      'nom': _nomController.text,
                      'prenom': _prenomController.text,
                      'telephone': _telephoneController.text,
                      'email': _emailController.text,
                      'estSuperviseur': estSuperviseur,
                      'estControleur': estControleur,
                      'residenceAffectee': selectedResidenceId,
                    });

                    if (personnel.residenceAffectee != null &&
                        personnel.residenceAffectee != selectedResidenceId) {
                      await FirebaseFirestore.instance
                          .collection('residences')
                          .doc(personnel.residenceAffectee!)
                          .update({
                        'personnelIds': FieldValue.arrayRemove([personnel.id])
                      });
                    }

                    if (selectedResidenceId != null) {
                      await FirebaseFirestore.instance
                          .collection('residences')
                          .doc(selectedResidenceId)
                          .update({
                        'personnelIds': FieldValue.arrayUnion([personnel.id])
                      });
                    }

                    setState(() {
                      personnel.nom = _nomController.text;
                      personnel.prenom = _prenomController.text;
                      personnel.telephone = _telephoneController.text;
                      personnel.email = _emailController.text;
                      personnel.estSuperviseur = estSuperviseur;
                      personnel.estControleur = estControleur;
                      personnel.residenceAffectee = selectedResidenceId;
                    });

                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Supprimer',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirmer la suppression'),
                          content: Text(
                              'Voulez-vous vraiment supprimer ce membre du personnel ?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Annuler'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text('Supprimer'),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('personnel')
                                    .doc(personnel.id)
                                    .delete()
                                    .then((_) {
                                  setState(() {
                                    personnelList.removeWhere(
                                            (p) => p.id == personnel.id);
                                    displayedPersonnelList.removeWhere(
                                            (p) => p.id == personnel.id);
                                  });
                                  Navigator.of(context)
                                      .pop(); // Ferme le dialogue de confirmation
                                  Navigator.of(context)
                                      .pop(); // Ferme le dialogue d'options
                                }).catchError((error) {
                                  print(
                                      "Erreur lors de la suppression du personnel : $error");
                                  Navigator.of(context)
                                      .pop(); // Ferme le dialogue de confirmation
                                });
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Chercher',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _filterPersonnel(value);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Residence>>(
              stream: _residencesStream(),
              builder: (context, snapshotResidences) {
                if (!snapshotResidences.hasData) return CircularProgressIndicator();

                return StreamBuilder<List<Personnel>>(
                  stream: _personnelStream(),
                  builder: (context, snapshotPersonnel) {
                    if (!snapshotPersonnel.hasData) return CircularProgressIndicator();

                    Set<String> allAssignedPersonnelIds = snapshotResidences.data!
                        .expand((residence) => residence.personnelIds)
                        .toSet();

                    List<Personnel> unassignedPersonnel = snapshotPersonnel.data!
                        .where((personnel) => !allAssignedPersonnelIds.contains(personnel.id) &&
                        (personnel.nom.toLowerCase().contains(searchController.text.toLowerCase()) ||
                            personnel.prenom.toLowerCase().contains(searchController.text.toLowerCase())))
                        .toList();

                    return ListView(
                      children: [
                        if (unassignedPersonnel.isNotEmpty)
                          ListTile(
                            title: Text('Personnel Non Affecté'),
                            subtitle: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: unassignedPersonnel.length,
                              itemBuilder: (context, index) {
                                Personnel personnel = unassignedPersonnel[index];
                                return ListTile(
                                  title: Text(personnel.nom + " " + personnel.prenom),
                                  subtitle: Text(personnel.telephone),
                                  onTap: () => _showPersonnelOptionsDialog(personnel),
                                );
                              },
                            ),
                          ),
                        ...snapshotResidences.data!.map((residence) {
                          List<Personnel> personnelDeCetteResidence = snapshotPersonnel.data!
                              .where((personnel) => residence.personnelIds.contains(personnel.id) &&
                              (personnel.nom.toLowerCase().contains(searchController.text.toLowerCase()) ||
                                  personnel.prenom.toLowerCase().contains(searchController.text.toLowerCase())))
                              .toList();

                          return ExpansionTile(
                            title: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(residence.nom),
                                SizedBox(width: 8), // Espace entre le nom et l'icône
                                Icon(Icons.person), // Icône représentant le personnel
                                SizedBox(width: 4), // Espace entre l'icône et le nombre
                                Text('(${personnelDeCetteResidence.length})'), // Nombre de personnes
                              ],
                            ),
                            children: personnelDeCetteResidence.map((personnel) {
                              bool isClient = personnel.typeCompte == 'client';
                              return ListTile(
                                title: Text(
                                  personnel.nom + " " + personnel.prenom,
                                  style: isClient
                                      ? TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)
                                      : null,
                                ),
                                subtitle: Text(personnel.telephone),
                                onTap: () => _showPersonnelOptionsDialog(personnel),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}