import 'package:get/get.dart';

class MapController extends GetxController {
  // Coordenadas iniciais (Centro do Brasil)
  final double initialLat = -15.793889;
  final double initialLon = -47.882778;

  // Estado observável para sabermos se já temos uma rota
  final isRouteCalculated = false.obs;

  void calculateOfflineRoute() {
    // Futuro: chamar o OfflineRoutingService passando a posição GPS real
    isRouteCalculated.value = true;
    print("Rota offline calculada via Isolate!");
  }
}
