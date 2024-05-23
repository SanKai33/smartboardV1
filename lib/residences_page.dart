import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartboard/parametrer_page.dart';
import 'models/residence.dart';

class ResidencesPage extends StatelessWidget {
  final String entrepriseId;

  ResidencesPage({required this.entrepriseId});

  Future<int> _getNombreAppartements(String residenceId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appartements')
        .where('residenceId', isEqualTo: residenceId)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résidences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('residences')
            .where('entrepriseId', isEqualTo: this.entrepriseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Une erreur s\'est produite'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune résidence trouvée'));
          }

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.0), // Ajout de padding horizontal
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,  // 3 colonnes
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,  // Chaque élément est un carré
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Residence residence = Residence.fromFirestore(document);
              return FutureBuilder<int>(
                future: _getNombreAppartements(residence.id),
                builder: (context, appartementsSnapshot) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: residence.imageUrl.isNotEmpty
                            ? NetworkImage(residence.imageUrl as String) // Cast en String explicitement
                            : AssetImage('assets/images/placeholder.png') as ImageProvider,
                        radius: 25,
                      ),
                      title: Text(
                        residence.nom,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(residence.adresse),
                      trailing: appartementsSnapshot.hasData
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.apartment),
                          SizedBox(width: 8),
                          Text(
                            '${appartementsSnapshot.data}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                          : SizedBox(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParametrerPage(entrepriseId: entrepriseId, residence: residence),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ParametrerPage(entrepriseId: entrepriseId)),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}