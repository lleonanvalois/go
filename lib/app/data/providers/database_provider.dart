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
        await db.execute('''
          CREATE TABLE road_nodes (
            id INTEGER PRIMARY KEY,
            lat REAL,
            lon REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE road_edges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source INTEGER,
            target INTEGER,
            distance REAL,
            max_speed INTEGER,
            is_toll INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE road_index (
            id INTEGER PRIMARY KEY,
            minX REAL,
            maxX REAL,
            minY REAL,
            maxY REAL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_road_nodes_coords ON road_nodes (lat, lon);',
        );

        // Inserir dados mock para teste do motor A*
        await _seedMockData(db);
      },
    );
  }

  static Future<void> _seedMockData(Database db) async {
    // Nós formando um pequeno quarteirão simulado no mapa
    final nodes = [
      {'id': 1, 'lat': -15.793889, 'lon': -47.882778}, // Ponto A (Início)
      {'id': 2, 'lat': -15.794000, 'lon': -47.880000}, // Ponto B (Cruzamento 1)
      {'id': 3, 'lat': -15.796000, 'lon': -47.880000}, // Ponto C (Cruzamento 2)
      {
        'id': 4,
        'lat': -15.796000,
        'lon': -47.882778,
      }, // Ponto D (Destino final)
      {
        'id': 5,
        'lat': -15.792000,
        'lon': -47.880000,
      }, // Ponto E (Rua cega / longe)
    ];

    for (var n in nodes) {
      await db.insert('road_nodes', n);
    }

    // Arestas / Conexões
    final edges = [
      {
        'source': 1,
        'target': 2,
        'distance': 100.0,
        'max_speed': 60,
        'is_toll': 0,
      },
      {
        'source': 2,
        'target': 3,
        'distance': 200.0,
        'max_speed': 60,
        'is_toll': 0,
      },
      {
        'source': 3,
        'target': 4,
        'distance': 100.0,
        'max_speed': 60,
        'is_toll': 0,
      },
      {
        'source': 2,
        'target': 5,
        'distance': 150.0,
        'max_speed': 60,
        'is_toll': 0,
      },
    ];

    for (var e in edges) {
      await db.insert('road_edges', e);
    }
  }

  // Funções de acesso rápido para o teste
  static Future<List<Map<String, dynamic>>> getNodes() async {
    final db = await initDb();
    return await db.query('road_nodes');
  }

  static Future<List<Map<String, dynamic>>> getEdges() async {
    final db = await initDb();
    return await db.query('road_edges');
  }
}
