import 'package:carenta/user/booking_detail_detail_screen/widget/booking_add_review_section.dart';
import 'package:carenta/user/booking_detail_detail_screen/widget/booking_cancelled_notice.dart';
import 'package:carenta/user/booking_detail_detail_screen/widget/booking_info_card.dart';
import 'package:carenta/user/booking_detail_detail_screen/widget/booking_payment_summary.dart';
import 'package:carenta/user/booking_detail_detail_screen/widget/booking_status_banner.dart';
import 'package:carenta/widget/shared/car_image_carousel.dart';
import 'package:carenta/service/user/review_service.dart';
import 'package:flutter/material.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final int? userId;

  const BookingDetailsScreen({super.key, required this.booking, this.userId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _reviewService = ReviewService();
  bool _canReview = false;
  bool _loadingReview = true;

  @override
  void initState() {
    super.initState();
    _checkIfCanReview();
  }

  Future<void> _checkIfCanReview() async {
    if (widget.userId == null) return;
    final carId = int.tryParse('${widget.booking['carid']}') ?? 0;
    final allowed = await _reviewService.canUserReview(widget.userId!, carId);
    if (!mounted) return;
    setState(() {
      _canReview = allowed;
      _loadingReview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final status = (booking['status'] ?? '').toString().toLowerCase();

    final carName =
        '${booking['manufacturer'] ?? ''} ${booking['model'] ?? ''}'.trim();
    final rentalType = (booking['rental_type'] ?? 'Self-drive').toString();
    final pickup = booking['pickup_location'] ?? '—';
    final dropoff = booking['dropoff_location'] ?? '—';
    final startDate = booking['start_date'] ?? '—';
    final endDate = booking['end_date'] ?? '—';
    final totalAmount =
        double.tryParse('${booking['total_amount'] ?? 0}') ?? 0.0;
    final currency = booking['currency'] ?? 'PHP';
    final symbol = currency == 'USD' ? '\$' : (currency == 'EUR' ? '€' : '₱');

    final media =
        booking['media'] ??
        booking['media_list'] ??
        booking['images'] ??
        booking['image_url'] ??
        '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _checkIfCanReview,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // 🖼️ Car Image Carousel
            CarImageCarousel(imageData: media),
            const SizedBox(height: 16),

            // 🟢 Status Banner
            BookingStatusBanner(status: status),
            const SizedBox(height: 16),

            // 🚗 Trip Details
            BookingInfoCard(
              title: "Trip Details",
              items: {
                "Car": carName,
                "Rental Type": rentalType,
                "Pickup Location": pickup,
                "Drop-off Location": dropoff,
                "Start Date": startDate,
                "End Date": endDate,
              },
            ),
            const SizedBox(height: 16),

            // 💳 Payment Summary
            BookingPaymentSummary(
              amount: totalAmount,
              method: booking['payment_method'] ?? 'Cash',
              status: booking['payment_status'] ?? '—',
              symbol: symbol,
            ),
            const SizedBox(height: 20),

            // 🟠 Status-based UI Blocks
            if (status == 'completed') ...[
              const Divider(thickness: 1.2),
              const SizedBox(height: 8),
              const Text(
                "Your Review",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _loadingReview
                  ? const Center(child: CircularProgressIndicator())
                  : _canReview
                  ? BookingAddReviewSection(
                    carId: int.tryParse('${booking['carid']}') ?? 0,
                    userId: widget.userId!,
                    onSubmitted: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Review added successfully!"),
                        ),
                      );
                      Navigator.pop(context, true);
                    },
                  )
                  : _reviewDoneMessage(),
            ],

            if (status == 'cancelled') ...[
              const SizedBox(height: 16),
              BookingCancelledNotice(
                reason:
                    booking['cancellation_reason'] ??
                    "This booking was cancelled.",
              ),
            ],

            if (status == 'ongoing') ...[
              const SizedBox(height: 16),
              _ongoingInfoCard(),
            ],

            if (status == 'confirmed') ...[
              const SizedBox(height: 16),
              _confirmedInfoCard(),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ Already reviewed message
  Widget _reviewDoneMessage() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "You have already reviewed this car.",
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  /// 🕒 Ongoing Info
  Widget _ongoingInfoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Colors.blue),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "Your rental is currently ongoing.\nPlease ensure the car is returned on time.",
            style: TextStyle(color: Colors.blue, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  /// 🟢 Confirmed Info
  Widget _confirmedInfoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.orange),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "Your booking is confirmed!\nPlease wait for pickup or contact support for any changes.",
            style: TextStyle(color: Colors.orange, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
