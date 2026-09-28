import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;

// Representa um Nó no grafo
class Node {
  final int id;
  final double lat;
  final double lon;
  Node(this.id, this.lat, this.lon);
}

// Representa uma Aresta (Rua)
class Edge {
  final int source;
  final int target;
  final double distance;
  Edge(this.source, this.target, this.distance);
}

class RoutingParams {
  final int startNodeId;
  final int endNodeId;
  final List<Node> nodes;
  final List<Edge> edges;

  RoutingParams(this.startNodeId, this.endNodeId, this.nodes, this.edges);
}

class OfflineRoutingService {
  Future<List<int>> calculateRoute(RoutingParams params) async {
    // Executa o algoritmo pesado no Isolate
    return await compute(_aStarCompute, params);
  }

  // Heurística do A* (Distância Euclidiana simples para o exemplo)
  static double _heuristic(Node a, Node b) {
    final dx = a.lat - b.lat;
    final dy = a.lon - b.lon;
    return math.sqrt(dx * dx + dy * dy);
  }

  // Função estática que roda FORA da UI Thread (dentro do compute)
  static List<int> _aStarCompute(RoutingParams params) {
    final nodes = {for (var n in params.nodes) n.id: n};
    final adjacencyList = <int, List<Edge>>{};
    
    // Constrói a lista de adjacência
    for (var edge in params.edges) {
      adjacencyList.putIfAbsent(edge.source, () => []).add(edge);
      // Assumindo vias de mão dupla para o teste
      adjacencyList.putIfAbsent(edge.target, () => []).add(Edge(edge.target, edge.source, edge.distance));
    }

    final start = nodes[params.startNodeId];
    final end = nodes[params.endNodeId];
    if (start == null || end == null) return [];

    // Fila de prioridade do A* baseada no menor custo total estimado (F)
    final openSet = PriorityQueue<_QueueNode>((a, b) => a.f.compareTo(b.f));
    final cameFrom = <int, int>{};
    
    // Custos reais (G)
    final gScore = <int, double>{params.startNodeId: 0.0};
    
    openSet.add(_QueueNode(params.startNodeId, _heuristic(start, end)));

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst().id;

      if (current == params.endNodeId) {
        // Objetivo alcançado, reconstrói o caminho de trás pra frente
        final path = <int>[current];
        var curr = current;
        while (cameFrom.containsKey(curr)) {
          curr = cameFrom[curr]!;
          path.insert(0, curr);
        }
        return path;
      }

      final neighbors = adjacencyList[current] ?? [];
      for (var edge in neighbors) {
        final neighbor = edge.target;
        final tentativeGScore = gScore[current]! + edge.distance;

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          final fScore = tentativeGScore + _heuristic(nodes[neighbor]!, end);
          openSet.add(_QueueNode(neighbor, fScore));
        }
      }
    }

    return []; // Sem caminho
  }
}

class _QueueNode {
  final int id;
  final double f;
  _QueueNode(this.id, this.f);
}
