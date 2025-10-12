import 'package:flutter/material.dart';
class PaymentMethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0077B6)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFFFF5722))
          : const Icon(Icons.circle_outlined, color: Colors.black26),
      onTap: onTap,
    );
  }
}
