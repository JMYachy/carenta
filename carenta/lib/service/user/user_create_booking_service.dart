import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// BookingResult maps the response from create_booking.php
class BookingResult {
  final bool success;
  final String message;
  final int? rentalId;
  final int? carId;
  final int? userId;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final int? days;
  final double? totalAmount;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? status;
  final Map<String, dynamic>? raw;

  BookingResult({
    required this.success,
    required this.message,
    this.rentalId,
    this.carId,
    this.userId,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.days,
    this.totalAmount,
    this.pickupLocation,
    this.dropoffLocation,
    this.status,
    this.raw,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    double? toDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? toIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    String? pickStr(Map<String, dynamic> j, List<String> keys) {
      for (final k in keys) {
        if (j[k] != null && j[k].toString().isNotEmpty) {
          return j[k].toString();
        }
      }
      return null;
    }

    // Support both {success: true} and {ok: true}
    final okFlag = json.containsKey('success') ? json['success'] : json['ok'];

    return BookingResult(
      success: toBool(okFlag),
      message: (json['message'] ?? '').toString(),
      rentalId: toIntOrNull(json['rental_id'] ?? json['rentalId']),
      carId: toIntOrNull(json['carid'] ?? json['carId']),
      userId: toIntOrNull(json['userid'] ?? json['userId']),
      startDate: pickStr(json, ['start_date', 'startDate']),
      startTime: pickStr(json, ['start_time', 'startTime']),
      endDate: pickStr(json, ['end_date', 'endDate']),
      endTime: pickStr(json, ['end_time', 'endTime']),
      days: toIntOrNull(json['days'] ?? json['total_days']),
      totalAmount: toDoubleOrNull(json['total_amount'] ?? json['totalAmount']),
      pickupLocation: pickStr(json, ['pickup_location', 'pickupLocation', 'pickup']),
      dropoffLocation: pickStr(json, ['dropoff_location', 'dropoffLocation', 'dropoff']),
      status: pickStr(json, ['status']),
      raw: json,
    );
  }

  factory BookingResult.error(String message, {Map<String, dynamic>? raw}) {
    return BookingResult(success: false, message: message, raw: raw);
  }
}

/// ✅ Service that calls create_booking.php
class UserCreateBookingService {
  final http.Client _client;

  UserCreateBookingService({http.Client? client})
      : _client = client ?? http.Client();

  // Make sure this matches your actual file name & path on the server:
  // /public_html/api/create_booking.php
  String get _endpoint => ServiceBaseUrl.endpoint("create_booking.php");

  /// ✅ Create a booking (User → API)
  /// Dates: `YYYY-MM-DD`, Times: `HH:mm` (24h)
  Future<BookingResult> createBooking({
    required int carId,
    required int userId,
    required String startDate,
    required String endDate,
    required String startTime,
    String? endTime,
    required int totalDays,
    required double dailyRate,
    required double totalAmount,
    required String pickupLocation,
    required String dropoffLocation,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final uri = Uri.parse(_endpoint);

      // ✅ PHP usually expects snake_case keys
      final body = <String, String>{
        'carid': '$carId',
        'userid': '$userId',
        'start_date': startDate,
        'start_time': startTime.isNotEmpty ? startTime : "00:00",
        'end_date': endDate,
        'end_time': (endTime != null && endTime.isNotEmpty) ? endTime : "00:00",
        'pickup_location': pickupLocation.isNotEmpty ? pickupLocation : "-",
        'dropoff_location': dropoffLocation.isNotEmpty ? dropoffLocation : "-",
        'total_days': '$totalDays',                 // ✅ added
        'daily_rate': dailyRate.toStringAsFixed(2), // ✅ added
        'total_amount': totalAmount.toStringAsFixed(2),
      };

      final res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        return BookingResult.error(
          'HTTP ${res.statusCode}',
          raw: {'raw': res.body},
        );
      }

      Map<String, dynamic>? json;
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        return BookingResult.error(
          'Invalid server response',
          raw: {'raw': res.body},
        );
      }

      final result = BookingResult.fromJson(json);
      return result.success
          ? result
          : BookingResult.error(result.message, raw: json);
    } on TimeoutException {
      return BookingResult.error('Request timed out');
    } catch (e) {
      return BookingResult.error('Error: $e');
    }
  }

  void close() => _client.close();
}
