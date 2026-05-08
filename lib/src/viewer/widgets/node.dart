import 'package:flutter/material.dart';
import 'package:villefort/villefort.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class ChipData {
  final String name;
  final IconData icon;

  const ChipData({required this.name, required this.icon});
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
  final bool active;

  const StatelessNodeCard({super.key, required this.title, this.active = false});

  @override
  Widget build(BuildContext context) {
    return NodeCardContainer(
      active: active,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
    );
  }
}

class NodeCardContainer extends StatelessWidget {
  final Option<double> width;
  final bool active;
  final Widget child;

  const NodeCardContainer({
    super.key,
    this.width = const None(),
    this.active = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: switch (width) {
        Some(:final value) => value,
        None() => null,
      },
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NodeColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? NodeColors.btnBlue : NodeColors.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          if (active)
            BoxShadow(
              color: NodeColors.btnBlue.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 3,
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

  final Option<List<ChipData>> actions;
  final Option<List<ChipData>> actors;

  final Option<String> invocation;
  final bool active;

  const ProcessNodeCard({
    super.key,
    required this.title,
    this.description = const None(),
    this.actions = const None(),
    this.invocation = const None(),
    this.actors = const None(),
    this.active = false,
  });

  @override
  State<ProcessNodeCard> createState() => _ProcessNodeCardState();
}

class _ProcessNodeCardState extends State<ProcessNodeCard> {
  bool _isCollapsed = false;
  bool _actionsExpanded = true;
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
      children.add(_InvocationItem(label: value));
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
        None<String>() => const Some(300),
        Some<String>() => const Some(300),
      },
      active: widget.active,
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
    return GestureDetector(
      onTap: onCollapseToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
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
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: NodeColors.textGray,
                size: 20,
              ),
            ),
          ],
        ),
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
  final List<ChipData> actions;

  const _ActionsList({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: actions
            .map(
              (a) => _Chip(
                label: a.name,
                icon: a.icon,
                iconColor: NodeColors.actionIconRed,
              ),
            )
            .toList(),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1C10),
        border: Border(left: BorderSide(color: NodeColors.codeGreen, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INVOCATION',
            style: TextStyle(
              color: NodeColors.headerOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  color: NodeColors.codeGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: NodeColors.codeGreen,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Actors List ─────────────────────────────────────────────────────────────

class _ActorsList extends StatelessWidget {
  final List<ChipData> actors;

  const _ActorsList({required this.actors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: actors
            .map(
              (a) => _Chip(
                label: a.name,
                icon: a.icon,
                iconColor: NodeColors.textGray,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _Chip({
    required this.label,
    required this.icon,
    required this.iconColor,
  });

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          Text(
            label,
            style: const TextStyle(color: NodeColors.textWhite, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
