import 'package:flutter/material.dart';

class BookingInfoSection extends StatelessWidget {
  final String title;
  final List<InfoRow> rows;

  const BookingInfoSection({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final r in rows) ...[
            _RowTile(icon: r.icon, label: r.label, value: r.value),
            if (r != rows.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow({required this.icon, required this.label, required this.value});
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _RowTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.labelLarge),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
