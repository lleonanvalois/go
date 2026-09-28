import 'package:flutter/foundation.dart';

class RoutingParams {
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;

  RoutingParams(this.startLat, this.startLon, this.endLat, this.endLon);
}

class OfflineRoutingService {
  Future<List<Map<String, double>>> calculateRoute(RoutingParams params) async {
    // Executa o processamento pesado em um Isolate (thread separada)
    // Isso impede que a interface do mapa (UI Thread) trave durante o cálculo
    return await compute(_aStarCompute, params);
  }

  static List<Map<String, double>> _aStarCompute(RoutingParams params) {
    // Futura implementação real:
    // 1. Conexão no SQLite
    // 2. Busca do Subgrafo usando a Bounding Box (origem -> destino)
    // 3. Algoritmo A* Bidirecional
    
    // Retorno temporário: reta direta entre os dois pontos
    return [
      {'lat': params.startLat, 'lon': params.startLon},
      {'lat': params.endLat, 'lon': params.endLon},
    ];
  }
}
