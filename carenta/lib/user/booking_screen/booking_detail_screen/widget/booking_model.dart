import 'package:flutter/foundation.dart';

@immutable
class BookingModel {
  final int rentalId;
  final String title;
  final String imageUrl;

  final DateTime start;
  final DateTime end;
  final String pickup;
  final String dropoff;

  final String rentalType;
  final String status;

  final double? totalAmount;
  final String paymentMethod;
  final String reference;

  const BookingModel({
    required this.rentalId,
    required this.title,
    required this.imageUrl,
    required this.start,
    required this.end,
    required this.pickup,
    required this.dropoff,
    required this.rentalType,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.reference,
  });

  static String _s(dynamic v) => (v ?? '').toString().trim();
  static int _i(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0);
  static double? _d(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(_s(v)));
  static DateTime _dt(dynamic d, dynamic t) {
    final sd = _s(d), st = _s(t);
    if (sd.isEmpty) return DateTime.now();
    return DateTime.tryParse(st.isEmpty ? sd : '$sd $st'.replaceFirst(' ', 'T')) ?? DateTime.now();
  }
  static String _first(List vals, {String fallback = ''}) {
    for (final v in vals) {
      final s = _s(v);
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  factory BookingModel.fromJson(Map<String, dynamic> j) {
    final manufacturer = _first([j['manufacturer'], j['brand']]);
    final model = _first([j['model'], j['name'], j['car_model']]);
    final title = _first([j['title'], '$manufacturer $model'.trim()],
        fallback: model.isNotEmpty ? model : manufacturer);

    final img = _first([
      j['image_url'],
      j['thumbnail_url'],
      j['media_url'],
      j['photo'],
      j['car_image'],
      j['image'],
    ]);

    return BookingModel(
      rentalId: _i(j['rentalid'] ?? j['rental_id']),
      title: title,
      imageUrl: img,
      start: _dt(j['start_date'], j['start_time']),
      end: _dt(j['end_date'], j['end_time']),
      pickup: _s(j['pickup_location']),
      dropoff: _s(j['dropoff_location']),
      rentalType: _first([j['rental_type']], fallback: 'self-drive'),
      status: _s(j['status']).isEmpty ? 'pending' : _s(j['status']),
      totalAmount: _d(j['total_amount'] ?? j['amount']),
      paymentMethod: _first([j['payment_method']], fallback: ''),
      reference: _first([j['reference_no'], j['transaction_id']], fallback: ''),
    );
  }
}
