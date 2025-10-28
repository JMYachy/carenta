import 'package:flutter/material.dart';

class BookingTripForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController pickupC;
  final TextEditingController dropoffC;

  const BookingTripForm({
    super.key,
    required this.formKey,
    required this.pickupC,
    required this.dropoffC,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: pickupC,
            decoration: const InputDecoration(
              labelText: 'Pickup Location',
              prefixIcon: Icon(Icons.my_location),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter pickup location' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dropoffC,
            decoration: const InputDecoration(
              labelText: 'Dropoff Location',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter dropoff location' : null,
          ),
        ],
      ),
    );
  }
}
