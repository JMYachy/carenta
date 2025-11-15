import 'package:flutter/material.dart';
import 'package:carenta/service/user/user_favorite_service.dart';
import 'package:carenta/service/util_service/session_manager_service.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/section/book_now_bar.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/section/car_favorite_section.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/section/car_header_section.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/section/car_specs_section.dart';
import 'package:carenta/user/user_home_screen/car_details_screen/section/car_rating_and_reviews_section.dart';
import 'package:carenta/user/user_home_screen/create_booking_screen/user_create_booking_screen.dart';

class UserCarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  const UserCarDetailsScreen({super.key, required this.car});

  @override
  State<UserCarDetailsScreen> createState() => _UserCarDetailsScreenState();
}

class _UserCarDetailsScreenState extends State<UserCarDetailsScreen> {
  bool isFavorite = false;
  bool isLoadingFav = false;
  int? userId;

  // 🔐 new: track if user is verified
  bool isVerified = false;

  final _favService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final session = await SessionManagerService.checkSession();

    print("SESSION DEBUG: $session"); // 🔍 SEE WHAT THE API RETURNS

    if (session['success'] == true) {
      final data = session['data'] ?? {};

      setState(() {
        userId = data['userid'];

        final v =
            data['is_verified'] ??
            data['verified'] ??
            data['verification_status'] ??
            data['status'] ??
            data['isVerified'] ??
            0;

        print("VERIFIED RAW VALUE = $v"); // 🔍 Print actual raw value

        isVerified =
            v == 1 || v == true || v == '1' || v == 'true' || v == 'verified';
      });

      await _checkFavoriteStatus();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (userId == null) return;
    try {
      setState(() => isLoadingFav = true);
      final res = await _favService.list(userId: userId!);
      if (res['status'] == 'success') {
        final List data = res['data'];
        final found = data.any(
          (c) => c['carid'].toString() == widget.car['carid'].toString(),
        );
        setState(() => isFavorite = found);
      }
    } finally {
      setState(() => isLoadingFav = false);
    }
  }

  void _toggleFavorite() async {
    if (isLoadingFav || userId == null) return;

    final bool newState = !isFavorite;
    setState(() => isLoadingFav = true);

    try {
      final res = await _favService.toggle(
        userId: userId!,
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

  /// 🧩 Normalize the car data to match the expected keys
  Map<String, dynamic> get normalizedCar {
    final raw = widget.car;
    return {
      'carid': raw['carid'] ?? raw['id'],
      'manufacturer': raw['manufacturer'] ?? raw['brand'] ?? '',
      'model': raw['model'] ?? raw['name'] ?? '',
      'type': raw['type'] ?? raw['car_type'] ?? '',
      'color': raw['color'] ?? raw['car_color'] ?? '',
      'milage': raw['milage'] ?? raw['mileage'] ?? raw['odometer'] ?? '',
      'transmission': raw['transmission'] ?? '',
      'fueltype': raw['fueltype'] ?? raw['fuel_type'] ?? '',
      'seatingcap': raw['seatingcap'] ?? raw['seating_capacity'] ?? '',
      'status': raw['status'] ?? '',
      'withDriver': raw['withDriver'] ?? raw['with_driver'] ?? 'No',
      'daily_rate': raw['daily_rate'] ?? raw['price'] ?? 0,
      'currency': raw['currency'] ?? 'PHP',
      'media_url':
          raw['media_url'] ??
          raw['thumbnail_url'] ??
          raw['image_url'] ??
          'https://via.placeholder.com/600x400?text=No+Image',
    };
  }

  @override
  Widget build(BuildContext context) {
    final car = normalizedCar;

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
            enabled: userId != null,
          ),
        ],
      ),

      /// 💰 Bottom booking bar
      bottomNavigationBar: BookNowBar(
        dailyRate: car['daily_rate'] ?? 0,
        currency: car['currency'] ?? 'PHP',
        onBook: () {
          // 🔐 Simple verification guard
          if (!isVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account is not verified. Please complete verification before booking.',
                ),
              ),
            );

            // Optional: navigate to profile / verification screen here
            // Navigator.pushNamed(context, '/user/profile');

            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserCreateBookingscreen(car: car),
            ),
          );
        },
      ),

      /// 🧾 Body
      body: RefreshIndicator(
        onRefresh: _checkFavoriteStatus,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            CarHeaderSection(car: car), // 🖼️ Image + title
            const SizedBox(height: 20),
            CarSpecsSection(car: car), // ⚙️ Specs (fuel, trans, seats)
            const SizedBox(height: 20),
            CarRatingsAndReviewsSection(
              carId: car['carid'],
              carName: "${car['manufacturer']} ${car['model']}",
            ),
          ],
        ),
      ),
    );
  }
}
