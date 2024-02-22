import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'creer_commande_web.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'models/personnel.dart';
import 'models/residence.dart';

class VisualiserCommandePage extends StatefulWidget {
  final String commandeId;
  final Commande commande;


  VisualiserCommandePage({required this.commandeId, required this.commande, });

  @override
  _VisualiserCommandePageState createState() => _VisualiserCommandePageState();
}

class _VisualiserCommandePageState extends State<VisualiserCommandePage> {
  late final String commandeId;
  late final Commande commande;


  @override
  void initState() {
    super.initState();
    commandeId = widget.commandeId;
    commande = widget.commande;
    // Ajoutez cette ligne
    // Autres initialisations si nécessaire
  }

  Future<List<Personnel>> _fetchPersonnel(String residenceId) async {
    QuerySnapshot personnelSnapshot = await FirebaseFirestore.instance
        .collection('personnel')
        .where('residenceAffectee', isEqualTo: residenceId)
        .get();

    return personnelSnapshot.docs
        .map((doc) => Personnel.fromFirestore(doc))
        .toList();
  }


  Future<void> _createPdf(Commande commande) async {
    final pdf = pw.Document();

    List<Personnel> personnelList = await _fetchPersonnel(commande.residenceId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          // Calcul des totaux pour le tableau de résumé
          int totalLitsSimples = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsSimples);
          int totalLitsDoubles = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsDoubles);
          int totalSallesDeBains = commande.appartements.fold(0, (sum, a) => sum + a.nombreSallesDeBains);
          int totalMenages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Ménage').length;
          int totalRecouches = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Recouche').length;
          int totalDegraissages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Dégraissage').length;
          int totalFermetures = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Fermeture').length;

          return <pw.Widget>[
            pw.Header(level: 0, child: pw.Text('Détails de la Commande')),
            pw.Paragraph(text: 'Résidence: ${commande.nomResidence}'),
            pw.Paragraph(text: 'Date de la commande: ${DateFormat('dd/MM/yyyy').format(commande.dateCommande)}'),
            pw.Paragraph(text: 'Nombre total d\'appartements: ${commande.appartements.length}'),

            // Tableau pour les détails des appartements
            pw.Table.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Ordre', 'Numéro', 'Typologie', 'Bâtiment', 'Note de l\'Appartement'],
                ...commande.appartements.map((appartement) {
                  final details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                  return [
                    details.ordreAppartements.toString(),
                    appartement.numero,
                    appartement.typologie,
                    appartement.batiment,
                    details.note, // La note de chaque appartement
                  ];
                }),
              ],
            ),

            // Ajoutez un espace avant le tableau de résumé
            pw.SizedBox(height: 20),

            // Tableau de résumé
            pw.Table.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Type', 'Total', 'Type de Ménage', 'Total'],
                ['Lits Simples', '${totalLitsSimples}', 'Ménages', '$totalMenages'],
                ['Lits Doubles', '${totalLitsDoubles}', 'Recouches', '$totalRecouches'],
                ['Salles de Bains', '${totalSallesDeBains}', 'Dégraissages', '$totalDegraissages'],
                ['', '', 'Fermetures', '$totalFermetures'],
              ],
            ),

            // Section du personnel affecté
            pw.Header(level: 1, child: pw.Text('Personnel Affecté')),
            pw.Table.fromTextArray(
              context: context,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Nom', 'Prénom', 'Téléphone'],
                ...personnelList.map((personnel) => [
                  personnel.nom,
                  personnel.prenom,
                  personnel.telephone,

                ]),
              ],
            ),







          ];
        },
      ),
    );




    // Enregistrez le fichier PDF et partagez-le
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Commande-${commande.nomResidence}.pdf');
  }


  Future<void> _navigateToCommandeEditPage(Commande commande) async {
    DocumentSnapshot residenceSnapshot = await FirebaseFirestore.instance.collection('residences').doc(commande.residenceId).get();
    Residence residence = Residence.fromFirestore(residenceSnapshot);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombinedSelectionDetailsPage(
          entrepriseId: commande.entrepriseId,
          residence: residence,
          commandeExistante: commande, // Ajout de cette ligne
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Commande'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // Alignement à droite
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _createPdf(widget.commande);
                    } catch (e) {
                      print('Erreur lors de la création du PDF: $e');
                      // Vous pouvez également afficher une alerte à l'utilisateur ici
                    }
                  },
                  child: Text('Extraire le PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: () {
                    // Logique pour modifier la commande
                    _navigateToCommandeEditPage(widget.commande);
                  },
                  child: Text('Modifier la Commande', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('commandes').doc(widget.commandeId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur lors du chargement des données."));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                Commande commande = Commande.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Résidence: ${commande.nomResidence}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Date de la commande: ${DateFormat('dd/MM/yyyy').format(commande.dateCommande)}', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        Text('Nombre total d\'appartements: ${commande.appartements.length}', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 20),
                        buildDataTable(commande),
                        SizedBox(height: 20),
                        buildSummaryTable(commande),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget buildDataTable(Commande commande) {
    return DataTable(
      columnSpacing: 38.0, // Ajustez l'espacement selon vos besoins
      dataRowHeight: 50.0, // Hauteur des lignes
      headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.grey[200]!; // Couleur de l'en-tête du tableau
      }),
      border: TableBorder.all(
        color: Colors.grey[300]!, // Couleur des bordures
        width: 1,
      ),
      columns: const <DataColumn>[
        DataColumn(label: Text('Numéro', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Typologie', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Bâtiment', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('État de Validation', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: commande.appartements.map<DataRow>((appartement) {
        DetailsAppartement details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
        return DataRow(
          cells: [
            DataCell(Text(appartement.numero)),
            DataCell(Text(appartement.typologie)),
            DataCell(Text(appartement.batiment)),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getColorForStatus(details.etatValidation),
                  ),
                ),
                SizedBox(width: 8),
                Text(details.etatValidation ?? "Non validé"),
              ],
            )),
            DataCell(Text(details.note ?? "Aucune")),
          ],
        );
      }).toList(),
    );
  }

  Color getColorForStatus(String? status) {
    if (status == null) {
      return Colors.grey; // Couleur par défaut si le statut est null
    }

    // Utilisation de switch pour gérer différentes valeurs de statut
    switch (status) {
      case 'Ménage validé':
        return Colors.blue;
      case 'Contrôle validé':
        return Colors.green;
      case 'Retour': // S'assurer que cette chaîne correspond exactement à vos données
        return Colors.red;
      default:
      // Pour le débogage, vous pouvez imprimer les statuts non reconnus
        print("Statut non reconnu: $status");
        return Colors.grey;
    }
  }

  Widget buildSummaryTable(Commande commande) {
    // Calcul des totaux
    int totalLitsSimples = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsSimples);
    int totalLitsDoubles = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsDoubles);
    int totalSallesDeBains = commande.appartements.fold(0, (sum, a) => sum + a.nombreSallesDeBains);
    int totalMenages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Ménage').length;
    int totalRecouches = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Recouche').length;
    int totalDegraissages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Dégraissage').length;
    int totalFermetures = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Fermeture').length;

    return DataTable(
      columnSpacing: 38.0,
      dataRowHeight: 50.0,
      headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.grey[200]!;
      }),
      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
      columns: const <DataColumn>[
        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: [
        DataRow(cells: [DataCell(Text('Lits Simples')), DataCell(Text('$totalLitsSimples'))]),
        DataRow(cells: [DataCell(Text('Lits Doubles')), DataCell(Text('$totalLitsDoubles'))]),
        DataRow(cells: [DataCell(Text('Salles de Bains')), DataCell(Text('$totalSallesDeBains'))]),
        DataRow(cells: [DataCell(Text('Ménages')), DataCell(Text('$totalMenages'))]),
        DataRow(cells: [DataCell(Text('Recouches')), DataCell(Text('$totalRecouches'))]),
        DataRow(cells: [DataCell(Text('Dégraissages')), DataCell(Text('$totalDegraissages'))]),
        DataRow(cells: [DataCell(Text('Fermetures')), DataCell(Text('$totalFermetures'))]),
      ],
    );
  }
}
