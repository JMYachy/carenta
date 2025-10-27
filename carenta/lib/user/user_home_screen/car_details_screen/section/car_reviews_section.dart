import 'package:carenta/user/user_home_screen/car_details_screen/review/review_list_view.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/user/review_service.dart';

class CarReviewSection extends StatefulWidget {
  final int carId;

  const CarReviewSection({super.key, required this.carId});

  @override
  State<CarReviewSection> createState() => _CarReviewSectionState();
}

class _CarReviewSectionState extends State<CarReviewSection> {
  final _reviewService = ReviewService();
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  /// Fetch all reviews for the given car
  Future<void> _loadReviews() async {
    setState(() => _loading = true);
    final res = await _reviewService.getReviews(widget.carId);
    if (res['status'] == 'success') {
      _reviews = List<Map<String, dynamic>>.from(res['data']);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "No reviews yet. Be the first to rent and leave feedback!",
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ReviewListView(reviews: _reviews),

        const SizedBox(height: 8),
      ],
    );
  }
}
