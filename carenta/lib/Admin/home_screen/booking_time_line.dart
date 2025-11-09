/*/ lib/admin/home_screen/booking_time_line.dart
import 'package:flutter/material.dart';
import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';

/// ✅ Create a single instance of the service (not static)
final AdminBookingService _bookingSvc = AdminBookingService();

class BookingTimeline extends StatelessWidget {
  const BookingTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookingSvc.fetchTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "⚠️ Failed to load booking timeline:\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const Center(
            child: Text(
              "No recent bookings found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final b = bookings[index];

            final carName =
                "${b["manufacturer"] ?? ""} ${b["car_model"] ?? ""}".trim();
            final status = (b["status"] ?? "unknown").toString().toUpperCase();
            final time = b["time"]?.toString() ?? "";

            Color statusColor;
            switch (status.toLowerCase()) {
              case "confirmed":
                statusColor = Colors.green;
                break;
              case "pending":
                statusColor = Colors.orange;
                break;
              case "cancelled":
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.grey;
            }

            return ListTile(
              leading: Icon(Icons.access_time, color: statusColor),
              title: Text(
                carName.isNotEmpty ? carName : "Unknown Car",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Status: $status"),
              trailing: Text(
                time,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            );
          },
        );
      },
    );
  }
}
*/