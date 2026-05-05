import 'dart:math';

import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';

const _nodeLabelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

const _edgeLabelStyle = TextStyle(
  fontSize: 11,
  color: Colors.black54,
  height: 1.2,
);

const _nodeHPad = 16.0;
const _nodeVPad = 10.0;
const _nodeMinWidth = 80.0;
const _nodeMinHeight = 38.0;
const _nodeMaxWidth = 220.0;
const _cornerRadius = 8.0;
const _arrowLen = 10.0;
const _arrowHalfAngle = 0.42; // radians

const _colGap = 80.0;
const _rowGap = 40.0;
const _padding = 60.0;
const _selfLoopH = 36.0;
const _selfLoopHalfW = 18.0;
const _backRouteExtra = 44.0; // clearance below nodes for back-edge routing

class _BadgeInfo<S extends Object, E extends Object> {
  final E event;
  final Offset center;
  final S from;
  final S to;

  const _BadgeInfo({
    required this.event,
    required this.center,
    required this.from,
    required this.to,
  });
}

/// Visualizes a state machine as an interactive node-edge graph.
///
/// Nodes are arranged left-to-right by BFS rank from [initial].
/// Edges are routed orthogonally (no diagonals).
/// Tapping an edge badge calls [onEvent] with the corresponding event.
/// [eventColor] optionally returns a highlight color per event; returning
/// null falls back to the default grey.
/// [stateLabel] overrides the text shown inside each node; defaults to
/// [Object.toString]. Use this when grouped states need a dynamic label.
class StateMachineChart<S extends Object, E extends Object>
    extends StatefulWidget {
  final S active;
  final S initial;
  final Graph<S, E> graph;
  final void Function(E)? onEvent;
  final Color? Function(E)? eventColor;
  final String Function(S)? stateLabel;

  const StateMachineChart({
    super.key,
    required this.active,
    required this.graph,
    required this.initial,
    this.onEvent,
    this.eventColor,
    this.stateLabel,
  });

  @override
  State<StateMachineChart<S, E>> createState() =>
      _StateMachineChartState<S, E>();
}

class _StateMachineChartState<S extends Object, E extends Object>
    extends State<StateMachineChart<S, E>> {
  Map<S, Size> _nodeSizes = const {};
  Map<S, Offset> _positions = const {};
  Map<S, int> _ranks = const {};
  Size _canvasSize = Size.zero;
  List<_BadgeInfo<S, E>> _badges = [];

  @override
  void initState() {
    super.initState();
    _buildLayout();
  }

  @override
  void didUpdateWidget(covariant StateMachineChart<S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.graph, widget.graph) ||
        oldWidget.initial != widget.initial) {
      _buildLayout();
    }
  }

  void _buildLayout() {
    final sizes = _measureNodes(widget.graph.vertices);
    final (positions, ranks, canvasSize) = _hierarchicalLayout(
      widget.graph,
      widget.initial,
      sizes,
    );
    _nodeSizes = sizes;
    _positions = positions;
    _ranks = ranks;
    _canvasSize = canvasSize;
    _badges = _computeBadges(widget.graph, positions, ranks, sizes);
  }

  // ── Node measurement ──────────────────────────────────────────────────────

  static Map<S, Size> _measureNodes<S>(Set<S> vertices) {
    return {for (final v in vertices) v: _nodeSize(v.toString())};
  }

  static Size _nodeSize(String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: _nodeLabelStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _nodeMaxWidth - _nodeHPad * 2);
    return Size(
      (tp.width + _nodeHPad * 2).clamp(_nodeMinWidth, _nodeMaxWidth),
      (tp.height + _nodeVPad * 2).clamp(_nodeMinHeight, 80.0),
    );
  }

  // ── Hierarchical layout ───────────────────────────────────────────────────

  static (Map<S, Offset>, Map<S, int>, Size)
  _hierarchicalLayout<S extends Object, E extends Object>(
    Graph<S, E> graph,
    S initial,
    Map<S, Size> sizes,
  ) {
    final ranks = _assignRanks(graph, initial);

    // Group nodes by rank in BFS discovery order
    final byRank = <int, List<S>>{};
    for (final entry in ranks.entries) {
      byRank.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    if (byRank.isEmpty) return (const {}, const {}, Size.zero);

    final maxRank = byRank.keys.reduce(max);

    // Column widths: max node width per rank
    final colWidths = <int, double>{
      for (final e in byRank.entries)
        e.key: e.value.map((n) => sizes[n]!.width).reduce(max),
    };

    // Column center x positions
    final colX = <int, double>{};
    var x = _padding;
    for (var r = 0; r <= maxRank; r++) {
      final w = colWidths[r] ?? _nodeMinWidth;
      colX[r] = x + w / 2;
      x += w + _colGap;
    }

    // Vertical centering: all columns share the same total height envelope
    double maxColH = 0;
    for (final nodes in byRank.values) {
      final h = nodes.fold(0.0, (a, n) => a + sizes[n]!.height) +
          (nodes.length - 1) * _rowGap;
      maxColH = max(maxColH, h);
    }

    final positions = <S, Offset>{};
    for (final entry in byRank.entries) {
      final rank = entry.key;
      final nodes = entry.value;
      final colH = nodes.fold(0.0, (a, n) => a + sizes[n]!.height) +
          (nodes.length - 1) * _rowGap;
      var y = _padding + (maxColH - colH) / 2;
      for (final node in nodes) {
        final h = sizes[node]!.height;
        positions[node] = Offset(colX[rank]!, y + h / 2);
        y += h + _rowGap;
      }
    }

    // Canvas size: extra vertical room below nodes for back-edge routing
    double maxX = 0, maxY = 0;
    for (final e in positions.entries) {
      final s = sizes[e.key]!;
      maxX = max(maxX, e.value.dx + s.width / 2);
      maxY = max(maxY, e.value.dy + s.height / 2);
    }
    final canvasSize = Size(maxX + _padding, maxY + _backRouteExtra + _padding);

    return (positions, ranks, canvasSize);
  }

  // BFS rank assignment from initial. Disconnected nodes get ranks after max.
  static Map<S, int> _assignRanks<S extends Object, E extends Object>(
    Graph<S, E> graph,
    S initial,
  ) {
    final ranks = <S, int>{initial: 0};
    final queue = <S>[initial];
    var head = 0;

    while (head < queue.length) {
      final node = queue[head++];
      final rank = ranks[node]!;
      for (final edge in graph.edges) {
        if (edge.from == node &&
            edge.to != node &&
            !ranks.containsKey(edge.to)) {
          ranks[edge.to] = rank + 1;
          queue.add(edge.to);
        }
      }
    }

    var next = ranks.isEmpty ? 0 : ranks.values.reduce(max) + 1;
    for (final v in graph.vertices) {
      if (!ranks.containsKey(v)) ranks[v] = next++;
    }

    return ranks;
  }

  // ── Badge position computation ────────────────────────────────────────────

  static List<_BadgeInfo<S, E>>
  _computeBadges<S extends Object, E extends Object>(
    Graph<S, E> graph,
    Map<S, Offset> positions,
    Map<S, int> ranks,
    Map<S, Size> sizes,
  ) {
    final groups = <(S, S), List<Edge<S, E>>>{};
    for (final e in graph.edges) {
      groups.putIfAbsent((e.from, e.to), () => []).add(e);
    }

    final maxBottom = positions.isEmpty
        ? 0.0
        : positions.entries
              .map((e) => e.value.dy + sizes[e.key]!.height / 2)
              .reduce(max);
    final backRouteY = maxBottom + _backRouteExtra / 2;

    final result = <_BadgeInfo<S, E>>[];
    for (final entry in groups.entries) {
      final (from, to) = entry.key;
      final Offset rawCenter;

      if (from == to) {
        final c = positions[from]!;
        final s = sizes[from]!;
        rawCenter = Offset(c.dx, c.dy - s.height / 2 - _selfLoopH);
      } else if ((ranks[from] ?? 0) < (ranks[to] ?? 0)) {
        // Forward edge — midpoint of the vertical segment of the S-bend
        final pF = positions[from]!;
        final pT = positions[to]!;
        final sF = sizes[from]!;
        final sT = sizes[to]!;
        final p0 = Offset(pF.dx + sF.width / 2, pF.dy);
        final p3 = Offset(pT.dx - sT.width / 2, pT.dy);
        final midX = (p0.dx + p3.dx) / 2;
        rawCenter = (p0.dy - p3.dy).abs() < 1
            ? (p0 + p3) / 2
            : Offset(midX, (p0.dy + p3.dy) / 2);
      } else {
        // Back edge — midpoint along the horizontal routing segment below nodes
        final pF = positions[from]!;
        final pT = positions[to]!;
        rawCenter = Offset((pF.dx + pT.dx) / 2, backRouteY);
      }

      for (final edge in entry.value) {
        final badgeSize = _estimateBadgeSize(edge.event.toString());
        final center = _avoidNodes(rawCenter, badgeSize, positions, sizes);
        result.add(
          _BadgeInfo(event: edge.event, center: center, from: from, to: to),
        );
      }
    }
    return result;
  }

  // Estimates the rendered size of a badge based on its text.
  // Matches the widget's padding: symmetric(horizontal: 10, vertical: 4).
  static Size _estimateBadgeSize(String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: _edgeLabelStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 200);
    return Size(tp.width + 20, tp.height + 8);
  }

  static const _minBadgeNodeGap = 6.0;

  // Shifts the badge center vertically until it has at least _minBadgeNodeGap
  // clearance from every node. Prefers the direction of least displacement.
  static Offset _avoidNodes<S>(
    Offset center,
    Size badgeSize,
    Map<S, Offset> positions,
    Map<S, Size> sizes,
  ) {
    var y = center.dy;

    for (var iter = 0; iter < 20; iter++) {
      final badgeRect = Rect.fromCenter(
        center: Offset(center.dx, y),
        width: badgeSize.width,
        height: badgeSize.height,
      );

      Rect? hit;
      for (final e in positions.entries) {
        final nodeRect = Rect.fromCenter(
          center: e.value,
          width: sizes[e.key]!.width + _minBadgeNodeGap * 2,
          height: sizes[e.key]!.height + _minBadgeNodeGap * 2,
        );
        if (badgeRect.overlaps(nodeRect)) {
          hit = nodeRect;
          break;
        }
      }

      if (hit == null) break;

      final yAbove = hit.top - badgeSize.height / 2;
      final yBelow = hit.bottom + badgeSize.height / 2;
      y = (y - yAbove).abs() <= (y - yBelow).abs() ? yAbove : yBelow;
    }

    return Offset(center.dx, y);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      minScale: 0.1,
      maxScale: 5,
      child: SizedBox(
        width: _canvasSize.width,
        height: _canvasSize.height,
        child: Stack(
          children: [
            CustomPaint(
              size: _canvasSize,
              painter: _ChartPainter<S, E>(
                graph: widget.graph,
                positions: _positions,
                sizes: _nodeSizes,
                ranks: _ranks,
                initial: widget.initial,
                active: widget.active,
                eventColor: widget.eventColor,
                stateLabel: widget.stateLabel ?? (s) => s.toString(),
              ),
            ),
            for (final badge in _badges)
              Positioned(
                left: badge.center.dx,
                top: badge.center.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: MouseRegion(
                    cursor: widget.onEvent != null
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    child: GestureDetector(
                      onTap: widget.onEvent != null
                          ? () => widget.onEvent!(badge.event)
                          : null,
                      child: _EdgeBadge(
                        label: badge.event.toString(),
                        color: widget.eventColor?.call(badge.event),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ChartPainter<S extends Object, E extends Object> extends CustomPainter {
  final Graph<S, E> graph;
  final Map<S, Offset> positions;
  final Map<S, Size> sizes;
  final Map<S, int> ranks;
  final S initial;
  final S active;
  final Color? Function(E)? eventColor;
  final String Function(S) stateLabel;
  // Cached label for the active node so shouldRepaint catches label-only changes
  // (e.g. when two grouped states share the same representative but differ in toString).
  final String activeLabel;

  _ChartPainter({
    required this.graph,
    required this.positions,
    required this.sizes,
    required this.ranks,
    required this.initial,
    required this.active,
    required this.stateLabel,
    this.eventColor,
  }) : activeLabel = stateLabel(active);

  @override
  bool shouldRepaint(_ChartPainter<S, E> old) =>
      old.active != active ||
      old.activeLabel != activeLabel ||
      !identical(old.graph, graph) ||
      !identical(old.positions, positions);

  @override
  void paint(Canvas canvas, Size size) {
    // Routing level below all nodes for back edges
    final maxBottom = positions.isEmpty
        ? 0.0
        : positions.entries
              .map((e) => e.value.dy + sizes[e.key]!.height / 2)
              .reduce(max);
    final backRouteY = maxBottom + _backRouteExtra / 2;

    _drawInitialArrow(canvas);
    _drawEdges(canvas, backRouteY);
    _drawNodes(canvas);
  }

  // ── Initial-state entry arrow ─────────────────────────────────────────────

  void _drawInitialArrow(Canvas canvas) {
    final c = positions[initial]!;
    final w = sizes[initial]!.width;
    final tip = Offset(c.dx - w / 2, c.dy);
    final start = tip - const Offset(30, 0);

    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, tip, paint);
    _arrowHead(canvas, tip, const Offset(1, 0), paint.color);
  }

  // ── Edges ─────────────────────────────────────────────────────────────────

  // Returns the first non-null color from eventColor across a group of events,
  // falling back to the default grey.
  Color _resolveColor(List<E> events) {
    if (eventColor != null) {
      for (final e in events) {
        final c = eventColor!(e);
        if (c != null) return c;
      }
    }
    return Colors.black45;
  }

  void _drawEdges(Canvas canvas, double backRouteY) {
    // Group edges by (from, to) so we draw one line per pair and can pick a color.
    final groups = <(S, S), List<E>>{};
    for (final e in graph.edges) {
      groups.putIfAbsent((e.from, e.to), () => []).add(e.event);
    }

    for (final entry in groups.entries) {
      final (from, to) = entry.key;
      final color = _resolveColor(entry.value);
      if (from == to) {
        _selfLoop(canvas, from, color);
      } else if ((ranks[from] ?? 0) < (ranks[to] ?? 0)) {
        _drawForwardEdge(canvas, from, to, color);
      } else {
        _drawBackEdge(canvas, from, to, backRouteY, color);
      }
    }
  }

  // Rectangular loop drawn above the node
  void _selfLoop(Canvas canvas, S state, Color color) {
    final c = positions[state]!;
    final s = sizes[state]!;

    final exitPt = Offset(c.dx - _selfLoopHalfW, c.dy - s.height / 2);
    final entryPt = Offset(c.dx + _selfLoopHalfW, c.dy - s.height / 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(exitPt.dx, exitPt.dy)
        ..lineTo(exitPt.dx, exitPt.dy - _selfLoopH)
        ..lineTo(entryPt.dx, entryPt.dy - _selfLoopH)
        ..lineTo(entryPt.dx, entryPt.dy),
      paint,
    );
    _arrowHead(canvas, entryPt, const Offset(0, 1), color);
  }

  // Forward edge: exits right of source, S-bend, enters left of target
  void _drawForwardEdge(Canvas canvas, S from, S to, Color color) {
    final pF = positions[from]!;
    final pT = positions[to]!;
    final sF = sizes[from]!;
    final sT = sizes[to]!;

    final p0 = Offset(pF.dx + sF.width / 2, pF.dy);
    final p3 = Offset(pT.dx - sT.width / 2, pT.dy);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if ((p0.dy - p3.dy).abs() < 1) {
      canvas.drawLine(p0, p3, paint);
    } else {
      final midX = (p0.dx + p3.dx) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(midX, p0.dy)
          ..lineTo(midX, p3.dy)
          ..lineTo(p3.dx, p3.dy),
        paint,
      );
    }
    _arrowHead(canvas, p3, const Offset(1, 0), color);
  }

  // Back edge: exits bottom of source, routes below all nodes, enters bottom of target
  void _drawBackEdge(Canvas canvas, S from, S to, double backRouteY, Color color) {
    final pF = positions[from]!;
    final pT = positions[to]!;
    final sF = sizes[from]!;
    final sT = sizes[to]!;

    final p0 = Offset(pF.dx, pF.dy + sF.height / 2);
    final pEnd = Offset(pT.dx, pT.dy + sT.height / 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p0.dx, backRouteY)
        ..lineTo(pEnd.dx, backRouteY)
        ..lineTo(pEnd.dx, pEnd.dy),
      paint,
    );
    _arrowHead(canvas, pEnd, const Offset(0, -1), color);
  }

  // ── Nodes ─────────────────────────────────────────────────────────────────

  void _drawNodes(Canvas canvas) {
    for (final state in graph.vertices) {
      _drawNode(canvas, state);
    }
  }

  void _drawNode(Canvas canvas, S state) {
    final c = positions[state]!;
    final s = sizes[state]!;
    final rect = Rect.fromCenter(center: c, width: s.width, height: s.height);
    final rr = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_cornerRadius),
    );

    final isActive = state == active;
    final isInitial = state == initial;

    canvas.drawRRect(
      rr,
      Paint()..color = isActive ? const Color(0xFFDBEAFE) : Colors.white,
    );

    canvas.drawRRect(
      rr,
      Paint()
        ..color = isActive
            ? const Color(0xFF1D4ED8)
            : isInitial
            ? Colors.black87
            : Colors.black38
        ..strokeWidth = isInitial ? 2.0 : 1.5
        ..style = PaintingStyle.stroke,
    );

    if (isInitial) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(4),
          const Radius.circular(_cornerRadius - 2),
        ),
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: stateLabel(state),
        style: _nodeLabelStyle.copyWith(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: s.width - _nodeHPad * 2);

    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Primitives ────────────────────────────────────────────────────────────

  void _arrowHead(Canvas canvas, Offset tip, Offset dir, Color color) {
    final a = atan2(dir.dy, dir.dx);
    final p1 =
        tip -
        Offset(cos(a - _arrowHalfAngle), sin(a - _arrowHalfAngle)) * _arrowLen;
    final p2 =
        tip -
        Offset(cos(a + _arrowHalfAngle), sin(a + _arrowHalfAngle)) * _arrowLen;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}

// ── Edge badge widget ─────────────────────────────────────────────────────────

class _EdgeBadge extends StatelessWidget {
  final String label;

  /// When non-null, the badge border, text, and arrow are drawn in this color.
  final Color? color;

  const _EdgeBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c != null ? c.withAlpha(20) : Colors.white.withAlpha(230),
        border: Border.all(
          color: c ?? Colors.black26,
          width: c != null ? 1.2 : 0.8,
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        label,
        style: _edgeLabelStyle.copyWith(
          color: c ?? Colors.black54,
          fontWeight: c != null ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}
