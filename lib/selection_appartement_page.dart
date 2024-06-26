import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detail_commande.dart';
import 'models/appartement.dart';
import 'models/residence.dart';

class SelectionAppartementPage extends StatefulWidget {
  final String entrepriseId;
  final Residence residence;
  final String agentId;

  SelectionAppartementPage({required this.entrepriseId, required this.residence, required this.agentId});

  @override
  _SelectionAppartementPageState createState() => _SelectionAppartementPageState();
}

class _SelectionAppartementPageState extends State<SelectionAppartementPage> {
  DateTime? selectedDate;
  Map<String, bool> selectedAppartements = {};
  List<Appartement> appartements = [];
  bool isLoading = true;

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
        isLoading = false;
      });
    } catch (error) {
      print('Erreur lors du chargement des appartements: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _onSuivantPressed() {
    if (selectedDate == null) {
      // Appelle la fonction de sélection de date si aucune date n'est sélectionnée
      _selectDate(context);
      return; // Retourne pour éviter de continuer l'exécution de cette fonction
    }

    // Continue avec la vérification des appartements sélectionnés
    List<Appartement> selected = appartements
        .where((appart) => selectedAppartements[appart.id] ?? false)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner au moins un appartement.')),
      );
      return;
    }

    // Si tout est en ordre, navigue à la page suivante
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeDetailsPage(
          entrepriseId: widget.entrepriseId,
          residence: widget.residence,
          appartementsSelectionnes: selected,
          dateCommande: selectedDate!, agentId: widget.agentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélection des Appartements'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text(selectedDate == null
                ? 'Choisir la date de la commande'
                : 'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: appartements.length,
              itemBuilder: (context, index) {
                final appartement = appartements[index];
                return Card(
                  child: CheckboxListTile(
                    title: Text('Appartement ${appartement.numero}'),
                    subtitle: Row(
                      children: [
                        Icon(Icons.apartment, size: 16),
                        SizedBox(width: 5),
                        Text(appartement.batiment),
                        SizedBox(width: 10),
                        Icon(Icons.category, size: 16),
                        SizedBox(width: 5),
                        Text(appartement.typologie),
                      ],
                    ),
                    value: selectedAppartements[appartement.id],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedAppartements[appartement.id] = value!;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _onSuivantPressed,
            child: Text('Suivant'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}