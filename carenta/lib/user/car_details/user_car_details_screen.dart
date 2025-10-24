import 'package:carenta/service/user/review_service.dart';
import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/user/car_details/section/book_now_bar.dart';
import 'package:carenta/user/car_details/section/car_favorite_section.dart';
import 'package:carenta/user/car_details/section/car_header_section.dart';
import 'package:carenta/user/car_details/section/car_reviews_section.dart';
import 'package:carenta/user/car_details/section/car_specs_section.dart';
import 'package:carenta/user/create_booking/user_create_booking_screen.dart';
import 'package:flutter/material.dart';

class UserCarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final int? userId;

  const UserCarDetailsScreen({super.key, required this.car, this.userId});

  @override
  State<UserCarDetailsScreen> createState() => _UserCarDetailsScreenState();
}

class _UserCarDetailsScreenState extends State<UserCarDetailsScreen> {
  bool isFavorite = false;
  bool isLoadingFav = false;
  bool isLoadingReviews = true;

  final _favService = FavoritesService();
  final _reviewService = ReviewService();

  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadReviews();
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.userId == null) return;
    try {
      setState(() => isLoadingFav = true);
      final res = await _favService.list(userId: widget.userId!);
      if (res['status'] == 'success') {
        final List data = res['data'];
        final found = data.any(
          (c) => c['carid'].toString() == widget.car['carid'].toString(),
        );
        setState(() => isFavorite = found);
      }
    } catch (_) {
      // ignore silently
    } finally {
      setState(() => isLoadingFav = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final result = await _reviewService.getReviews(widget.car['carid']);
      if (mounted) {
        final List<Map<String, dynamic>> data =
            (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          reviews = data;
          isLoadingReviews = false;
        });
      }
    } catch (_) {
      setState(() => isLoadingReviews = false);
    }
  }

  void _toggleFavorite() async {
    if (isLoadingFav || widget.userId == null) return;
    final bool newState = !isFavorite;
    setState(() => isLoadingFav = true);
    try {
      final res = await _favService.toggle(
        userId: widget.userId!,
        carId: widget.car['carid'],
        add: newState,
      );
      if (!mounted) return;
      if (res['status'] == 'success') {
        setState(() => isFavorite = newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState ? 'Added to favorites' : 'Removed from favorites',
            ),
          ),
        );
      }
    } finally {
      setState(() => isLoadingFav = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          "${car['manufacturer']} ${car['model']}",
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          CarFavoriteButton(
            isFavorite: isFavorite,
            isLoading: isLoadingFav,
            onTap: _toggleFavorite,
            enabled: widget.userId != null,
          ),
        ],
      ),
      bottomNavigationBar: BookNowBar(
        dailyRate: car['daily_rate'] ?? car['price'],
        currency: car['currency'] ?? 'PHP',
        onBook: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserCreateBookingscreen(car: car),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            CarHeaderSection(car: car),
            const SizedBox(height: 20),
            CarSpecsSection(car: car),
            const SizedBox(height: 20),

            /// ✅ Read-only reviews section
            CarReviewSection(carId: car['carid']),
          ],
        ),
      ),
    );
  }
}
