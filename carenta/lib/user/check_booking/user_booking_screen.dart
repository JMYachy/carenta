// lib/user/bookings/user_booking_screen.dart

import 'package:carenta/main/splash_screen.dart';
import 'package:carenta/service/user/user_booking_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/check_booking/widgets/booking_filter_strip.dart';
import 'package:carenta/user/check_booking/widgets/booking_state_widgets.dart';
import 'package:carenta/user/check_booking/widgets/booking_card_container.dart';
import 'package:carenta/user/check_booking/widgets/booking_header_bar.dart';
import 'package:carenta/widget/shared/booking_card_widget.dart';
import 'package:flutter/material.dart';

class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({super.key});

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  int? _userId;
  final _svc = UserBookingService();

  final List<FilterSpec> _filters = const [
    FilterSpec('All', null, Icons.all_inclusive_rounded),
    FilterSpec('Upcoming', 'confirmed', Icons.event_available_rounded),
    FilterSpec('Ongoing', 'ongoing', Icons.timelapse_rounded),
    FilterSpec('Completed', 'completed', Icons.verified_rounded),
    FilterSpec('Cancelled', 'cancelled', Icons.cancel_rounded),
  ];

  int _selected = 0;
  late Future<List<Map<String, dynamic>>> _future = Future.value([]);

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoad();
  }

  Future<void> _checkSessionAndLoad() async {
    try {
      final res = await SessionService.checkSession();
      if (res['success'] == true) {
        final id = res['data']?['userid'];
        if (id != null) {
          final future = _load();
          if (!mounted) return;
          setState(() {
            _userId = id;
            _future = future;
          });
          return;
        }
      }
      _redirectToSplash();
    } catch (_) {
      _redirectToSplash();
    }
  }

  void _redirectToSplash() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (_userId == null) return [];

    final status = _filters[_selected].status;
    final res = await _svc.fetchUserBookings(
      userId: _userId!,
      status: status,
      limit: 100,
      offset: 0,
      order: 'desc',
    );

    if (res['status'] == 'success') {
      final List data = (res['data'] as List? ?? const []);
      return data
          .cast<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } else {
      throw Exception(res['message'] ?? 'Failed to fetch bookings');
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          const BookingHeaderBar(
            title: 'My Bookings',
            subtitle: 'Manage your trips & rentals',
          ),
          BookingFilterStrip(
            filters: _filters,
            selected: _selected,
            onSelect: (i) {
              if (_selected == i) return;
              setState(() => _selected = i);
              _reload();
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }
                    if (snap.hasError) {
                      return ErrorState(
                        message:
                            'Failed to load bookings.\nPull down to retry.',
                        onRetry: _reload,
                      );
                    }

                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) {
                      return const EmptyState();
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return BookingCardContainer(
                          child: BookingCardWidget.fromApi(
                            r,
                            onTap: () {
                              // 🚀 Navigate to booking details or car detail page
                              debugPrint(
                                'Tapped booking with ID: ${r['rentalid']}',
                              );
                              // Example:
                              // Navigator.push(context, MaterialPageRoute(
                              //   builder: (_) => BookingDetailScreen(booking: r),
                              // ));
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
