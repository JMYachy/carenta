import 'package:carenta/user/user_home_screen/car_details_screen/widgets/review_card.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/user/review_service.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/section/user_all_reviews_screen.dart';

class CarRatingsAndReviewsSection extends StatefulWidget {
  final int carId;
  final String carName;

  const CarRatingsAndReviewsSection({
    super.key,
    required this.carId,
    required this.carName,
  });

  @override
  State<CarRatingsAndReviewsSection> createState() =>
      _CarRatingsAndReviewsSectionState();
}

class _CarRatingsAndReviewsSectionState
    extends State<CarRatingsAndReviewsSection> {
  final _svc = ReviewService();

  bool _loading = true;
  double _average = 0.0;
  int _totalRatings = 0;
  final Map<int, int> _summary = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _svc.getReviews(widget.carId);
      final List<Map<String, dynamic>> data =
          (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (data.isNotEmpty) {
        // Calculate summary
        final counts = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
        for (final r in data) {
          final rating = int.tryParse('${r['rating'] ?? 0}') ?? 0;
          if (counts.containsKey(rating)) counts[rating] = counts[rating]! + 1;
        }
        final total = data.length;
        final avg =
            total > 0
                ? counts.entries.fold(0, (a, e) => a + e.key * e.value) / total
                : 0;

        setState(() {
          _reviews = data;
          _summary
            ..clear()
            ..addAll(counts);
          _average = double.parse(avg.toStringAsFixed(1));
          _totalRatings = total;
        });
      } else {
        setState(() {
          _reviews = [];
          _average = 0;
          _totalRatings = 0;
          for (var i = 1; i <= 5; i++) {
            _summary[i] = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Review load error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ Header
        const Text(
          'Ratings & Reviews',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 10),

        // ⭐ Average rating + star icon + count
        Row(
          children: [
            Text(
              _average.toStringAsFixed(1),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              '($_totalRatings ratings)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 📊 Rating summary bars
        Column(
          children: List.generate(5, (i) {
            final stars = 5 - i;
            final count = _summary[stars] ?? 0;
            final ratio = _totalRatings > 0 ? count / _totalRatings : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('$stars', style: const TextStyle(fontSize: 12)),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: Colors.grey[300],
                      color: Colors.amber,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$count', style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // 🧾 Review carousel
        if (_reviews.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _reviews.length.clamp(0, 5),
              itemBuilder: (_, i) {
                final r = _reviews[i];
                return Padding(
                  padding: EdgeInsets.only(
                    right: i == _reviews.length - 1 ? 0 : 10,
                  ),
                  child: ReviewCard(review: r),
                );
              },
            ),
          )
        else
          const Text('No reviews yet.', style: TextStyle(color: Colors.grey)),

        const SizedBox(height: 12),

        // 🔗 See all reviews
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UserAllReviewsScreen(
                        carId: widget.carId,
                        carName: widget.carName,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text(
              'See all reviews',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
