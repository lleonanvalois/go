import 'package:get/get.dart' hide Node;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:go/app/data/providers/database_provider.dart';
import 'package:go/app/data/services/offline_routing_service.dart';
import 'package:go/app/data/services/offline_map_service.dart';

class MapController extends GetxController {
  final double initialLat = -15.793889;
  final double initialLon = -47.882778;

  final isRouteCalculated = false.obs;
  final isOfflineMapActive = false.obs;
  
  // Lista de pontos reativa que vai desenhar a linha da rota no mapa
  final routePoints = <LatLng>[].obs;

  final OfflineMapService offlineMapService = OfflineMapService();
  MbTilesTileProvider? get offlineTileProvider => offlineMapService.tileProvider;

  @override
  void onInit() {
    super.onInit();
    _checkOfflineMap();
  }

  Future<void> _checkOfflineMap() async {
    final available = await offlineMapService.initOfflineMap();
    isOfflineMapActive.value = available;
  }

  Future<void> calculateOfflineRoute() async {
    // 1. Busca os dados no Banco Local
    final nodesData = await DatabaseProvider.getNodes();
    final edgesData = await DatabaseProvider.getEdges();

    final nodes = nodesData.map((n) => Node(n['id'] as int, n['lat'] as double, n['lon'] as double)).toList();
    final edges = edgesData.map((e) => Edge(e['source'] as int, e['target'] as int, (e['distance'] as num).toDouble())).toList();

    // 2. Prepara parâmetros: Queremos ir do Nó 1 ao Nó 4
    final params = RoutingParams(1, 4, nodes, edges);
    final routingService = OfflineRoutingService();

    // 3. Executa o Motor Matemático no Isolate
    final pathNodeIds = await routingService.calculateRoute(params);
    
    // 4. Converte os IDs da resposta em Coordenadas Geográficas
    final newRoute = <LatLng>[];
    for (var id in pathNodeIds) {
      final node = nodes.firstWhere((n) => n.id == id);
      newRoute.add(LatLng(node.lat, node.lon));
    }

    routePoints.value = newRoute;
    isRouteCalculated.value = true;
  }

  @override
  void onClose() {
    offlineMapService.dispose();
    super.onClose();
  }
}
