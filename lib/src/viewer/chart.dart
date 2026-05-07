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

  GraphLayoutAlgorithm<S> _algorithm;

  set graph(Graph<S, E> value) {
    _graph = value;
    markNeedsLayout();
  }

  set algorithm(GraphLayoutAlgorithm<S> value) {
    _algorithm = value;
    markNeedsLayout();
  }

  RenderStateGraph({
    required Graph<S, E> graph,
    required GraphLayoutAlgorithm<S> algorithm,
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
    // Pass 1: let every child size itself
    final sizes = <S, Size>{};

    var child = firstChild;
    while (child != null) {
      final data = child.parentData as GraphParentData<S>;

      child.layout(const BoxConstraints(), parentUsesSize: true);

      if (data.vertex != null) {
        sizes[data.vertex as S] = child.size;
      }

      child = data.nextSibling;
    }

    // Pass 2: compute positions
    final positions = _algorithm.compute(
      vertices: sizes.keys.toList(),
      edges: _graph.edges.map((e) => (e.from, e.to)).toList(),
      sizes: sizes,
    );

    // Pass 3: apply positions and measure content bounds
    double maxRight = 0;
    double maxBottom = 0;
    child = firstChild;
    while (child != null) {
      final data = child.parentData as GraphParentData<S>;
      final offset = positions[data.vertex] ?? Offset.zero;
      data.offset = offset;
      if (data.vertex != null) {
        final sz = sizes[data.vertex as S] ?? Size.zero;
        maxRight = math.max(maxRight, offset.dx + sz.width);
        maxBottom = math.max(maxBottom, offset.dy + sz.height);
      }
      child = data.nextSibling;
    }

    const padding = 40.0;
    size = constraints.constrain(Size(maxRight + padding, maxBottom + padding));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paint edges first so they appear beneath nodes
    // _paintEdges(context.canvas, offset);
    // Then paint all children on top
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class StateGraph<S extends Object, E extends Object>
    extends MultiChildRenderObjectWidget {
  final Graph<S, E> graph;

  final GraphLayoutAlgorithm<S> algorithm;

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
  void updateRenderObject(
    BuildContext context,
    RenderStateGraph<S, E> renderObject,
  ) {
    renderObject.graph = graph;
    renderObject.algorithm = algorithm;
  }
}
