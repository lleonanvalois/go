import 'package:flutter/material.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Offline')),
      body: const Center(
        child: Text('O mapa será renderizado aqui.'),
      ),
    );
  }
}
