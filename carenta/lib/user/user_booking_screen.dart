// lib/screen/user_booking_screen.dart
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/widget/admin_widget/admin_booking_screen_widget/card_builder_booking_card.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/user/user_booking_service.dart';
import 'package:carenta/main/splash_screen.dart';

class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({super.key});

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  int? _userId; // will come from SessionService
  final _svc = UserBookingService();

  final List<_FilterSpec> _filters = const [
    _FilterSpec('All', null, Icons.all_inclusive_rounded),
    _FilterSpec('Upcoming', 'confirmed', Icons.event_available_rounded),
    _FilterSpec('Ongoing', 'ongoing', Icons.timelapse_rounded),
    _FilterSpec('Completed', 'completed', Icons.verified_rounded),
    _FilterSpec('Cancelled', 'cancelled', Icons.cancel_rounded),
  ];

  int _selected = 0;
  late Future<List<Map<String, dynamic>>> _future;

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
          final future = _load(); // ✅ run load once
          if (!mounted) return;
          setState(() {
            _userId = id;
            _future = future;
          });
          return;
        }
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (_userId == null) {
      return []; // ✅ don’t throw, just return empty
    }

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
    final newFuture = _load(); // ✅ start async work outside setState
    if (!mounted) return;
    setState(() {
      _future = newFuture; // ✅ synchronous assignment only
    });
    await newFuture; // ✅ wait outside
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
          _HeaderBar(
            title: 'My Bookings',
            subtitle: 'Manage your trips & rentals',
          ),
          _FilterStrip(
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
                      return const _LoadingState();
                    }
                    if (snap.hasError) {
                      return _ErrorState(
                        message:
                            'Failed to load bookings.\nPull down to retry.',
                        onRetry: _reload,
                      );
                    }

                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) {
                      return const _EmptyState();
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return _CardContainer(
                          child: CardbuilderBookingcard.fromApi(r),
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

/* ==================== UI helpers ==================== */

class _FilterSpec {
  final String label;
  final String? status;
  final IconData icon;
  const _FilterSpec(this.label, this.status, this.icon);
}

class _HeaderBar extends StatelessWidget {
  final String title, subtitle;
  const _HeaderBar({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.primary.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: scheme.primary, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final List<_FilterSpec> filters;
  final int selected;
  final ValueChanged<int> onSelect;
  const _FilterStrip({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return ChoiceChip(
            label: Row(
              children: [
                Icon(filters[i].icon, size: 18),
                const SizedBox(width: 6),
                Text(filters[i].label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(i),
          );
        },
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: child);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.event_busy_rounded, size: 56, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          'No bookings yet',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          'Your bookings will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline_rounded, size: 56, color: scheme.error),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
