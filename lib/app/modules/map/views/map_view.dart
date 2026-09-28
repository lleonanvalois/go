import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong.dart';
import 'package:go/app/routes/app_routes.dart';
import '../controllers/map_controller.dart';

class MapView extends GetView<MapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go - Navegação Offline'),
        actions: [
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: controller.isOfflineMapActive.value ? Colors.green.shade800 : Colors.blueGrey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.isOfflineMapActive.value ? Icons.offline_pin : Icons.cloud_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.isOfflineMapActive.value ? 'OFFLINE' : 'ONLINE',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(controller.initialLat, controller.initialLon),
              initialZoom: 16.0,
            ),
            children: [
              Obx(() {
                if (controller.isOfflineMapActive.value && controller.offlineTileProvider != null) {
                  return TileLayer(
                    tileProvider: controller.offlineTileProvider!,
                  );
                }
                return TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.go',
                );
              }),
              Obx(() => PolylineLayer(
                polylines: [
                  if (controller.routePoints.isNotEmpty)
                    Polyline(
                      points: controller.routePoints.toList(),
                      color: Colors.blueAccent,
                      strokeWidth: 6.0,
                    ),
                ],
              )),
              Obx(() => MarkerLayer(
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
              )),
            ],
          ),
          // Botão flutuante para traçar rota
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'calc_route_btn',
              onPressed: controller.calculateOfflineRoute,
              child: const Icon(Icons.directions),
            ),
          ),
          // Card de Iniciar Navegação quando rota estiver calculada
          Positioned(
            bottom: 20,
            left: 20,
            right: 90,
            child: Obx(() {
              if (!controller.isRouteCalculated.value) return const SizedBox.shrink();

              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                icon: const Icon(Icons.navigation, size: 26),
                label: const Text(
                  'INICIAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                onPressed: () {
                  Get.toNamed(
                    AppRoutes.navigation,
                    arguments: controller.routePoints.toList(),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
