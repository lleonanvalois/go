import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/navigation_controller.dart';

class NavigationView extends GetView<NavigationController> {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final content = Scaffold(
        backgroundColor: Colors.black, // Fundo preto para HUD à noite (menos brilho falso)
        appBar: AppBar(
          title: const Text('Navegação'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(controller.isHudMode.value ? Icons.flip : Icons.flip_to_back),
              onPressed: controller.toggleHud,
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.turn_right, size: 100, color: Colors.greenAccent),
              SizedBox(height: 20),
              Text('Vire à direita em 200m', style: TextStyle(fontSize: 32, color: Colors.white)),
              SizedBox(height: 20),
              Text('80 km/h', style: TextStyle(fontSize: 64, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

      // Se estiver no modo HUD, espelha a tela
      if (controller.isHudMode.value) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: content,
        );
      }
      return content;
    });
  }
}
