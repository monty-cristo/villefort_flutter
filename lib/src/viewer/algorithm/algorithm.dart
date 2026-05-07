import 'dart:ui';

abstract interface class GraphLayoutAlgorithm<S extends Object> {
  Map<S, Offset> compute({
    required List<S> vertices,
    required List<(S, S)> edges,
    required Map<S, Size> sizes,
  });
}
