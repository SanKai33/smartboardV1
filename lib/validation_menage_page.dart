import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCommande();
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
        // Marquer comme effectué si le ménage ou le contrôle est validé
        details.menageEffectue = choix == 'Ménage validé' || choix == 'Contrôle validé';
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
    FirebaseFirestore.instance.collection('notifications').add({
      'titre': 'Notification de ménage',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'entrepriseId': widget.commande.entrepriseId,
      // Vous pouvez ajouter d'autres détails si nécessaire
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
                padding: EdgeInsets.all(10),
                child: Text(
                  'Avancement: ${avancement.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 16),
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
                ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('Commande - ${DateFormat('dd/MM/yyyy').format(widget.commande.dateCommande)}'),
                      SizedBox(width: 8),
                      Icon(Icons.apartment),
                      Text(' (${widget.commande.appartements.length})'),
                    ],
                  ),
                  children: widget.commande.appartements.map((appartement) {
                    DetailsAppartement details = widget.commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                    return ListTile(
                      title: Text('Appartement ${appartement.numero}'),
                      subtitle: Text('État : ${details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"}'),
                    );
                  }).toList(),
                ),
                ...widget.commande.equipes.map((equipe) {
                  return ExpansionTile(
                    title: Text(equipe.nom),
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
                        child: ListTile(
                          leading: details.prioritaire ? Icon(Icons.priority_high, color: Colors.red) : null, // Icône de priorité
                          title: Text('Appartement ${appartement.numero} - ${appartement.typologie} - Bâtiment ${appartement.batiment}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('État: ${details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"}'),
                              Text('Type de ménage: ${details.typeMenage}'),
                              if (details.note.isNotEmpty) Text('Note: ${details.note}'),
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


