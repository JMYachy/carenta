// lib/admin/admin_booking_screen.dart
import 'package:carenta/admin/booking_screen/rental_detail_screen/admin_canceled_rental_detail_screen.dart';
import 'package:carenta/admin/booking_screen/rental_detail_screen/admin_ongoing_rental_screen.dart';
import 'package:carenta/admin/booking_screen/rental_detail_screen/admin_rental_details_screen.dart';
import 'package:carenta/service/admin/admin_booking_service.dart';
import 'package:carenta/admin/booking_screen/widget/booking_card_container.dart';
import 'package:carenta/admin/booking_screen/widget/booking_empty_state.dart';
import 'package:carenta/admin/booking_screen/widget/booking_error_state.dart';
import 'package:carenta/admin/booking_screen/widget/booking_filter_strip.dart';
import 'package:carenta/admin/booking_screen/widget/booking_header_bar.dart';
import 'package:carenta/admin/booking_screen/widget/booking_loading_state.dart';
import 'package:carenta/admin/booking_screen/widget/card_builder_booking_card.dart';
import 'package:flutter/material.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final _svc = AdminBookingService();
  final int _adminId = 1;

  final List<FilterSpec> _filters = const [
    FilterSpec('All', null, Icons.all_inclusive_rounded),
    FilterSpec('Pending', 'pending', Icons.pending_actions_rounded),
    FilterSpec('Confirmed', 'confirmed', Icons.event_available_rounded),
    FilterSpec('Ongoing', 'ongoing', Icons.timelapse_rounded),
    FilterSpec('Completed', 'completed', Icons.verified_rounded),
    FilterSpec('Cancelled', 'cancelled', Icons.cancel_rounded),
  ];
  int _selected = 0;

  late Future<List<Map<String, dynamic>>> _future;
  final Set<int> _busy = {};
  List<Map<String, dynamic>> _cache = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final status = _filters[_selected].status;
    final res = await _svc.fetchBookings(status: status, limit: 200);
    if (res['status'] == 'success') {
      final List data = (res['data'] as List?) ?? const [];
      _cache =
          data
              .cast<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
      return _cache;
    } else {
      throw Exception(res['message'] ?? 'Failed to fetch bookings');
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _approve(int rentalId) async {
    setState(() => _busy.add(rentalId));
    final res = await _svc.approveBooking(
      rentalId: rentalId,
      adminId: _adminId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));

    final idx = _cache.indexWhere((r) => '${r['rentalid']}' == '$rentalId');
    if (idx != -1) {
      final patched = Map<String, dynamic>.from(_cache[idx])
        ..['status'] = 'confirmed';
      setState(() {
        _cache[idx] = patched;
        _future = Future.value(List<Map<String, dynamic>>.from(_cache));
        _busy.remove(rentalId);
      });
    } else {
      setState(() => _busy.remove(rentalId));
      await _reload();
    }
  }

  Future<void> _cancel(int rentalId) async {
    final reason = await _askReason(context);
    if (reason == null) return;
    setState(() => _busy.add(rentalId));
    final res = await _svc.cancelBooking(
      rentalId: rentalId,
      adminId: _adminId,
      reason: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));

    final idx = _cache.indexWhere((r) => '${r['rentalid']}' == '$rentalId');
    if (idx != -1) {
      final patched = Map<String, dynamic>.from(_cache[idx])
        ..['status'] = 'cancelled';
      setState(() {
        _cache[idx] = patched;
        _future = Future.value(List<Map<String, dynamic>>.from(_cache));
        _busy.remove(rentalId);
      });
    } else {
      setState(() => _busy.remove(rentalId));
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          BookingHeaderBar(
            title: 'Bookings (Admin)',
            subtitle: 'Review & manage requests',
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
                      return const BookingLoadingState();
                    }
                    if (snap.hasError) {
                      return BookingErrorState(
                        message: 'Failed to load.\nPull down to retry.',
                        onRetry: _reload,
                      );
                    }

                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) return const BookingEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final rentalId =
                            int.tryParse(
                              '${r['rentalid'] ?? r['id'] ?? '0'}',
                            ) ??
                            0;
                        final status =
                            (r['status'] ?? '').toString().toLowerCase();
                        final canAct = status == 'pending';
                        final busy = _busy.contains(rentalId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              final status =
                                  (r['status'] ?? '').toString().toLowerCase();

                              if (status == 'ongoing') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AdminOngoingRentalDetailScreen(
                                          rental: r,
                                          adminId: _adminId,
                                          onUpdated: _reload,
                                        ),
                                  ),
                                ).then((_) => _reload());
                              } else if (status == 'cancelled') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AdminCancelledRentalDetailScreen(
                                          rental: r,
                                          adminId: _adminId,
                                        ),
                                  ),
                                ).then((_) => _reload());
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AdminRentalDetailsScreen(
                                          rental: r,
                                          adminId: _adminId,
                                          onCancelled: _reload,
                                        ),
                                  ),
                                ).then((_) => _reload());
                              }
                            },
                            child: BookingCardContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CardbuilderBookingcard.fromApi(r),
                                  if (canAct)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        0,
                                        12,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed:
                                                  busy
                                                      ? null
                                                      : () =>
                                                          _approve(rentalId),
                                              icon: const Icon(
                                                Icons.check_rounded,
                                              ),
                                              label: const Text('Accept'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  busy
                                                      ? null
                                                      : () => _cancel(rentalId),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                              label: const Text('Cancel'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
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

class FilterSpec {
  final String label;
  final String? status;
  final IconData icon;
  const FilterSpec(this.label, this.status, this.icon);
}

Future<String?> _askReason(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Cancel booking'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'e.g., overlapping schedule, policy issue',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        ),
  );
}
