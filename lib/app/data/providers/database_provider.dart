import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseProvider {
  static Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'routing.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabela de Nós (Interseções/Pontos)
        await db.execute('''
          CREATE TABLE road_nodes (
            id INTEGER PRIMARY KEY,
            lat REAL,
            lon REAL
          )
        ''');
        
        // Tabela de Arestas (Ruas/Rodovias)
        await db.execute('''
          CREATE TABLE road_edges (
            id INTEGER PRIMARY KEY,
            source INTEGER,
            target INTEGER,
            distance REAL,
            max_speed INTEGER,
            is_toll INTEGER
          )
        ''');
        
        // Extensão Espacial (R*Tree) para busca rápida de subgrafos por Bounding Box
        await db.execute('''
          CREATE VIRTUAL TABLE road_index USING rtree(
            id, minX, maxX, minY, maxY
          )
        ''');
      },
    );
  }
}
