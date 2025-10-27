import 'package:carenta/user/user_home_screen/car_details_screen/widgets/review_card.dart';
import 'package:flutter/material.dart';
import 'package:carenta/service/user/review_service.dart';

class UserAllReviewsScreen extends StatefulWidget {
  final int carId;
  final String carName;
  const UserAllReviewsScreen({
    super.key,
    required this.carId,
    required this.carName,
  });

  @override
  State<UserAllReviewsScreen> createState() => _UserAllReviewsScreenState();
}

class _UserAllReviewsScreenState extends State<UserAllReviewsScreen> {
  final _svc = ReviewService();
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _svc.getReviews(widget.carId);
    setState(() {
      _reviews = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reviews - ${widget.carName}')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _reviews.isEmpty
              ? const Center(child: Text('No reviews yet'))
              : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ReviewCard(review: _reviews[i]),
              ),
    );
  }
}
