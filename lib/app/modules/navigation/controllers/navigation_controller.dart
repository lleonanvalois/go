import 'package:get/get.dart';

class NavigationController extends GetxController {
  final isHudMode = false.obs; // Controle para modo HUD (espelhado)

  void toggleHud() {
    isHudMode.value = !isHudMode.value;
  }
}
