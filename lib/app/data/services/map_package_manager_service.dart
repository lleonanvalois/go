import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MapRegion {
  final String id;
  final String name;
  final String stateCode;
  final double sizeMb;
  final String downloadUrl;

  const MapRegion({
    required this.id,
    required this.name,
    required this.stateCode,
    required this.sizeMb,
    required this.downloadUrl,
  });

  String get fileName => '$id.mbtiles';
}

class MapPackageManagerService {
  static const List<MapRegion> availableRegions = [
    MapRegion(
      id: 'df_distrito_federal',
      name: 'Distrito Federal',
      stateCode: 'DF',
      sizeMb: 85.0,
      downloadUrl: 'https://download.geofabrik.de/south-america/brazil/centro-oeste-latest.osm.pbf',
    ),
    MapRegion(
      id: 'sp_sao_paulo',
      name: 'São Paulo',
      stateCode: 'SP',
      sizeMb: 420.0,
      downloadUrl: 'https://download.geofabrik.de/south-america/brazil/sudeste-latest.osm.pbf',
    ),
    MapRegion(
      id: 'rj_rio_de_janeiro',
      name: 'Rio de Janeiro',
      stateCode: 'RJ',
      sizeMb: 180.0,
      downloadUrl: 'https://download.geofabrik.de/south-america/brazil/sudeste-latest.osm.pbf',
    ),
    MapRegion(
      id: 'mg_minas_gerais',
      name: 'Minas Gerais',
      stateCode: 'MG',
      sizeMb: 350.0,
      downloadUrl: 'https://download.geofabrik.de/south-america/brazil/sudeste-latest.osm.pbf',
    ),
    MapRegion(
      id: 'pr_parana',
      name: 'Paraná',
      stateCode: 'PR',
      sizeMb: 195.0,
      downloadUrl: 'https://download.geofabrik.de/south-america/brazil/sul-latest.osm.pbf',
    ),
    MapRegion(
      id: 'ba_bahia',
      name: 'Bahia',
      stateCode: 'BA',
      sizeMb: 240.0,
      downloadUrl: 'https://download.geofabrik.de/south-america/brazil/nordeste-latest.osm.pbf',
    ),
  ];

  Future<String> getMapsDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory(p.join(appDir.path, 'maps'));
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }
    return mapsDir.path;
  }

  Future<bool> isRegionDownloaded(MapRegion region) async {
    final dirPath = await getMapsDirectoryPath();
    final file = File(p.join(dirPath, region.fileName));
    return await file.exists();
  }

  Future<void> deleteRegionMap(MapRegion region) async {
    final dirPath = await getMapsDirectoryPath();
    final file = File(p.join(dirPath, region.fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Download resiliente em streaming com callback de progresso percentual (0.0 a 1.0)
  Future<void> downloadRegionMap(
    MapRegion region, {
    required void Function(double progress) onProgress,
  }) async {
    final dirPath = await getMapsDirectoryPath();
    final targetPath = p.join(dirPath, region.fileName);
    final tempPath = '$targetPath.tmp';

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(region.downloadUrl));
      final response = await request.close();

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Renomeia o arquivo temporário para o destino final seguro
      await tempFile.rename(targetPath);
      onProgress(1.0);
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }
}
