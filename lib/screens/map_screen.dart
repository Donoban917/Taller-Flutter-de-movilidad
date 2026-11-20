import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/park_service.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _currentPosition = const LatLng(4.6583, -74.0939); // Coordenada inicial (Bogotá)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndParks();
  }

  Future<void> _initLocationAndParks() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final Position pos = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14.5),
      );

      final parks = await ParkService.fetchNearbyParks(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );

      if (!mounted) return;
      setState(() {
        _markers.clear();
        for (int i = 0; i < parks.length; i++) {
          _markers.add(
            Marker(
              markerId: MarkerId('park_$i'),
              position: LatLng(parks[i]['lat'], parks[i]['lon']),
              infoWindow: InfoWindow(
                title: parks[i]['name'],
                snippet: 'Zona verde cercana',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        }
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parques Cercanos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar ubicación y parques',
            onPressed: () {
              setState(() => _isLoading = true);
              _initLocationAndParks();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            ),
        ],
      ),
    );
  }
}