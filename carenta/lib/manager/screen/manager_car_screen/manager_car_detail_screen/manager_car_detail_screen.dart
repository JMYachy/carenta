import 'dart:async';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_detail_screen/service/manager_car_detail_service.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_detail_screen/widget/car_detail_form.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_detail_screen/widget/car_gallery_section.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_detail_screen/widget/car_price_form.dart';
import 'package:carenta/manager/screen/manager_car_screen/manager_car_detail_screen/widget/car_status_badge.dart';
import 'package:carenta/widget/shared/car_media_carousel.dart';
import 'package:flutter/material.dart';

class ManagerCarDetailScreen extends StatefulWidget {
  final int carId;
  const ManagerCarDetailScreen({super.key, required this.carId});

  @override
  State<ManagerCarDetailScreen> createState() => _ManagerCarDetailScreenState();
}

class _ManagerCarDetailScreenState extends State<ManagerCarDetailScreen> {
  late Future<Map<String, dynamic>> _bundleFuture;

  Map<String, dynamic> _car = {};
  Map<String, dynamic> _price = {};
  List<Map<String, dynamic>> _media = [];
  String _rentalStatus = 'none';

  bool _dirty = false; // ✅ set true when something is updated

  @override
  void initState() {
    super.initState();
    _bundleFuture = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final b = await ManagerCarDetailService.fetchCarBundle(widget.carId);
    _car = Map<String, dynamic>.from(b['car'] ?? {});
    _price = Map<String, dynamic>.from(b['price'] ?? {});
    _media = List<Map<String, dynamic>>.from(
      (b['media'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
    _rentalStatus = '${b['rental_status'] ?? 'none'}';
    return b;
  }

  void _refresh() {
    setState(() {
      _bundleFuture = _load();
    });
  }

  // ✅ map to final effective status for the header badge
  String _effectiveStatus(String carStatus, String rentalStatus) {
    return CarStatusBadge.effectiveStatus(
      carStatus: carStatus,
      rentalStatus: rentalStatus,
    );
  }

  // ✅ status change (standalone)
  Future<void> _onStatusChanged(String newStatus) async {
    final carId = _safeCarId(_car['carid']) ?? widget.carId;

    final ok = await ManagerCarDetailService.updateCarStatus(
      carId: carId,
      status: newStatus, // available | maintenance | inactive
    );

    if (!mounted) return;
    if (ok) {
      _dirty = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Car status updated')));
      _refresh();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }

  int? _safeCarId(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v');
  }

  String _composeTitle(Map<String, dynamic> c) {
    final year = '${c['year'] ?? ''}'.trim();
    final make = '${c['manufacturer'] ?? ''}'.trim();
    final model = '${c['model'] ?? ''}'.trim();
    final title = [year, make, model].where((s) => s.isNotEmpty).join(' ');
    return title.isEmpty ? 'Car #${c['carid'] ?? ''}' : title;
  }

  @override
  Widget build(BuildContext context) {
    // return `true` to caller if something changed
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_dirty);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Car Details'),
          centerTitle: false,
          actions: [
            if (_dirty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _bundleFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final car = _car;
            final price = _price;
            final media = _media;
            final rentalStatus = _rentalStatus;

            final title = _composeTitle(car);
            final carStatusRaw = '${car['status'] ?? 'available'}';
            final effective = _effectiveStatus(carStatusRaw, rentalStatus);

            // build media URLs for the shared carousel
            final mediaUrls = List<String>.from(
              media
                  .map((m) => '${m['media_url'] ?? ''}')
                  .where((u) => u.isNotEmpty),
            );

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ Top media carousel (read-only; editing on Media tab)
                    CarMediaCarousel(
                      mediaUrls: mediaUrls,
                      editable: false,
                      autoPlay: true,
                    ),
                    const SizedBox(height: 12),

                    // 🧾 Header with dynamic status + standalone dropdown
                    _HeaderCard(
                      title: title,
                      effectiveStatus: effective,
                      carStatusRaw: carStatusRaw,
                      onStatusChanged: _onStatusChanged,
                    ),
                    const SizedBox(height: 12),

                    // 🧭 Tabs for Overview / Pricing / Media
                    DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: const TabBar(
                              tabs: [
                                Tab(text: 'Overview'),
                                Tab(text: 'Pricing'),
                                Tab(text: 'Media'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // give TabBarView its own height to avoid overflow
                          SizedBox(
                            height:
                                980, // generous height for forms + small screens
                            child: TabBarView(
                              children: [
                                // OVERVIEW (car details)
                                CarDetailForm(
                                  car: car,
                                  onSaved: (updatedFields) async {
                                    final carId =
                                        _safeCarId(car['carid']) ??
                                        widget.carId;
                                    final ok =
                                        await ManagerCarDetailService.updateCarDetails(
                                          carId: carId,
                                          fields: updatedFields,
                                        );
                                    if (!mounted) return;
                                    if (ok) {
                                      _dirty = true;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Car details updated'),
                                        ),
                                      );
                                      _refresh();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to update car details',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),

                                // PRICING
                                CarPriceForm(
                                  price: price,
                                  onSaved: (updatedPrice) async {
                                    final carId =
                                        _safeCarId(car['carid']) ??
                                        widget.carId;
                                    final ok =
                                        await ManagerCarDetailService.updatePrice(
                                          carId: carId,
                                          priceFields: updatedPrice,
                                        );
                                    if (!mounted) return;
                                    if (ok) {
                                      _dirty = true;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pricing updated'),
                                        ),
                                      );
                                      _refresh();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to update pricing',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),

                                // MEDIA (add/remove)
                                CarGallerySection(
                                  carId: _safeCarId(car['carid']) ?? 0,
                                  items: media,
                                  onChanged: () {
                                    _dirty = true;
                                    _refresh();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// HEADER CARD (status badge + standalone status dropdown)
/// ─────────────────────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final String title;
  final String
  effectiveStatus; // Available, Reserved, Rented, Maintenance, Inactive
  final String carStatusRaw; // available | maintenance | inactive
  final ValueChanged<String> onStatusChanged;

  const _HeaderCard({
    required this.title,
    required this.effectiveStatus,
    required this.carStatusRaw,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const statusOptions = ['available', 'maintenance', 'inactive'];

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CarStatusBadge(text: effectiveStatus),
              ],
            ),
            const SizedBox(height: 12),

            // dropdown
            Row(
              children: [
                Text(
                  'Car Status:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value:
                      statusOptions.contains(carStatusRaw)
                          ? carStatusRaw
                          : 'available',
                  items:
                      statusOptions
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(_pretty(s)),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) onStatusChanged(v);
                  },
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Note: “Rented/Reserved” reflects current rentals automatically (read-only).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pretty(String s) {
    switch (s) {
      case 'available':
        return 'Available';
      case 'maintenance':
        return 'Maintenance';
      case 'inactive':
        return 'Inactive';
    }
    return s;
  }
}
