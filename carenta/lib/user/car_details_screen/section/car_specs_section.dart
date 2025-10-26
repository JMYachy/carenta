import 'package:flutter/material.dart';

class CarSpecsSection extends StatelessWidget {
  final Map<String, dynamic> car;
  const CarSpecsSection({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final color = (car['color'] ?? '—').toString();
    final milage = (car['milage'] ?? '—').toString();
    final transmission = (car['transmission'] ?? '—').toString();
    final fuel = (car['fueltype'] ?? '—').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _SpecRow(
                icon: Icons.color_lens_rounded,
                label: 'Color',
                value: color,
              ),
              const Divider(height: 20),
              _SpecRow(
                icon: Icons.speed_rounded,
                label: 'Milage',
                value: milage,
              ),
              const Divider(height: 20),
              _SpecRow(
                icon: Icons.settings_rounded,
                label: 'Transmission',
                value: transmission,
              ),
              const Divider(height: 20),
              _SpecRow(
                icon: Icons.local_gas_station_rounded,
                label: 'Fuel Type',
                value: fuel,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: child,
    );
  }
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final val = value.isEmpty ? '—' : value;
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF5722)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(val, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
