import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:smartboard/selectScreenMap.dart';
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
  final TextEditingController _adresseResidenceController = TextEditingController();
  List<Appartement> appartements = [];
  bool isLoading = true;
  File? _image;
  final picker = ImagePicker();



  @override
  void initState() {
    super.initState();
    _nomResidenceController.text = widget.residence?.nom ?? '';
    _adresseResidenceController.text = widget.residence?.adresse ?? '';
    if (widget.residence != null) {
      _loadAppartements();
    } else {
      isLoading = false;
    }
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'delete':
        _supprimerResidence();
        break;
    // Autres cas si nécessaire...
    }
  }

  void _supprimerResidence() async {
    if (widget.residence?.id != null) {
      await FirebaseFirestore.instance.collection('residences').doc(widget.residence!.id).delete();
      // Supprimer également tous les appartements associés à cette résidence si nécessaire
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Résidence supprimée')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidencesPage(entrepriseId: widget.entrepriseId)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression')));
    }
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('Aucune image sélectionnée.');
      }
    });
  }

  Future<String> uploadImage(File image) async {
    String fileName = 'residences/${DateTime.now().millisecondsSinceEpoch}.png';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void _enregistrerResidence() async {
    if (_nomResidenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Le nom de la résidence est requis.")));
      return;
    }

    try {
      String imageUrl = '';
      if (_image != null) {
        imageUrl = await uploadImage(_image!);
      }

      // Créer ou obtenir l'ID de la résidence
      final residenceId = widget.residence?.id ?? FirebaseFirestore.instance.collection('residences').doc().id;

      // Enregistrer ou mettre à jour la résidence
      await FirebaseFirestore.instance.collection('residences').doc(residenceId).set({
        'nom': _nomResidenceController.text,
        'adresse': _adresseResidenceController.text,
        'entrepriseId': widget.entrepriseId,
        'imageUrl': imageUrl,
      });

      // Enregistrer ou mettre à jour les appartements
      for (var appartement in appartements) {
        await FirebaseFirestore.instance.collection('appartements').doc(appartement.id).set({
          ...appartement.toMap(),
          'residenceId': residenceId,
        });
      }

      // Rediriger vers la page des résidences
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidencesPage(entrepriseId: widget.entrepriseId)));
    } catch (e) {
      // Afficher une erreur en cas d'échec
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'enregistrement: $e")));
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
            .map((doc) => Appartement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        isLoading = false;
        appartements.sort((a, b) => a.numero.compareTo(b.numero)); // Tri par numéro
      });
    }).catchError((error) {
      print('Erreur lors du chargement des appartements: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  void _showEditAppartementDialog(Appartement appartement) {
    final TextEditingController _numeroController = TextEditingController(text: appartement.numero);
    final TextEditingController _batimentController = TextEditingController(text: appartement.batiment);
    final TextEditingController _typologieController = TextEditingController(text: appartement.typologie);
    final TextEditingController _nombrePersonnesController = TextEditingController(text: appartement.nombrePersonnes.toString());
    final TextEditingController _nombreLitsSimplesController = TextEditingController(text: appartement.nombreLitsSimples.toString());
    final TextEditingController _nombreLitsDoublesController = TextEditingController(text: appartement.nombreLitsDoubles.toString());
    final TextEditingController _nombreSallesDeBainsController = TextEditingController(text: appartement.nombreSallesDeBains.toString());

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
                TextField(
                  controller: _nombreLitsSimplesController,
                  decoration: InputDecoration(labelText: 'Nombre de lits simples'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _nombreLitsDoublesController,
                  decoration: InputDecoration(labelText: 'Nombre de lits doubles'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _nombreSallesDeBainsController,
                  decoration: InputDecoration(labelText: 'Nombre de salles de bains'),
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
                    .collection('appartements')
                    .doc(appartement.id)
                    .delete();
                Navigator.of(context).pop();
                _loadAppartements();
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
                appartement.nombreLitsSimples = int.tryParse(_nombreLitsSimplesController.text) ?? appartement.nombreLitsSimples;
                appartement.nombreLitsDoubles = int.tryParse(_nombreLitsDoublesController.text) ?? appartement.nombreLitsDoubles;
                appartement.nombreSallesDeBains = int.tryParse(_nombreSallesDeBainsController.text) ?? appartement.nombreSallesDeBains;

                await FirebaseFirestore.instance
                    .collection('appartements')
                    .doc(appartement.id)
                    .update(appartement.toMap());
                Navigator.of(context).pop();
                _loadAppartements();
              },
            ),
          ],
        );
      },
    );
  }

  void _ouvrirSelectionAdresse() async {
    // Remplacez 'SelectAddressScreen' par le nom de votre écran de sélection d'adresse
    final selectedAddress = await Navigator.push(context, MaterialPageRoute(builder: (context) => SelectAddressScreen()));
    if (selectedAddress != null) {
      _adresseResidenceController.text = selectedAddress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramétrer Résidence'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Supprimer'),
              ),
              // Ajoutez d'autres options de menu ici si nécessaire
            ],
          ),
        ],
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adresseResidenceController,
                      decoration: InputDecoration(
                        labelText: 'Adresse de la Résidence',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.map),
                    onPressed: _ouvrirSelectionAdresse,
                  ),
                ],
              ),
            ),
            kIsWeb ? _buildWebLayout() : _buildMobileLayout(),
          ],
        ),
      ),
      floatingActionButton: !kIsWeb ? FloatingActionButton(
        onPressed: _enregistrerResidence,
        child: Icon(Icons.save),
      ) : null,
    );
  }


  Widget _buildMobileLayout() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: appartements.length + 1, // +1 pour inclure l'en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          // En-tête avec le bouton d'ajout et le compteur
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _ajouterNouvelAppartement, // Mettez à jour pour ajouter un appartement
                  icon: Icon(Icons.add),
                  label: Text('Ajouter un appartement'),
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.apartment, size: 24),
                    SizedBox(width: 4),
                    Text('${appartements.length} '),
                  ],
                ),
              ],
            ),
          );
        }

        // Ajustement de l'index pour accéder aux appartements
        final appartement = appartements[index - 1];

        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            leading: Icon(Icons.apartment), // Icône représentant un appartement
            title: Text('Appartement ${appartement.numero}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.business, size: 16), // Icône pour le bâtiment
                    SizedBox(width: 4),
                    Text('Bâtiment: ${appartement.batiment}'),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.category, size: 16), // Icône pour la typologie
                    SizedBox(width: 4),
                    Text('Typologie: ${appartement.typologie}'),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.person, size: 16), // Icône pour le nombre de personnes
                    SizedBox(width: 4),
                    Text('Nombre de personnes: ${appartement.nombrePersonnes}'),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.bed, size: 16), // Icône pour les lits simples
                    SizedBox(width: 4),
                    Text('Lits simples: ${appartement.nombreLitsSimples}'),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.king_bed, size: 16), // Icône pour les lits doubles
                    SizedBox(width: 4),
                    Text('Lits doubles: ${appartement.nombreLitsDoubles}'),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(Icons.bathtub, size: 16), // Icône pour les salles de bains
                    SizedBox(width: 4),
                    Text('Salles de bains: ${appartement.nombreSallesDeBains}'),
                  ],
                ),
              ],
            ),
            onTap: () => _showEditAppartementDialog(appartement), // Gestionnaire onTap
          ),
        );
      },
    );
  }

  void _ajouterNouvelAppartement() {
    // Créez un nouvel appartement avec des données fictives ou récupérez les données via un formulaire
    Appartement nouvelAppartement = Appartement(
      id: DateTime.now().toString(), // Juste un ID fictif pour l'exemple
      numero: 'App ${appartements.length + 1}',
      batiment: 'Bâtiment X',
      typologie: 'T2',
      nombrePersonnes: 2,
      nombreLitsSimples: 1,
      nombreLitsDoubles: 1,
      nombreSallesDeBains: 1, residenceId: widget.residence!.id,
    );

    // Ajoutez le nouvel appartement à la liste et mettez à jour l'état
    setState(() {
      appartements.add(nouvelAppartement);
    });
  }




  Widget _buildWebLayout() {
  return DataTable(
    columns: const [
      DataColumn(label: Text('Numéro')),
      DataColumn(label: Text('Bâtiment')),
      DataColumn(label: Text('Typologie')),
      DataColumn(label: Text('Nombre de personnes')),
      // Ajoutez plus de colonnes si nécessaire
    ],
    rows: appartements.map((appartement) {
      return DataRow(cells: [
        DataCell(Text(appartement.numero)),
        DataCell(Text(appartement.batiment)),
        DataCell(Text(appartement.typologie)),
        DataCell(Text(appartement.nombrePersonnes.toString())),
        // Ajoutez plus de cellules si nécessaire
      ]);
    }).toList(),
  );
}


}










