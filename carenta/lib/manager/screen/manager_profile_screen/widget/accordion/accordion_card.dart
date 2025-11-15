import 'package:flutter/material.dart';

/// AccordionCard
/// A reusable expandable card controlled externally with GlobalKey<AccordionCardController>.
class AccordionCard extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const AccordionCard({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  AccordionCardController createState() => AccordionCardController();
}

/// Public controller class
class AccordionCardController extends State<AccordionCard> {
  bool _expanded = false;

  void expand() {
    if (!_expanded && mounted) setState(() => _expanded = true);
  }

  void collapse() {
    if (_expanded && mounted) setState(() => _expanded = false);
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // ❌ CRASH SOURCE — REMOVED
          // key: PageStorageKey(widget.title),

          // ✅ SAFE: Expansion state controlled by our controller
          initiallyExpanded: _expanded,
          onExpansionChanged: (val) => setState(() => _expanded = val),

          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

          title: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF0077B6),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          children: [widget.child],
        ),
      ),
    );
  }
}
