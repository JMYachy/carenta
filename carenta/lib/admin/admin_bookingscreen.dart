import 'package:carenta/service/admin/adminbooking_service.dart';
import 'package:carenta/widget/cardbuilder_bookingcard.dart';
import 'package:flutter/material.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final _svc = AdminBookingService();
  final int _adminId = 1;

  final List<_FilterSpec> _filters = const [
    _FilterSpec('Pending', 'pending', Icons.pending_actions_rounded),
    _FilterSpec('Confirmed', 'confirmed', Icons.event_available_rounded),
    _FilterSpec('Ongoing', 'ongoing', Icons.timelapse_rounded),
    _FilterSpec('Completed', 'completed', Icons.verified_rounded),
    _FilterSpec('Cancelled', 'cancelled', Icons.cancel_rounded),
    _FilterSpec('All', null, Icons.all_inclusive_rounded),
  ];
  int _selected = 0;

  late Future<List<Map<String, dynamic>>> _future;
  final Set<int> _busy = {};
  List<Map<String, dynamic>> _cache = []; // <-- Add cache

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
      _cache = data.cast<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
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
    final res = await _svc.approveBooking(rentalId: rentalId, adminId: _adminId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));

    // optimistic patch
    final idx = _cache.indexWhere((r) => '${r['rentalid']}' == '$rentalId');
    if (idx != -1) {
      final patched = Map<String, dynamic>.from(_cache[idx])..['status'] = 'confirmed';
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
    final res = await _svc.cancelBooking(rentalId: rentalId, adminId: _adminId, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Updated')));

    final idx = _cache.indexWhere((r) => '${r['rentalid']}' == '$rentalId');
    if (idx != -1) {
      final patched = Map<String, dynamic>.from(_cache[idx])..['status'] = 'cancelled';
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
          _HeaderBar(title: 'Bookings (Admin)', subtitle: 'Review & manage requests'),

          _FilterStrip(
            filters: _filters,
            selected: _selected,
            onSelect: (i) {
              if (_selected == i) return;
              setState(() {
                _selected = i; // SYNC ONLY
              });
              _reload(); // async work OUTSIDE setState
            },
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        message: 'Failed to load.\nPull down to retry.',
                        onRetry: _reload,
                      );
                    }

                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) return const _EmptyState();

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = rows[i];

                        // normalize id
                        final rentalId = int.tryParse('${r['rentalid'] ?? r['id'] ?? '0'}') ?? 0;
                        final status = (r['status'] ?? '').toString().toLowerCase();
                        final canAct = status == 'pending';
                        final busy = _busy.contains(rentalId);

                        return _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CardbuilderBookingcard.fromApi(r),
                              if (canAct)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: busy ? null : () { _approve(rentalId); },
                                          icon: const Icon(Icons.check_rounded),
                                          label: const Text('Accept'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: busy ? null : () { _cancel(rentalId); },
                                          icon: const Icon(Icons.close_rounded),
                                          label: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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

/* ========= helpers ========== */

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
            scheme.primary.withValues(alpha:  0.12),
            scheme.primary.withValues(alpha: 0.04),
            Colors.transparent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: scheme.primary, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  const _FilterStrip({required this.filters, required this.selected, required this.onSelect});
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
            onSelected: (_) => onSelect(i), // <- returns void, no async
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
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
        Icon(Icons.inbox_rounded, size: 56, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          'No bookings in this view',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
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
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry, // sync callback
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

Future<String?> _askReason(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
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
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Submit')),
      ],
    ),
  );
}
