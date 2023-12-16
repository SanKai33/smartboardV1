import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/creer_equipes.dart';
import 'models/appartement.dart';
import 'models/commande.dart';



class ValidationMenagePage extends StatefulWidget {
  late final Commande commande;

  ValidationMenagePage({required this.commande});

  @override
  _ValidationMenagePageState createState() => _ValidationMenagePageState();
}

class _ValidationMenagePageState extends State<ValidationMenagePage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    Navigator.of(context).pop();
    setState(() {
      appartement.etatValidation = choix;
      _updateAppartement(appartement);
    });
  }

  void _updateAppartement(Appartement appartement) async {
    await _firestore.collection('appartements').doc(appartement.id).update({
      'etatValidation': appartement.etatValidation,
    });
    _loadCommande();
  }

  Color _getCardColor(Appartement appartement) {
    if (appartement.etatValidation.startsWith('Retour:')) {
      return Colors.red.shade100;
    } else {
      switch (appartement.etatValidation) {
        case 'Ménage validé':
          return Colors.lightBlue.shade100;
        case 'Contrôle validé':
          return Colors.lightGreen.shade100;
        default:
          return Colors.white;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validation du Ménage'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CreerEquipePage(),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Logique pour créer une nouvelle équipe
              },
              child: Text('Créer une Équipe'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.commande.appartements.length,
              itemBuilder: (context, index) {
                Appartement appartement = widget.commande.appartements[index];
                return Card(
                  color: _getCardColor(appartement),
                  child: ListTile(
                    title: Text('Appartement ${appartement.numero}'),
                    subtitle: Text('État : ${appartement.etatValidation.isNotEmpty ? appartement.etatValidation : "Non validé"}'),
                    onTap: () => _afficherOptionsValidation(appartement),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}