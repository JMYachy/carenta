import 'package:carenta/user/user_create_booking_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarDetails extends StatefulWidget {
  final Map<String, dynamic> car;
  const CarDetails({super.key, required this.car});

  @override
  State<CarDetails> createState() => _CarDetailsState();
}

class _CarDetailsState extends State<CarDetails> {
  final CarouselSliderController _carousel = CarouselSliderController();
  int _activeIndex = 0;

  String get _currencySymbol {
    final currency = (widget.car['currency'] ?? 'PHP').toString().toUpperCase();
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'PHP':
      default:
        return '₱';
    }
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  List<Widget> _buildMedia() {
    final List<Widget> items = [];
    final img = (widget.car['image_url'] ?? widget.car['media_url'])?.toString().trim();

    if (img != null && img.isNotEmpty) {
      items.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 80),
              ),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.directions_car, size: 80)),
            ),
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    final manufacturer = (car['manufacturer'] ?? '').toString();
    final model = (car['model'] ?? '').toString();
    final year = (car['year'] ?? '').toString();

    final type = (car['type'] ?? '—').toString();
    final seats = car['seatingcap']?.toString() ?? car['seats']?.toString() ?? '—';
    final transmission = (car['transmission'] ?? '—').toString();
    final fuel = (car['fueltype'] ?? '—').toString();
    final color = (car['color'] ?? '—').toString();
    final milage = (car['milage'] ?? '—').toString();

    final daily = _num(car['daily_rate'] ?? car['price']);
    final weekly = _num(car['weekly_rate']);
    final monthly = _num(car['monthly_rate']);

    final priceFmt = NumberFormat('#,##0.##');
    final mediaWidgets = _buildMedia();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text('$manufacturer $model', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      const TextSpan(text: 'From ', style: TextStyle(fontSize: 12)),
                      TextSpan(
                        text: '$_currencySymbol${priceFmt.format(daily)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(text: '/day', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserCreateBookingscreen(car: car)),
                  );
                },
                child: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // HERO / MEDIA
          Stack(
            children: [
              CarouselSlider(
                carouselController: _carousel,
                items: mediaWidgets,
                options: CarouselOptions(
                  height: 230,
                  enlargeCenterPage: true,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: mediaWidgets.length > 1,
                  onPageChanged: (index, _) => setState(() => _activeIndex = index),
                ),
              ),
              if (mediaWidgets.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(mediaWidgets.length, (i) {
                      final isActive = i == _activeIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFFF5722) : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title & Plate
          Text('$manufacturer $model${year.isNotEmpty ? ' ($year)' : ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('${car['license_plate'] ?? ''}'.trim().isNotEmpty ? 'Plate: ${car['license_plate']}' : '',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(icon: Icons.category_rounded, label: type),
              _Pill(icon: Icons.event_seat, label: '$seats seats'),
              _Pill(icon: Icons.settings, label: transmission),
              _Pill(icon: Icons.local_gas_station, label: fuel),
            ],
          ),
          const SizedBox(height: 18),

          // Price Card
          _Card(
            child: Row(
              children: [
                _PriceTile(
                  title: 'Daily',
                  price: '$_currencySymbol${priceFmt.format(daily)}',
                  highlight: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _PriceRow(label: 'Weekly', value: weekly > 0 ? '$_currencySymbol${priceFmt.format(weekly)}' : '—'),
                      const SizedBox(height: 8),
                      _PriceRow(label: 'Monthly', value: monthly > 0 ? '$_currencySymbol${priceFmt.format(monthly)}' : '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Specifications
          const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                _SpecRow(icon: Icons.color_lens_rounded, label: 'Color', value: color),
                const Divider(height: 20),
                _SpecRow(icon: Icons.speed_rounded, label: 'Milage', value: milage),
                const Divider(height: 20),
                _SpecRow(icon: Icons.settings_rounded, label: 'Transmission', value: transmission),
                const Divider(height: 20),
                _SpecRow(icon: Icons.local_gas_station_rounded, label: 'Fuel Type', value: fuel),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ---- Supporting sections from your UI (empty placeholders) ----

          const Text('About this Car', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _Card(child: Container(height: 80)), // placeholder for description/about

          const SizedBox(height: 18),
          const Text('Owner Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _Card(child: Container(height: 60)), // placeholder for owner/host info

          const SizedBox(height: 18),
          const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _Card(child: Container(height: 120)), // placeholder for reviews list

          const SizedBox(height: 18),
          const Text('Similar Cars', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3, // dummy
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- UI bits (same as before) ---

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF5722)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final val = value.isEmpty ? '—' : value;
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF90E0EF).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: const Color(0xFF0077B6)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Text(val, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String title;
  final String price;
  final bool highlight;
  const _PriceTile({required this.title, required this.price, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFF5722) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlight ? const Color(0xFFFF5722) : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  color: highlight ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(price,
                style: TextStyle(
                  color: highlight ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
