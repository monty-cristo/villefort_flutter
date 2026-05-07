import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'algorithm.dart';

Set<(S, S)> findBackEdges<S extends Object>(
  List<S> vertices,
  List<(S, S)> edges,
) {
  final outEdges = <S, List<S>>{};
  for (final (from, to) in edges) {
    outEdges.putIfAbsent(from, () => []).add(to);
  }

  final visited = <S>{};
  final onStack = <S>{};
  final backEdges = <(S, S)>{};

  void dfs(S node) {
    visited.add(node);
    onStack.add(node);
    for (final next in outEdges[node] ?? []) {
      if (onStack.contains(next)) {
        backEdges.add((node, next)); // cycle — mark as back-edge
      } else if (!visited.contains(next)) {
        dfs(next);
      }
    }
    onStack.remove(node);
  }

  for (final node in vertices) {
    if (!visited.contains(node)) dfs(node);
  }

  return backEdges;
}

final class LayoutAlgorithmSugiyama<S extends Object>
    implements GraphLayoutAlgorithm<S> {
  final double layerSpacing;
  final double nodeSpacing;

  const LayoutAlgorithmSugiyama({
    this.layerSpacing = 80,
    this.nodeSpacing = 24,
  });

  @override
  Map<S, Offset> compute({
    required List<S> vertices,
    required List<(S, S)> edges,
    required Map<S, Size> sizes,
  }) {
    final layers = _assignLayers(vertices, edges);
    _minimizeCrossings(layers, edges);
    return _assignCoordinates(layers, sizes);
  }

  // ── Phase 1: Longest-path layering (Kahn's algorithm) ──────────────────────

  List<List<S>> _assignLayers(List<S> vertices, List<(S, S)> edges) {
    final backEdges = findBackEdges<S>(vertices, edges);
    // Only layer forward edges — back-edges are routed separately
    final forwardEdges = edges.where((e) => !backEdges.contains(e)).toList();

    final inDegree = <S, int>{for (final id in vertices) id: 0};
    final outEdgesMap = <S, List<S>>{for (final id in vertices) id: []};

    for (final (from, to) in forwardEdges) {
      outEdgesMap[from]!.add(to);
      inDegree[to] = inDegree[to]! + 1;
    }

    final layer = <S, int>{};
    final queue = Queue<S>();

    for (final id in vertices) {
      if (inDegree[id] == 0) {
        queue.add(id);
        layer[id] = 0;
      }
    }

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      for (final neighbor in outEdgesMap[node]!) {
        final candidate = layer[node]! + 1;
        if (candidate > (layer[neighbor] ?? 0)) layer[neighbor] = candidate;
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) queue.add(neighbor);
      }
    }

    final maxLayer = layer.values.fold(0, math.max);
    for (final id in vertices) {
      layer.putIfAbsent(id, () => maxLayer);
    }

    final result = List.generate(
      layer.values.fold(0, math.max) + 1,
      (_) => <S>[],
    );
    for (final id in vertices) {
      result[layer[id]!].add(id);
    }
    return result;
  }
  // ── Phase 2: Crossing minimization (barycenter heuristic) ──────────────────

  void _minimizeCrossings(List<List<S>> layers, List<(S, S)> edges) {
    for (var pass = 0; pass < 4; pass++) {
      for (var i = 1; i < layers.length; i++) {
        _sortByBarycenter(layers[i], layers[i - 1], edges, forward: true);
      }
      for (var i = layers.length - 2; i >= 0; i--) {
        _sortByBarycenter(layers[i], layers[i + 1], edges, forward: false);
      }
    }
  }

  void _sortByBarycenter(
    List<S> layer,
    List<S> fixedLayer,
    List<(S, S)> edges, {
    required bool forward,
  }) {
    final fixedPos = {
      for (var i = 0; i < fixedLayer.length; i++) fixedLayer[i]: i,
    };

    double barycenter(S node) {
      final neighbors = edges
          .where((e) => forward ? e.$2 == node : e.$1 == node)
          .map((e) => forward ? e.$1 : e.$2)
          .where(fixedPos.containsKey)
          .map((n) => fixedPos[n]!.toDouble())
          .toList();
      return neighbors.isEmpty
          ? layer.indexOf(node).toDouble()
          : neighbors.reduce((a, b) => a + b) / neighbors.length;
    }

    layer.sort((a, b) => barycenter(a).compareTo(barycenter(b)));
  }

  // ── Phase 3: Coordinate assignment using actual node sizes ─────────────────

  Map<S, Offset> _assignCoordinates(List<List<S>> layers, Map<S, Size> sizes) {
    final positions = <S, Offset>{};
    double x = 0;

    for (final layer in layers) {
      final layerWidth = layer.fold(
        0.0,
        (w, id) => math.max(w, sizes[id]?.width ?? 0),
      );
      double y = 0;

      for (final id in layer) {
        final size = sizes[id] ?? Size.zero;
        // Center node horizontally within its layer column
        positions[id] = Offset(x + (layerWidth - size.width) / 2, y);
        y += size.height + nodeSpacing;
      }

      x += layerWidth + layerSpacing;
    }

    return positions;
  }
}
