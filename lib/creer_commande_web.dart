import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models/appartement.dart';
import 'models/detailAppartement.dart';
import 'models/residence.dart';

class CombinedSelectionDetailsPage extends StatefulWidget {
  final String entrepriseId;
  final Residence residence;

  CombinedSelectionDetailsPage({required this.entrepriseId, required this.residence});

  @override
  _CombinedSelectionDetailsPageState createState() => _CombinedSelectionDetailsPageState();
}

class _CombinedSelectionDetailsPageState extends State<CombinedSelectionDetailsPage> {
  DateTime? selectedDate;
  Map<String, bool> selectedAppartements = {};
  Map<String, DetailsAppartement> appartementDetails = {};
  List<Appartement> appartements = [];
  bool isLoading = true;
  Appartement? selectedAppartement;

  @override
  void initState() {
    super.initState();
    _loadAppartements();
  }

  void _loadAppartements() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appartements')
          .where('residenceId', isEqualTo: widget.residence.id)
          .get();

      setState(() {
        appartements = querySnapshot.docs
            .map((doc) => Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        selectedAppartements = {for (var appart in appartements) appart.id: false};
        for (var appart in appartements) {
          appartementDetails[appart.id] = DetailsAppartement();
        }
        isLoading = false;
      });
    } catch (error) {
      print('Erreur lors du chargement des appartements: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélection et Détails des Appartements'),
      ),
      body: Row(
        children: [
          // Volet de gauche : Sélection des appartements
          Expanded(
            flex: 1,
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: appartements.length,
              itemBuilder: (context, index) {
                final appart = appartements[index];
                return Card(
                  child: CheckboxListTile(
                    title: Text('Appartement ${appart.numero}'),
                    subtitle: Text('Bâtiment: ${appart.batiment}, Typologie: ${appart.typologie}'),
                    value: selectedAppartements[appart.id],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedAppartements[appart.id] = value!;
                        selectedAppartement = appart;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // Volet de droite : Détails de l'appartement sélectionné
          Expanded(
            flex: 2,
            child: selectedAppartement == null
                ? Center(child: Text('Sélectionnez un appartement pour afficher les détails'))
                : DetailsView(appartement: selectedAppartement!),
          ),
        ],
      ),
    );
  }
}

class DetailsView extends StatelessWidget {
  final Appartement appartement;

  DetailsView({required this.appartement});

  @override
  Widget build(BuildContext context) {
    // Ajoutez ici les détails de l'appartement sélectionné
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Appartement ${appartement.numero}', style: Theme.of(context).textTheme.headline6),
          // Complétez avec d'autres détails de l'appartement
        ],
      ),
    );
  }
}
