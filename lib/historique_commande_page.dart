import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models/commande.dart';
import 'models/detailAppartement.dart';
import 'package:pdf/widgets.dart' as pw;

class HistoriqueCommandePage extends StatefulWidget {
  final Commande commande;

  HistoriqueCommandePage({required this.commande});

  @override
  _HistoriqueCommandePageState createState() => _HistoriqueCommandePageState();
}

class _HistoriqueCommandePageState extends State<HistoriqueCommandePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique de la Commande'),
        automaticallyImplyLeading: false, // This removes the back arrow
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              _extraireHistorique(widget.commande);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date de la commande: ${DateFormat('dd/MM/yyyy').format(widget.commande.dateCommande)}'),
              SizedBox(height: 8),
              Text('Résidence: ${widget.commande.nomResidence}'),
              SizedBox(height: 8),
              Text('Nombre d\'appartements: ${widget.commande.appartements.length}'),
              SizedBox(height: 8),
              Text('Avancement: ${_calculerAvancement().toStringAsFixed(0)}%'),
              SizedBox(height: 16),
              Text('Détails des Appartements:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...widget.commande.appartements.map((appartement) {
                DetailsAppartement details = widget.commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                return Card(
                  child: ListTile(
                    title: Text('Appartement ${appartement.numero}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('État: ${details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé"}'),
                        Text('Type de ménage: ${details.typeMenage}'),
                        Text('Note: ${details.note}'),
                        if (details.prioritaire) Icon(Icons.priority_high, color: Colors.red),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  double _calculerAvancement() {
    int totalAppartements = widget.commande.appartements.length;
    int appartementsFait = widget.commande.detailsAppartements.values.where((details) => details.menageEffectue).length;
    return (appartementsFait / totalAppartements) * 100;
  }

  Future<void> _extraireHistorique(Commande commande) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          int totalLitsSimples = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsSimples);
          int totalLitsDoubles = commande.appartements.fold(0, (sum, a) => sum + a.nombreLitsDoubles);
          int totalSallesDeBains = commande.appartements.fold(0, (sum, a) => sum + a.nombreSallesDeBains);
          int totalMenages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Ménage').length;
          int totalRecouches = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Recouche').length;
          int totalDegraissages = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Dégraissage').length;
          int totalFermetures = commande.detailsAppartements.values.where((d) => d.typeMenage == 'Fermeture').length;

          return <pw.Widget>[
            pw.Header(level: 0, child: pw.Text('Historique de la Commande')),
            pw.Paragraph(text: 'Résidence: ${commande.nomResidence}'),
            pw.Paragraph(text: 'Date de la commande: ${DateFormat('dd/MM/yyyy').format(commande.dateCommande)}'),
            pw.Paragraph(text: 'Nombre total d\'appartements: ${commande.appartements.length}'),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Appartement', 'État', 'Type de Ménage', 'Note', 'Équipe Attribuée'],
                ...commande.appartements.map((appartement) {
                  DetailsAppartement details = commande.detailsAppartements[appartement.id] ?? DetailsAppartement();
                  String equipeAttribuee = _trouverEquipePourAppartement(commande, appartement.id);
                  return [
                    appartement.numero,
                    details.etatValidation.isNotEmpty ? details.etatValidation : "Non validé",
                    details.typeMenage,
                    details.note,
                    equipeAttribuee
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Résumé des Types de Ménage')),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Type', 'Total'],
                ['Lits Simples', '$totalLitsSimples'],
                ['Lits Doubles', '$totalLitsDoubles'],
                ['Salles de Bains', '$totalSallesDeBains'],
                ['Ménages', '$totalMenages'],
                ['Recouches', '$totalRecouches'],
                ['Dégraissages', '$totalDegraissages'],
                ['Fermetures', '$totalFermetures'],
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Historique-${commande.nomResidence}.pdf');
  }

  String _trouverEquipePourAppartement(Commande commande, String appartementId) {
    for (var equipe in commande.equipes) {
      if (equipe.appartementIds.contains(appartementId)) {
        return equipe.nom;
      }
    }
    return 'Non attribuée';
  }}