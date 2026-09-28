import 'package:get/get.dart';
import '../controllers/download_maps_controller.dart';

class DownloadMapsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DownloadMapsController>(() => DownloadMapsController());
  }
}
