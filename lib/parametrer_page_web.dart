import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartboard/selectScreenMap.dart';
import 'models/appartement.dart';
import 'models/residence.dart';
import 'residences_page.dart';

class ParametrerPageWeb extends StatefulWidget {
  final String entrepriseId;
  final Residence? residence;

  ParametrerPageWeb({required this.entrepriseId, this.residence});

  @override
  _ParametrerPageWebState createState() => _ParametrerPageWebState();
}

class _ParametrerPageWebState extends State<ParametrerPageWeb> {
  final TextEditingController _nomResidenceController = TextEditingController();
  final TextEditingController _adresseResidenceController = TextEditingController();
  List<Appartement> appartements = [];
  bool isLoading = true;
  bool hasChanges = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _nomResidenceController.text = widget.residence?.nom ?? '';
    _adresseResidenceController.text = widget.residence?.adresse ?? '';
    _imageUrl = widget.residence?.imageUrl;
    _nomResidenceController.addListener(() => setState(() => hasChanges = true));
    _adresseResidenceController.addListener(() => setState(() => hasChanges = true));
    if (widget.residence != null) {
      _loadAppartements();
    } else {
      isLoading = false;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String fileName = 'residences/${widget.residence?.id ?? DateTime.now().toString()}.png';
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl;
      });
    }
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'delete':
        _supprimerResidence();
        break;
    }
  }

  void _supprimerResidence() async {
    if (widget.residence?.id != null) {
      await FirebaseFirestore.instance.collection('residences').doc(widget.residence!.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Résidence supprimée')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidencesPage(entrepriseId: widget.entrepriseId)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression')));
    }
  }

  void _enregistrerResidence() async {
    if (_nomResidenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Le nom de la résidence est requis.")));
      return;
    }

    try {
      final residenceId = widget.residence?.id ?? FirebaseFirestore.instance.collection('residences').doc().id;

      await FirebaseFirestore.instance.collection('residences').doc(residenceId).set({
        'nom': _nomResidenceController.text,
        'adresse': _adresseResidenceController.text,
        'entrepriseId': widget.entrepriseId,
        'imageUrl': _imageUrl,
      });

      for (var appartement in appartements) {
        await FirebaseFirestore.instance.collection('appartements').doc(appartement.id).set(appartement.toMap());
      }

      setState(() {
        hasChanges = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text('Les modifications ont été enregistrées avec succès.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResidencesPage(entrepriseId: widget.entrepriseId),
                    ),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
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
        appartements.sort((a, b) => a.ordre.compareTo(b.ordre));
      });
    }).catchError((error) {
      print('Erreur lors du chargement des appartements: $error');
      setState(() {
        isLoading = false;
      });
    });
  }

  void _updateAppartement(Appartement appartement, String field, dynamic value) {
    setState(() {
      if (field == 'numero') {
        appartement.numero = value;
      } else if (field == 'batiment') {
        appartement.batiment = value;
      } else if (field == 'typologie') {
        appartement.typologie = value;
      } else if (field == 'nombrePersonnes') {
        appartement.nombrePersonnes = int.tryParse(value) ?? 0;
      } else if (field == 'nombreLitsSimples') {
        appartement.nombreLitsSimples = int.tryParse(value) ?? 0;
      } else if (field == 'nombreLitsDoubles') {
        appartement.nombreLitsDoubles = int.tryParse(value) ?? 0;
      } else if (field == 'nombreSallesDeBains') {
        appartement.nombreSallesDeBains = int.tryParse(value) ?? 0;
      }
      hasChanges = true;
    });
  }

  void _ajouterNouvelAppartement() {
    setState(() {
      Appartement nouvelAppartement = Appartement(
        id: DateTime.now().toString(),
        numero: 'App ${appartements.length + 1}',
        batiment: 'Bâtiment ',
        typologie: 'T2',
        nombrePersonnes: 2,
        residenceId: widget.residence!.id,
        nombreLitsSimples: 1,
        nombreLitsDoubles: 1,
        nombreSallesDeBains: 1,
        ordre: appartements.length,
      );
      appartements.add(nouvelAppartement);
      hasChanges = true;
    });
  }

  void _ouvrirSelectionAdresse() async {
    final selectedAddress = await Navigator.push(context, MaterialPageRoute(builder: (context) => SelectAddressScreen()));
    if (selectedAddress != null) {
      _adresseResidenceController.text = selectedAddress;
      setState(() {
        hasChanges = true;
      });
    }
  }

  void _supprimerAppartement(Appartement appartement) async {
    await FirebaseFirestore.instance.collection('appartements').doc(appartement.id).delete();
    setState(() {
      appartements.remove(appartement);
      hasChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (hasChanges) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Attention'),
          content: Text('Vous avez des modifications non enregistrées. Voulez-vous vraiment quitter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Oui'),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = appartements.removeAt(oldIndex);
      appartements.insert(newIndex, item);
      for (int i = 0; i < appartements.length; i++) {
        appartements[i].ordre = i;
      }
      hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                  child: _imageUrl == null ? Icon(Icons.add_a_photo, size: 50) : null,
                ),
              ),
              SizedBox(height: 20),
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
              _buildWebLayout(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _enregistrerResidence,
          icon: Icon(Icons.save),
          label: Text('Enregistrer'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _ajouterNouvelAppartement,
            icon: Icon(Icons.add),
            label: Text(
              'Ajouter un appartement',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Container(
                  color: Colors.grey[200],
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Numéro', textAlign: TextAlign.center)),
                      Expanded(child: Text('Bâtiment', textAlign: TextAlign.center)),
                      Expanded(child: Text('Typologie', textAlign: TextAlign.center)),
                      Expanded(child: Text('Nombre de personnes', textAlign: TextAlign.center)),
                      Expanded(child: Text('Lits simples', textAlign: TextAlign.center)),
                      Expanded(child: Text('Lits doubles', textAlign: TextAlign.center)),
                      Expanded(child: Text('Salles de bains', textAlign: TextAlign.center)),
                      Expanded(child: Text('Actions', textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  onReorder: _onReorder,
                  children: appartements.map((appartement) {
                    return ListTile(
                      key: ValueKey(appartement.id),
                      title: Row(
                        children: [
                          Expanded(child: _buildEditableCell(appartement, 'numero')),
                          Expanded(child: _buildEditableCell(appartement, 'batiment')),
                          Expanded(child: _buildEditableCell(appartement, 'typologie')),
                          Expanded(child: _buildEditableCell(appartement, 'nombrePersonnes', isNumeric: true)),
                          Expanded(child: _buildEditableCell(appartement, 'nombreLitsSimples', isNumeric: true)),
                          Expanded(child: _buildEditableCell(appartement, 'nombreLitsDoubles', isNumeric: true)),
                          Expanded(child: _buildEditableCell(appartement, 'nombreSallesDeBains', isNumeric: true)),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _supprimerAppartement(appartement),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(Appartement appartement, String field, {bool isNumeric = false}) {
    return TextFormField(
      initialValue: isNumeric
          ? (appartement.toMap()[field] ?? 0).toString()
          : appartement.toMap()[field] ?? '',
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      onChanged: (value) {
        _updateAppartement(appartement, field, value);
      },
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    );
  }
}