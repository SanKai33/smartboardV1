import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectAddressScreen extends StatefulWidget {
  @override
  _SelectAddressScreenState createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  GoogleMapController? mapController;

  // Position initiale par défaut (par exemple, Paris)
  final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(48.8566, 2.3522), // Coordonnées de Paris
    zoom: 12.0,
  );

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onSelectLocation(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        // Généralement, le premier résultat est le plus pertinent
        Placemark place = placemarks.first;

        String address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';

        // Utiliser l'adresse obtenue
        print("Adresse sélectionnée: $address");

        // Vous pouvez également renvoyer cette adresse à l'écran précédent si nécessaire
        Navigator.pop(context, address);
      }
    } catch (e) {
      print("Erreur lors du géocodage inversé: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner une Adresse'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onTap: _onSelectLocation,
        initialCameraPosition: _initialCameraPosition,
      ),
    );
  }
}