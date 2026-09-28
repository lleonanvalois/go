import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart' hide Node;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go/app/data/providers/database_provider.dart';
import 'package:go/app/data/services/offline_routing_service.dart';

class NavigationController extends GetxController {
  final isHudMode = false.obs;
  final isVoiceMuted = false.obs;
  final currentSpeed = 0.obs; // km/h
  final nextInstruction = 'Siga em frente'.obs;
  final distanceToNext = '150 m'.obs;
  final nextManeuverIcon = Rx<IconData>(Icons.straight);

  // Posição atual do veículo e rota
  final currentPosition = Rxn<LatLng>();
  final currentBearing = 0.0.obs;
  final routePoints = <LatLng>[].obs;

  StreamSubscription<Position>? _positionSubscription;
  final FlutterTts _flutterTts = FlutterTts();

  // Controle de emissão de voz para evitar sobreposição
  String? _lastSpokenMessage;
  int _lastSpokenStage = -1; // 2: 150m, 1: <= 35m, 0: destino
  bool _isRerouting = false;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is List<LatLng>) {
      routePoints.assignAll(Get.arguments as List<LatLng>);
      if (routePoints.isNotEmpty) {
        currentPosition.value = routePoints.first;
      }
    }
    _initTts();
    _initNavigation();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String message) async {
    if (isVoiceMuted.value || message == _lastSpokenMessage) return;
    _lastSpokenMessage = message;
    await _flutterTts.stop();
    await _flutterTts.speak(message);
  }

  void toggleVoice() {
    isVoiceMuted.value = !isVoiceMuted.value;
    if (isVoiceMuted.value) {
      _flutterTts.stop();
    } else {
      _lastSpokenMessage = null;
      _speak("Instruções de voz ativadas");
    }
  }

  Future<void> _initNavigation() async {
    await WakelockPlus.enable();
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

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
          ),
        ).listen((Position position) {
          final latLng = LatLng(position.latitude, position.longitude);
          currentPosition.value = latLng;

          final speedKmH = (position.speed * 3.6).clamp(0, 300).round();
          currentSpeed.value = speedKmH;
          currentBearing.value = position.heading;

          _updateManeuverGuidance(latLng);
        });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final dLon = (end.longitude - start.longitude) * (math.pi / 180.0);
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * (180.0 / math.pi) + 360.0) % 360.0;
  }

  void _updateManeuverGuidance(LatLng current) {
    if (routePoints.isEmpty) return;

    final distanceCalc = const Distance();
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      final d = distanceCalc.as(LengthUnit.Meter, current, routePoints[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIndex = i;
      }
    }

    // Se o usuário se afastou mais de 35 metros do trajeto: Recalcular rota
    if (minDistance > 35.0 && !_isRerouting) {
      _recalculateRoute(current);
      return;
    }

    if (closestIndex < routePoints.length - 1) {
      final nextTarget = routePoints[closestIndex + 1];
      final distToTarget = distanceCalc
          .as(LengthUnit.Meter, current, nextTarget)
          .round();
      distanceToNext.value = '$distToTarget m';

      String action = 'Siga em frente';
      IconData icon = Icons.straight;

      if (closestIndex < routePoints.length - 2) {
        final b1 = _calculateBearing(
          routePoints[closestIndex],
          routePoints[closestIndex + 1],
        );
        final b2 = _calculateBearing(
          routePoints[closestIndex + 1],
          routePoints[closestIndex + 2],
        );
        var angleDiff = b2 - b1;
        while (angleDiff > 180) {
          angleDiff -= 360;
        }
        while (angleDiff < -180) {
          angleDiff += 360;
        }

        if (angleDiff > 35 && angleDiff <= 110) {
          action = 'Vire à direita';
          icon = Icons.turn_right;
        } else if (angleDiff > 110) {
          action = 'Faça o retorno';
          icon = Icons.u_turn_right;
        } else if (angleDiff < -35 && angleDiff >= -110) {
          action = 'Vire à esquerda';
          icon = Icons.turn_left;
        } else if (angleDiff < -110) {
          action = 'Faça o retorno';
          icon = Icons.u_turn_left;
        }
      }

      nextInstruction.value = action;
      nextManeuverIcon.value = icon;

      // Gatilhos de voz: 150m e curva iminente (<= 35m)
      if (distToTarget <= 35 && _lastSpokenStage != 1) {
        _lastSpokenStage = 1;
        _speak(action);
      } else if (distToTarget <= 150 &&
          distToTarget > 35 &&
          _lastSpokenStage != 2) {
        _lastSpokenStage = 2;
        _speak("Em $distToTarget metros, $action");
      }
    } else {
      distanceToNext.value = '0 m';
      nextInstruction.value = 'Você chegou ao seu destino!';
      nextManeuverIcon.value = Icons.flag;
      if (_lastSpokenStage != 0) {
        _lastSpokenStage = 0;
        _speak("Você chegou ao seu destino!");
      }
    }
  }

  Future<void> _recalculateRoute(LatLng current) async {
    _isRerouting = true;
    _speak("Recalculando rota");
    nextInstruction.value = 'Recalculando rota...';
    nextManeuverIcon.value = Icons.sync;

    try {
      final nodesData = await DatabaseProvider.getNodes();
      final edgesData = await DatabaseProvider.getEdges();

      final nodes = nodesData
          .map(
            (n) => Node(n['id'] as int, n['lat'] as double, n['lon'] as double),
          )
          .toList();
      final edges = edgesData
          .map(
            (e) => Edge(
              e['source'] as int,
              e['target'] as int,
              (e['distance'] as num).toDouble(),
            ),
          )
          .toList();

      // Encontra o nó da malha mais próximo da posição atual do veículo
      final distanceCalc = const Distance();
      Node? nearestStartNode;
      double minStartDist = double.infinity;
      for (var node in nodes) {
        final d = distanceCalc.as(
          LengthUnit.Meter,
          current,
          LatLng(node.lat, node.lon),
        );
        if (d < minStartDist) {
          minStartDist = d;
          nearestStartNode = node;
        }
      }

      if (nearestStartNode != null) {
        final routingService = OfflineRoutingService();
        final destinationNodeId = nodes.last.id;
        final params = RoutingParams(
          nearestStartNode.id,
          destinationNodeId,
          nodes,
          edges,
        );
        final newPathIds = await routingService.calculateRoute(params);

        if (newPathIds.isNotEmpty) {
          final newRoute = [current]; // Inclui posição atual na frente
          for (var id in newPathIds) {
            final n = nodes.firstWhere((node) => node.id == id);
            newRoute.add(LatLng(n.lat, n.lon));
          }
          routePoints.assignAll(newRoute);
          _lastSpokenStage = -1;
          _speak("Nova rota calculada. Siga em frente.");
        }
      }
    } catch (_) {
      // Falha silenciosa de recálculo
    } finally {
      _isRerouting = false;
    }
  }

  void toggleHud() {
    isHudMode.value = !isHudMode.value;
  }

  @override
  void onClose() {
    _flutterTts.stop();
    _positionSubscription?.cancel();
    WakelockPlus.disable();
    super.onClose();
  }
}
