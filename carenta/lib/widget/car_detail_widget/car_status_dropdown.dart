import 'package:flutter/material.dart';
import 'package:carenta/service/admin/admin_edit_car_service.dart';
import 'package:carenta/service/admin/admin_get_car_detail_service.dart';
import 'package:carenta/widget/admin_widget/car_model.dart';

class CarStatusDropdown extends StatefulWidget {
  final int carId;
  final String currentStatus;
  final void Function(CarModel updated)? onStatusUpdated; // ✅ optional callback

  const CarStatusDropdown({
    super.key,
    required this.carId,
    required this.currentStatus,
    this.onStatusUpdated,
  });

  @override
  State<CarStatusDropdown> createState() => _CarStatusDropdownState();
}

class _CarStatusDropdownState extends State<CarStatusDropdown> {
  late String _selectedStatus;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _loading = true);

    final result = await AdminEditCarService.updateCarStatus(
      carId: widget.carId,
      newStatus: newStatus,
    );

    if (result['success'] == true) {
      // ✅ Fetch latest data from backend for full sync
      final refreshedCar =
          await AdminGetCarDetailsService.fetchCarById(widget.carId);

      if (mounted) {
        setState(() {
          _selectedStatus = newStatus;
          _loading = false;
        });
      }

      // ✅ Notify parent (CarDetailScreen) if provided
      if (widget.onStatusUpdated != null && refreshedCar != null) {
        widget.onStatusUpdated!(refreshedCar);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car status updated to "$newStatus" ✅')),
      );
    } else {
      if (mounted) setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(result['message'] ?? 'Failed to update car status ❌')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : DropdownButton<String>(
            value: _selectedStatus,
            underline: Container(height: 1, color: Colors.grey.shade400),
            items: const [
              DropdownMenuItem(value: 'available', child: Text('Available')),
              DropdownMenuItem(
                  value: 'in-maintenance', child: Text('In Maintenance')),
              DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
            ],
            onChanged: (newValue) {
              if (newValue != null && newValue != _selectedStatus) {
                _updateStatus(newValue);
              }
            },
          );
  }
}
