// lib/service/config/service_base_url.dart

class ServiceBaseUrl {
  // 🔹 Change this one line when moving between local and production
  static const String _base = "https://carentaph.com/";
  static const String _api = "${_base}api/";

  /// ✅ For PHP API endpoints (e.g. user_add_review.php)
  static String endpoint(String path) {
    if (path.startsWith('http')) return path;
    return '$_api$path';
  }

  /// ✅ For media or file URLs (e.g. car thumbnails, videos)
  static String file(String path) {
    if (path.startsWith('http')) return path;
    return '$_base$path'; // no /api/
  }
}
