import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartboard/login_page.dart';


class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _localisationController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  bool _isLoading = false;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _chargerProfilEntreprise();
  }

  Future<void> _chargerProfilEntreprise() async {
    var document = await FirebaseFirestore.instance.collection('entreprise').doc('votre_document_id').get();
    if (document.exists) {
      setState(() {
        _nomController.text = document.data()?['nom'] ?? '';
        _localisationController.text = document.data()?['localisation'] ?? '';
        _telephoneController.text = document.data()?['telephone'] ?? '';
        imageUrl = document.data()?['image_url'];
      });
    }
  }

  Future<void> _sauvegarderModifications() async {
    setState(() {
      _isLoading = true;
    });

    await FirebaseFirestore.instance.collection('entreprise').doc('votre_document_id').update({
      'nom': _nomController.text,
      'localisation': _localisationController.text,
      'telephone': _telephoneController.text,
      'image_url': imageUrl,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modifications enregistrées avec succès')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $error')),
      );
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _selectAndUploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      try {
        setState(() {
          _isLoading = true;
        });

        // Upload to Firebase Storage
        var snapshot = await FirebaseStorage.instance.ref().child('profile_images/${DateTime.now().toIso8601String()}').putFile(file);
        var downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          imageUrl = downloadUrl;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement de l\'image: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deconnexion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage())); // Utilisez votre widget LoginPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil de l\'entreprise'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _deconnexion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20),
            GestureDetector(
              onTap: _selectAndUploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) as ImageProvider : AssetImage('assets/images/default_profile.png') as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading ? SpinKitCircle(color: Colors.purpleAccent) : _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom de l\'entreprise',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _localisationController,
            decoration: InputDecoration(
              labelText: 'Localisation',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _telephoneController,
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone (facultatif)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
        ElevatedButton(
          onPressed: _sauvegarderModifications,
          child: Text('Sauvegarder les modifications'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _localisationController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }
}