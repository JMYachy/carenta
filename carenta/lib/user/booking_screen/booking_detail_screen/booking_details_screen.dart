import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_action_section.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_feedback_section.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_header_image.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_info_card.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_section_info.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_status_badge.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/widget/booking_timeline_tracker.dart';
import 'package:flutter/material.dart';
import 'package:carenta/user/booking_screen/booking_detail_screen/service/user_booking_action_service.dart';
import 'package:carenta/service/user/user_cancellation_request_service.dart';
import 'package:carenta/service/user/user_feedback_service.dart';

class UserBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const UserBookingDetailScreen({super.key, required this.booking});

  @override
  State<UserBookingDetailScreen> createState() =>
      _UserBookingDetailScreenState();
}

class _UserBookingDetailScreenState extends State<UserBookingDetailScreen> {
  final _bookingSvc = UserBookingActionService();
  final _cancelSvc = UserCancellationRequestService();
  final _feedbackSvc = UserFeedbackService();

  bool _loading = false;
  int _rating = 0;

  // ✅ persistent comment controller
  final TextEditingController _commentCtl = TextEditingController();

  @override
  void dispose() {
    _commentCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final status = (b['status'] ?? '').toString().toLowerCase();

    debugPrint(
      '🧠 Booking image data: ${b['media_url'] ?? b['car_image'] ?? b['image']}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BookingTimelineTracker(status: status),
                  const SizedBox(height: 8),

                  // ✅ unified image key
                  BookingHeaderImage(
                    imageUrl: b['media_url'] ?? b['car_image'] ?? b['image'],
                    carName:
                        '${b['manufacturer'] ?? ''} ${b['model'] ?? ''}'.trim(),
                  ),

                  const SizedBox(height: 12),
                  BookingStatusBadge(
                    rentalId: b['rentalid'],
                    status: status,
                    context: context,
                  ),
                  const SizedBox(height: 16),

                  // 🧾 Car Info
                  BookingInfoCard(
                    title: 'Car Information',
                    icon: Icons.directions_car_rounded,
                    children: [
                      BookingSectionInfo(label: 'Model', value: b['model']),
                      BookingSectionInfo(
                        label: 'Rental Type',
                        value: b['rental_type'],
                      ),
                      BookingSectionInfo(
                        label: 'Plate Number',
                        value: b['license_plate'],
                      ),
                      BookingSectionInfo(
                        label: 'With Driver',
                        value: b['withDriver'] ?? 'No',
                      ),
                    ],
                  ),

                  // 📅 Schedule
                  BookingInfoCard(
                    title: 'Schedule & Location',
                    icon: Icons.calendar_month_rounded,
                    children: [
                      BookingSectionInfo(
                        label: 'Pickup',
                        value: b['pickup_location'],
                      ),
                      BookingSectionInfo(
                        label: 'Dropoff',
                        value: b['dropoff_location'],
                      ),
                      BookingSectionInfo(
                        label: 'Start Date',
                        value: b['start_date'],
                      ),
                      BookingSectionInfo(
                        label: 'End Date',
                        value: b['end_date'],
                      ),
                    ],
                  ),

                  // 💰 Payment
                  BookingInfoCard(
                    title: 'Payment',
                    icon: Icons.payments_rounded,
                    children: [
                      BookingSectionInfo(
                        label: 'Payment Method',
                        value: b['payment_method'] ?? 'Unpaid',
                      ),
                      BookingSectionInfo(
                        label: 'Total Amount',
                        value: '₱${b['total_amount']}',
                      ),
                    ],
                  ),

                  // ⚙️ Actions
                  if (['pending', 'confirmed', 'ongoing'].contains(status))
                    BookingActionSection(
                      status: status,
                      rentalId: b['rentalid'],
                      userId: b['userid'],
                      onCancel: _handleCancel,
                    ),

                  // ⭐ Review
                  if (status == 'completed')
                    BookingFeedbackSection(
                      rating: _rating,
                      onRatingChange: (r) => setState(() => _rating = r),
                      commentController: _commentCtl, // ✅ persistent
                      onSubmit: _saveFeedback,
                    ),
                ],
              ),
    );
  }

  Future<void> _handleCancel({
    required int rentalId,
    required int userId,
    required bool isRequest,
    required String reason,
  }) async {
    setState(() => _loading = true);
    final res =
        isRequest
            ? await _cancelSvc.submitRequest(
              rentalId: rentalId,
              userId: userId,
              reason: reason,
            )
            : await _bookingSvc.updateStatus(
              rentalId,
              'cancel',
              reason: reason,
            );
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']),
        backgroundColor:
            res['success'] == true ? Colors.green : Colors.redAccent,
      ),
    );

    if (res['success'] == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveFeedback() async {
    final comment = _commentCtl.text.trim();
    if (_rating <= 0 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rating and your review comment.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final res = await _feedbackSvc.saveFeedback(
      userId: widget.booking['userid'],
      carId: widget.booking['carid'],
      rating: _rating,
      title: '', // title removed
      comment: comment,
    );
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']),
        backgroundColor:
            res['success'] == true ? Colors.green : Colors.redAccent,
      ),
    );

    if (res['success'] == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}
