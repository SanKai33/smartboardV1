import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';





class PresencePage extends StatefulWidget {
  @override
  _PresencePageState createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  // Ici, vous pouvez définir des variables d'état, comme une liste de personnels

  @override
  void initState() {
    super.initState();
    // Initialiser votre état ici, par exemple, charger des données depuis Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche de Présence'),
      ),
      body: Center(
        // Ici, vous pouvez construire votre UI, par exemple une liste de personnels
        child: Text('Contenu de la page de présence'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ajouter une action, par exemple ouvrir un scanner de QR code
        },
        child: Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

