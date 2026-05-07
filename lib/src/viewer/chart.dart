import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:villefort/villefort.dart';

import 'algorithm/algorithm.dart';

class GraphParentData<S extends Object>
    extends ContainerBoxParentData<RenderBox> {
  S? vertex;
}

class GraphNode<S extends Object> extends ParentDataWidget<GraphParentData<S>> {
  final S vertex;

  const GraphNode({super.key, required this.vertex, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as GraphParentData<S>;

    if (data.vertex != vertex) {
      data.vertex = vertex;
      (renderObject.parent as RenderObject).markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => StateGraph<S, dynamic>;
}

class RenderStateGraph<S extends Object, E extends Object> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GraphParentData> {
  Graph<S, E> _graph;

  GraphLayoutAlgorithm _algorithm;

  set graph(Graph<S, E> value) {
    _graph = value;
    markNeedsLayout();
  }

  set algorithm(GraphLayoutAlgorithm value) {
    _algorithm = value;
    markNeedsLayout();
  }

  RenderStateGraph({
    required Graph<S, E> graph,
    required GraphLayoutAlgorithm algorithm,
  }) : _graph = graph,
       _algorithm = algorithm;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GraphParentData<S>) {
      child.parentData = GraphParentData<S>();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    // Pass 1: let every child size itself
    final sizes = <S, Size>{};

    var child = firstChild;
    while (child != null) {
      final data = child.parentData as GraphParentData<S>;

      child.layout(
        BoxConstraints.loose(constraints.biggest),
        parentUsesSize: true,
      );
      if (data.vertex != null) sizes[data.vertex as S] = child.size;
      child = data.nextSibling;
    }

    sizes.entries.forEach(print);

    // // Pass 2: Sugiyama with real sizes
    final positions = _algorithm.compute(
      vertices: sizes.keys.toList(),
      edges: _graph.edges.map((e) => (e.from, e.to)).toList(),
      sizes: sizes,
    );

    // Pass 3: apply positions
    child = firstChild;
    while (child != null) {
      final data = child.parentData as GraphParentData;
      data.offset = positions[data.vertex] ?? Offset.zero;
      child = data.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint edges first so they appear beneath nodes
    _paintEdges(context.canvas, offset);
    // Then paint all children on top
    defaultPaint(context, offset);
  }

  void _paintEdges(Canvas canvas, Offset offset) {
    final rects = <S, Rect>{};
    var child = firstChild;
    while (child != null) {
      final data = child.parentData as GraphParentData<S>;
      if (data.vertex != null) {
        rects[data.vertex as S] = (data.offset + offset) & child.size;
      }

      child = data.nextSibling;
    }

    final stroke = Paint()
      ..color = const Color(0xFF607D8B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = const Color(0xFF607D8B)
      ..style = PaintingStyle.fill;

    for (final edge in _graph.edges) {
      final fromRect = rects[edge.from];
      final toRect = rects[edge.to];
      if (fromRect == null || toRect == null) continue;

      final src = Offset(fromRect.right, fromRect.center.dy);

      // Detect nodes whose bounding box overlaps the edge corridor
      final blockers = rects.entries
          .where((e) => e.key != edge.from && e.key != edge.to)
          .map((e) => e.value)
          .where((r) =>
              r.left < toRect.left &&
              r.right > fromRect.right &&
              r.top < math.max(fromRect.bottom, toRect.bottom) &&
              r.bottom > math.min(fromRect.top, toRect.top))
          .toList();

      if (blockers.isNotEmpty && toRect.left > fromRect.right) {
        final routeY = blockers.map((r) => r.top).reduce(math.min) - 24.0;
        if (routeY < src.dy) {
          final tip = Offset(toRect.center.dx, toRect.top);
          canvas.drawPath(_routeAbovePath(src, tip, routeY), stroke);
          _paintArrowhead(canvas, fill, tip, pointDown: true);
          continue;
        }
      }

      final dst = Offset(toRect.left, toRect.center.dy);
      canvas.drawPath(_orthogonalPath(src, dst), stroke);
      _paintArrowhead(canvas, fill, dst);
    }
  }

  Path _orthogonalPath(Offset src, Offset dst, {double radius = 8.0}) {
    final path = Path()..moveTo(src.dx, src.dy);

    // Back edge: destination is to the left of source — loop below
    if (dst.dx < src.dx) {
      const r = 8.0;
      final bottom = math.max(src.dy, dst.dy) + 60.0;
      path.lineTo(src.dx, bottom - r);
      // Down → Left (clockwise on screen)
      path.arcToPoint(Offset(src.dx - r, bottom), radius: Radius.circular(r), clockwise: true);
      path.lineTo(dst.dx + r, bottom);
      // Left → Up (clockwise on screen)
      path.arcToPoint(Offset(dst.dx, bottom - r), radius: Radius.circular(r), clockwise: true);
      path.lineTo(dst.dx, dst.dy);
      return path;
    }

    // Same row — no bends needed
    if ((src.dy - dst.dy).abs() <= 1) {
      return path..lineTo(dst.dx, dst.dy);
    }

    final mid = (src.dx + dst.dx) / 2;
    final goingDown = dst.dy > src.dy;

    // Clamp radius so it fits within both the horizontal and vertical segments
    final r = math.min(
      radius,
      math.min(
        (mid - src.dx), // horizontal segment length
        (dst.dy - src.dy).abs() / 2, // half of vertical segment
      ),
    );

    if (goingDown) {
      path.lineTo(mid - r, src.dy);
      // Right → Down (clockwise on screen)
      path.arcToPoint(
        Offset(mid, src.dy + r),
        radius: Radius.circular(r),
        clockwise: true,
      );
      path.lineTo(mid, dst.dy - r);
      // Down → Right (counter-clockwise on screen)
      path.arcToPoint(
        Offset(mid + r, dst.dy),
        radius: Radius.circular(r),
        clockwise: false,
      );
    } else {
      path.lineTo(mid - r, src.dy);
      // Right → Up (counter-clockwise on screen)
      path.arcToPoint(
        Offset(mid, src.dy - r),
        radius: Radius.circular(r),
        clockwise: false,
      );
      path.lineTo(mid, dst.dy + r);
      // Up → Right (clockwise on screen)
      path.arcToPoint(
        Offset(mid + r, dst.dy),
        radius: Radius.circular(r),
        clockwise: true,
      );
    }

    path.lineTo(dst.dx, dst.dy);
    return path;
  }

  // Routes src → up to routeY → right → down to tip (top-center of destination)
  Path _routeAbovePath(Offset src, Offset tip, double routeY) {
    const r = 8.0;
    final path = Path()..moveTo(src.dx, src.dy);
    path.lineTo(src.dx, routeY + r);
    // Up → Right (clockwise on screen)
    path.arcToPoint(Offset(src.dx + r, routeY), radius: Radius.circular(r), clockwise: true);
    path.lineTo(math.max(src.dx + r, tip.dx - r), routeY);
    // Right → Down (clockwise on screen)
    path.arcToPoint(Offset(tip.dx, routeY + r), radius: Radius.circular(r), clockwise: true);
    path.lineTo(tip.dx, tip.dy);
    return path;
  }

  void _paintArrowhead(Canvas canvas, Paint paint, Offset tip, {bool pointDown = false}) {
    const sa = 8.0;
    canvas.drawPath(
      pointDown
          ? (Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - sa / 2, tip.dy - sa)
            ..lineTo(tip.dx + sa / 2, tip.dy - sa)
            ..close())
          : (Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - sa, tip.dy - sa / 2)
            ..lineTo(tip.dx - sa, tip.dy + sa / 2)
            ..close()),
      paint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class StateGraph<S extends Object, E extends Object>
    extends MultiChildRenderObjectWidget {
  final Graph<S, E> graph;

  final GraphLayoutAlgorithm algorithm;

  final Widget Function(S state) builder;

  StateGraph({
    super.key,
    required this.graph,
    required this.algorithm,
    required this.builder,
  }) : super(
         children: graph.vertices.map((vertex) {
           return GraphNode<S>(vertex: vertex, child: builder(vertex));
         }).toList(),
       );

  @override
  RenderStateGraph<S, E> createRenderObject(BuildContext context) {
    return RenderStateGraph(graph: graph, algorithm: algorithm);
  }

  @override
  void updateRenderObject(BuildContext context, RenderStateGraph<S, E> renderObject) {
    renderObject.graph = graph;
    renderObject.algorithm = algorithm;
  }
}
