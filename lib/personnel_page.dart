import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:smartboard/models/personnel.dart';
import 'models/client.dart';
import 'models/presence.dart';
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
  List<FichePresence> presenceList = [];
  TextEditingController searchController = TextEditingController();
  Map<String, bool> expandedResidences = {};

  @override
  void initState() {
    super.initState();
    _loadExistingPersonnel();
    _loadExistingClients();
    _loadResidences();
    _loadPresenceData();
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
      for (var residence in residences) {
        expandedResidences[residence.id] = false;
      }
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

  void _loadPresenceData() {
    FirebaseFirestore.instance
        .collection('fichesPresence')
        .where('entrepriseId', isEqualTo: widget.entrepriseId)
        .snapshots()
        .listen((snapshot) {
      var tempList = snapshot.docs
          .map((doc) => FichePresence.fromFirestore(doc))
          .toList();
      setState(() {
        presenceList = tempList;
      });
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

  void _movePersonnel(Personnel personnel, List<String> selectedResidences) async {
    await FirebaseFirestore.instance
        .collection('personnel')
        .doc(personnel.id)
        .update({'residencesAffectees': selectedResidences});
    setState(() {
      personnel.residencesAffectees = selectedResidences;
      _filterPersonnelAndClients(searchController.text);
    });
  }

  void _moveClient(Client client, List<String> selectedResidences) async {
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(client.id)
        .update({'residencesAffectees': selectedResidences});
    setState(() {
      client.residencesAffectees = selectedResidences;
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

  Future<void> _deletePersonnel(Personnel personnel) async {
    await FirebaseFirestore.instance
        .collection('personnel')
        .doc(personnel.id)
        .delete();
    setState(() {
      personnelList.remove(personnel);
      _filterPersonnelAndClients(searchController.text);
    });
  }

  Future<void> _deleteClient(Client client) async {
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(client.id)
        .delete();
    setState(() {
      clientList.remove(client);
      _filterPersonnelAndClients(searchController.text);
    });
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> _generateUniqueIdentifiant(String baseIdentifiant) async {
    String identifiant = baseIdentifiant;
    for (int i = 1; i <= 10; i++) {
      var existingUser = await FirebaseFirestore.instance
          .collection('personnel')
          .where('identifiant', isEqualTo: identifiant)
          .get();

      if (existingUser.docs.isEmpty) {
        return identifiant;
      }

      // Si l'identifiant existe déjà, ajouter un chiffre à la fin
      identifiant = '$baseIdentifiant$i';
    }

    // Si tous les identifiants de 1 à 10 sont pris, retourner une erreur
    throw Exception("Impossible de générer un identifiant unique.");
  }

  void _addNewPersonnel(
      String nom, String prenom, String telephone, String email, String typeCompte, bool estSuperviseur) async {
    String baseIdentifiant = nom.toLowerCase() + prenom[0].toLowerCase();

    try {
      String identifiant = await _generateUniqueIdentifiant(baseIdentifiant);

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
    } catch (e) {
      _showErrorDialog("Impossible de créer un identifiant unique pour cet utilisateur.");
    }
  }

  void _addNewClient(
      String nom, String prenom, String telephone, String email, bool estControleur) async {
    String baseIdentifiant = nom.toLowerCase() + prenom[0].toLowerCase();

    try {
      String identifiant = await _generateUniqueIdentifiant(baseIdentifiant);

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
    } catch (e) {
      _showErrorDialog("Impossible de créer un identifiant unique pour ce client.");
    }
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${personnel.nom} ${personnel.prenom}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSettingsDialog(personnel);
                },
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextField(
                            controller: _telephoneController,
                            decoration: InputDecoration(hintText: "Téléphone"),
                          ),
                          Text("Téléphone actuel", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(hintText: "Email"),
                          ),
                          Text("Email actuel", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 16),
                          Text('ID: ${personnel.identifiant}', style: TextStyle(color: Colors.grey)),
                          Text("Identifiant (Non modifiable)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 16),
                          Text('Résidences affectées: ${personnel.residencesAffectees.map((id) {
                            final residence = residences.firstWhere((res) => res.id == id, orElse: () => Residence(id: '', entrepriseId: '', nom: '', adresse: ''));
                            return residence.nom;
                          }).join(', ')}'),
                          Text("Résidences actuelles", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 8),
                          TextButton(
                            child: Text('Affecter à une autre résidence'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showAffectResidenceDialog(personnel);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            child: Text('Changer rôle'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showRoleDialogPersonnel(personnel);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            child: Text('Supprimer de la résidence'),
                            onPressed: () {
                              _showDeleteFromResidenceDialog(personnel);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(thickness: 1, color: Colors.black),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text('Gestion des fichiers', style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildFileSection('Carte d\'identité', personnel.id, 'identity_card', personnel.identityCardUrl),
                          _buildFileSection('Permis de conduire', personnel.id, 'driving_license', personnel.drivingLicenseUrl),
                          _buildOtherFilesSection(personnel.id, personnel.otherFilesUrls),
                        ],
                      ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFromResidenceDialog(Personnel personnel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer de la résidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: personnel.residencesAffectees.map((residenceId) {
              Residence residence = residences.firstWhere((res) => res.id == residenceId, orElse: () => Residence(id: '', entrepriseId: '', nom: '', adresse: ''));
              return ListTile(
                title: Text(residence.nom),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.black),
                  onPressed: () {
                    _deletePersonnelFromResidence(personnel, residenceId);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${client.nom} ${client.prenom}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSettingsDialog(client);
                },
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextField(
                            controller: _telephoneController,
                            decoration: InputDecoration(hintText: "Téléphone"),
                          ),
                          Text("Téléphone actuel", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(hintText: "Email"),
                          ),
                          Text("Email actuel", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 16),
                          Text('ID: ${client.nom.toLowerCase() + client.prenom[0].toLowerCase()}', style: TextStyle(color: Colors.grey)),
                          Text("Identifiant (Non modifiable)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 16),
                          Text('Résidences affectées: ${client.residencesAffectees.map((id) {
                            final residence = residences.firstWhere((res) => res.id == id, orElse: () => Residence(id: '', entrepriseId: '', nom: '', adresse: ''));
                            return residence.nom;
                          }).join(', ')}'),
                          Text("Résidences actuelles", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          SizedBox(height: 8),
                          TextButton(
                            child: Text('Affecter à une autre résidence'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showAffectResidenceDialogClient(client);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            child: Text('Changer rôle'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showRoleDialogClient(client);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            child: Text('Supprimer de la résidence'),
                            onPressed: () {
                              _showDeleteFromResidenceDialogClient(client);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(thickness: 1, color: Colors.black),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text('Gestion des fichiers', style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildFileSection('Carte d\'identité', client.id, 'identity_card', client.identityCardUrl),
                          _buildFileSection('Permis de conduire', client.id, 'driving_license', client.drivingLicenseUrl),
                          _buildOtherFilesSection(client.id, client.otherFilesUrls),
                        ],
                      ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFromResidenceDialogClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer de la résidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: client.residencesAffectees.map((residenceId) {
              Residence residence = residences.firstWhere((res) => res.id == residenceId, orElse: () => Residence(id: '', entrepriseId: '', nom: '', adresse: ''));
              return ListTile(
                title: Text(residence.nom),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.black),
                  onPressed: () {
                    _deleteClientFromResidence(client, residenceId);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, dynamic person) async {
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
                Text('Êtes-vous sûr de vouloir supprimer ce $entityType ? Cette action est irréversible.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () {
                if (person is Personnel) {
                  _deletePersonnel(person);
                } else if (person is Client) {
                  _deleteClient(person);
                }
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAffectResidenceDialog(Personnel personnel) {
    List<String> selectedResidences = List.from(personnel.residencesAffectees);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Affecter à une résidence'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Chercher résidence',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setState(() {
                        residences = residences.where((residence) {
                          return residence.nom.toLowerCase().contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  Expanded(
                    child: ListView(
                      children: residences.map((residence) {
                        bool isSelected = selectedResidences.contains(residence.id);
                        return CheckboxListTile(
                          title: Text(residence.nom),
                          subtitle: isSelected
                              ? Text('Déjà affecté', style: TextStyle(color: Colors.red))
                              : null,
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedResidences.add(residence.id);
                              } else {
                                selectedResidences.remove(residence.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedResidences.clear();
                      });
                      _showValidationDialog('Les affectations ont été réinitialisées.');
                    },
                    child: Text('Réinitialiser les affectations'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              child: Text('Affecter'),
              onPressed: () {
                _movePersonnel(personnel, selectedResidences);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAffectResidenceDialogClient(Client client) {
    List<String> selectedResidences = List.from(client.residencesAffectees);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Affecter à une résidence'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Chercher résidence',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setState(() {
                        residences = residences.where((residence) {
                          return residence.nom.toLowerCase().contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  Expanded(
                    child: ListView(
                      children: residences.map((residence) {
                        bool isSelected = selectedResidences.contains(residence.id);
                        return CheckboxListTile(
                          title: Text(residence.nom),
                          subtitle: isSelected
                              ? Text('Déjà affecté', style: TextStyle(color: Colors.red))
                              : null,
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedResidences.add(residence.id);
                              } else {
                                selectedResidences.remove(residence.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedResidences.clear();
                      });
                      _showValidationDialog('Les affectations ont été réinitialisées.');
                    },
                    child: Text('Réinitialiser les affectations'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              child: Text('Affecter'),
              onPressed: () {
                _moveClient(client, selectedResidences);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFileSection(String title, String personnelId, String fileType, String fileUrl) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        if (fileUrl.isEmpty)
          Text('Aucun fichier enregistré.')
        else
          Column(
            children: [
              Container(
                height: 200,
                child: PDFView(
                  filePath: fileUrl,
                ),
              ),
              ListTile(
                title: Text('Fichier enregistré'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.black),
                      onPressed: () => _downloadFile(fileUrl),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFile(personnelId, fileType),
                    ),
                  ],
                ),
              ),
            ],
          ),
        IconButton(
          icon: Icon(Icons.add, color: Colors.black),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );
            if (result != null) {
              File file = File(result.files.single.path!);
              await _uploadFile(file, personnelId, fileType);
              setState(() {});
            }
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOtherFilesSection(String personnelId, List<String> fileUrls) {
    return Column(
      children: [
        Text('Autres fichiers', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        if (fileUrls.isEmpty)
          Text('Aucun fichier enregistré.')
        else
          Column(
            children: fileUrls.map((url) {
              return Column(
                children: [
                  Container(
                    height: 200,
                    child: PDFView(
                      filePath: url,
                    ),
                  ),
                  ListTile(
                    title: Text('Fichier enregistré'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.download, color: Colors.black),
                          onPressed: () => _downloadFile(url),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteOtherFile(personnelId, url),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        IconButton(
          icon: Icon(Icons.add, color: Colors.black),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );
            if (result != null) {
              File file = File(result.files.single.path!);
              await _uploadFile(file, personnelId, 'other');
              setState(() {});
            }
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _uploadFile(File file, String personnelId, String fileType) async {
    String fileName = '${personnelId}_$fileType.pdf';
    await FirebaseStorage.instance.ref('uploads/$fileName').putFile(file);
    String downloadURL = await FirebaseStorage.instance.ref('uploads/$fileName').getDownloadURL();

    if (fileType == 'identity_card') {
      await FirebaseFirestore.instance.collection('personnel').doc(personnelId).update({'identityCardUrl': downloadURL});
    } else if (fileType == 'driving_license') {
      await FirebaseFirestore.instance.collection('personnel').doc(personnelId).update({'drivingLicenseUrl': downloadURL});
    } else if (fileType == 'other') {
      Personnel personnel = personnelList.firstWhere((p) => p.id == personnelId);
      personnel.otherFilesUrls.add(downloadURL);
      await FirebaseFirestore.instance.collection('personnel').doc(personnelId).update({'otherFilesUrls': personnel.otherFilesUrls});
    }
  }

  Future<String> _getFileUrl(String personnelId, String fileType) async {
    String fileName = '${personnelId}_$fileType.pdf';
    try {
      return await FirebaseStorage.instance.ref('uploads/$fileName').getDownloadURL();
    } catch (e) {
      return '';
    }
  }

  Future<List<String>> _getOtherFilesUrls(String personnelId) async {
    ListResult result = await FirebaseStorage.instance.ref('uploads').listAll();
    List<String> urls = [];
    for (Reference ref in result.items) {
      if (ref.name.startsWith(personnelId) && ref.name.contains('_other')) {
        String url = await ref.getDownloadURL();
        urls.add(url);
      }
    }
    return urls;
  }

  Future<void> _deleteFile(String personnelId, String fileType) async {
    String fileName = '${personnelId}_$fileType.pdf';
    await FirebaseStorage.instance.ref('uploads/$fileName').delete();

    if (fileType == 'identity_card') {
      await FirebaseFirestore.instance.collection('personnel').doc(personnelId).update({'identityCardUrl': ''});
    } else if (fileType == 'driving_license') {
      await FirebaseFirestore.instance.collection('personnel').doc(personnelId).update({'drivingLicenseUrl': ''});
    }
    setState(() {});
  }

  Future<void> _deleteOtherFile(String personnelId, String url) async {
    await FirebaseStorage.instance.refFromURL(url).delete();
    Personnel personnel = personnelList.firstWhere((p) => p.id == personnelId);
    personnel.otherFilesUrls.remove(url);
    await FirebaseFirestore.instance.collection('personnel').doc(personnelId).update({'otherFilesUrls': personnel.otherFilesUrls});
    setState(() {});
  }

  void _downloadFile(String url) async {
    // Ajoutez la logique pour télécharger le fichier
  }

  Widget _buildPresenceIndicator(Personnel personnel) {
    var presence = presenceList.firstWhere(
            (fiche) => fiche.statutPresence.containsKey(personnel.id),
        orElse: () => FichePresence(id: '', date: DateTime.now(), statutPresence: {}));
    bool present = presence.statutPresence[personnel.id] ?? false;

    return Row(
      children: [
        Icon(
          Icons.fiber_manual_record,
          color: present ? Colors.green : Colors.red,
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPresenceIndicatorClient(Client client) {
    var presence = presenceList.firstWhere(
            (fiche) => fiche.statutPresence.containsKey(client.id),
        orElse: () => FichePresence(id: '', date: DateTime.now(), statutPresence: {}));
    bool present = presence.statutPresence[client.id] ?? false;

    return Row(
      children: [
        Icon(
          Icons.fiber_manual_record,
          color: present ? Colors.green : Colors.red,
        ),
        SizedBox(width: 8),
      ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: _showAffectationsDialog,
              icon: Icon(Icons.edit, color: Colors.white),
              label: Text(
                'Affectations',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
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
                  _buildPresenceTable(
                    title: 'Personnel et Clients',
                    rows: _buildAllPersonnelAndClientRows(),
                    showHeader: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildAllPersonnelAndClientRows() {
    List<DataRow> rows = [];

    var allPersonnelAndClients = <dynamic>[
      ...filteredPersonnelList,
      ...filteredClientList
    ];

    allPersonnelAndClients.sort((a, b) => (a as dynamic).nom.compareTo((b as dynamic).nom));

    for (var item in allPersonnelAndClients) {
      if (item is Personnel) {
        rows.add(DataRow(cells: [
          DataCell(Text(item.nom)),
          DataCell(Text(item.prenom)),
          DataCell(Text(item.telephone)),
          DataCell(Text(item.email)),
          DataCell(Text(
            item.estSuperviseur ? 'Superviseur' : 'Agent',
            style: TextStyle(color: item.estSuperviseur ? Colors.red : Colors.black),
          )),
          DataCell(Text(item.residencesAffectees.map((id) {
            final residence = residences.firstWhere((res) => res.id == id, orElse: () => Residence(id: '', entrepriseId: '', nom: '', adresse: ''));
            return residence.nom;
          }).join(', '))),
          DataCell(Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue), // Nouveau design de l'icône
                onPressed: () {
                  _showEditPersonnelDialog(item);
                },
              ),
            ],
          )),
        ]));
      } else if (item is Client) {
        rows.add(DataRow(
          color: MaterialStateColor.resolveWith((states) => Colors.grey.shade100), // Gris plus clair
          cells: [
            DataCell(Text(item.nom)),
            DataCell(Text(item.prenom)),
            DataCell(Text(item.telephone)),
            DataCell(Text(item.email)),
            DataCell(Text(
              item.estControleur ? 'Contrôleur' : 'Client',
              style: TextStyle(color: item.estControleur ? Colors.red : Colors.black),
            )),
            DataCell(Text(item.residencesAffectees.map((id) {
              final residence = residences.firstWhere((res) => res.id == id, orElse: () => Residence(id: '', entrepriseId: '', nom: '', adresse: ''));
              return residence.nom;
            }).join(', '))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue), // Nouveau design de l'icône
                  onPressed: () {
                    _showEditClientDialog(item);
                  },
                ),
              ],
            )),
          ],
        ));
      }
    }

    return rows;
  }

  Widget _buildPresenceTable({required String title, required List<DataRow> rows, required bool showHeader}) {
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
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade200), // Bleu agréable à l'œil pour l'entête
              columns: [
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Prénom')),
                DataColumn(label: Text('Téléphone')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Rôle')),
                DataColumn(label: Text('Résidences')),
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

  void _showAffectationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Affectations en cours'),
          content: SingleChildScrollView(
            child: Column(
              children: residences.map((residence) {
                List<Personnel> personnelAffecte = personnelList.where((p) => p.residencesAffectees.contains(residence.id)).toList();
                return ListTile(
                  title: Text(residence.nom),
                  subtitle: Text('Agents affectés: ${personnelAffecte.length}'),
                  trailing: TextButton(
                    onPressed: () => _showModifyAffectationDialog(residence),
                    child: Text('Modifier', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModifyAffectationDialog(Residence residence) {
    List<String> selectedPersonnel = personnelList
        .where((p) => p.residencesAffectees.contains(residence.id))
        .map((p) => p.id)
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier affectation - ${residence.nom}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: personnelList.map((personnel) {
                  return CheckboxListTile(
                    title: Text('${personnel.nom} ${personnel.prenom}'),
                    subtitle: selectedPersonnel.contains(personnel.id)
                        ? Text('Déjà affecté', style: TextStyle(color: Colors.red))
                        : null,
                    value: selectedPersonnel.contains(personnel.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedPersonnel.add(personnel.id);
                        } else {
                          selectedPersonnel.remove(personnel.id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              child: Text('Enregistrer'),
              onPressed: () {
                _saveAffectationChanges(residence.id, selectedPersonnel);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveAffectationChanges(String residenceId, List<String> selectedPersonnel) async {
    for (var personnel in personnelList) {
      if (selectedPersonnel.contains(personnel.id)) {
        if (!personnel.residencesAffectees.contains(residenceId)) {
          personnel.residencesAffectees.add(residenceId);
        }
      } else {
        personnel.residencesAffectees.remove(residenceId);
      }
      await _updatePersonnel(personnel);
    }
    setState(() {
      _loadExistingPersonnel();
    });
  }

  // Missing methods added here
  void _showSettingsDialog(dynamic person) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Paramètres'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: Text('Modifier le mot de passe'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showChangePasswordDialog(person);
                  },
                ),
                ListTile(
                  title: Text('Supprimer le compte'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDeleteAccount(context, person);
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(dynamic person) {
    final _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(hintText: "Nouveau mot de passe"),
                  obscureText: true,
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              child: Text('Enregistrer'),
              onPressed: () {
                _changePassword(person, _passwordController.text);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _changePassword(dynamic person, String newPassword) async {
    String identifiant;
    if (person is Personnel) {
      identifiant = person.identifiant;
    } else if (person is Client) {
      identifiant = person.nom.toLowerCase() + person.prenom[0].toLowerCase();
    } else {
      return;
    }

    await FirebaseFirestore.instance
        .collection('auth')
        .where('identifiant', isEqualTo: identifiant)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.update({'password': newPassword});
      }
    });

    _showValidationDialog('Le mot de passe a été mis à jour.');
  }
}
