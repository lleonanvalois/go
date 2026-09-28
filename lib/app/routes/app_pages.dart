import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/map/views/map_view.dart';
import '../modules/map/bindings/map_binding.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.map,
      page: () => const MapView(),
      binding: MapBinding(),
    ),
  ];
}
