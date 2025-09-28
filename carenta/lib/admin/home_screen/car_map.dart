import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CarMap extends StatefulWidget {
  const CarMap({super.key});

  @override
  State<CarMap> createState() => _CarMapState();
}

class _CarMapState extends State<CarMap> {
  late GoogleMapController _mapController;

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId("car1"),
      position: LatLng(14.5995, 120.9842), // Manila
      infoWindow: InfoWindow(title: "Toyota Vios", snippet: "Available"),
    ),
    const Marker(
      markerId: MarkerId("car2"),
      position: LatLng(14.6760, 121.0437), // QC
      infoWindow: InfoWindow(title: "Honda Civic", snippet: "Ongoing Rental"),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(14.5995, 120.9842),
            zoom: 11,
          ),
          markers: _markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}
