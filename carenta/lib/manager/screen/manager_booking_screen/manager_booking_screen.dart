import 'package:carenta/manager/screen/manager_booking_screen/service/manager_booking_service.dart';
import 'package:flutter/material.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_types.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_card.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_loading_state.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_empty_state.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_error_state.dart';
import 'package:carenta/manager/screen/manager_booking_screen/widget/booking_filter_strip.dart';
import 'package:carenta/manager/screen/manager_booking_screen/manager_booking_detail_screen.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';

class ManagerBookingScreen extends StatefulWidget {
  final String? filterStatus; // optional initial filter
  const ManagerBookingScreen({super.key, this.filterStatus});

  @override
  State<ManagerBookingScreen> createState() => _ManagerBookingScreenState();
}

class _ManagerBookingScreenState extends State<ManagerBookingScreen> {
  final _svc = ManagerBookingService();
  final _session = SessionManagerService();

  final List<FilterSpec> _filters = const [
    FilterSpec('All', null, Icons.all_inclusive_rounded),
    FilterSpec('Pending', 'pending', Icons.hourglass_bottom_rounded),
    FilterSpec('Confirmed', 'confirmed', Icons.event_available_rounded),
    FilterSpec('Ongoing', 'ongoing', Icons.directions_car_filled_rounded),
    FilterSpec('Completed', 'completed', Icons.verified_rounded),
    FilterSpec('Cancelled', 'cancelled', Icons.cancel_outlined),
  ];

  late int _selected; // index into _filters
  late Future<Map<String, dynamic>> _future;
  int? _managerId; // logged-in manager id
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _selected = _initialIndexFromParam(widget.filterStatus);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Pull the current logged-in user; adapt keys if your session uses different names
      final session = await SessionManagerService.getSession();
      // try managerid first, then userid fallback
      _managerId = session?.adminId ?? session?.userId ?? 0;
    } catch (_) {
      _managerId = 0;
    } finally {
      _future = _load();
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  int _initialIndexFromParam(String? status) {
    if (status == null || status.isEmpty) return 0; // All
    final i = _filters.indexWhere((f) => f.status == status.toLowerCase());
    return i >= 0 ? i : 0;
  }

  Future<Map<String, dynamic>> _load() {
    final status = _filters[_selected].status; // null for All
    // If your API supports scoping by manager, add managerId here in the service call.
    return _svc.fetchBookings(status: status /*, managerId: _managerId*/);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  void dispose() {
    _svc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0077B6);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: BookingFilterStrip(
                filters: _filters,
                selected: _selected,
                onSelect: (int index) {
                  setState(() {
                    _selected = index;
                    _future = _load();
                  });
                },
              ),
            ),
            const SizedBox(height: 4),

            // While we’re still loading the session/managerId, show a loader once.
            if (_bootstrapping)
              const Expanded(child: BookingLoadingState())
            else
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const BookingLoadingState();
                    }

                    if (snapshot.hasError) {
                      return BookingErrorState(
                        message: 'Failed to load bookings:\n${snapshot.error}',
                        onRetry: _reload,
                      );
                    }

                    if (snapshot.hasData) {
                      final result = snapshot.data!;
                      final ok = result['ok'] == true;
                      final String message =
                          (result['message'] ?? '').toString();
                      final List data = (result['data'] ?? []) as List;

                      if (!ok) {
                        return BookingErrorState(
                          message:
                              message.isNotEmpty ? message : 'Server error.',
                          onRetry: _reload,
                        );
                      }

                      if (data.isEmpty) {
                        return const BookingEmptyState();
                      }

                      final bookings = data.cast<BookingRow>();

                      return RefreshIndicator(
                        onRefresh: _reload,
                        color: primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: bookings.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final row = bookings[i];
                            return BookingCard(
                              booking: row,
                              onTap: () async {
                                // Pass the REAL managerId to detail screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ManagerBookingDetailScreen(
                                          booking: row,
                                        ),
                                  ),
                                );
                                _reload();
                              },
                            );
                          },
                        ),
                      );
                    }

                    return const BookingEmptyState();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
