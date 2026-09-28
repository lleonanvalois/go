import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' hide MapController;
import 'package:latlong2/latlong.dart';
import '../controllers/navigation_controller.dart';

class NavigationView extends GetView<NavigationController> {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isHud = controller.isHudMode.value;

      Widget content = Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(
            isHud ? 'MODO HUD (PARA-BRISA)' : 'NAVEGAÇÃO',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: isHud ? Colors.greenAccent : Colors.white,
              ),
              icon: Icon(isHud ? Icons.wb_sunny : Icons.nightlight_round),
              label: Text(isHud ? 'NORMAL' : 'HUD'),
              onPressed: controller.toggleHud,
            ),
          ],
        ),
        body: SafeArea(
          child: isHud ? _buildHudCockpit() : _buildDriverCockpit(),
        ),
      );

      // Inversão ótica de espelho no Modo HUD
      if (isHud) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: content,
        );
      }

      return content;
    });
  }

  /// Visão de cockpit com mapa vivo + dashboard de condução
  Widget _buildDriverCockpit() {
    return Column(
      children: [
        // Painel superior com manobra
        _buildManeuverHeader(),

        // Mapa centrado no veículo
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: controller.currentPosition.value ??
                      (controller.routePoints.isNotEmpty
                          ? controller.routePoints.first
                          : const LatLng(-15.793889, -47.882778)),
                  initialZoom: 17.5,
                  initialRotation: controller.currentBearing.value,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.go',
                  ),
                  if (controller.routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: controller.routePoints.toList(),
                          color: Colors.blueAccent,
                          strokeWidth: 7.0,
                        ),
                      ],
                    ),
                  if (controller.currentPosition.value != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: controller.currentPosition.value!,
                          width: 40,
                          height: 40,
                          child: Transform.rotate(
                            angle: (controller.currentBearing.value * (math.pi / 180)),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.cyanAccent,
                              size: 38,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Velocímetro flutuante sobre o mapa
              Positioned(
                bottom: 20,
                left: 20,
                child: _buildSpeedometerBadge(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Visão HUD otimizada para reflexo noturno no vidro do carro
  Widget _buildHudCockpit() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.nextManeuverIcon.value,
              size: 140,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 10),
            Text(
              controller.distanceToNext.value,
              style: const TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.nextInstruction.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${controller.currentSpeed.value}',
                  style: const TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'KM/H',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManeuverHeader() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.nextManeuverIcon.value,
              size: 42,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Em ${controller.distanceToNext.value}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  controller.nextInstruction.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${controller.currentSpeed.value}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'KM/H',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
