import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'detail_commande.dart';  // Assurez-vous que ce chemin est correct
import 'models/appartement.dart';
import 'models/residence.dart';

class SelectionAppartementPage extends StatefulWidget {
  final String entrepriseId;
  final Residence residence;

  SelectionAppartementPage({required this.entrepriseId, required this.residence});

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
    List<Appartement> selected = appartements
        .where((appart) => selectedAppartements[appart.id] ?? false)
        .toList();

    if (selectedDate == null || selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner une date et au moins un appartement.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandeDetailsPage(
          entrepriseId: widget.entrepriseId,
          residence: widget.residence,
          appartementsSelectionnes: selected,
          dateCommande: selectedDate!,
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
                    subtitle: Text('Bâtiment: ${appartement.batiment}, Typologie: ${appartement.typologie}'),
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
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}