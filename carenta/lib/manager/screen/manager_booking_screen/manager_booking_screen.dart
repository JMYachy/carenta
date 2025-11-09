import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';
import 'package:flutter/material.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_types.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_card.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_detail_screen.dart';

class ManagerBookingScreen extends StatefulWidget {
  final String? filterStatus;
  const ManagerBookingScreen({super.key, this.filterStatus});

  @override
  State<ManagerBookingScreen> createState() => _ManagerBookingScreenState();
}

class _ManagerBookingScreenState extends State<ManagerBookingScreen> {
  final _svc = ManagerBookingService();
  final List<String> _statuses = [
    'all',
    'pending',
    'confirmed',
    'ongoing',
    'completed',
    'cancelled',
  ];

  int _selected = 0;
  late Future<List<BookingRow>> _future;
  List<BookingRow> _cache = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<BookingRow>> _load() async {
    final status = _statuses[_selected] == 'all' ? null : _statuses[_selected];
    final res = await _svc.fetchBookings(status: status);
    if (res['status'] == 'success') {
      final List data = (res['data'] as List?) ?? const [];
      _cache = data.cast<BookingRow>();
      return _cache;
    } else {
      throw Exception(res['message'] ?? 'Failed to fetch bookings');
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Bookings')),
      body: FutureBuilder<List<BookingRow>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}'),
            );
          }

          final bookings = snap.data ?? const [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookings.length,
              itemBuilder: (context, i) {
                final row = bookings[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BookingCard(
                    booking: row,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManagerBookingDetailScreen(
                            booking: row,
                          ),
                        ),
                      );
                      _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
