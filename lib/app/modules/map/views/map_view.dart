import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/map_controller.dart';

class MapView extends GetView<MapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go - Navegação Offline')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(controller.initialLat, controller.initialLon),
              initialZoom: 4.0,
            ),
            children: [
              TileLayer(
                // Temporário: mapa via internet. 
                // Futuro: MbTilesTileProvider() local
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.go',
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: controller.calculateOfflineRoute,
              child: const Icon(Icons.directions),
            ),
          )
        ],
      ),
    );
  }
}
