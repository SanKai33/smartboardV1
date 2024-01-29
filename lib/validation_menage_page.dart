import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Visualisation.dart';
import 'affectation_personnel.dart';
import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/equipes.dart';
import 'models/personnel.dart';
import 'models/residence.dart';



class ValidationMenagePage extends StatefulWidget {
  late final Commande commande;

  ValidationMenagePage({required this.commande});

  @override
  _ValidationMenagePageState createState() => _ValidationMenagePageState();
}

class _ValidationMenagePageState extends State<ValidationMenagePage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _commandeSubscription;
  Commande? _commande;

  @override
  void initState() {
    super.initState();
    _subscribeToCommande();
  }
  void _subscribeToCommande() {
    _commandeSubscription = _firestore.collection('commandes').doc(widget.commande.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _commande = Commande.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
        });
      }
    });
  }
  @override
  void dispose() {
    _commandeSubscription?.cancel();
    super.dispose();
  }

  void _updateCommande() async {
    await _firestore.collection('commandes').doc(widget.commande.id).update({
      'detailsAppartements': widget.commande.detailsAppartements.map((key, value) => MapEntry(key, value.toMap())),
      'equipes': widget.commande.equipes.map((e) => e.toMap()).toList(),
    });
  }





  void _afficherOptionsValidation(Appartement appartement) {
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
                onTap: () {
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  _choisirOption(appartement, 'Ménage validé');
                },
              ),
              ListTile(
                title: Text('Valider le contrôle'),
                onTap: () {
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  _demanderCodeAdminPourControle(appartement);
                },
              ),
              ListTile(
                title: Text('Retour sur le ménage'),
                onTap: () {
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                  _afficherOptionsRetourMenage(appartement);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculerAvancement() {
    int totalAppartements = widget.commande.appartements.length;
    int appartementsFait = widget.commande.detailsAppartements.values
        .where((details) => details.menageEffectue)
        .length;
    return (appartementsFait / totalAppartements) * 100;
  }

  void _afficherOptionsRetourMenage(Appartement appartement) {
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
                  onTap: () => _choisirOption(appartement, 'Retour: $option'),
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
                  _choisirOption(appartement, 'Retour: ${_noteController.text}');
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _choisirOption(Appartement appartement, String choix) {
    Navigator.of(context).pop(); // Ferme la boîte de dialogue

    setState(() {
      // Récupère les détails de l'appartement actuel ou crée de nouveaux détails si inexistants
      DetailsAppartement details = _commande?.detailsAppartements[appartement.id] ?? DetailsAppartement();

      // Si c'est un retour, mettre à jour la note et marquer le ménage comme non effectué
      if (choix.startsWith('Retour:')) {
        details.note = choix.replaceFirst('Retour: ', '');
        details.etatValidation = 'Retour: ' + details.note;
        details.menageEffectue = false;
      } else if (details.etatValidation != choix) {
        // Si ménage/contrôle validé, mettre à jour l'état et marquer le ménage comme effectué si nécessaire
        details.etatValidation = choix;
        details.menageEffectue = choix == 'Ménage validé' || choix == 'Contrôle validé';

        if (choix == 'Ménage validé') {
          // Appeler la méthode pour créer une notification
          _creerNotification(
              appartement,
              'Le ménage de l\'appartement ${appartement.numero} a été validé à ${DateFormat('HH:mm').format(DateTime.now())}'
          );
        }
      } else {
        // Si l'utilisateur clique à nouveau sur la même option, réinitialiser l'état
        details.etatValidation = '';
        details.menageEffectue = false;
      }

      // Mettre à jour les détails dans la commande
      _commande?.detailsAppartements[appartement.id] = details;

      // Mettre à jour la commande dans Firestore et localement
      _updateCommande();
    });
  }

  void _creerNotification(Appartement appartement, String message) {
    _firestore.collection('notifications').add({
      'titre': 'Notification de ménage',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'appartementId': appartement.id,
      'entrepriseId': widget.commande.entrepriseId,
      // Ajouter d'autres détails si nécessaire
    });
  }

  Color _getCardColor(DetailsAppartement details) {
    if (details.etatValidation.startsWith('Retour:')) {
      return Colors.red.shade100;
    } else {
      switch (details.etatValidation) {
        case 'Ménage validé':
          return Colors.white;
        case 'Contrôle validé':
          return Colors.white;
        default:
          return Colors.white;
      }
    }
  }

  void _ajouterEquipe() {
    setState(() {
      String newTeamName = 'Équipe ${widget.commande.equipes.length + 1}';
      widget.commande.equipes.add(Equipe(nom: newTeamName, appartementIds: [], appartements: [], personnelIds: []));
    });
  }

  void _showTeamOptions(Equipe equipe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Options pour ${equipe.nom}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Affecter des appartements'),
                onTap: () => _showAssignAppartementsDialog(equipe),
              ),
              ListTile(
                title: Text('Ajouter personnel'),
                onTap: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue actuelle
                  _showAddPersonnelDialog(equipe); // Afficher la nouvelle boîte de dialogue
                },
              ),
              ListTile(
                title: Text('Supprimer l\'équipe'),
                onTap: () => _deleteEquipe(equipe),
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
          .where('entrepriseId', isEqualTo: widget.commande.entrepriseId) // Assurez-vous que cette condition est correcte
          .get();

      for (var doc in querySnapshot.docs) {
        personnelList.add(Personnel.fromFirestore(doc));
      }
    } catch (e) {
      print("Erreur lors de la récupération du personnel: $e");
    }
    return personnelList;
  }

  Future<void> _showAddPersonnelDialog(Equipe equipe) async {
    List<Personnel> personnelList = await _fetchAvailablePersonnel();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter personnel à ${equipe.nom}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: personnelList.map((personnel) {
                return ListTile(
                  title: Text('${personnel.prenom} ${personnel.nom}'),
                  onTap: () {
                    // Logique pour ajouter le personnel à l'équipe
                    equipe.appartementIds.add(personnel.id); // Ajouter l'ID de l'agent à l'équipe
                    _updateCommande(); // Mettre à jour la commande
                    Navigator.of(context).pop(); // Fermer la boîte de dialogue
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showAssignAppartementsDialog(Equipe equipe) {
    // Création d'une map pour suivre les appartements sélectionnés
    Map<String, bool> selectedAppartements = Map.fromIterable(
      widget.commande.appartements,
      key: (item) => item.id,
      value: (item) => equipe.appartementIds.contains(item.id),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Affecter des appartements à ${equipe.nom}'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: widget.commande.appartements.map((appartement) {
                    String equipeAffectation = _trouverEquipeAffectation(appartement.id);
                    bool isAssignedToAnotherTeam = equipeAffectation.isNotEmpty && equipeAffectation != equipe.nom;

                    return CheckboxListTile(
                      title: Text('Appartement ${appartement.numero}' + (isAssignedToAnotherTeam ? ' (Affecté à $equipeAffectation)' : '')),
                      value: selectedAppartements[appartement.id],
                      onChanged: isAssignedToAnotherTeam ? null : (bool? value) {
                        setState(() {
                          selectedAppartements[appartement.id] = value!;
                          if (value) {
                            // Supprimer l'appartement des autres équipes
                            widget.commande.equipes.forEach((otherEquipe) {
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
                    _applyAppartementSelection(selectedAppartements, equipe);
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

  String _trouverEquipeAffectation(String appartementId) {
    for (var equipe in widget.commande.equipes) {
      if (equipe.appartementIds.contains(appartementId)) {
        return equipe.nom;
      }
    }
    return '';
  }
  void _applyAppartementSelection(Map<String, bool> selectedAppartements, Equipe equipe) {
    setState(() {
      equipe.appartementIds = selectedAppartements.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      _updateCommande();
    });

    Navigator.pop(context); // Ajoutez cette ligne pour revenir à la page précédente
  }

  void _deleteEquipe(Equipe equipe) {
    setState(() {
      widget.commande.equipes.removeWhere((e) => e.nom == equipe.nom);
      _updateCommande();
    });
    Navigator.of(context).pop();
  }
  bool _peutFinaliserCommande() {
    return widget.commande.detailsAppartements.values
        .every((details) => details.etatValidation == 'Contrôle validé');
  }

  double _calculerAvancementEquipe(Equipe equipe) {
    int totalAppartementsEquipe = equipe.appartementIds.length;
    if (totalAppartementsEquipe == 0) return 0.0;

    int appartementsFait = equipe.appartementIds
        .where((id) => widget.commande.detailsAppartements[id]?.menageEffectue ?? false)
        .length;

    return (appartementsFait / totalAppartementsEquipe) * 100;
  }


  String _trouverEquipePourAppartement(String appartementId) {
    for (var equipe in widget.commande.equipes) {
      if (equipe.appartementIds.contains(appartementId)) {
        return equipe.nom; // Retourne le nom de l'équipe
      }
    }
    return 'Non attribué'; // Si aucun appartement n'est trouvé
  }

  Color _getColorForValidationStatus(DetailsAppartement details) {
    if (details.etatValidation.startsWith('Retour:')) {
      return Colors.red; // Point rouge pour le retour
    } else if (details.etatValidation == 'Ménage validé') {
      return Colors.blue; // Point bleu pour le ménage validé
    } else if (details.etatValidation == 'Contrôle validé') {
      return Colors.green; // Point vert pour le contrôle validé
    }
    return Colors.grey; // Couleur par défaut si non validé
  }

  // Fonction pour afficher les options de l'appartement
  void _afficherOptionsAppartement(Appartement appartement) {
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
                  // Logique pour modifier l'appartement
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Supprimer'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmerSuppressionAppartement(appartement);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _demanderCodeAdminPourControle(Appartement appartement) {
    final TextEditingController _codeAdminController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Entrer le Code Administrateur'),
          content: TextField(
            controller: _codeAdminController,
            keyboardType: TextInputType.number, // Clavier numérique
            decoration: InputDecoration(
              hintText: 'Code Administrateur',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Valider'),
              onPressed: () {
                if (_codeAdminController.text == "2233") {
                  Navigator.of(context).pop();
                  _choisirOption(appartement, 'Contrôle validé'); // Validez le contrôle
                } else {
                  // Gérer le cas où le code est incorrect
                  print('Code Administrateur incorrect');
                }
              },
            ),
          ],
        );
      },
    );
  }

// Fonction pour confirmer la suppression d'un appartement
  void _confirmerSuppressionAppartement(Appartement appartement) {
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
                _supprimerAppartement(appartement);
                Navigator.of(context).pop(); // Ferme la boîte de dialogue de confirmation
              },
            ),
          ],
        );
      },
    );
  }

// Fonction pour supprimer un appartement
  void _supprimerAppartement(Appartement appartement) {
    // Suppression locale
    setState(() {
      widget.commande.appartements.removeWhere((a) => a.id == appartement.id);
      widget.commande.detailsAppartements.remove(appartement.id);
      // Mettre à jour les équipes si nécessaire
      widget.commande.equipes.forEach((equipe) {
        equipe.appartementIds.removeWhere((id) => id == appartement.id);
      });
    });

    // Mise à jour de la commande dans Firestore
    _mettreAJourCommandeDansFirestore();
  }

  Future<void> _mettreAJourCommandeDansFirestore() async {
    try {
      // Préparez les données à mettre à jour
      Map<String, dynamic> commandeMiseAJour = {
        'appartements': widget.commande.appartements.map((x) => x.toMap()).toList(),
        'detailsAppartements': widget.commande.detailsAppartements.map((key, value) => MapEntry(key, value.toMap())),
        // Autres mises à jour si nécessaire
      };

      // Mise à jour du document de commande
      await FirebaseFirestore.instance.collection('commandes').doc(widget.commande.id).update(commandeMiseAJour);

      print("Commande mise à jour dans Firestore");
    } catch (e) {
      print("Erreur lors de la mise à jour de la commande : $e");
    }
  }




  Icon _getIconForValidationStatus(DetailsAppartement details) {
    if (details.etatValidation.startsWith('Retour:')) {
      return Icon(Icons.refresh, color: Colors.red); // Icône pour indiquer un retour
    } else if (details.etatValidation == 'Ménage validé') {
      return Icon(Icons.check_circle, color: Colors.blue); // Icône bleue pour le ménage validé
    } else if (details.etatValidation == 'Contrôle validé') {
      return Icon(Icons.check_circle, color: Colors.green); // Icône verte pour le contrôle validé
    }
    return Icon(Icons.circle, color: Colors.grey); // Icône par défaut si non validé
  }

  Widget _buildCustomProgressIndicator() {
    double avancement = _calculerAvancement();
    Color progressColor;

    if (avancement < 33) {
      progressColor = Colors.redAccent; // Couleur rouge plus vive
    } else if (avancement < 66) {
      progressColor = Colors.amber; // Couleur jaune plus vive
    } else {
      progressColor = Colors.greenAccent; // Couleur verte plus vive
    }

    return Container(
      alignment: Alignment.centerLeft, // Alignement du conteneur à gauche
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement des éléments de la colonne sur la gauche
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.0), // Ajout d'un padding pour déplacer le texte vers la gauche
            child: Text('', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: 8.0), // Ajout d'un padding pour déplacer le widget de progression vers la gauche
            child: SizedBox(
              height: 40.0, // Taille réduite
              width: 40.0, // Taille réduite
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    value: avancement / 100,
                    strokeWidth: 6.0, // Épaisseur réduite du trait
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                  Text(
                    '${avancement.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16, // Taille de police réduite
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                // Logique pour modifier la commande
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Wrap(
              spacing: 8, // Espacement horizontal entre les boutons
              runSpacing: 8, // Espacement vertical entre les lignes
              alignment: WrapAlignment.end, // Alignement des boutons à droite
              children: [
                ElevatedButton(
                  onPressed: _visualiserCommande,
                  child: Text('Visualiser la commande', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _ajouterEquipe,
                  child: Icon(Icons.group_add, color: Colors.white), // Icône pour ajouter une équipe
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Visibility(
                  visible: false, // Rendre le bouton invisible
                  maintainSize: true, // Conserve la taille du bouton
                  maintainAnimation: true, // Conserve l'animation du bouton
                  maintainState: true, // Conserve l'état du bouton
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AffectationPage()),
                      );
                    },
                    child: Icon(Icons.person_add_alt_1, color: Colors.white), // Icône pour affecter le personnel
                    style: ElevatedButton.styleFrom(
                      primary: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),





          Expanded(
            child: ListView(

              children: [
                Visibility(
                visible: false, // Mettez ce paramètre à false pour rendre le bouton invisible
                maintainSize: true, // Maintient la taille du bouton même s'il est invisible
                maintainAnimation: true, // Maintient les animations
                maintainState: true, // Maintient l'état du bouton
                child: ElevatedButton(
                  onPressed: _visualiserCommande,
                  child: Text('Visualiser la commande'),
                ),
                ),



                ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('Commande - ${DateFormat('dd/MM/yyyy').format(widget.commande.dateCommande)}', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 8),
                      Icon(Icons.apartment),
                      Text(' (${widget.commande.appartements.length})'),
                    ],
                  ),
                  children: widget.commande.appartements.map((appartement) {
                    DetailsAppartement details = widget.commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                    String equipeAttribuee = _trouverEquipePourAppartement(appartement.id);
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.circle, color: _getColorForValidationStatus(details)), // Icône de cercle coloré
                          title: Text('${appartement.numero}'),
                          subtitle: Text('${appartement.typologie} - ${appartement.batiment}'),
                          trailing: Text(equipeAttribuee), // Affiche l'équipe attribuée ici
                          isThreeLine: true, // Permet d'avoir trois lignes
                          onTap: () => _afficherOptionsAppartement(appartement),
                          // État du ménage en bas
                          dense: true, // Réduit l'espace entre les lignes
                        ),
                        // Affiche l'état du ménage en bas
                        Padding(
                          padding: EdgeInsets.only(left: 72), // Aligner avec le texte du ListTile
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"),
                              SizedBox(width: 8), // Espace supplémentaire
                            ],
                          ),
                        ),
                        Divider(), // Ajoute un fin trait pour séparer chaque appartement
                      ],
                    );
                  }).toList(),
                ),
                ...widget.commande.equipes.map((equipe) {
                  double avancementEquipe = _calculerAvancementEquipe(equipe) / 100;



                  return ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(equipe.nom),
                        avancementEquipe > 0
                            ? SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(
                            value: avancementEquipe,
                            strokeWidth: 3.0,
                          ),
                        )
                            : SizedBox(),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.black),
                      onPressed: () => _showTeamOptions(equipe),
                    ),
                    children: equipe.appartementIds.map((id) {
                      Appartement appartement = widget.commande.appartements.firstWhere((a) => a.id == id);
                      DetailsAppartement details = widget.commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                      return Card(
                        color: _getCardColor(details),
                        child: ListTile(
                          trailing: _getIconForValidationStatus(details),

                          leading: details.prioritaire ? Icon(Icons.priority_high, color: Colors.red) : null,
                          title: Text(
                            ' ${appartement.numero}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${appartement.typologie} - ${appartement.batiment}'),
                              Text('État: ${details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"}'),
                              if (details.note.isNotEmpty)
                                Text('Note: ${details.note}', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                              Row(
                                children: [
                                  Icon(Icons.bedroom_child_outlined, size: 20),
                                  SizedBox(width: 4),
                                  Text('${appartement.nombreLitsSimples} lits simples'),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.king_bed, size: 20),
                                  SizedBox(width: 4),
                                  Text('${appartement.nombreLitsDoubles} lits doubles'),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.bathtub, size: 20),
                                  SizedBox(width: 4),
                                  Text('${appartement.nombreSallesDeBains} SdB'),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _afficherOptionsValidation(appartement),
                            ),



                        );

                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

/**
  Future<void> _showPersonnelSelectionDialog() async {
    Set<String> selectedPersonnelIds = Set<String>.from(widget.commande.personnelIds);
    final List<Personnel> personnelList = await _fetchPersonnel();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Sélectionner le Personnel'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: personnelList.map((personnel) {
                    return CheckboxListTile(
                      title: Text('${personnel.prenom} ${personnel.nom}'),
                      value: _isSelected(personnel, selectedPersonnelIds),
                      onChanged: (bool? value) {
                        if (value == true) {
                          selectedPersonnelIds.add(personnel.id);
                        } else {
                          selectedPersonnelIds.remove(personnel.id);
                        }
                        setState(() {}); // Met à jour l'état local de la boîte de dialogue
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
                  child: Text('Valider'),
                  onPressed: () {
                    _updateCommandeWithSelectedPersonnel(selectedPersonnelIds);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }**/


  void _updateCommandeWithSelectedPersonnel(Set<String> selectedPersonnelIds) {
    setState(() {
      widget.commande.personnelIds = selectedPersonnelIds.toList();
    });
    // Mettez à jour la commande dans Firestore
    FirebaseFirestore.instance.collection('commandes').doc(widget.commande.id).update({
      'personnelIds': selectedPersonnelIds.toList(),
    });
  }

  Future<List<Personnel>> _fetchPersonnel() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String entrepriseId = widget.commande.entrepriseId; // Utilisation de l'ID de l'entreprise depuis l'objet commande

    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('personnel')
          .where('entrepriseId', isEqualTo: entrepriseId)
          .get();

      return querySnapshot.docs
          .map((doc) => Personnel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Erreur lors de la récupération du personnel : $e");
      return [];
    }
  }


  Set<String> selectedPersonnelIds = Set<String>();

  bool _isSelected(Personnel personnel, Set<String> selectedPersonnelIds) {
    return selectedPersonnelIds.contains(personnel.id);
  }

  void _togglePersonnelSelection(Personnel personnel, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedPersonnelIds.add(personnel.id);
      } else {
        selectedPersonnelIds.remove(personnel.id);
      }
    });
  }









  void _visualiserCommande() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => VisualiserCommandePage(commande: widget.commande, commandeId: widget.commande.id,)),
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
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                Navigator.of(context).pop(); // Retourne à l'écran précédent
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
      // Afficher un message de succès ou naviguer vers un autre écran si nécessaire
    } catch (e) {
      // Gérer l'erreur ici, par exemple afficher un message d'erreur
    }
  }
}




