import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartboard/selection_appartement_page.dart';
import 'models/appartement.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/equipes.dart';
import 'models/residence.dart';



class ValidationMenagePage extends StatefulWidget {
  late final Commande commande;

  ValidationMenagePage({required this.commande});

  @override
  _ValidationMenagePageState createState() => _ValidationMenagePageState();
}

class _ValidationMenagePageState extends State<ValidationMenagePage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Residence? residence; // Variable pour stocker l'objet Residence
  String _fcmToken = '';

  @override
  void initState() {
    super.initState();
    _loadCommande();
    _obtenirFcmToken();
  }



  void _obtenirFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();  // Assure-toi que Firebase Messaging est importé
    setState(() {
      _fcmToken = token ?? '';
    });
    print("Token FCM: $_fcmToken");
  }

  void _loadCommande() async {
    DocumentSnapshot snapshot = await _firestore.collection('commandes').doc(widget.commande.id).get();
    Commande updatedCommande = Commande.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    setState(() {
      widget.commande = updatedCommande;
    });
  }

  void _updateCommande() async {
    await _firestore.collection('commandes').doc(widget.commande.id).update({
      'detailsAppartements': widget.commande.detailsAppartements.map((key, value) => MapEntry(key, value.toMap())),
      'equipes': widget.commande.equipes.map((e) => e.toMap()).toList(),
    });
    _loadCommande();
  }


  void _loadResidence() async {
    DocumentSnapshot resSnapshot = await _firestore.collection('residences').doc(widget.commande.residenceId).get();
    setState(() {
      residence = Residence.fromFirestore(resSnapshot);
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
                onTap: () => _choisirOption(appartement, 'Ménage validé'),
              ),
              ListTile(
                title: Text('Valider le contrôle'),
                onTap: () => _choisirOption(appartement, 'Contrôle validé'),
              ),
              ListTile(
                title: Text('Retour sur le ménage'),
                onTap: () {
                  Navigator.of(context).pop();
                  _afficherOptionsRetourMenage(appartement);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _envoyerNotificationPersonnelle() {
    _firestore.collection('userNotifications').add({
      'token': _fcmToken,
      'message': 'Le ménage a été validé à ${DateTime.now()}',
      'timestamp': FieldValue.serverTimestamp(),
    });
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
      DetailsAppartement details = widget.commande.detailsAppartements[appartement.id] ?? DetailsAppartement();

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

      widget.commande.detailsAppartements[appartement.id] = details;
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
          return Colors.lightBlue.shade100;
        case 'Contrôle validé':
          return Colors.lightGreen.shade100;
        default:
          return Colors.white;
      }
    }
  }



  void _ajouterEquipe() {
    setState(() {
      String newTeamName = 'Équipe ${widget.commande.equipes.length + 1}';
      widget.commande.equipes.add(Equipe(nom: newTeamName, appartementIds: [], appartements: []));
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
                title: Text('Supprimer l\'équipe'),
                onTap: () => _deleteEquipe(equipe),
              ),
            ],
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



  void _finaliserCommande() async {
    await _firestore.collection('commandes').doc(widget.commande.id).update({
      'statut': 'Finalisée'
    });

    // Afficher un message ou naviguer vers une autre page si nécessaire
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Commande finalisée avec succès')),
    );

    // Vous pouvez choisir de naviguer vers une autre page après la finalisation
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



  Future<void> _afficherListeAppartements() async {
    List<Appartement> tousLesAppartements = await _recupererAppartements();
    List<Appartement> appartementsDisponibles = tousLesAppartements.where((appartement) =>
    !widget.commande.appartements.any((appartementCommande) => appartementCommande.id == appartement.id)).toList();

    // Vérifiez si vous obtenez les bons appartements
    print("Appartements disponibles : ${appartementsDisponibles.length}");

    _montrerPopupSelectionAppartement(appartementsDisponibles);
  }



  Future<List<Appartement>> _recupererAppartements() async {
    List<Appartement> appartements = [];
    var querySnapshot = await FirebaseFirestore.instance.collection('appartements').where('residenceId', isEqualTo: widget.commande.residenceId).get();
    for (var doc in querySnapshot.docs) {
      appartements.add(Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id));
      print("Appartement récupéré : ${doc.data()}");
    }
    return appartements;
  }



  void _montrerPopupSelectionAppartement(List<Appartement> appartementsDisponibles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sélectionner un appartement'),
          content: SingleChildScrollView(
            child: ListBody(
              children: appartementsDisponibles.map((appartement) {
                return ListTile(
                  title: Text(appartement.numero),
                  // Reste du code...
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }


  void _ajouterAppartementALaCommande(Appartement appartement) {
    setState(() {
      widget.commande.appartements.add(appartement);
      // Ajoutez également les détails et validations par défaut pour ce nouvel appartement
    });

    Navigator.of(context).pop(); // Ferme la popup après la sélection
    // Mettez à jour la commande dans Firestore ici si nécessaire
  }
  Widget _buildProgressIndicatorWithPercentage() {
    double avancement = _calculerAvancement();
    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: avancement / 100,
            strokeWidth: 3.0,
          ),
          Text(
            '${avancement.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10, // Vous pouvez ajuster la taille selon l'espace disponible
              color: Colors.black, // Changez la couleur si nécessaire
            ),
          ),
        ],
      ),
    );
  }





  @override
  Widget build(BuildContext context) {

    double avancement = _calculerAvancement();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 60.0),

                child: Row(
                  children: [
                    _buildProgressIndicatorWithPercentage(), // Utilisez le nouveau widget ici
                    SizedBox(width: 8), // Espace entre l'indicateur et le texte
                    // ... autres éléments de la Row
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: _ajouterEquipe,
                  child: Text('Ajouter une équipe'),
                ),
              ),
            ],
          ),





          Expanded(
            child: ListView(

              children: [
              ElevatedButton(
              onPressed: _afficherListeAppartements,
              child: Text('Ajouter un appartement'),
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
                    trailing: ElevatedButton(
                      onPressed: () => _showTeamOptions(equipe),
                      child: Text('Modifier', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    children: equipe.appartementIds.map((id) {
                      Appartement appartement = widget.commande.appartements.firstWhere((a) => a.id == id);
                      DetailsAppartement details = widget.commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                      return Card(
                        color: _getCardColor(details),
                        child: Stack(
                          children: [
                            ListTile(
                              leading: details.prioritaire ? Icon(Icons.priority_high, color: Colors.red) : null,
                              title: Text(
                                ' ${appartement.numero}',
                                style: TextStyle(fontWeight: FontWeight.bold), // Numéro d'appartement en gras
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text('${appartement.typologie} - ${appartement.batiment}'),
                                  Text('État: ${details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"}'),
                                  if (details.note.isNotEmpty) Text('Note: ${details.note}', style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                  ),),
                                ],
                              ),
                              onTap: () => _afficherOptionsValidation(appartement),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Text(
                                '${details.typeMenage}',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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


  void _openCommandEditPage() {
    if (residence != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectionAppartementPage(
            entrepriseId: widget.commande.entrepriseId,
            residence: residence!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: Résidence non chargée')),
      );
    }
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


