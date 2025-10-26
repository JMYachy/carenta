class FavItem {
  final int carId;
  final String title;
  final String? imageUrl;
  final int pricePerDay;
  final int seats;
  final String transmission;
  final bool withDriver;
  final double rating;
  final List<String> tags;

  FavItem({
    required this.carId,
    required this.title,
    required this.imageUrl,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.withDriver,
    required this.rating,
    required this.tags,
  });

  static int _toInt(dynamic v, {int def = 0}) =>
      v == null ? def : (v is int ? v : int.tryParse(v.toString()) ?? def);
  static double _toDouble(dynamic v, {double def = 0}) =>
      v == null ? def : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? def);
  static String _toStr(dynamic v, {String def = ''}) => v?.toString() ?? def;

  factory FavItem.fromMap(Map<String, dynamic> m) {
    final carId = _toInt(m['carid']);
    final brand = _toStr(m['brand']);
    final model = _toStr(m['model']);
    final carname = _toStr(m['carname']);
    final title = carname.isNotEmpty
        ? carname
        : [brand, model].where((e) => e.isNotEmpty).join(' ');

    final image = _toStr(m['thumbnail_url'] ?? m['media_url']);
    final rate = _toInt(m['daily_rate']);
    final seats = _toInt(m['seats'] ?? m['capacity'] ?? m['max_seats'], def: 4);
    final trans = _toStr(m['transmission'], def: 'Automatic');
    final withDriver =
        (m['with_driver']?.toString() == '1') || (m['driver_available']?.toString() == '1');
    final rating = _toDouble(m['rating'], def: 4.5);
    final tags = <String>[
      if (withDriver) 'With driver' else 'Self-drive',
      if ((m['type'] ?? '').toString().isNotEmpty) m['type'].toString(),
    ];

    return FavItem(
      carId: carId,
      title: title.isEmpty ? 'Car #$carId' : title,
      imageUrl: image.isEmpty ? null : image,
      pricePerDay: rate,
      seats: seats,
      transmission: trans,
      withDriver: withDriver,
      rating: rating,
      tags: tags.where((e) => e.isNotEmpty).toList(),
    );
  }
}
