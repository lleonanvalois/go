import 'package:get/get.dart';
import 'package:go/app/data/services/map_package_manager_service.dart';

class DownloadMapsController extends GetxController {
  final MapPackageManagerService packageService = MapPackageManagerService();
  
  // Status de cada região: baixada ou não
  final downloadedMap = <String, bool>{}.obs;
  // Progresso de download ativo por ID da região: 0.0 a 1.0
  final downloadProgress = <String, double>{}.obs;
  // Regiões que estão baixando no momento
  final downloadingMap = <String, bool>{}.obs;

  List<MapRegion> get regions => MapPackageManagerService.availableRegions;

  @override
  void onInit() {
    super.onInit();
    checkAllRegions();
  }

  Future<void> checkAllRegions() async {
    for (var region in regions) {
      final downloaded = await packageService.isRegionDownloaded(region);
      downloadedMap[region.id] = downloaded;
    }
  }

  Future<void> startDownload(MapRegion region) async {
    downloadingMap[region.id] = true;
    downloadProgress[region.id] = 0.0;

    try {
      await packageService.downloadRegionMap(
        region,
        onProgress: (progress) {
          downloadProgress[region.id] = progress;
        },
      );
      downloadedMap[region.id] = true;
      Get.snackbar(
        'Mapa Baixado',
        'O mapa de ${region.name} está pronto para uso 100% offline!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Falha no Download',
        'Não foi possível baixar o mapa de ${region.name}. Verifique sua conexão.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      downloadingMap[region.id] = false;
      downloadProgress.remove(region.id);
    }
  }

  Future<void> deleteMap(MapRegion region) async {
    await packageService.deleteRegionMap(region);
    downloadedMap[region.id] = false;
    Get.snackbar(
      'Mapa Removido',
      'O pacote de ${region.name} foi excluído.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
