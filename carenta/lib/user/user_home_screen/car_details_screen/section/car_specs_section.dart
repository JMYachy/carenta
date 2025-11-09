import 'package:flutter/material.dart';

class CarSpecsSection extends StatelessWidget {
  final Map<String, dynamic> car;

  const CarSpecsSection({super.key, required this.car});

  String _readSpec(List<String> keys) {
    for (final k in keys) {
      final v = car[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    print('🧠 CarSpecsSection got car: $car');
    final color = _readSpec(['color']);
    final milage = _readSpec(['milage', 'mileage', 'odometer']);
    final transmission = _readSpec(['transmission']);
    final fuel = _readSpec(['fueltype', 'fuel_type']);
    final seats = _readSpec(['seatingcap', 'seating_capacity']);
    final type = _readSpec(['type', 'car_type']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Specifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _SpecRow(icon: Icons.color_lens_rounded, label: 'Color', value: color),
              _SpecRow(icon: Icons.speed_rounded, label: 'Milage', value: milage),
              _SpecRow(icon: Icons.settings_rounded, label: 'Transmission', value: transmission),
              _SpecRow(icon: Icons.local_gas_station_rounded, label: 'Fuel Type', value: fuel),
              _SpecRow(icon: Icons.people_alt_rounded, label: 'Seating Capacity', value: seats),
              _SpecRow(icon: Icons.directions_car_filled_rounded, label: 'Type', value: type),
            ],
          ),
        ),
      ],
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
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrangeAccent),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
