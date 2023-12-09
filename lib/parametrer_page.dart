import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models/appartement.dart';
import 'models/residence.dart';
import 'residences_page.dart';



class ParametrerPage extends StatefulWidget {
  final String entrepriseId;
  final Residence? residence;

  ParametrerPage({required this.entrepriseId, this.residence});

  @override
  _ParametrerPageState createState() => _ParametrerPageState();
}

class _ParametrerPageState extends State<ParametrerPage> {
  final TextEditingController _nomResidenceController = TextEditingController();
  List<Appartement> appartements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _nomResidenceController.text = widget.residence?.nom ?? '';
    if (widget.residence != null) {
      _loadAppartements();
    } else {
      isLoading = false;
    }
  }

  void _loadAppartements() async {
    if (widget.residence?.id == null) return;

    FirebaseFirestore.instance
        .collection('appartements')
        .where('residenceId', isEqualTo: widget.residence!.id)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        appartements = querySnapshot.docs
            .map((doc) => Appartement.fromMap(doc as DocumentSnapshot))
            .toList();
        isLoading = false;
      });
    }).catchError((error) {
      print('Erreur lors du chargement des appartements: $error');
    });
  }


  void _ajouterAppartement() {
    final newAppartement = Appartement(
      id: FirebaseFirestore.instance.collection('appartements').doc().id,
      numero: 'Numéro ${appartements.length + 1}',
      batiment: 'Bâtiment ${appartements.length + 1}',
      typologie: 'T1',
      nombrePersonnes: 1,
      residenceId: widget.residence?.id ?? '',
    );
    setState(() {
      appartements.add(newAppartement);
    });
  }

  void _enregistrerResidence() async {
    if (_nomResidenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le nom de la résidence est requis.')));
      return;
    }

    final residenceId = widget.residence?.id ?? FirebaseFirestore.instance.collection('residences').doc().id;

    await FirebaseFirestore.instance
        .collection('residences')
        .doc(residenceId)
        .set({
      'nom': _nomResidenceController.text,
      'entrepriseId': widget.entrepriseId, // Associer la résidence à l'entreprise
    });

    for (var appartement in appartements) {
      await FirebaseFirestore.instance.collection('appartements').doc(appartement.id).set({
        ...appartement.toMap(),
        'residenceId': residenceId,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Résidence enregistrée avec succès')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidencesPage(entrepriseId: widget.entrepriseId)));
  }

  void _showEditAppartementDialog(Appartement appartement) {
    final TextEditingController _numeroController = TextEditingController(text: appartement.numero);
    final TextEditingController _batimentController = TextEditingController(text: appartement.batiment);
    final TextEditingController _typologieController = TextEditingController(text: appartement.typologie);
    final TextEditingController _nombrePersonnesController = TextEditingController(text: appartement.nombrePersonnes.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier Appartement'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _numeroController,
                  decoration: InputDecoration(labelText: 'Numéro'),
                ),
                TextField(
                  controller: _batimentController,
                  decoration: InputDecoration(labelText: 'Bâtiment'),
                ),
                TextField(
                  controller: _typologieController,
                  decoration: InputDecoration(labelText: 'Typologie'),
                ),
                TextField(
                  controller: _nombrePersonnesController,
                  decoration: InputDecoration(labelText: 'Nombre de Personnes'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Supprimer'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('entreprise')
                    .doc(widget.entrepriseId)
                    .collection('residences')
                    .doc(widget.residence?.id ?? '')
                    .collection('appartements')
                    .doc(appartement.id)
                    .delete();

                setState(() {
                  appartements.removeWhere((a) => a.id == appartement.id);
                });

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Enregistrer'),
              onPressed: () async {
                appartement.numero = _numeroController.text;
                appartement.batiment = _batimentController.text;
                appartement.typologie = _typologieController.text;
                appartement.nombrePersonnes = int.tryParse(_nombrePersonnesController.text) ?? appartement.nombrePersonnes;

                await FirebaseFirestore.instance
                    .collection('entreprise')
                    .doc(widget.entrepriseId)
                    .collection('residences')
                    .doc(widget.residence?.id ?? '')
                    .collection('appartements')
                    .doc(appartement.id)
                    .update(appartement.toMap());

                setState(() {});

                Navigator.of(context).pop();
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
        title: Text('Paramétrer Résidence'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _nomResidenceController,
                decoration: InputDecoration(
                  labelText: 'Nom de la Résidence',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _ajouterAppartement,
              child: Text('Ajouter Appartement'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: appartements.length,
              itemBuilder: (context, index) {
                final appartement = appartements[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Appartement ${appartement.numero}'),
                    subtitle: Text('Bâtiment: ${appartement.batiment}, Typologie: ${appartement.typologie}, Nombre de personnes: ${appartement.nombrePersonnes}'),
                    onTap: () => _showEditAppartementDialog(appartement),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enregistrerResidence,
        child: Icon(Icons.save),
      ),
    );
  }
}


