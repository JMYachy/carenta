import 'package:carenta/manager/screen/manager_car_screen/manager_add_car/model/manager_add_car_form_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManagerAddCarFieldset {
  static Widget details(ManagerAddCarFormModel form) {
    return Column(
      children: [
        _input(
          "Year",
          (v) => form.year = v,
          type: TextInputType.number,
          icon: Icons.event,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _input(
          "Manufacturer",
          (v) => form.manufacturer = v,
          icon: Icons.factory,
        ),
        _input("Model", (v) => form.model = v, icon: Icons.directions_car),
        _input("Type", (v) => form.type = v, icon: Icons.category),
        _input(
          "License Plate",
          (v) => form.licensePlate = v,
          icon: Icons.confirmation_number,
        ),
        _input("Color", (v) => form.color = v, icon: Icons.color_lens),
        _input(
          "Transmission",
          (v) => form.transmission = v,
          icon: Icons.settings,
        ),
        _input(
          "Fuel Type",
          (v) => form.fuelType = v,
          icon: Icons.local_gas_station,
        ),
        _input(
          "Mileage (km)",
          (v) => form.milage = v,
          type: TextInputType.number,
          icon: Icons.speed,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _input(
          "Seating Capacity",
          (v) => form.seatingCap = v,
          type: TextInputType.number,
          icon: Icons.event_seat,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        // ⚠️ Status picker removed — status is always 'available' on create.
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: form.withDriver,
          decoration: const InputDecoration(labelText: "With Driver"),
          items: const [
            DropdownMenuItem(value: 'Yes', child: Text("Yes")),
            DropdownMenuItem(value: 'No', child: Text("No")),
          ],
          onChanged: (v) => form.withDriver = v ?? 'No',
        ),
      ],
    );
  }

  static Widget pricing(ManagerAddCarFormModel form) {
    return Column(
      children: [
        _input(
          "Daily Rate (₱)",
          (v) => form.dailyRate = v,
          type: TextInputType.number,
          icon: Icons.price_change,
        ),
        _input(
          "Promo 1 Discount %",
          (v) => form.promo1 = v,
          type: TextInputType.number,
          icon: Icons.local_offer,
        ),
        _input(
          "Promo 2 Discount %",
          (v) => form.promo2 = v,
          type: TextInputType.number,
          icon: Icons.local_offer,
        ),
        _input(
          "Promo 3 Discount %",
          (v) => form.promo3 = v,
          type: TextInputType.number,
          icon: Icons.discount,
        ),
      ],
    );
  }

  static Widget _input(
    String label,
    Function(String) onChanged, {
    TextInputType type = TextInputType.text,
    IconData? icon,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        keyboardType: type,
        inputFormatters: formatters,
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
