import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

enum ActorIconType { storage, hub }

class ActorData {
  final String name;
  final ActorIconType type;
  const ActorData({required this.name, required this.type});
}

// ─── Color Palette ───────────────────────────────────────────────────────────

class NodeColors {
  static const cardBg = Color(0xFF181929);
  static const cardBorder = Color(0xFF2A2B40);
  static const sectionBg = Color(0xFF1E1F32);
  static const sectionBorder = Color(0xFF2E3050);
  static const headerOrange = Color(0xFFFF9B5C);
  static const codeGreen = Color(0xFF4ADE80);
  static const textWhite = Color(0xFFE2E8F0);
  static const textGray = Color(0xFF7A8099);
  static const textMuted = Color(0xFF555870);
  static const chipBorder = Color(0xFF3A4060);
  static const chipBg = Color(0xFF252738);
  static const actionIconRed = Color(0xFFEF4444);
  static const divider = Color(0xFF232438);
  static const dotsBg = Color(0xFF252638);
  static const btnBlue = Color(0xFF6366F1);
  static const btnAmber = Color(0xFFFFB800);
  static const btnGreen = Color(0xFF22C55E);
  static const stateBorder = Color(0xFF374060);
  static const stateChipBg = Color(0xFF1A1B2E);
}

/* -------------------------------------------------------------------------- */
/*                                    TYPES                                   */
/* -------------------------------------------------------------------------- */

class StatelessNodeCard extends StatelessWidget {
  final String title;

  const StatelessNodeCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 300,
      color: Colors.red,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 10,
          children: [
            const _NodeIcon(),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: NodeColors.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NodeCardContainer extends StatelessWidget {
  final double width;

  final Widget child;

  const NodeCardContainer({
    super.key,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: NodeColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NodeColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

class ProcessNodeCard extends StatefulWidget {
  final String title;
  final Option<String> description;
  final Option<List<String>> actions;
  final Option<String> invocation;
  final Option<List<ActorData>> actors;

  const ProcessNodeCard({
    super.key,
    required this.title,
    this.description = const None(),
    this.actions = const None(),
    this.invocation = const None(),
    this.actors = const None(),
  });

  @override
  State<ProcessNodeCard> createState() => _ProcessNodeCardState();
}

class _ProcessNodeCardState extends State<ProcessNodeCard> {
  bool _isCollapsed = false;
  bool _actionsExpanded = true;
  bool _invocationExpanded = true;
  bool _actorsExpanded = true;

  List<Widget> _buildBody() {
    final children = <Widget>[];

    if (widget.description case Some(:final value)) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(
            value,
            style: const TextStyle(
              color: NodeColors.textGray,
              fontSize: 12.5,
              height: 1.55,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
      children.add(_Divider());
    }

    if (widget.actions case Some(:final value)) {
      children.add(
        _CollapsibleSection(
          title: 'Actions',
          expanded: _actionsExpanded,
          onToggle: () => setState(() => _actionsExpanded = !_actionsExpanded),
          child: _ActionsList(actions: value),
        ),
      );
    }

    if (widget.invocation case Some(:final value)) {
      if (widget.actions.isSome()) children.add(_Divider());
      children.add(
        _CollapsibleSection(
          title: 'Invocation',
          expanded: _invocationExpanded,
          onToggle: () =>
              setState(() => _invocationExpanded = !_invocationExpanded),
          child: _InvocationItem(label: value),
        ),
      );
    }

    if (widget.actors case Some(:final value)) {
      if (widget.actions.isSome() || widget.invocation.isSome()) {
        children.add(_Divider());
      }
      children.add(
        _CollapsibleSection(
          title: 'Actors',
          expanded: _actorsExpanded,
          onToggle: () => setState(() => _actorsExpanded = !_actorsExpanded),
          child: _ActorsList(actors: value),
        ),
      );
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return NodeCardContainer(
      width: switch (widget.description) {
        None<String>() => 300,
        Some<String>() => 480,
      },
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          _Header(
            title: widget.title,
            isCollapsed: _isCollapsed,
            onCollapseToggle: () =>
                setState(() => _isCollapsed = !_isCollapsed),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: .topCenter,
            child: switch (_isCollapsed) {
              true => const SizedBox.shrink(),
              false => Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: _buildBody(),
              ),
            },
          ),
        ],
      ),
    );
  }
}

// ─── Node Icon ───────────────────────────────────────────────────────────────

class _NodeIcon extends StatelessWidget {
  const _NodeIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: NodeColors.dotsBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.storage_rounded,
        color: NodeColors.textWhite,
        size: 17,
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final bool isCollapsed;
  final VoidCallback onCollapseToggle;

  const _Header({
    required this.title,
    required this.isCollapsed,
    required this.onCollapseToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        spacing: 10,
        children: [
          const _NodeIcon(),
          Expanded(
            child: GestureDetector(
              onTap: onCollapseToggle,
              behavior: .opaque,
              child: Text(
                title,
                style: const TextStyle(
                  color: NodeColors.textWhite,
                  fontSize: 15,
                  fontWeight: .w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCollapseToggle,
            child: AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: NodeColors.textGray,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: NodeColors.divider);
}

// ─── Collapsible Section ─────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        // Section header
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: NodeColors.headerOrange,
                    fontSize: 11.5,
                    fontWeight: .w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Icon(
                  switch (expanded) {
                    true => Icons.keyboard_arrow_up,
                    false => Icons.keyboard_arrow_down,
                  },
                  color: NodeColors.headerOrange,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // Section content
        if (expanded) child,
      ],
    );
  }
}

// ─── Actions List ─────────────────────────────────────────────────────────────

class _ActionsList extends StatelessWidget {
  final List<String> actions;
  const _ActionsList({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        mainAxisSize: .min,
        children: actions.map((action) => _ActionItem(label: action)).toList(),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  const _ActionItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        spacing: 7,
        children: [
          const Icon(
            Icons.settings_rounded,
            color: NodeColors.actionIconRed,
            size: 13,
          ),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: NodeColors.textWhite,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Invocation Item ─────────────────────────────────────────────────────────

class _InvocationItem extends StatelessWidget {
  final String label;

  const _InvocationItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        spacing: 7,
        children: [
          const Text(
            '<>',
            style: TextStyle(
              color: NodeColors.codeGreen,
              fontSize: 10,
              fontWeight: .w600,
              fontFamily: 'monospace',
            ),
          ),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: NodeColors.codeGreen,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actors List ─────────────────────────────────────────────────────────────

class _ActorsList extends StatelessWidget {
  final List<ActorData> actors;
  const _ActorsList({required this.actors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: actors.map((a) => _ActorChip(actor: a)).toList(),
      ),
    );
  }
}

class _ActorChip extends StatelessWidget {
  final ActorData actor;
  const _ActorChip({required this.actor});

  IconData get _icon {
    return switch (actor.type) {
      .storage => Icons.storage_rounded,
      .hub => Icons.hub_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: NodeColors.chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NodeColors.chipBorder, width: 1),
      ),
      child: Row(
        spacing: 6,
        mainAxisSize: .min,
        children: [
          Icon(_icon, color: NodeColors.textGray, size: 13),
          Text(
            actor.name,
            style: const TextStyle(color: NodeColors.textWhite, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
