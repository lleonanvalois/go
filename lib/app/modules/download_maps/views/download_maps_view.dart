import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/download_maps_controller.dart';

class DownloadMapsView extends GetView<DownloadMapsController> {
  const DownloadMapsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Mapas Offline do Brasil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: controller.regions.length,
        itemBuilder: (context, index) {
          final region = controller.regions[index];

          return Obx(() {
            final isDownloaded = controller.downloadedMap[region.id] ?? false;
            final isDownloading = controller.downloadingMap[region.id] ?? false;
            final progress = controller.downloadProgress[region.id] ?? 0.0;

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDownloaded
                      ? Colors.greenAccent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDownloaded
                                ? Colors.greenAccent.withValues(alpha: 0.15)
                                : Colors.blueAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            region.stateCode,
                            style: TextStyle(
                              color: isDownloaded ? Colors.greenAccent : Colors.blueAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                region.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${region.sizeMb.toInt()} MB • Pacote Vetorial',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDownloading)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 3,
                              color: Colors.cyanAccent,
                            ),
                          )
                        else if (isDownloaded)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Excluir mapa',
                            onPressed: () => controller.deleteMap(region),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.cyanAccent),
                            tooltip: 'Baixar mapa',
                            onPressed: () => controller.startDownload(region),
                          ),
                      ],
                    ),
                    if (isDownloading) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
