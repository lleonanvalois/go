import 'dart:io';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class OfflineMapService {
  MbTilesTileProvider? _tileProvider;
  bool _isOfflineAvailable = false;

  bool get isOfflineAvailable => _isOfflineAvailable;
  MbTilesTileProvider? get tileProvider => _tileProvider;

  /// Retorna o caminho da pasta onde os pacotes de mapas .mbtiles são guardados
  Future<String> getMapsDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory(p.join(appDir.path, 'maps'));
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }
    return mapsDir.path;
  }

  /// Inicializa o provedor de blocos de mapa local caso exista um arquivo .mbtiles
  Future<bool> initOfflineMap({String fileName = 'brasil.mbtiles'}) async {
    try {
      final dirPath = await getMapsDirectoryPath();
      final filePath = p.join(dirPath, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        _tileProvider = MbTilesTileProvider.fromPath(path: filePath);
        _isOfflineAvailable = true;
        return true;
      }
    } catch (e) {
      _isOfflineAvailable = false;
    }

    _isOfflineAvailable = false;
    return false;
  }

  /// Fecha e libera o arquivo de tiles quando necessário
  void dispose() {
    _tileProvider?.dispose();
    _tileProvider = null;
    _isOfflineAvailable = false;
  }
}
