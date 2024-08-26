import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Visualisation.dart';

import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/equipes.dart';
import 'models/personnel.dart';
import 'models/residence.dart';

class ValidationMenagePage extends StatefulWidget {
  final Commande commande;

  ValidationMenagePage({required this.commande});

  @override
  _ValidationMenagePageState createState() => _ValidationMenagePageState();
}

class _ValidationMenagePageState extends State<ValidationMenagePage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Residence? residence;
  String _fcmToken = '';
  Timer? _timer;
  List<Personnel> _personnelAffecte = [];
  TextEditingController noteGlobaleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noteGlobaleController.text = widget.commande.noteGlobale;
    _fetchPersonnelAffecte();
  }

  Future<void> _fetchPersonnelAffecte() async {
    List<Personnel> personnelList = [];
    try {
      QuerySnapshot personnelSnapshot = await _firestore
          .collection('personnel')
          .where('residenceAffectee', isEqualTo: widget.commande.residenceId)
          .get();

      for (var doc in personnelSnapshot.docs) {
        personnelList.add(Personnel.fromFirestore(doc));
      }
    } catch (e) {
      print("Erreur lors de la récupération du personnel: $e");
    }

    if (mounted) {
      setState(() {
        _personnelAffecte = personnelList;
      });
    }
  }

  void _updateCommande(Commande commande) async {
    commande.noteGlobale = noteGlobaleController.text;
    await _firestore.collection('commandes').doc(commande.id).update({
      'detailsAppartements': commande.detailsAppartements.map((key, value) => MapEntry(key, value.toMap())),
      'equipes': commande.equipes.map((e) => e.toMap()).toList(),
      'noteGlobale': commande.noteGlobale,
    });
  }

  void _afficherOptionsValidation(Appartement appartement, Commande commande) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Options de validation pour ${appartement.numero}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Valider le ménage'),
                onTap: () => _choisirOption(appartement, 'Ménage validé', commande),
              ),
              ListTile(
                title: Text('Valider le contrôle'),
                onTap: () => _choisirOption(appartement, 'Contrôle validé', commande),
              ),
              ListTile(
                title: Text('Retour sur le ménage'),
                onTap: () {
                  Navigator.of(context).pop();
                  _afficherOptionsRetourMenage(appartement, commande);
                },
              ),
              ListTile(
                title: Text('Modifier'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualiserCommandePage(
                        commandeId: commande.id,
                        commande: commande,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _afficherOptionsRetourMenage(Appartement appartement, Commande commande) {
    final TextEditingController _noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Spécifier le type de retour pour ${appartement.numero}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(hintText: 'Écrire une note spécifique'),
                ),
                ...['Lit', 'Cuisine', 'Salle de bain', 'Poussière', 'Aspirateur']
                    .map((option) => ListTile(
                  title: Text(option),
                  onTap: () => _choisirOption(appartement, 'Retour: $option', commande),
                ))
                    .toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Enregistrer Note'),
              onPressed: () {
                if (_noteController.text.isNotEmpty) {
                  _choisirOption(appartement, 'Retour: ${_noteController.text}', commande);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _choisirOption(Appartement appartement, String choix, Commande commande) {
    Navigator.of(context).pop();
    setState(() {
      DetailsAppartement details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();

      if (choix.startsWith('Retour:')) {
        details.note = choix.replaceFirst('Retour: ', '');
        details.etatValidation = 'Retour: ' + details.note;
        details.menageEffectue = false;
      } else if (details.etatValidation != choix) {
        details.etatValidation = choix;
        details.menageEffectue = choix == 'Ménage validé' || choix == 'Contrôle validé';

        if (choix == 'Ménage validé') {
          _creerNotification(appartement,
              'Le ménage de l\'appartement ${appartement.numero} a été validé à ${DateFormat('HH:mm').format(DateTime.now())}');
        }
      } else {
        details.etatValidation = '';
        details.menageEffectue = false;
      }

      commande.detailsAppartements[appartement.id] = details;
      _updateCommande(commande);
    });
  }

  void _creerNotification(Appartement appartement, String message) {
    _firestore.collection('notifications').add({
      'titre': 'Notification de ménage',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'appartementId': appartement.id,
      'entrepriseId': widget.commande.entrepriseId,
    });
  }

  Color _getCardColor(DetailsAppartement details) {
    if (details.etatValidation.startsWith('Retour:')) {
      return Colors.red.shade100;
    } else {
      return Colors.white;
    }
  }

  void _ajouterEquipe(Commande commande) {
    setState(() {
      String newTeamName = 'Équipe ${commande.equipes.length + 1}';
      Equipe nouvelleEquipe = Equipe(nom: newTeamName, appartementIds: [], personnelIds: []);
      commande.equipes.add(nouvelleEquipe);

      _firestore.collection('commandes').doc(commande.id).update({
        'equipes': commande.equipes.map((e) => e.toMap()).toList(),
      });
    });
  }

  void _showTeamOptions(Equipe equipe, Commande commande) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Options pour ${equipe.nom}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Ajouter appartement'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAssignAppartementsDialog(equipe, commande);
                },
              ),
              ListTile(
                title: Text('Affecter personnel'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddPersonnelDialog(equipe, commande);
                },
              ),
              ListTile(
                title: Text('Supprimer l\'équipe'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteEquipe(equipe, commande);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Personnel>> _fetchAvailablePersonnel() async {
    List<Personnel> personnelList = [];
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('personnel')
          .where('entrepriseId', isEqualTo: widget.commande.entrepriseId)
          .get();

      for (var doc in querySnapshot.docs) {
        personnelList.add(Personnel.fromFirestore(doc));
      }
    } catch (e) {
      print("Erreur lors de la récupération du personnel: $e");
    }
    return personnelList;
  }

  Future<void> _showAddPersonnelDialog(Equipe equipe, Commande commande) async {
    List<Personnel> personnelList = await _fetchAvailablePersonnel();
    List<Personnel> personnelAffecte =
    personnelList.where((p) => p.residencesAffectees == widget.commande.residenceId).toList();
    List<Personnel> personnelGeneral =
    personnelList.where((p) => p.residencesAffectees != widget.commande.residenceId).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter personnel à ${equipe.nom}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ...personnelAffecte.map((personnel) {
                  String? equipeNom = _getEquipeForPersonnel(personnel.id, commande);
                  bool isAssignedToAnotherTeam = equipeNom != null && equipeNom != equipe.nom;

                  return ListTile(
                    title: Text('${personnel.prenom} ${personnel.nom}'),
                    subtitle: isAssignedToAnotherTeam ? Text('Affecté à $equipeNom') : null,
                    onTap: isAssignedToAnotherTeam
                        ? null
                        : () {
                      setState(() {
                        equipe.personnelIds.add(personnel.id);
                        _updateCommande(commande);
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Personnel ajouté avec succès.'),
                        ),
                      );
                    },
                    trailing: isAssignedToAnotherTeam
                        ? null
                        : IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          equipe.personnelIds.remove(personnel.id);
                          _updateCommande(commande);
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Personnel désaffecté avec succès.'),
                          ),
                        );
                      },
                    ),
                    enabled: !isAssignedToAnotherTeam,
                  );
                }).toList(),
                Divider(),
                Text('Personnes non affectées à la résidence'),
                ...personnelGeneral.map((personnel) {
                  return ListTile(
                    title: Text('${personnel.prenom} ${personnel.nom}'),
                    onTap: () {
                      setState(() {
                        equipe.personnelIds.add(personnel.id);
                        _updateCommande(commande);
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Personnel ajouté avec succès.'),
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _getEquipeForPersonnel(String personnelId, Commande commande) {
    for (var equipe in commande.equipes) {
      if (equipe.personnelIds.contains(personnelId)) {
        return equipe.nom;
      }
    }
    return null;
  }

  void _showAssignAppartementsDialog(Equipe equipe, Commande commande) {
    Map<String, bool> selectedAppartements = Map.fromIterable(
      commande.appartements,
      key: (item) => item.id,
      value: (item) => equipe.appartementIds.contains(item.id),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Ajouter appartement à ${equipe.nom}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: commande.appartements.map((appartement) {
                    String equipeAffectation = _trouverEquipeAffectation(appartement.id, commande);
                    bool isAssignedToAnotherTeam =
                        equipeAffectation.isNotEmpty && equipeAffectation != equipe.nom;

                    return CheckboxListTile(
                      title: Text(
                          'Appartement ${appartement.numero} - Bâtiment ${appartement.batiment}' +
                              (isAssignedToAnotherTeam ? ' (Affecté à $equipeAffectation)' : '')),
                      value: selectedAppartements[appartement.id],
                      onChanged: isAssignedToAnotherTeam
                          ? null
                          : (bool? value) {
                        setState(() {
                          selectedAppartements[appartement.id] = value!;
                          if (value) {
                            commande.equipes.forEach((otherEquipe) {
                              if (otherEquipe.nom != equipe.nom) {
                                otherEquipe.appartementIds.remove(appartement.id);
                              }
                            });
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Enregistrer'),
                  onPressed: () {
                    _applyAppartementSelection(selectedAppartements, equipe, commande);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appartements affectés avec succès.'),
                      ),
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

  String _trouverEquipeAffectation(String appartementId, Commande commande) {
    for (var equipe in commande.equipes) {
      if (equipe.appartementIds.contains(appartementId)) {
        return equipe.nom;
      }
    }
    return '';
  }

  void _applyAppartementSelection(
      Map<String, bool> selectedAppartements, Equipe equipe, Commande commande) {
    setState(() {
      equipe.appartementIds =
          selectedAppartements.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
      _updateCommande(commande);
    });
  }

  void _deleteEquipe(Equipe equipe, Commande commande) {
    setState(() {
      commande.equipes.removeWhere((e) => e.nom == equipe.nom);
      _updateCommande(commande);
    });
  }

  bool _peutFinaliserCommande(Commande commande) {
    return commande.detailsAppartements.values
        .every((details) => details.etatValidation == 'Contrôle validé');
  }

  double _calculerAvancementEquipe(Equipe equipe, Commande commande) {
    int totalAppartementsEquipe = equipe.appartementIds.length;
    if (totalAppartementsEquipe == 0) return 0.0;

    int appartementsFait = equipe.appartementIds
        .where((id) => commande.detailsAppartements[id]?.menageEffectue ?? false)
        .length;

    return (appartementsFait / totalAppartementsEquipe) * 100;
  }

  int _calculerNombreLitsSimplesPourEquipe(Equipe equipe, Commande commande) {
    int totalLitsSimples = 0;
    for (var appartementId in equipe.appartementIds) {
      var appartement = commande.appartements.firstWhere((a) => a.id == appartementId);
      totalLitsSimples += appartement.nombreLitsSimples;
    }
    return totalLitsSimples;
  }

  int _calculerNombreLitsDoublesPourEquipe(Equipe equipe, Commande commande) {
    int totalLitsDoubles = 0;
    for (var appartementId in equipe.appartementIds) {
      var appartement = commande.appartements.firstWhere((a) => a.id == appartementId);
      totalLitsDoubles += appartement.nombreLitsDoubles;
    }
    return totalLitsDoubles;
  }

  int _calculerNombreSallesDeBainPourEquipe(Equipe equipe, Commande commande) {
    int totalSallesDeBain = 0;
    for (var appartementId in equipe.appartementIds) {
      var appartement = commande.appartements.firstWhere((a) => a.id == appartementId);
      totalSallesDeBain += appartement.nombreSallesDeBains;
    }
    return totalSallesDeBain;
  }

  String _trouverEquipePourAppartement(String appartementId, Commande commande) {
    for (var equipe in commande.equipes) {
      if (equipe.appartementIds.contains(appartementId)) {
        return equipe.nom;
      }
    }
    return 'Non attribué';
  }

  Color _getColorForValidationStatus(DetailsAppartement details) {
    if (details.etatValidation.startsWith('Retour:')) {
      return Colors.red;
    } else if (details.etatValidation == 'Ménage validé') {
      return Colors.blue;
    } else if (details.etatValidation == 'Contrôle validé') {
      return Colors.green;
    }
    return Colors.grey;
  }

  void _afficherOptionsAppartement(Appartement appartement, Commande commande) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Options pour ${appartement.numero}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Modifier'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualiserCommandePage(
                        commandeId: commande.id,
                        commande: commande,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Supprimer'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmerSuppressionAppartement(appartement, commande);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmerSuppressionAppartement(Appartement appartement, Commande commande) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer l\'appartement ${appartement.numero} ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () {
                _supprimerAppartement(appartement, commande);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _supprimerAppartement(Appartement appartement, Commande commande) {
    setState(() {
      commande.appartements.removeWhere((a) => a.id == appartement.id);
      commande.detailsAppartements.remove(appartement.id);
      commande.equipes.forEach((equipe) {
        equipe.appartementIds.removeWhere((id) => id == appartement.id);
      });
    });

    _mettreAJourCommandeDansFirestore(commande);
  }

  Future<void> _mettreAJourCommandeDansFirestore(Commande commande) async {
    try {
      Map<String, dynamic> commandeMiseAJour = {
        'appartements': commande.appartements.map((x) => x.toMap()).toList(),
        'detailsAppartements': commande.detailsAppartements.map((key, value) => MapEntry(key, value.toMap())),
        'equipes': commande.equipes.map((e) => e.toMap()).toList(),
      };

      await FirebaseFirestore.instance.collection('commandes').doc(commande.id).update(commandeMiseAJour);

      print("Commande mise à jour dans Firestore");
    } catch (e) {
      print("Erreur lors de la mise à jour de la commande : $e");
    }
  }

  Icon _getIconForValidationStatus(DetailsAppartement details) {
    if (details.etatValidation.startsWith('Retour:')) {
      return Icon(Icons.refresh, color: Colors.red);
    } else if (details.etatValidation == 'Ménage validé') {
      return Icon(Icons.check_circle, color: Colors.blue);
    } else if (details.etatValidation == 'Contrôle validé') {
      return Icon(Icons.check_circle, color: Colors.green);
    }
    return Icon(Icons.circle, color: Colors.grey);
  }

  int _calculerNombreLits(Commande commande) {
    int totalLits = 0;
    for (var appartement in commande.appartements) {
      totalLits += appartement.nombreLitsSimples + appartement.nombreLitsDoubles;
    }
    return totalLits;
  }

  int _calculerNombreSallesDeBain(Commande commande) {
    int totalSallesDeBain = 0;
    for (var appartement in commande.appartements) {
      totalSallesDeBain += appartement.nombreSallesDeBains;
    }
    return totalSallesDeBain;
  }

  double _calculerAvancementGlobal(Commande commande) {
    int totalAppartements = commande.appartements.length;
    if (totalAppartements == 0) return 0.0;

    int appartementsFait = commande.detailsAppartements.values.where((details) => details.menageEffectue).length;

    return (appartementsFait / totalAppartements) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validation du Ménage'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'Modifier':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualiserCommandePage(
                        commandeId: widget.commande.id,
                        commande: widget.commande,
                      ),
                    ),
                  );
                  break;
                case 'Supprimer':
                  _showDeleteConfirmationDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Modifier',
                child: Text('Modifier'),
              ),
              const PopupMenuItem<String>(
                value: 'Supprimer',
                child: Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('commandes').doc(widget.commande.id).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Vérification des données de la commande
          var data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null || data.isEmpty) {
            return Center(child: Text('Aucune donnée disponible'));
          }

          Commande commande = Commande.fromMap(data, snapshot.data!.id);

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _visualiserCommande,
                      child: Text('Visualiser la commande', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _ajouterEquipe(commande),
                      child: Icon(Icons.group_add, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.black, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apartment, size: 20),
                              SizedBox(width: 4),
                              Text('Appartements: ${commande.appartements.length}', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.bed, size: 20),
                              SizedBox(width: 4),
                              Text('Lits Simples: ${_calculerNombreLitsSimplesPourEquipe(commande.equipes.isNotEmpty ? commande.equipes[0] : Equipe(nom: 'N/A', appartementIds: [], personnelIds: []), commande)}', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.king_bed_outlined, size: 20),
                              SizedBox(width: 4),
                              Text('Lits Doubles: ${_calculerNombreLitsDoublesPourEquipe(commande.equipes.isNotEmpty ? commande.equipes[0] : Equipe(nom: 'N/A', appartementIds: [], personnelIds: []), commande)}', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.bathtub, size: 20),
                              SizedBox(width: 4),
                              Text('SdB: ${_calculerNombreSallesDeBainPourEquipe(commande.equipes.isNotEmpty ? commande.equipes[0] : Equipe(nom: 'N/A', appartementIds: [], personnelIds: []), commande)}', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Note Globale:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    noteGlobaleController.text,
                                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          CircularProgressIndicator(
                            value: _calculerAvancementGlobal(commande) / 100,
                            strokeWidth: 6.0,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: _afficherPersonnelAffecte(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: commande.equipes.length,
                  itemBuilder: (context, index) {
                    Equipe equipe = commande.equipes[index];
                    double avancementEquipe = _calculerAvancementEquipe(equipe, commande) / 100;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.black, width: 1),
                        ),
                        child: ExpansionTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(equipe.nom, style: TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(Icons.more_vert),
                                    onPressed: () => _showTeamOptions(equipe, commande),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.apartment, size: 16),
                                      SizedBox(width: 4),
                                      Text('Appartements: ${equipe.appartementIds.length}'),
                                    ],
                                  ),
                                  CircularProgressIndicator(
                                    value: avancementEquipe,
                                    strokeWidth: 6.0,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.child_friendly, size: 16),
                                      SizedBox(width: 4),
                                      Text('Lits Simples: ${_calculerNombreLitsSimplesPourEquipe(equipe, commande)}'),
                                    ],
                                  ),
                                  SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.king_bed_outlined, size: 16),
                                      SizedBox(width: 4),
                                      Text('Lits Doubles: ${_calculerNombreLitsDoublesPourEquipe(equipe, commande)}'),
                                    ],
                                  ),
                                  SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.bathtub_outlined, size: 16),
                                      SizedBox(width: 4),
                                      Text('SdB: ${_calculerNombreSallesDeBainPourEquipe(equipe, commande)}'),
                                    ],
                                  ),
                                ],
                              ),
                              if (equipe.personnelIds.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text('Personnel:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Wrap(
                                  spacing: 4,
                                  children: equipe.personnelIds.map((personnelId) {
                                    Personnel personnel = _personnelAffecte.firstWhere(
                                          (p) => p.id == personnelId,
                                      orElse: () => Personnel(
                                        id: '',
                                        identifiant: '',
                                        nom: 'Inconnu',
                                        prenom: '',
                                        email: '',
                                        telephone: '',
                                        typeCompte: '',
                                        estSuperviseur: false,
                                        entrepriseId: '', residencesAffectees: [],
                                      ),
                                    );
                                    return Chip(
                                      label: Text('${personnel.prenom} ${personnel.nom}', style: TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(Icons.keyboard_arrow_down),
                          children: equipe.appartementIds.map((id) {
                            Appartement appartement = commande.appartements.firstWhere((a) => a.id == id);
                            DetailsAppartement details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.black, width: 1),
                              ),
                              color: _getCardColor(details),
                              child: ListTile(
                                trailing: _getIconForValidationStatus(details),
                                leading: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (details.prioritaire)
                                      Text('Prio', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    Text('Ordre: ${details.ordreAppartements}', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        ' ${appartement.numero}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Bâtiment: ${appartement.batiment}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (details.note.isNotEmpty)
                                      Text('Note: ${details.note}', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.single_bed_outlined, size: 20),
                                            SizedBox(width: 4),
                                            Text('${appartement.nombreLitsSimples}'),
                                          ],
                                        ),
                                        SizedBox(width: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.king_bed_outlined, size: 20),
                                            SizedBox(width: 4),
                                            Text('${appartement.nombreLitsDoubles}'),
                                          ],
                                        ),
                                        SizedBox(width: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.bathtub_outlined, size: 20),
                                            SizedBox(width: 4),
                                            Text('${appartement.nombreSallesDeBains}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Typologie: ${appartement.typologie}',
                                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            details.estLibre ? 'Libre' : 'Occupé',
                                            style: TextStyle(
                                              color: details.estLibre ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _afficherOptionsValidation(appartement, commande),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _afficherPersonnelAffecte() {
    List<Widget> personnelWidgets = [];
    for (var personnel in _personnelAffecte) {
      personnelWidgets.add(Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('${personnel.prenom} ${personnel.nom}'),
        ),
      ));
    }
    return personnelWidgets;
  }

  void _visualiserCommande() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => VisualiserCommandePage(commande: widget.commande, commandeId: widget.commande.id)),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer cette commande ?'),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () async {
                await _deleteCommande();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCommande() async {
    try {
      await _firestore.collection('commandes').doc(widget.commande.id).delete();
    } catch (e) {
      print("Erreur lors de la suppression de la commande : $e");
    }
  }
}