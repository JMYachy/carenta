import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carenta/service/config/service_base_url.dart';

/// Represents an unavailable range of dates for a car.
class UnavailableRange {
  final DateTime start;
  final DateTime end;

  const UnavailableRange(this.start, this.end);

  bool containsDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    // inclusive range check
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

class BookingValidationService {
  final http.Client _client;
  BookingValidationService({http.Client? client})
      : _client = client ?? http.Client();

  /// Builds URI for the API call
  Uri _buildUri(int carId, {String mode = 'ranges'}) {
    // ✅ File lives directly under /api/, not /user/
    final base = ServiceBaseUrl.endpoint('get_unavailable_dates.php');
    return Uri.parse('$base?carid=$carId&mode=$mode');
  }

  /// Fetches unavailable ranges for a specific car.
  Future<List<UnavailableRange>> fetchUnavailableRanges(int carId) async {
    try {
      final res = await _client.get(_buildUri(carId, mode: 'ranges'));
      if (res.statusCode != 200) {
        print('⚠️ HTTP ${res.statusCode}: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body);
      if (data is! Map || data['success'] != true) {
        print('⚠️ Unexpected response: $data');
        return [];
      }

      final list = (data['ranges'] as List?) ?? const [];

      DateTime _parseLocal(String value) {
        final parts = value.split('-').map(int.parse).toList();
        return DateTime(parts[0], parts[1], parts[2]); // local midnight
      }

      return list.map((r) {
        final s = _parseLocal(r['start'] as String);
        final e = _parseLocal(r['end'] as String);
        return UnavailableRange(s, e);
      }).toList(growable: false);
    } catch (e) {
      print('❌ fetchUnavailableRanges error: $e');
      return [];
    }
  }

  /// Fetches all blocked dates individually (for showDatePicker use).
  Future<List<DateTime>> fetchUnavailableDates(int carId) async {
    try {
      final res = await _client.get(_buildUri(carId, mode: 'dates'));
      if (res.statusCode != 200) {
        print('⚠️ HTTP ${res.statusCode}: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body);
      if (data is! Map || data['success'] != true) {
        print('⚠️ Unexpected response: $data');
        return [];
      }

      final list = (data['dates'] as List?) ?? const [];
      return list
          .map((e) => DateTime.parse(e as String))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toList(growable: false);
    } catch (e) {
      print('❌ fetchUnavailableDates error: $e');
      return [];
    }
  }

  /// Checks if a proposed range overlaps with any unavailable range.
  Future<bool> isRangeAvailable(
      int carId, DateTime start, DateTime end) async {
    final ranges = await fetchUnavailableRanges(carId);
    for (final r in ranges) {
      final overlap = !(end.isBefore(r.start) || start.isAfter(r.end));
      if (overlap) return false;
    }
    return true;
  }

  void close() => _client.close();
}
