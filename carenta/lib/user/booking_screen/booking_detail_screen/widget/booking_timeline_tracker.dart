import 'package:flutter/material.dart';

class BookingTimelineTracker extends StatelessWidget {
  final String status;

  const BookingTimelineTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['pending', 'confirmed', 'ongoing', 'completed'];
    final currentStep = steps.indexOf(status.toLowerCase());

    if (status == 'cancelled') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 26),
            const SizedBox(width: 8),
            const Text(
              'This booking was cancelled',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isActive = i <= currentStep;
          final isCompleted = i < currentStep;

          Color color;
          IconData icon;
          switch (step) {
            case 'pending':
              color = Colors.orange;
              icon = Icons.schedule_rounded;
              break;
            case 'confirmed':
              color = Colors.blue;
              icon = Icons.check_circle_outline_rounded;
              break;
            case 'ongoing':
              color = Colors.teal;
              icon = Icons.directions_car_rounded;
              break;
            case 'completed':
              color = Colors.green;
              icon = Icons.verified_rounded;
              break;
            default:
              color = Colors.grey;
              icon = Icons.circle;
          }

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // --- Timeline line before icon (except first)
                    if (i != 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isCompleted
                              ? color
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    // --- Icon marker
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? color : Colors.grey[300],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    // --- Timeline line after icon (except last)
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i < currentStep
                              ? color
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step[0].toUpperCase() + step.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? color : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
