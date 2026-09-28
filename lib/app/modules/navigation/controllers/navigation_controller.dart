import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class NavigationController extends GetxController {
  final isHudMode = false.obs;
  final currentSpeed = 0.obs; // km/h
  final nextInstruction = 'Siga em frente'.obs;
  final distanceToNext = '150 m'.obs;
  final nextManeuverIcon = Rx<IconData>(Icons.straight);
  
  // Posição atual do veículo e rota
  final currentPosition = Rxn<LatLng>();
  final currentBearing = 0.0.obs;
  final routePoints = <LatLng>[].obs;
  
  StreamSubscription<Position>? _positionSubscription;

  @override
  void onInit() {
    super.onInit();
    // Recebe os pontos da rota via argumentos da rota
    if (Get.arguments is List<LatLng>) {
      routePoints.assignAll(Get.arguments as List<LatLng>);
      if (routePoints.isNotEmpty) {
        currentPosition.value = routePoints.first;
      }
    }
    
    _initNavigation();
  }

  Future<void> _initNavigation() async {
    // Mantém a tela acesa durante a condução
    await WakelockPlus.enable();

    // Inicia escuta do GPS
    await _startLocationStream();
  }

  Future<void> _startLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      nextInstruction.value = 'Ative o GPS para navegar';
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        nextInstruction.value = 'Permissão de localização negada';
        return;
      }
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      currentPosition.value = latLng;
      
      // Velocidade do sensor em m/s convertida para km/h
      final speedKmH = (position.speed * 3.6).clamp(0, 300).round();
      currentSpeed.value = speedKmH;
      currentBearing.value = position.heading;

      _updateManeuverGuidance(latLng);
    });
  }

  void _updateManeuverGuidance(LatLng current) {
    if (routePoints.isEmpty) return;

    final distanceCalc = const Distance();
    // Distância até o próximo ponto da rota
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      final d = distanceCalc.as(LengthUnit.Meter, current, routePoints[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIndex = i;
      }
    }

    if (closestIndex < routePoints.length - 1) {
      final nextTarget = routePoints[closestIndex + 1];
      final distToTarget = distanceCalc.as(LengthUnit.Meter, current, nextTarget).round();
      distanceToNext.value = '$distToTarget m';
      nextInstruction.value = 'Siga em direção à via';
      nextManeuverIcon.value = Icons.straight;
    } else {
      distanceToNext.value = '0 m';
      nextInstruction.value = 'Você chegou ao seu destino!';
      nextManeuverIcon.value = Icons.flag;
    }
  }

  void toggleHud() {
    isHudMode.value = !isHudMode.value;
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    WakelockPlus.disable();
    super.onClose();
  }
}
