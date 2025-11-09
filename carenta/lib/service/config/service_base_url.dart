// lib/service/config/service_base_url.dart

class ServiceBaseUrl {
  static const String _base = "https://carentaph.com/";
  static const String _api = "${_base}api/";

  /// ✅ For PHP API endpoints (e.g. user_add_review.php)
  static String endpoint(String path) {
    if (path.startsWith('http')) return path;
    return '$_api$path';
  }

  /// ✅ For media or file URLs (e.g. car thumbnails, videos)
  static String file(String path) {
    if (path.isEmpty) return '${_base}uploads/placeholder_car.jpg';
    if (path.startsWith('http')) return path;

    // 🧩 Remove any leading slash to prevent "//uploads"
    final cleanPath = path.startsWith('/')
        ? path.substring(1)
        : path;

    return '$_base$cleanPath';
  }
}
