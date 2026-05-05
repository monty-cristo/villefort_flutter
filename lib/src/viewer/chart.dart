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

/// Visualizes a state machine as an interactive node-edge graph.
///
/// The graph is built by calling [Explorer.explore] on [initial].
/// If an optional [active] is provided its node is highlighted.
class StateMachineChart<S extends Object, E extends Object>
    extends StatefulWidget {
  final S active;
  final S initial;

  final Graph<S, E> graph;

  const StateMachineChart({
    super.key,
    required this.active,
    required this.graph,
    required this.initial,
  });

  @override
  State<StateMachineChart<S, E>> createState() =>
      _StateMachineChartState<S, E>();
}

class _StateMachineChartState<S extends Object, E extends Object>
    extends State<StateMachineChart<S, E>> {
  // Result<Graph<S, E>, ExploreError<S, E>>? _result;

  Map<S, Size> _nodeSizes = const {};
  Map<S, Offset> _positions = const {};

  Size _canvasSize = Size.zero;

  static const _padding = 60.0;

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
    // final result = widget.explorer.explore(widget.initial);
    // if (result case Ok(value: final graph)) {
    final sizes = _measureNodes(widget.graph.vertices);
    final raw = _forceLayout(widget.graph, sizes);
    final normalized = _normalize(raw, sizes);
    _nodeSizes = sizes;
    _positions = normalized;
    _canvasSize = _measureCanvas(normalized, sizes);
    // }
    // setState(() => _result = result);
  }

  // ── Node size measurement ─────────────────────────────────────────────────

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

  // ── Force-directed layout (Fruchterman-Reingold) ──────────────────────────

  static Map<S, Offset> _forceLayout<S extends Object, E extends Object>(
    Graph<S, E> graph,
    Map<S, Size> sizes,
  ) {
    final nodes = graph.vertices.toList();
    final n = nodes.length;
    if (n == 0) return const {};
    if (n == 1) return {nodes[0]: Offset.zero};

    final r = 150.0 + n * 18.0;
    final pos = <S, Offset>{
      for (var i = 0; i < n; i++)
        nodes[i]: Offset(cos(2 * pi * i / n), sin(2 * pi * i / n)) * r,
    };

    const k = 130.0;
    var temp = 120.0;

    final pairs = <(S, S)>{};
    for (final e in graph.edges) {
      if (e.from != e.to) pairs.add((e.from, e.to));
    }

    for (var iter = 0; iter < 280; iter++) {
      final disp = {for (final v in nodes) v: Offset.zero};

      // Repulsion between all pairs
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          final delta = pos[nodes[i]]! - pos[nodes[j]]!;
          final d = delta.distance.clamp(1.0, 1e9);
          final force = k * k / d;
          final u = delta / d;
          disp[nodes[i]] = disp[nodes[i]]! + u * force;
          disp[nodes[j]] = disp[nodes[j]]! - u * force;
        }
      }

      // Attraction along edges
      for (final (a, b) in pairs) {
        final delta = pos[b]! - pos[a]!;
        final d = delta.distance.clamp(1.0, 1e9);
        final force = d * d / k;
        final u = delta / d;
        disp[a] = disp[a]! + u * force;
        disp[b] = disp[b]! - u * force;
      }

      for (final v in nodes) {
        final d = disp[v]!;
        final dd = d.distance.clamp(1.0, 1e9);
        pos[v] = pos[v]! + d / dd * min(dd, temp);
      }
      temp = (temp * 0.95).clamp(0.1, 1e9);
    }

    return pos;
  }

  // ── Coordinate normalization ──────────────────────────────────────────────

  static Map<S, Offset> _normalize<S>(Map<S, Offset> raw, Map<S, Size> sizes) {
    if (raw.isEmpty) return const {};
    final minX = raw.values.map((o) => o.dx).reduce(min);
    final minY = raw.values.map((o) => o.dy).reduce(min);
    final maxHW = sizes.values.map((s) => s.width / 2).reduce(max);
    final maxHH = sizes.values.map((s) => s.height / 2).reduce(max);
    final origin =
        Offset(minX, minY) - Offset(_padding + maxHW, _padding + maxHH);
    return raw.map((k, v) => MapEntry(k, v - origin));
  }

  static Size _measureCanvas<S>(Map<S, Offset> positions, Map<S, Size> sizes) {
    if (positions.isEmpty) return Size.zero;
    double maxX = 0, maxY = 0;
    for (final e in positions.entries) {
      final s = sizes[e.key]!;
      maxX = max(maxX, e.value.dx + s.width / 2);
      maxY = max(maxY, e.value.dy + s.height / 2);
    }
    return Size(maxX + _padding, maxY + _padding);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _buildViewer(widget.graph);
  }

  Widget _buildViewer(Graph<S, E> graph) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      minScale: 0.1,
      maxScale: 5,
      child: SizedBox(
        width: _canvasSize.width,
        height: _canvasSize.height,
        child: CustomPaint(
          painter: _ChartPainter<S, E>(
            graph: graph,
            positions: _positions,
            sizes: _nodeSizes,
            initial: widget.initial,
            active: widget.active,
          ),
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
  final S initial;
  final S active;

  const _ChartPainter({
    required this.graph,
    required this.positions,
    required this.sizes,
    required this.initial,
    required this.active,
  });

  @override
  bool shouldRepaint(_ChartPainter<S, E> old) =>
      old.active != active ||
      !identical(old.graph, graph) ||
      !identical(old.positions, positions);

  @override
  void paint(Canvas canvas, Size size) {
    _drawInitialArrow(canvas);
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  // ── Initial-state entry arrow ─────────────────────────────────────────────

  void _drawInitialArrow(Canvas canvas) {
    final c = positions[initial]!;
    final w = sizes[initial]!.width;
    final tip = Offset(c.dx - w / 2 - 4, c.dy);
    final start = tip - const Offset(30, 0);

    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, tip, paint);
    _arrowHead(canvas, tip, const Offset(1, 0), paint.color);
  }

  // ── Edges ─────────────────────────────────────────────────────────────────

  void _drawEdges(Canvas canvas) {
    // Group by (from, to) so we can show combined labels and detect bidirectional pairs
    final groups = <(S, S), List<Edge<S, E>>>{};
    for (final e in graph.edges) {
      groups.putIfAbsent((e.from, e.to), () => []).add(e);
    }

    for (final entry in groups.entries) {
      final (from, to) = entry.key;
      final label = entry.value.map((e) => e.event.toString()).join('\n');
      if (from == to) {
        _selfLoop(canvas, from, label);
      } else {
        _drawEdge(
          canvas,
          from,
          to,
          label,
          curved: groups.containsKey((to, from)),
        );
      }
    }
  }

  void _selfLoop(Canvas canvas, S state, String label) {
    final c = positions[state]!;
    final s = sizes[state]!;

    // Arc above the node: exits top-left, re-enters top-right
    final exitPt = c + Offset(-s.width / 4, -s.height / 2 - 4);
    final entryPt = c + Offset(s.width / 4, -s.height / 2 - 4);
    const loopH = 50.0;
    final ctrl1 = exitPt + Offset(-22, -loopH);
    final ctrl2 = entryPt + Offset(22, -loopH);

    final paint = Paint()
      ..color = Colors.black45
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(exitPt.dx, exitPt.dy)
      ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, entryPt.dx, entryPt.dy);
    canvas.drawPath(path, paint);

    final arrowDir = (entryPt - ctrl2).normalize();
    _arrowHead(canvas, entryPt, arrowDir, paint.color);

    // Label centred above the loop
    final labelPos = c - Offset(0, s.height / 2 + loopH * 0.55 + 6);
    _drawLabel(canvas, label, labelPos);
  }

  void _drawEdge(
    Canvas canvas,
    S from,
    S to,
    String label, {
    required bool curved,
  }) {
    final pF = positions[from]!;
    final pT = positions[to]!;
    final dir = pT - pF;
    if (dir.distance < 1) return;

    final perp = Offset(-dir.dy, dir.dx).normalize();
    const curvature = 48.0;
    final ctrl = (pF + pT) / 2 + (curved ? perp * curvature : Offset.zero);

    final startDir = (ctrl - pF).normalize();
    final endDir = (ctrl - pT).normalize();
    final p0 = _rectBorder(pF, startDir, sizes[from]!);
    final p1 = _rectBorder(pT, endDir, sizes[to]!);

    final paint = Paint()
      ..color = Colors.black45
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (curved) {
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, p1.dx, p1.dy);
      canvas.drawPath(path, paint);
      _arrowHead(canvas, p1, (p1 - ctrl).normalize(), paint.color);
      _drawLabel(canvas, label, _quadMid(p0, ctrl, p1));
    } else {
      canvas.drawLine(p0, p1, paint);
      _arrowHead(canvas, p1, (p1 - p0).normalize(), paint.color);
      _drawLabel(canvas, label, (p0 + p1) / 2);
    }
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

    // Outer border
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

    // Double-border for the initial state
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

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: state.toString(),
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

  /// Intersection of a ray from [center] in [dir] (normalized) with the
  /// node's bounding rectangle (expanded by 4 px on each side).
  Offset _rectBorder(Offset center, Offset dir, Size size) {
    final hw = size.width / 2 + 4;
    final hh = size.height / 2 + 4;
    var t = double.infinity;
    if (dir.dx.abs() > 1e-9) t = min(t, hw / dir.dx.abs());
    if (dir.dy.abs() > 1e-9) t = min(t, hh / dir.dy.abs());
    return center + dir * t;
  }

  Offset _quadMid(Offset p0, Offset ctrl, Offset p1) => Offset(
    0.25 * p0.dx + 0.5 * ctrl.dx + 0.25 * p1.dx,
    0.25 * p0.dy + 0.5 * ctrl.dy + 0.25 * p1.dy,
  );

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _edgeLabelStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 140);

    final origin = center - Offset(tp.width / 2, tp.height / 2);

    // White pill background for readability
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: tp.width + 8,
          height: tp.height + 4,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withAlpha(220),
    );

    tp.paint(canvas, origin);
  }
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension on Offset {
  Offset normalize() {
    final d = distance;
    return d < 1e-9 ? this : this / d;
  }
}
