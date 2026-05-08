import 'dart:async';

import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';

import '../recorder/recording.dart';
import 'algorithm/sugiyama.dart';
import 'chart.dart';
import 'widgets/node.dart';

class MachineReplayViewer<S extends Object, E extends Object>
    extends StatefulWidget {
  final String title;
  final MachineRecording<S, E> recording;
  final Widget Function(S state, bool active) builder;

  const MachineReplayViewer({
    super.key,
    required this.title,
    required this.recording,
    required this.builder,
  });

  @override
  State<MachineReplayViewer<S, E>> createState() =>
      _MachineReplayViewerState<S, E>();
}

class _MachineReplayViewerState<S extends Object, E extends Object>
    extends State<MachineReplayViewer<S, E>> {
  late final Graph<S, E> _rawGraph;

  int _step = 0;
  bool _isPlaying = false;
  Timer? _timer;

  S get _current => widget.recording.stateAt(_step);
  int get _total => widget.recording.length;

  @override
  void initState() {
    super.initState();
    final recording = widget.recording;
    final vertices = <S>{recording.initial};
    final edges = <Edge<S, E>>{};
    for (var i = 0; i < recording.transitions.length; i++) {
      final (event, to) = recording.transitions[i];
      final from = recording.stateAt(i);
      vertices.add(to);
      edges.add(Edge(from: from, event: event, to: to));
    }
    _rawGraph = Graph(vertices: vertices, edges: edges);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _stepBack() {
    _pause();
    if (_step > 0) setState(() => _step--);
  }

  void _stepForward() {
    _pause();
    if (_step < _total) setState(() => _step++);
  }

  void _togglePlay() {
    if (_isPlaying) {
      _pause();
    } else {
      if (_step == _total) setState(() => _step = 0);
      setState(() => _isPlaying = true);
      _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
        if (_step < _total) {
          setState(() => _step++);
        } else {
          _pause();
        }
      });
    }
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (_isPlaying) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NodeColors.sectionBg,
      appBar: AppBar(title: Text(widget.title)),
      body: Row(
        children: [
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              minScale: 0.1,
              maxScale: 5,
              child: StateGraph<S, E>(
                graph: _rawGraph,
                algorithm: LayoutAlgorithmSugiyama(),
                builder: (state) => widget.builder(state, state == _current),
              ),
            ),
          ),
          _ReplayPanel<S, E>(
            step: _step,
            total: _total,
            current: _current,
            recording: widget.recording,
            isPlaying: _isPlaying,
            onBack: _stepBack,
            onForward: _stepForward,
            onTogglePlay: _togglePlay,
            onSeek: (step) {
              _pause();
              setState(() => _step = step);
            },
          ),
        ],
      ),
    );
  }
}

// ── Replay panel ──────────────────────────────────────────────────────────────

class _ReplayPanel<S extends Object, E extends Object> extends StatelessWidget {
  final int step;
  final int total;
  final S current;
  final MachineRecording<S, E> recording;
  final bool isPlaying;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onTogglePlay;
  final void Function(int) onSeek;

  const _ReplayPanel({
    required this.step,
    required this.total,
    required this.current,
    required this.recording,
    required this.isPlaying,
    required this.onBack,
    required this.onForward,
    required this.onTogglePlay,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── State header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current State',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  current.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Playback controls ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: step.toDouble(),
                    min: 0,
                    max: total.toDouble(),
                    divisions: total == 0 ? null : total,
                    onChanged: total == 0 ? null : (v) => onSeek(v.round()),
                  ),
                ),
                // Step counter
                Center(
                  child: Text(
                    'Step $step / $total',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.outline),
                  ),
                ),
                const SizedBox(height: 8),
                // Transport buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      tooltip: 'Step back',
                      onPressed: step > 0 ? onBack : null,
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: total == 0 ? null : onTogglePlay,
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      tooltip: 'Step forward',
                      onPressed: step < total ? onForward : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Transition that led to current state ──────────────────────
          if (step > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Via Event',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 13, color: cs.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recording.transitions[step - 1].$1.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          // ── Full transition log ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              'Recording',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.outline,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: total == 0
                ? Center(
                    child: Text(
                      'No transitions recorded',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: total,
                    itemBuilder: (context, i) {
                      final (event, state) = recording.transitions[i];
                      final isCurrent = i == step - 1;
                      return _TransitionRow(
                        index: i + 1,
                        event: event,
                        state: state,
                        isCurrent: isCurrent,
                        onTap: () => onSeek(i + 1),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransitionRow<S extends Object, E extends Object>
    extends StatelessWidget {
  final int index;
  final E event;
  final S state;
  final bool isCurrent;
  final VoidCallback onTap;

  const _TransitionRow({
    required this.index,
    required this.event,
    required this.state,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isCurrent ? cs.primaryContainer.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$index',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.outline),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 11, color: cs.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      state.toString(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.circle, size: 6, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
