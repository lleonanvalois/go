import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
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
          Obx(() => FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(controller.initialLat, controller.initialLon),
              initialZoom: 16.0, // Zoom próximo para enxergar as ruas simuladas
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.go',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: controller.routePoints.toList(),
                    color: Colors.blueAccent,
                    strokeWidth: 6.0,
                  )
                ],
              ),
              MarkerLayer(
                markers: controller.routePoints.map((point) => Marker(
                  point: point,
                  width: 15,
                  height: 15,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )).toList(),
              )
            ],
          )),
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
