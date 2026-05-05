import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';

import 'chart.dart';

class MachineViewer<S extends Object, E extends Object> extends StatefulWidget {
  final String title;

  final S initial;

  final TransitionFunction<S, E> transition;

  final GenerateEventFactory<S, E> generate;

  /// Optionally returns a highlight color for an event's arrow and badge.
  /// Return null to use the default grey styling.
  final Color? Function(E)? eventColor;

  /// When provided, states for which this returns true are collapsed into a
  /// single node. The representative is the first reachable state of the group
  /// (DFS order from [initial]). The active node always displays the actual
  /// current state's label.
  final bool Function(S a, S b)? sameGroup;

  const MachineViewer({
    super.key,
    required this.title,
    required this.initial,
    required this.transition,
    required this.generate,
    this.eventColor,
    this.sameGroup,
  });

  @override
  State<MachineViewer<S, E>> createState() => _MachineViewerState<S, E>();
}

class _MachineViewerState<S extends Object, E extends Object>
    extends State<MachineViewer<S, E>> {
  late S _current = widget.initial;

  // The full explored graph.
  late final Graph<S, E> _rawGraph;

  // Either the condensed graph (when sameGroup is provided) or _rawGraph.
  late final Graph<S, E> _displayGraph;

  // Maps every raw state → its group representative. Null when no grouping.
  late final Map<S, S>? _repOf;

  final List<(E, S)> _history = [];

  @override
  void initState() {
    super.initState();

    _rawGraph = Explorer(
      generate: widget.generate,
      transition: widget.transition,
    ).explore(widget.initial);

    if (widget.sameGroup case final sg?) {
      final (condensed, repOf) = _condense(_rawGraph, sg);
      _displayGraph = condensed;
      _repOf = repOf;
    } else {
      _displayGraph = _rawGraph;
      _repOf = null;
    }
  }

  /// Groups [raw] vertices by [sameGroup] and returns the condensed graph plus
  /// a mapping from every raw state to its representative.
  ///
  /// The representative of each group is the first state of that group
  /// encountered in DFS order (i.e. the iteration order of [raw.vertices]).
  static (Graph<S, E>, Map<S, S>) _condense<S extends Object, E extends Object>(
    Graph<S, E> raw,
    bool Function(S, S) sameGroup,
  ) {
    final reps = <S>[];
    final repOf = <S, S>{};

    for (final v in raw.vertices) {
      S? found;
      for (final r in reps) {
        if (sameGroup(v, r)) {
          found = r;
          break;
        }
      }
      if (found != null) {
        repOf[v] = found;
      } else {
        repOf[v] = v;
        reps.add(v);
      }
    }

    final edges = <Edge<S, E>>{};
    for (final e in raw.edges) {
      edges.add(Edge(from: repOf[e.from]!, event: e.event, to: repOf[e.to]!));
    }

    return (Graph(vertices: reps.toSet(), edges: edges), repOf);
  }

  void _send(E event) {
    final result = widget.transition(_current, event);

    if (result case Some(value: final next)) {
      setState(() {
        _history.insert(0, (event, next));
        _current = next;
      });
    }
  }

  void _reset() {
    setState(() {
      _current = widget.initial;
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repOf = _repOf;
    final activeRep = repOf?[_current] ?? _current;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Chart ────────────────────────────────────────────────────────
          Expanded(
            child: StateMachineChart<S, E>(
              graph: _displayGraph,
              initial: repOf?[widget.initial] ?? widget.initial,
              active: activeRep,
              onEvent: _send,
              eventColor: widget.eventColor,
              stateLabel: repOf != null
                  ? (rep) => rep == activeRep
                        ? _current.toString()
                        : rep.toString()
                  : null,
            ),
          ),
          // ── Inspector panel ───────────────────────────────────────────────
          Container(
            width: 272,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StateHeader(state: _current),
                const Divider(height: 1),
                _EventPanel(
                  state: _current,
                  onSend: _send,
                  generate: widget.generate,
                ),
                const Divider(height: 1),
                Expanded(child: _HistoryPanel(history: _history)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── State header ──────────────────────────────────────────────────────────────

class _StateHeader<S extends Object> extends StatelessWidget {
  final S state;

  const _StateHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current State',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event panel ───────────────────────────────────────────────────────────────

class _EventPanel<S extends Object, E extends Object> extends StatelessWidget {
  final S state;

  final void Function(E) onSend;

  final GenerateEventFactory<S, E> generate;

  const _EventPanel({
    required this.state,
    required this.onSend,
    required this.generate,
  });

  @override
  Widget build(BuildContext context) {
    final events = generate(state);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Send Event',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton(
                onPressed: () => onSend(event),
                child: Text(event.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History panel ─────────────────────────────────────────────────────────────

class _HistoryPanel<S extends Object, E extends Object>
    extends StatelessWidget {
  final List<(E, S)> history;

  const _HistoryPanel({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Text(
            'History',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? Center(
                  child: Text(
                    'No events sent yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: history.length,
                  itemBuilder: (context, i) {
                    final (event, state) = history[i];
                    
                    return _HistoryEntry(
                      event: event,
                      state: state,
                      index: history.length - i,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HistoryEntry<S extends Object, E extends Object>
    extends StatelessWidget {
  final E event;
  final S state;
  final int index;

  const _HistoryEntry({
    required this.event,
    required this.state,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event row
          Row(
            children: [
              Icon(Icons.arrow_forward, size: 12, color: cs.primary),
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
              Text(
                '#$index',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
          // Resulting state row
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              state.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
